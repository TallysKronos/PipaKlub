extends SceneTree
## Campaign walker (F05/F06 of MAPA-DE-REFINAMENTOS): plays the main story from a QA
## jump to the credits through the real frontend. Each step reads the current beat,
## travels to the scene that holds its event (map exits or the city map), walks there
## on the map's own path, presses interact, answers every dialogue and settles every
## duel through the battle view's finish signal. Between beats it closes and reopens
## the app on the same save. Nothing is written to the save except through the game.
##   godot --path godot -s tools/campaign_walker.gd -- --from=serra [--until=final] [--motion] [--shots]
## Report: tmp/campaign-walk/report.md (+ PNGs with --shots).
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const Story = preload("res://scripts/campaign/kronasta_story.gd")
const Endgame = preload("res://scripts/campaign/endgame_story.gd")

var view: Node
var store_path := ""
var folder := ""
var log := PackedStringArray()
var issues := PackedStringArray()
var shots := false
var motion := false
var shot_index := 0
var beat_id := ""
var seen_dialogs := {}
var duels := 0
var exhausted := {}

## Story actions that finish (part of) a beat, by beat id. District beats use the next
## duel of the district; endgame steps use their own event.
const ACTIONS := {
	"tufanocorte": ["tufanocorteStory"],
	"serra-habilidades": ["learnDig","serraGalleryReturn","serraWind","serraDig"],
	"rabiolava": ["aracatiTerreiro"],
	"ruinas-aliados": ["ruinasDuel"],
	"rato": ["ruinasChamber","ruinasDuel"],
	"eremor": ["ruinasChamber","ruinasDuel"],
	"final": ["ruinasDuel"],
	"homunculo": ["study"],
}
const DISTRICTS := {"dona-neve":"alto-da-serra","leo-antena":"centro","taina":"lajes","jurandir":"porto","icaro":"mirante"}
const BEAT_SCENES := {
	"tufanocorte": ["kronasta-montanha-c"], "serra-habilidades": ["kronasta-montanha-c","mina-ferro-a"],
	"rabiolava": ["kronasta-aracati-c"], "ruinas-aliados": ["kronasta-coracao-a","kronasta-coracao-b","kronasta-coracao-c"],
	"rato": ["kronasta-coracao-c","kronasta-coracao-d"], "eremor": ["kronasta-coracao-d"], "final": ["kronasta-estadio-a"],
}

func _initialize() -> void:
	run.call_deferred()

func arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="): return a.trim_prefix("--" + name + "=")
	return fallback

func note(text: String) -> void:
	log.append(text)
	print(text)

func issue(text: String) -> void:
	issues.append("[" + beat_id + "] " + text)
	note("ISSUE " + text)

func run() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	motion = "--motion" in OS.get_cmdline_user_args()
	Engine.time_scale = float(arg("speed", "3"))
	folder = ProjectSettings.globalize_path("res://").get_base_dir().path_join("../tmp/campaign-walk").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1280, 720)
	store_path = "user://campaign-walk-" + State.new_id()
	await open_app(true, arg("from", "serra"))
	var until := arg("until", "final")
	var guard := 0
	while guard < 400:
		guard += 1
		var player: Dictionary = view.session.snapshot().player
		var beat: Dictionary = Story.current_beat(player)
		if player.flags.get("campeaoKronasta", false) and player.flags.get("kronastaEndingSeen", false):
			note("== campanha concluída"); break
		var id: String = beat.get("id", "final")
		if id != beat_id:
			if beat_id == until: break
			beat_id = id
			note("\n## " + id + " — " + str(beat.get("text", "")))
			await restart_app()
		if not await step(beat):
			issue("sem ação possível; parado em " + scene_now() + " · objetivo HUD: " + hud_objective())
			await shot("stall")
			break
	finish()

## ---------------------------------------------------------------- app lifecycle

