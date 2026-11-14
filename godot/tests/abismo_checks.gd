extends SceneTree
## Abismo de Kronasta (11/11/2026): quatro labirintos submersos encadeados (A → D), baús,
## mergulho só com montaria aquática (Capiboia) e o chefe Coromar no Trono das Marés.
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Mounts = preload("res://scripts/campaign/mount_passives.gd")
const Encounters = preload("res://scripts/campaign/encounters.gd")
const Bosque = preload("res://scripts/campaign/bosque_campaign.gd")
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
	var scenes := ["abismo-a", "abismo-b", "abismo-c", "abismo-d"]
	for i in scenes.size():
		var scene: String = scenes[i]
		check(CP.MAPS.has(scene) and CP.is_regional_preview(scene), scene + " registrada")
		var map := CP.data(scene)
		check(int(map.w) == 64 and int(map.h) == 56 and bool(map.forest.get("submerged", false)), scene + ": mapa grande submerso")
		check(int(map.forest.get("depth", -1)) == i, scene + ": profundidade %d" % i)
		var model = CP.model_for(scene)
		var start := CP.spawn(scene)
		var chests := 0
		for piece in map.pieces:
			if piece.asset != "bau": continue
			chests += 1
			var near: Vector2 = Vector2.INF
			for d in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
				var at: Vector2 = Vector2(piece.u + .5, piece.v + .5) + d
				if model.point_walkable(at) and not model.path_to(start, at).is_empty(): near = at; break
			check(near.is_finite(), scene + ": baú %d alcançável" % int(piece.id))
		check(chests >= 6, scene + ": baús (%d)" % chests)
		for event in map.events:
			if event.type == "entrada" or event.props.has("requer"): continue
			var target := Vector2(event.u + .5, event.v + .5)
			var reach: bool = not model.path_to(start, target).is_empty()
			if not reach and event.type == "npc":
				reach = not model.path_to(start, target + Vector2(0, 2)).is_empty()
			check(reach, scene + ": alcança " + str(event.name))
		if i < 3:
			var exit: Dictionary = {}
			for event in map.events:
				if event.type == "saida" and event.props.get("destino", "") == scenes[i + 1]: exit = event
			check(not exit.is_empty(), scene + ": desce para " + scenes[i + 1])
			if not exit.is_empty():
				var at := Vector2(exit.u + .5, exit.v + .5)
				var target := CP.exit_target({"kind": "world", "scene": scene, "position": [at.x, at.y], "space": CP.SPACE}, str(int(exit.id)), {"flags": {}})
				check(target.get("status", "") == "ok" and target.scene == scenes[i + 1] and CP.model_for(scenes[i + 1]).point_walkable(target.point), scene + ": chega em " + scenes[i + 1])
	# Montaria aquática: sem Capiboia não mergulha; a Marisol entrega a Boia depois da aula.
	var player := {"partners": [{"id": "p", "modelId": "rabbito", "xp": Levels.xp_for_level(30), "craftBonus": 0, "condition": {"line": 100, "structure": 100}}], "equippedPartnerId": "p", "flags": {}}
	check(not Mounts.can_dive(player), "sem montaria aquática não mergulha")
	check(not Mounts.grant_boia(player), "sem a aula de remo a Marisol não entrega a Boia")
	player.flags.canRemar = true
	check(Mounts.grant_boia(player) and Mounts.can_dive(player), "Boia entregue: pode mergulhar")
	check(Levels.level_for_xp(player.partners[1].xp) == 28, "Boia chega dois níveis abaixo do parceiro")
	check(not Mounts.grant_boia(player), "Boia não é entregue duas vezes")
	player.partners[1].condition = {"line": 0, "structure": 100}
	check(not Mounts.can_dive(player), "Boia sem linha não nada")
	check("aquatica" in Mounts.passives("marevia") and "terrestre" in Mounts.passives("doberman-c"), "formas evoluídas herdam a passiva")
	# Baú de verdade: abre uma vez, entrega o item e fica aberto.
	var session := Session.new()
	root.add_child(session)
	session._store = Store.new("user://abismo-" + State.new_id())
	check(session.start("slot-1").status == "ok", "slot isolado")
	var live: Dictionary = session.snapshot().player
	live.partners = [{"id": "p", "modelId": "capivara-boia", "xp": Levels.xp_for_level(42), "craftBonus": 0, "condition": {"line": 100, "structure": 100}}]
	live.equippedPartnerId = "p"
	live.journey = {"phase": "complete", "lesson": 5}
	var chest: Dictionary = {}
	for piece in CP.data("abismo-a").pieces:
		if piece.asset == "bau" and chest.is_empty(): chest = piece
	var model_a = CP.model_for("abismo-a")
	var spot := Vector2.INF
	for d in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		if model_a.point_walkable(Vector2(chest.u + .5, chest.v + .5) + d): spot = Vector2(chest.u + .5, chest.v + .5) + d; break
	check(session.checkpoint(CP.make("abismo-a", spot, CP.SPACE), live).status == "ok", "junto do baú")
	var before: Dictionary = session.snapshot().player.duplicate(true)
	var opened := Bosque.new(session).collect("piece-" + str(int(chest.id)), spot)
	check(opened.status == "ok", "baú abre: " + str(opened.get("status")))
	var after: Dictionary = session.snapshot().player
	var item: String = str(chest.props.item)
	var gained: int = (after.coins - before.coins) if item == "moedas" else int(after.inventory.get(item, 0)) - int(before.get("inventory", {}).get(item, 0))
	check(gained == int(str(chest.props.quantidade)), "baú entrega %s × %s" % [chest.props.quantidade, item])
	check(("parque:abismo-a:" + str(int(chest.id))) in after.openedChests, "baú fica aberto")
	check(Bosque.new(session).collect("piece-" + str(int(chest.id)), spot).status == "already_applied", "baú não abre de novo")
	# Chefe: Coromar no Trono das Marés.
	var boss: Dictionary = {}
	for event in CP.data("abismo-d").events:
		if event.props.get("acao", "") == "abismoBoss": boss = event
	var near_boss := Vector2(boss.u + .5, boss.v + 2.5)
	check(session.checkpoint(CP.make("abismo-d", near_boss, CP.SPACE), session.snapshot().player).status == "ok", "chega ao trono")
	var encounters := Encounters.new(session)
	check(encounters.start_abismo_boss(CP.spawn("abismo-d")).status == "wrong_step", "longe do chefe não começa")
	var started := encounters.start_abismo_boss(near_boss)
	check(started.status == "ok", "duelo com o Coromar começa: " + str(started.get("status")))
	var enc: Dictionary = session.snapshot().player.get("encounter", {})
	check(enc.get("kind", "") == "abismo-boss" and enc.state.q.boss and enc.state.enemyModelId == "coromar", "Coromar é chefe")
	var m := Model.new()
	m.restore(enc.state)
	m.outcome = "won"
	var p: Dictionary = session.snapshot().player
	p.encounter.state = m.snapshot()
	session.checkpoint({"kind": "encounter"}, p)
	check(encounters.settle().status == "ok", "resultado grava")
	var done: Dictionary = session.snapshot().player
	check(done.flags.get("abismoCoromarVencido", false) and not CP.allowed(boss, done, "abismo-d"), "Coromar vencido sai do trono")
	print("abismo_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)
