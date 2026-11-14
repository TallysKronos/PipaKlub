extends SceneTree
## Serra Gelada (11/11/2026): três mapas de gelo encadeados (A → B → C), cachoeiras de água e
## congeladas, e o chefe Borealvo na Coroa Glacial.
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Encounters = preload("res://scripts/campaign/encounters.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Levels = preload("res://scripts/campaign/partner_levels.gd")

var failures := 0

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var scenes := ["serra-gelada-a", "serra-gelada-b", "serra-gelada-c"]
	for i in scenes.size():
		var scene: String = scenes[i]
		check(CP.MAPS.has(scene) and CP.is_regional_preview(scene), scene + " registrada")
		var map := CP.data(scene)
		check(int(map.w) == 64 and int(map.h) == 56 and bool(map.forest.get("ice", false)), scene + ": mapa grande de gelo")
		var top := 0
		for cell in map.cells: top = maxi(top, int(cell.level))
		check(top >= 5, scene + ": vários andares (%d)" % top)
		var model = CP.model_for(scene)
		var start := CP.spawn(scene)
		for event in map.events:
			if event.type == "entrada": continue
			if event.props.has("requer"): continue
			check(not model.path_to(start, Vector2(event.u + .5, event.v + .5)).is_empty(), scene + ": alcança " + str(event.name))
		var falls: Array = map.forest.get("waterFalls", []) + map.forest.get("iceFalls", [])
		check(falls.size() >= 2, scene + ": cachoeiras (%d)" % falls.size())
		for fall in falls:
			var lip: Dictionary = model.cell_at(Vector2i(int(fall.u), int(fall.v)))
			var below: Dictionary = model.cell_at(Vector2i(int(fall.u), int(fall.v) + 1))
			check(int(lip.level) - int(below.get("level", 0)) == int(fall.drop), scene + ": queda em %d,%d" % [int(fall.u), int(fall.v)])
		# A saída do alto leva ao próximo trecho, na chegada dele.
		if i < 2:
			var exit: Dictionary = {}
			for event in map.events:
				if event.type == "saida" and event.props.get("destino", "") == scenes[i + 1]: exit = event
			check(not exit.is_empty(), scene + ": saída para " + scenes[i + 1])
			if not exit.is_empty():
				var player := {"flags": {}, "morro": {"stars": {}}}
				var at := Vector2(exit.u + .5, exit.v + .5)
				var target := CP.exit_target({"kind": "world", "scene": scene, "position": [at.x, at.y], "space": CP.SPACE}, str(int(exit.id)), player)
				check(target.get("status", "") == "ok" and target.scene == scenes[i + 1], scene + ": passa para " + scenes[i + 1] + " " + str(target))
				if target.get("status", "") == "ok":
					check(CP.model_for(scenes[i + 1]).point_walkable(target.point), scene + ": chega andando em " + scenes[i + 1])
	# Chefe: começa só perto dele, grava no save, a vitória o remove e abre o santuário.
	var session := Session.new()
	root.add_child(session)
	session._store = Store.new("user://gelada-" + State.new_id())
	check(session.start("slot-1").status == "ok", "slot isolado")
	var player: Dictionary = session.snapshot().player
	player.partners = [{"id": "p", "modelId": "rabbito", "xp": Levels.xp_for_level(38), "craftBonus": 0, "condition": {"line": 100, "structure": 100}}]
	player.equippedPartnerId = "p"
	player.journey = {"phase": "complete", "lesson": 5}
	var boss: Dictionary = {}
	var shrine: Dictionary = {}
	for event in CP.data("serra-gelada-c").events:
		if event.props.get("acao", "") == "geleiraBoss": boss = event
		if event.props.get("requer", "") == "geleiraBorealvoVencido" and event.type == "item": shrine = event
	check(not boss.is_empty() and not shrine.is_empty(), "chefe e santuário no mapa")
	var near := Vector2(boss.u + .5, boss.v + 2.5)
	check(session.checkpoint(CP.make("serra-gelada-c", CP.spawn("serra-gelada-c"), CP.SPACE), player).status == "ok", "entra na Coroa")
	var encounters := Encounters.new(session)
	check(encounters.start_geleira_boss(CP.spawn("serra-gelada-c")).status == "wrong_step", "longe do chefe não começa")
	check(session.checkpoint(CP.make("serra-gelada-c", near, CP.SPACE), session.snapshot().player).status == "ok", "chega perto do chefe")
	var started := encounters.start_geleira_boss(near)
	check(started.status == "ok", "duelo começa: " + str(started.get("status")))
	var enc: Dictionary = session.snapshot().player.get("encounter", {})
	check(enc.get("kind", "") == "geleira-boss" and enc.state.q.boss and enc.state.enemyModelId == "borealvo", "Borealvo é chefe")
	check(not CP.allowed(shrine, session.snapshot().player, "serra-gelada-c"), "santuário fechado antes")
	var model := Model.new()
	model.restore(enc.state)
	model.outcome = "won"
	var p: Dictionary = session.snapshot().player
	p.encounter.state = model.snapshot()
	session.checkpoint({"kind": "encounter"}, p)
	check(encounters.settle().status == "ok", "resultado grava")
	var after: Dictionary = session.snapshot()
	check(after.player.flags.get("geleiraBorealvoVencido", false), "vitória marcada")
	check(after.checkpoint.get("space", "") == CP.SPACE and after.checkpoint.scene == "serra-gelada-c", "volta ao mapa")
	check(not CP.allowed(boss, after.player, "serra-gelada-c"), "chefe sai do mapa")
	check(CP.allowed(shrine, after.player, "serra-gelada-c"), "santuário abre")
	check(encounters.start_geleira_boss(near).status in ["already_applied", "wrong_step"], "não repete o chefe")
	print("serra_gelada_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)