func open_app(fresh: bool, from: String = "") -> void:
	view = FrontEnd.new()
	root.add_child(view)
	view.preferences.reduced_motion = not motion
	view.preferences.fullscreen = false
	# The title screen opens a few frames after start; loading before it cancels the load.
	for i in 30: await process_frame
	view.session._store = Store.new(store_path)
	if fresh:
		view.session.start("slot-1")
		var result: Dictionary = QA.install(view.session, from)
		if result.status != "ok": issue("salto QA recusado: " + str(result)); return
	# Same path as "Continuar" on the title screen.
	view._choose("slot-1", false)
	await settle()
	if not park_ready() and not is_instance_valid(view.room): issue("save não reabriu a exploração")

func restart_app() -> void:
	var before: Dictionary = view.session.snapshot()
	view.queue_free()
	await process_frame
	await process_frame
	await open_app(false)
	var after: Dictionary = view.session.snapshot()
	if after.checkpoint.get("scene") != before.checkpoint.get("scene"): issue("reabrir mudou a cena: %s → %s" % [before.checkpoint.get("scene"), after.checkpoint.get("scene")])
	if Story.current_beat(after.player).get("id") != Story.current_beat(before.player).get("id"): issue("reabrir mudou o passo")

## Waits for loads, answers dialogues and settles battles until the world is idle.
func settle(limit: int = 900) -> void:
	var idle := 0
	for i in limit:
		await process_frame
		if handle_battle() or await handle_dialogs():
			idle = 0
			continue
		if is_instance_valid(view.scene_loading) or view.flow_busy:
			idle = 0; continue
		idle += 1
		if idle > 20: return

func handle_battle() -> bool:
	if not is_instance_valid(view.battle) or view.battle.is_queued_for_deletion(): return false
	var b = view.battle
	if b.get("_walker_done"): return true
	b.set("_walker_done", true)
	var enc: Dictionary = view.session.snapshot().player.get("encounter", {})
	duels += 1
	note("   duelo: %s (%s, Nv %s)" % [str(enc.get("state", {}).get("q", {}).get("name", "?")), str(enc.get("kind", "")), str(enc.get("state", {}).get("q", {}).get("level", "?"))])
	b.model.outcome = "won"
	b.finish_requested.emit()
	return true

func handle_dialogs() -> bool:
	for node in get_nodes_in_group("manga_dialogue"):
		if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.visible or node.get("_closed"): continue
		var key := str(node.get_instance_id())
		if not seen_dialogs.has(key):
			seen_dialogs[key] = true
			var title := str(node.get("title"))
			var text := str(node.get("dialog_text"))
			note("   [%s] %s → %s" % [title, text.replace("\n\n", " / ").replace("\n", " "), str(node.get("ok_button_text"))])
			if title == "Aviso" and looks_like_error(text): issue("aviso de erro: " + text)
			await shot("dialog")
		await process_frame
		if is_instance_valid(node) and not node.get("_closed"): node._finish(true)
		return true
	for node in view.find_children("*", "ConfirmationDialog", true, false):
		if node.visible:
			note("   [painel %s] %s" % [node.title, node.ok_button_text])
			await shot("panel")
			node.confirmed.emit()
			return true
	return false

func looks_like_error(text: String) -> bool:
	for word in ["Não foi possível", "não está disponível", "Conclua", "Vença os quatro", "primeiro", "ainda"]:
		if text.contains(word): return true
	return false

func shot(tag: String) -> void:
	if not shots or DisplayServer.get_name() == "headless": return
	shot_index += 1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("%03d-%s-%s.png" % [shot_index, beat_id, tag]))

## ---------------------------------------------------------------- world queries

func scene_now() -> String:
	return str(view.session.snapshot().checkpoint.get("scene", ""))

func hud_objective() -> String:
	if is_instance_valid(view.park) and view.park.get("exploration_hud") != null and is_instance_valid(view.park.exploration_hud):
		return str(view.park.exploration_hud.objective.text)
	return ""

func park_ready() -> bool:
	return is_instance_valid(view.park) and view.park.has_method("interact") and view.park.get("model") != null

func events_of(scene: String) -> Array:
	if is_instance_valid(view.park) and view.park.get("area_id") != null and scene_now() == scene and view.park.get("interaction_events") != null:
		return view.park.interaction_events
	if not CP.MAPS.has(scene): return []
	return CP.model_for(scene).data.events

