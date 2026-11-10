extends SceneTree
## Review the campaign view with in-memory checkpoints and capture its actors.

const View = preload("res://scripts/campaign/park_overworld_view.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const Story = preload("res://scripts/campaign/endgame_story.gd")
const ATTENDANT := "res://assets/npc-ds/estadio-v1/atendente.png"
const NEVE := "res://assets/npc-ds/serra-v1/dona-neve.png"
const PRODUCER := "res://assets/npc-ds/historia-v1/produtor-pipa-tv.png"
const RANGER := "res://assets/npc-ds/historia-v1/guarda-parque-dito.png"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var folder := ProjectSettings.globalize_path("res://../documentation/campaign/overworld-sprites/capturas")
	DirAccess.make_dir_recursive_absolute(folder)
	var player: Dictionary = State.fresh("slot-1").player
	player.journey = {"lesson":5, "phase":"complete"}
	for district: Dictionary in Rules.catalog():
		var entry: Dictionary = Rules.entry(player, district.id)
		entry.completed = true
		entry.champion = "player"
		Rules.store(player, district.id, entry)
	player.flags.ruinasChefeVencido = true
	player.flags.enamorDerrotado = true
	player.flags.tufanocorteLiberto = true
	var selected := OS.get_cmdline_user_args()
	var relocated := {
		"mirante-icaro": Vector2(23.5, 8.5),
		"serra-veyl": Vector2(22.5, 17.5),
		"serra-oren": Vector2(26.5, 14.5),
	}
	for target in [
		["kronasta-feira-a", Vector2(20.5, 27.5), "res://assets/npc-ds/feira-v1/lalau.png", "feira-lalau", 13],
		["kronasta-estadio-a", Vector2(24.5, 8.1), ATTENDANT, "estadio-atendente", 32002],
		["kronasta-montanha-c", Vector2(24.5, 12.5), NEVE, "serra-dona-neve"],
		["kronasta-centro-a", Story.point("kronasta-centro-a", Story.STEPS.reuniao.anchor) + Vector2(0, 1), NEVE, "reuniao-dona-neve"],
		["kronasta-centro-c", Vector2(24.5, 8.5), "res://assets/npc-ds/centro-v1/leo-antena.png", "centro-leo-antena"],
		["kronasta-lajes-c", Vector2(24.5, 8.5), "res://assets/npc-ds/lajes-v1/taina.png", "lajes-taina"],
		["kronasta-porto-c", Vector2(24.5, 8.5), "res://assets/npc-ds/porto-v1/jurandir.png", "porto-jurandir"],
		["kronasta-mirante-c", Vector2(24.5, 8.5), "res://assets/npc-ds/mirante-v1/icaro.png", "mirante-icaro"],
		["kronasta-centro-a", Vector2(24.5, 32.5), "res://assets/npc-ds/centro-v1/vitra.png", "centro-vitra"],
		["kronasta-centro-a", Vector2(24.5, 13.5), "res://assets/npc-ds/centro-v1/davi.png", "centro-davi"],
		["kronasta-centro-b", Vector2(24.5, 32.5), "res://assets/npc-ds/centro-v1/sinal.png", "centro-sinal"],
		["kronasta-centro-b", Vector2(24.5, 13.5), "res://assets/npc-ds/centro-v1/oriel.png", "centro-oriel"],
		["kronasta-centro-c", Vector2(24.5, 13.5), "res://assets/npc-ds/centro-v1/fantasma.png", "centro-pipeiro-fantasma"],
		["kronasta-lajes-a", Vector2(24.5, 32.5), "res://assets/npc-ds/lajes-v1/jair.png", "lajes-jair"],
		["kronasta-lajes-a", Vector2(24.5, 13.5), "res://assets/npc-ds/lajes-v1/livia.png", "lajes-livia"],
		["kronasta-lajes-b", Vector2(24.5, 32.5), "res://assets/npc-ds/lajes-v1/tome.png", "lajes-tome"],
		["kronasta-lajes-b", Vector2(24.5, 13.5), "res://assets/npc-ds/lajes-v1/rute.png", "lajes-rute"],
		["kronasta-porto-a", Vector2(24.5, 28.5), "res://assets/npc-ds/porto-v1/neris.png", "porto-neris"],
		["kronasta-porto-a", Vector2(18.5, 13.5), "res://assets/npc-ds/porto-v1/varko.png", "porto-varko"],
		["kronasta-porto-b", Vector2(31.5, 34.5), "res://assets/npc-ds/porto-v1/elune.png", "porto-elune"],
		["kronasta-porto-b", Vector2(12.5, 13.5), "res://assets/npc-ds/porto-v1/tervan.png", "porto-tervan"],
		["kronasta-mirante-a", Vector2(24.5, 32.5), "res://assets/npc-ds/mirante-v1/vael.png", "mirante-vael"],
		["kronasta-mirante-a", Vector2(24.5, 13.5), "res://assets/npc-ds/mirante-v1/ilyra.png", "mirante-ilyra"],
		["kronasta-mirante-b", Vector2(24.5, 32.5), "res://assets/npc-ds/mirante-v1/orvik.png", "mirante-orvik"],
		["kronasta-mirante-b", Vector2(24.5, 13.5), "res://assets/npc-ds/mirante-v1/senael.png", "mirante-senael"],
		["kronasta-montanha-a", Vector2(22.5, 18.5), "res://assets/npc-ds/serra-v1/veyl.png", "serra-veyl"],
		["kronasta-montanha-a", Vector2(22.5, 9.5), "res://assets/npc-ds/serra-v1/sora.png", "serra-sora"],
		["kronasta-montanha-b", Vector2(26.5, 15.5), "res://assets/npc-ds/serra-v1/oren.png", "serra-oren"],
		["kronasta-montanha-b", Vector2(22.5, 9.5), "res://assets/npc-ds/serra-v1/kaiva.png", "serra-kaiva"],
		["parque-patio-liga", Vector2(18.5, 24.5), Story.CIDA_SPRITE, "liga-cida-azul", 5],
		["kronasta-centro-a", Story.point("kronasta-centro-a", Story.STEPS["exame-vermelho"].anchor) + Vector2(0, 1), Story.CIDA_SPRITE, "liga-cida-vermelha", "exame-vermelho"],
		["kronasta-centro-a", Story.point("kronasta-centro-a", Story.STEPS["copa-relampago"].anchor) + Vector2(0, 1), Story.CIDA_SPRITE, "liga-cida-dourada", "copa-relampago"],
		["kronasta-centro-a", Story.point("kronasta-centro-a", Story.STEPS["pipa-tv"].anchor) + Vector2(0, 1), PRODUCER, "centro-produtor-pipa-tv", "pipa-tv"],
		["kronasta-bosque-a", Vector2(25.5, 36.5), RANGER, "bosque-guarda-parque-dito", 943],
		["kronasta-bosque-d", Vector2(33.5, 14.0), "res://assets/campaign/retalho-mascarada-v1/overworld.png", "bosque-retalho-mascarada", 18620],
		story_target("trovareta", Story.NAVALHA, "bosque-navalha", {"aracatiRabiolavaLivre":true}),
		story_target("desalmado-centro", Story.DESALMADO, "noite-desalmado-centro", {"tylerCreatedKnown":true,"bracadeiraBando":true}),
		story_target("desalmado-lajes", Story.DESALMADO, "noite-desalmado-lajes", {"tylerCreatedKnown":true,"bracadeiraBando":true}),
		story_target("galpao", Story.PETECA, "galpao-peteca", {"tylerCreatedKnown":true}),
		story_target("galpao", Story.COLA_FINA, "galpao-cola-fina", {"tylerCreatedKnown":true,"endgame-galpao-0":true}),
		story_target("galpao", Story.NAVALHA, "galpao-navalha", {"tylerCreatedKnown":true,"endgame-galpao-0":true,"endgame-galpao-1":true}),
		story_target("galpao", Story.CAPANGA, "galpao-capanga", {"tylerCreatedKnown":true,"endgame-galpao-0":true,"endgame-galpao-1":true,"endgame-galpao-2":true}),
		story_target("galpao", Story.CAPANGA_F, "galpao-capanga-feminina", {"tylerCreatedKnown":true,"endgame-galpao-0":true,"endgame-galpao-1":true,"endgame-galpao-2":true,"endgame-galpao-3":true}),
		story_target("barreira", Story.CAPANGA_F, "noite-capanga-barreira", {"tylerCreatedKnown":true}),
		story_target("gollia-bando", Story.STEPS["gollia-bando"].sprite, "galpao-gollia", {"galpaoInvadido":true,"tylerCreatedKnown":true}),
		story_target("gollia-arrependimento", Story.STEPS["gollia-arrependimento"].sprite, "camara-gollia-arrependido", {"ruinasJamileLivre":true}),
		["kronasta-bosque-c", Story.point("kronasta-bosque-c", Story.STEPS.trovareta.anchor), Story.KIT+"rato-idle-eight.png", "bosque-rato-vigia", null, {"trovaretaLivre":true}],
		["kronasta-coracao-d", Vector2(24.5,18.5), Story.KIT+"rato-idle-eight.png", "camara-rato", 31002, {"enamorDerrotado":false,"golliaArrependido":true}],
	]:
		if not selected.is_empty() and not selected.has(target[3]):
			continue
		var view = View.new()
		view.saved_checkpoint = CP.make(target[0], CP.safe(target[0], target[1]), CP.SPACE)
		view.saved_player = player.duplicate(true)
		if target.size() > 5:
			view.saved_player.flags.merge(target[5], true)
		elif target.size() > 4 and target[4] is String:
			var step: Dictionary = Story.STEPS[target[4]]
			view.saved_player.flags[step.requires] = true
		view.content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
		view.reduced_motion = target[3] not in ["noite-desalmado-centro","camara-gollia-arrependido"]
		root.add_child(view)
		view.set_physics_process(false)
		var scope: Node = view.actors
		if target[3] == "reuniao-dona-neve":
			view.stage_endgame("reuniao")
			scope = view.actors.get_node("EndgameStaging")
		var actor := find_actor(scope, target[2])
		if actor == null:
			printerr("Actor texture missing in " + str(target[0]) + ": " + str(target[2]))
			if target.size() > 5 and target[4] is String:
				printerr("Story event ready: ", Story.ready(view.saved_player, target[4]))
				printerr("Interaction event: ", view.interaction_events.filter(func(event: Dictionary): return event.props.get("step", "") == target[4]))
				for npc: Dictionary in view.npc_nodes:
					if npc.root.get_meta("event", {}).get("props", {}).get("step", "") != target[4]: continue
					for child in npc.visual.get_children():
						if child is Sprite2D: printerr("Rendered texture: ", child.texture, " visible: ", child.is_visible_in_tree())
			quit(1)
			return
		if target.size() > 4 and target[4] != null:
			var actions: Array[String] = []
			view.action_requested.connect(func(action: String): actions.append(action))
			view._physics_process(0.0)
			var event: Dictionary = view.nearby
			var expected = target[4]
			if event.is_empty() or (event.props.get("step", "") != expected if expected is String else int(event.id) != expected):
				printerr("Wrong nearby event at " + str(target[3]) + ": " + str(event))
				quit(1)
				return
			if view.model.path_to(CP.spawn(target[0]), view.player).is_empty():
				printerr("Cannot approach " + str(target[3]) + " from the entrance")
				quit(1)
				return
			view.interact()
			if actions != ["park-event:" + str(int(event.id))]:
				printerr("Interaction did not open at " + str(target[3]))
				quit(1)
				return
			if str(target[3]).begins_with("noite-desalmado"):
				var initial_y := actor.position.y
				await create_timer(0.3).timeout
				if (absf(actor.position.y - initial_y) > 0.1) == view.reduced_motion:
					printerr("Unexpected Desalmado hover at " + str(target[3]))
					quit(1)
					return
			if expected is String and expected == "galpao":
				var marks := view.actors.get_node_or_null("NightMarks") as Node2D
				var knots := 0
				if marks != null:
					for mark in marks.get_children():
						if str(mark.name).begins_with("Knot"): knots += 1
				if knots != maxi(0, 3 - Story.duel_index(view.saved_player, "galpao")):
					printerr("Wrong remaining knot count at " + str(target[3]))
					quit(1)
					return
		var kit: String = target[2].get_base_dir().get_file()
		var is_directional_cast: bool = kit in ["centro-v1", "lajes-v1", "porto-v1", "serra-v1", "mirante-v1"] and target[3] != "reuniao-dona-neve"
		var is_special_cast: bool = target[2] in [ATTENDANT, PRODUCER, RANGER, Story.CIDA_SPRITE]
		if (is_directional_cast or is_special_cast or target[3] == "feira-lalau") and not check_turning(view, actor):
			printerr(str(target[3]) + " did not turn through all eight directions")
			quit(1)
			return
		if target[3] == "camara-gollia-arrependido":
			view.stage_endgame("gollia-arrependimento")
			var guards: Node = view.actors.get_node_or_null("EndgameStaging")
			if guards == null or find_actor(guards, Story.KIT+"capanga-masculino-0.png") == null or find_actor(guards, Story.KIT+"capanga-feminina-0.png") == null:
				printerr("Both guards must appear in Gollia's scene")
				quit(1)
				return
			view.animate_gollia_entrance()
			var steps := {}
			var deadline := Time.get_ticks_msec()+1300
			while Time.get_ticks_msec()<deadline:
				var x := actor.region_rect.position.x
				if x > 0.0: steps[x] = true
				if x == 0.0 and steps.size() == 2: break
				await process_frame
			if steps.size() != 2 or actor.region_rect.position.x != 0.0:
				printerr("Gollia entrance did not play both steps and return to idle")
				quit(1)
				return
		if relocated.has(target[3]):
			var position: Vector2 = relocated[target[3]]
			if not view.model.point_walkable(position) or view.model.path_to(CP.spawn(target[0]), position).is_empty():
				printerr("Actor position is not reachable: " + str(target[3]))
				quit(1)
				return
		if DisplayServer.get_name() != "headless":
			view.camera.position_smoothing_enabled = false
			view.camera.position = actor.global_position.lerp(view.player_root.global_position, 0.3) - Vector2(0, 40)
			view.camera.reset_smoothing()
			for i in range(5):
				await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(folder.path_join(target[3] + ".png")) != OK:
				quit(1)
				return
		print("OVERWORLD CAST: ", target[3], " uses ", actor.texture.resource_path)
		if target[3] == "camara-gollia-arrependido":
			var resolved: Dictionary = view.saved_player.duplicate(true)
			resolved.flags.golliaArrependido = true
			view.refresh(resolved)
			if find_actor(view.actors, target[2]) != null:
				printerr("Gollia still offers the encounter after repentance")
				quit(1)
				return
		if target[3] == "bosque-retalho-mascarada":
			var defeated: Dictionary = view.saved_player.duplicate(true)
			defeated.flags.retalhoBosqueVencido = true
			view.refresh(defeated)
			if find_actor(view.actors, target[2]) != null:
				printerr("Masked Retalho still visible after the encounter")
				quit(1)
				return
		if target[3] == "centro-pipeiro-fantasma":
			var before_centro: Dictionary = view.saved_player.duplicate(true)
			var entry: Dictionary = Rules.entry(before_centro, "centro")
			entry.completed = false
			Rules.store(before_centro, "centro", entry)
			view.refresh(before_centro)
			if find_actor(view.actors, target[2]) != null:
				printerr("Pipeiro Fantasma visible before Centro completion")
				quit(1)
				return
			var resolved: Dictionary = player.duplicate(true)
			resolved.flags.pipeiroFantasmaResolvido = true
			view.refresh(resolved)
			if find_actor(view.actors, target[2]) != null:
				printerr("Pipeiro Fantasma still visible after resolution")
				quit(1)
				return
		view.free()
	quit()

func story_target(id: String, art: Dictionary, capture: String, flags: Dictionary) -> Array:
	var step: Dictionary = Story.STEPS[id]
	return [step.scene, Story.point(step.scene, step.anchor) + Vector2(0, 1), art.path, capture, id, flags]

func check_turning(view: View, sprite: Sprite2D) -> bool:
	var cell: Vector2 = sprite.get_meta("directional_cell", Vector2.ZERO)
	if cell not in [Vector2(64, 64), Vector2(64, 96)]:
		return false
	var original_player: Vector2 = view.player
	var original_nearby: Dictionary = view.nearby
	var original_region := sprite.region_rect
	var offsets := [Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0),
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(1, 0)]
	var correct := false
	for actor: Dictionary in view.npc_nodes:
		if sprite.get_parent() != actor.visual:
			continue
		view.nearby = actor.root.get_meta("event", {})
		correct = true
		for index in offsets.size():
			view.player = actor.point + offsets[index]
			view.interact()
			if sprite.region_rect.position != Vector2(index % 4, index >> 2) * cell:
				correct = false
		break
	view.player = original_player
	view.nearby = original_nearby
	sprite.region_rect = original_region
	return correct

func find_actor(node: Node, path: String) -> Sprite2D:
	var directional_path := path.get_base_dir().path_join("direcoes").path_join(path.get_file())
	if node is Sprite2D and node.is_visible_in_tree() and node.texture != null and node.texture.resource_path in [path, directional_path]:
		return node
	for child in node.get_children():
		var actor := find_actor(child, path)
		if actor != null:
			return actor
	return null
