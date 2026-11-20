extends SceneTree
## Morro do Sol no modelo isométrico (08/11/2026): mapas kronasta-morro-a…e ligados às cenas
## "morro" e "morro-area-2…5". Confere chegada, rivais, portão entre as áreas, luta e volta,
## migração de saves do mapa pintado e a saída para a Rua dos Ventos.
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const MorroModel = preload("res://scripts/campaign/morro_model.gd")
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")

var failures := 0

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var stages := ["morro-1", "morro-2", "morro-3", "morro-4", "morro-5"]
	for i in CP.MORRO_SCENES.size():
		var scene: String = CP.MORRO_SCENES[i]
		check(CP.MAPS.has(scene), scene + " no mapa isométrico")
		var map := CP.data(scene)
		check(map.get("scene", "") == scene, scene + ": cena do mapa compilado")
		var rival := CP.morro_rival(scene)
		check(rival.is_finite(), scene + ": tem rival")
		var model = CP.model_for(scene)
		var start := CP.spawn(scene)
		check(model.point_walkable(start), scene + ": chegada andável")
		check(not model.path_to(start, rival + Vector2(0, 1)).is_empty(), scene + ": caminho até o rival")
		var duel := ""
		for e in map.events:
			if e.props.get("acao", "") == "morroDuel": duel = e.props.duel
		check(duel == stages[i], scene + ": desafio " + duel)
		var top := false
		for e in map.events:
			if e.type == "saida" and e.props.has("morroGate"):
				top = true
				check(e.props.morroGate == stages[i], scene + ": portão pede " + stages[i])
				check(not model.path_to(start, Vector2(e.u + .5, e.v + .5)).is_empty(), scene + ": caminho até a subida")
		check(top, scene + ": subida para a próxima área")

	# Saves do mapa pintado (pixels) migram para o mapa novo.
	var old := CP.make("morro", Vector2(528, 752))
	check(old.space == CP.SPACE and CP.model_for("morro").point_walkable(Vector2(old.position[0], old.position[1])), "save antigo na chegada migra")
	var near := CP.resolve({"kind": "world", "scene": "morro-area-3", "position": [714, 500]})
	check(near.distance_to(CP.morro_rival("morro-area-3")) < 3.5, "save antigo junto do rival volta ao rival")

	# Percurso: luta e vence em cada área, sobe pela saída do alto, sai para a rua no fim.
	var session := Session.new()
	root.add_child(session)
	session._store = Store.new("user://morro-iso-" + State.new_id())
	session.start("slot-1")
	var player: Dictionary = session.snapshot().player
	player.partners = [{"id": "test", "modelId": "basica", "craftBonus": 0, "xp": 0}]
	player.equippedPartnerId = "test"
	player.journey = {"phase": "complete", "lesson": 5}
	var result: Dictionary
	result = session.checkpoint(CP.make("morro", CP.spawn("morro"), CP.SPACE), player)
	check(result.status == "ok", "entra no Morro A: " + str(result))
	var morro := Morro.new(session)
	for i in 5:
		var scene: String = CP.MORRO_SCENES[i]
		var at := CP.morro_rival(scene) + Vector2(0, 1)
		var saved := session.snapshot()
		check(saved.checkpoint.scene == scene, "na área " + scene + " (está em " + str(saved.checkpoint.scene) + ")")
		# Antes de vencer, a subida está fechada.
		var gate_id := ""
		for e in CP.data(scene).events:
			if e.type == "saida" and e.props.has("morroGate"): gate_id = str(int(e.id))
		var gate_event: Dictionary = {}
		for e in CP.data(scene).events:
			if str(int(e.id)) == gate_id: gate_event = e
		var top := Vector2(gate_event.u + .5, gate_event.v + .5)
		var closed := CP.exit_target({"kind": "world", "scene": scene, "position": [top.x, top.y], "space": CP.SPACE}, gate_id, saved.player)
		check(closed.status == "morro_gate", scene + ": subida fechada antes do desafio (" + str(closed.status) + ")")
		# Longe do rival não começa.
		session.checkpoint(CP.make(scene, CP.spawn(scene), CP.SPACE), session.snapshot().player)
		check(morro.start(CP.spawn(scene)).status == "wrong_step", scene + ": longe do rival não começa")
		session.checkpoint(CP.make(scene, at, CP.SPACE), session.snapshot().player)
		var partner: Dictionary = session.snapshot().player.partners[0]
		check(partner.get("condition", {}).get("line", 100) > 0, "parceiro em condição")
		result = morro.start(at)
		check(result.status == "ok", scene + ": desafio começa junto do rival (" + str(result.status) + ")")
		if result.status != "ok": break
		var enc: Dictionary = session.snapshot().player.encounter
		check(enc.get("space", "") == CP.SPACE, scene + ": luta guarda o espaço do mapa")
		var model := MorroModel.new()
		model.restore(enc.state)
		model.outcome = "won"
		var p: Dictionary = session.snapshot().player
		p.encounter.state = model.snapshot()
		session.checkpoint({"kind": "encounter"}, p)
		result = morro.settle()
		check(result.status == "ok", scene + ": resultado (" + str(result.status) + ")")
		saved = session.snapshot()
		check(saved.checkpoint.get("space", "") == CP.SPACE and saved.checkpoint.scene == scene, scene + ": volta ao mapa isométrico")
		check(saved.player.morro.stars.has(stages[i]), scene + ": estrela")
		session.checkpoint(CP.make(scene, top, CP.SPACE), saved.player)
		var open := CP.exit_target(session.snapshot().checkpoint, gate_id, session.snapshot().player)
		check(open.status == "ok", scene + ": subida abre depois de vencer (" + str(open.status) + ")")
		if open.status != "ok": break
		if i < 4:
			check(open.scene == CP.MORRO_SCENES[i + 1], scene + ": leva para " + str(open.scene))
			result = session.checkpoint(CP.make(open.scene, open.point, CP.SPACE), session.snapshot().player)
			check(result.status == "ok", "entra em " + str(open.scene))
		else:
			check(open.scene == "quintal" and open.point == Vector2(2592, 1040), "Praça da Campeã sai para a Rua dos Ventos")
	print("morro_iso_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)