## The event that advances this beat, as [scene, event]; empty when none is open.
func target(beat: Dictionary) -> Array:
	var player: Dictionary = view.session.snapshot().player
	var id: String = beat.get("id", "")
	var scenes: Array = []
	if Endgame.STEPS.has(id): scenes = [Endgame.STEPS[id].scene]
	elif DISTRICTS.has(id):
		var district: String = DISTRICTS[id]
		for stage in Rules.definition(district).stages:
			if Rules.prepare(player, district, stage.id).status == "ok":
				return find_event(Rules.definition(district).stages.map(func(s): return str(s.get("scene", ""))), func(e): return e.props.get("duel", "") == stage.id)
		return []
	else: scenes = BEAT_SCENES.get(id, [])
	var wanted: Array = ACTIONS.get(id, [])
	return find_event(scenes, func(e):
		var a: String = e.props.get("acao", "")
		if Endgame.STEPS.has(id): return a == "endgameStep" and e.props.get("step", "") == id
		if a not in wanted or not CP.allowed(e, player, ""): return false
		if exhausted.has(str(scene_key(e))): return false
		if a == "ruinasDuel" and e.props.has("rescueFlag") and player.flags.get(e.props.rescueFlag, false): return false
		return true)

func find_event(scenes: Array, matcher: Callable) -> Array:
	var ordered: Array = scenes.duplicate()
	if scene_now() in ordered: ordered.erase(scene_now()); ordered.push_front(scene_now())
	for scene in ordered:
		for e in events_of(str(scene)):
			if matcher.call(e): return [str(scene), e]
	return []

## ---------------------------------------------------------------- acting

func step(beat: Dictionary) -> bool:
	var found := target(beat)
	if found.is_empty():
		issue("nenhum evento abre o passo; cena " + scene_now())
		return false
	if not await go_to(found[0]): return false
	# Re-read the event from the live view (injected events carry runtime ids).
	found = target(beat)
	if found.is_empty() or found[0] != scene_now(): issue("evento sumiu ao chegar"); return false
	var hud := hud_objective()
	note("   em %s · HUD: %s" % [scene_now(), hud])
	if hud.strip_edges().is_empty(): issue("HUD sem objetivo em " + scene_now())
	var event: Dictionary = found[1]
	if not await walk_to(Vector2(event.u + .5, event.v + .5), 1.5): return false
	var nearby: Dictionary = view.park.nearby
	if nearby.is_empty() or str(nearby.get("id")) != str(event.get("id")):
		issue("ao lado de '%s' o botão aponta para '%s'" % [event.get("name"), nearby.get("name", "nada")])
	var before := JSON.stringify(view.session.snapshot().player)
	view.park.interact()
	await settle()
	if JSON.stringify(view.session.snapshot().player) == before and scene_now() == found[0]:
		# Probably an earlier sub-step of this beat; try the next action before giving up.
		note("   (sem mudança em '%s'; tentando a próxima ação)" % event.get("name"))
		exhausted[scene_key(event)] = true
		return not target(beat).is_empty()
	exhausted.clear()
	return true

func scene_key(e: Dictionary) -> String:
	return "%s:%s:%s" % [str(e.get("name")), str(e.u), str(e.v)]

func go_to(scene: String) -> bool:
	for hop in 12:
		await settle()
		var here := scene_now()
		if here == scene and park_ready(): return true
		var route := route_between(here, scene)
		if route.is_empty():
			note("   viagem pelo mapa da cidade: %s → %s" % [here, entry_of(scene)])
			view._travel_kronasta(entry_of(scene))
			await settle()
			if scene_now() == here: issue("mapa da cidade recusou viajar para " + entry_of(scene)); return false
			continue
		var exit: Dictionary = route[0]
		note("   saída '%s' (%s → %s)" % [exit.name, here, exit.props.destino])
		if not await walk_to(Vector2(exit.u + .5, exit.v + .5), .4): return false
		for i in 60:
			await process_frame
			if scene_now() != here: break
		if scene_now() == here and park_ready():
			view.park.interact()
			await settle()
		if scene_now() == here: issue("saída '%s' não levou a %s" % [exit.name, exit.props.destino]); return false
	issue("não chegou a " + scene)
	return false

func entry_of(scene: String) -> String:
	var region := CP.region_of(scene)
	return "kronasta-%s-a" % region if not region.is_empty() else scene

## Exits to take inside a region, by breadth-first search over map exits.
func route_between(from: String, to: String) -> Array:
	if CP.region_of(from) != CP.region_of(to) or CP.region_of(from).is_empty(): return []
	var player: Dictionary = view.session.snapshot().player
	var queue := [[from, []]]
	var seen := {from: true}
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		if item[0] == to: return item[1]
		for e in events_of(str(item[0])):
			if e.type != "saida" or not CP.MAPS.has(str(e.props.get("destino", ""))): continue
			if not CP.allowed(e, player, ""): continue
			var next: String = e.props.destino
			if seen.has(next): continue
			seen[next] = true
			queue.append([next, item[1] + [e]])
	return []

func walk_to(goal: Vector2, reach: float) -> bool:
	if not park_ready():
		issue("sem mapa para andar (park=%s room=%s loading=%s busy=%s filhos=%s)" % [str(view.park), str(view.get("room")), str(view.scene_loading), str(view.flow_busy), str(view.get_children().map(func(c): return c.get_class() + ":" + str(c.name)))])
		return false
	var park = view.park
	var model = park.model
	var best := Vector2.INF
	var path := PackedVector2Array()
	var best_clear := false
	for dv in [Vector2.ZERO, Vector2(0,1), Vector2(1,0), Vector2(-1,0), Vector2(0,-1), Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]:
		var candidate: Vector2 = goal + dv
		if not model.point_walkable(candidate): continue
		var route: PackedVector2Array = model.path_to(park.player, candidate)
		if route.is_empty() and park.player.distance_to(candidate) > .1: continue
		# Prefer a spot where the interact button points at this target, as a player would.
		var clear: bool = reach > 1.0 and nearest_event(candidate) == goal
		if best == Vector2.INF or (clear and not best_clear) or (clear == best_clear and route.size() < path.size()):
			best = candidate; path = route; best_clear = clear
	if best == Vector2.INF:
		issue("sem caminho até (%.1f, %.1f) em %s" % [goal.x, goal.y, scene_now()])
		await shot("noroute")
		return false
	park.path = path
	var last: Vector2 = park.player
	var still := 0
	for i in 4000:
		await process_frame
		if handle_battle() or await handle_dialogs():
			await settle()
			if not park_ready() or view.park != park: return false
			park.path = model.path_to(park.player, best)
			continue
		if park.path.is_empty(): break
		if park.player == last:
			still += 1
			if still > 240: issue("parado no caminho em %s perto de %s" % [scene_now(), str(park.player)]); return false
		else: still = 0
		last = park.player
	return park.player.distance_to(goal) <= reach + 1.5

## The event the interact button would pick standing at a point (same rule as the view).
func nearest_event(at: Vector2) -> Vector2:
	var park = view.park
	var found := Vector2.INF
	var nearest := 1.8
	for event in park.interaction_events:
		if event.type == "entrada" or not CP.allowed(event, park.saved_player, park.area_id): continue
		var spot := Vector2(event.u + .5, event.v + .5)
		var gap := at.distance_to(spot)
		if gap < nearest and absf(park.model.height_at(at) - park.model.height_at(spot)) < .25:
			found = spot; nearest = gap
	return found

func finish() -> void:
	var report := PackedStringArray(["# Percurso da campanha", "", "Início: salto QA `%s`. Duelos: %d. Problemas: %d." % [arg("from", "serra"), duels, issues.size()], ""])
	if not issues.is_empty():
		report.append("## Problemas"); report.append("")
		for i in issues: report.append("- " + i)
		report.append("")
	report.append("## Registro"); report.append_array(log)
	var file := FileAccess.open(folder.path_join("report.md"), FileAccess.WRITE)
	file.store_string("\n".join(report) + "\n")
	print("REPORT ", folder.path_join("report.md"), " issues=", issues.size())
	quit(1 if not issues.is_empty() else 0)
