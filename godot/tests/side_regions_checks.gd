extends SceneTree
## Regiões laterais jogáveis (side_regions.gd, 11/11/2026): Vulcão, Serra Gelada e Abismo.
## Para cada uma: abre no ponto certo da campanha, cada área tem selvagens próprios aceitos
## pelo save, as duas missões funcionam do pedido à recompensa e o guardião luta uma vez.
## As Planícies têm o teste próprio (planicie_story_checks.gd), com as mesmas regras.
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Atlas = preload("res://scripts/campaign/kronasta_atlas.gd")
const Regions = preload("res://scripts/campaign/side_regions.gd")
const KStory = preload("res://scripts/campaign/kronasta_story.gd")
const Wild = preload("res://scripts/campaign/wild_tables.gd")
const Pacing = preload("res://scripts/campaign/park_pacing.gd")
const Bosque = preload("res://scripts/campaign/bosque_campaign.gd")
const Encounters = preload("res://scripts/campaign/encounters.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Levels = preload("res://scripts/campaign/partner_levels.gd")

## região → [flags que abrem, bairros concluídos, tipo do guardião]
const CASES := {
	"vulcao": [{"aracatiRabiolavaLivre": true}, [], "vulcao-boss"],
	"serra-gelada": [{}, ["alto-da-serra"], "geleira-boss"],
	"abismo": [{}, ["porto"], "abismo-boss"],
}

var failures := 0
var session: Node

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)

func _initialize() -> void:
	run.call_deferred()

func at(event: Dictionary) -> Vector2:
	return Vector2(event.u + .5, event.v + .5)

func go(scene: String, point: Vector2) -> void:
	check(session.checkpoint(CP.make(scene, point, CP.SPACE), session.snapshot().player).status == "ok", "vai para " + scene + " em " + str(point))

func beside(scene: String, event: Dictionary) -> Vector2:
	var model = CP.model_for(scene)
	for d in [Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1)]:
		if model.point_walkable(at(event) + d): return at(event) + d
	return at(event)

## O evento com essa ação nas cenas da região: [cena, evento].
func find_action(id: String, action: String) -> Array:
	for scene in Regions.REGIONS[id].scenes:
		for event in CP.data(scene).events:
			if event.props.get("acao", "") == action: return [scene, event]
	return []

func talk(id: String, action: String) -> Dictionary:
	var found := find_action(id, action)
	if found.is_empty(): return {"status": "missing"}
	var point := beside(found[0], found[1])
	go(found[0], point)
	return Regions.new(session).talk(action, point)

func fresh_player(case: Array) -> Dictionary:
	var player: Dictionary = session.snapshot().player
	player.partners = [{"id": "p", "modelId": "rabbito", "xp": Levels.xp_for_level(40), "craftBonus": 0, "condition": {"line": 100, "structure": 100}}]
	player.equippedPartnerId = "p"
	player.journey = {"phase": "complete", "lesson": 5}
	player.flags = case[0].duplicate()
	var rules = preload("res://scripts/campaign/district_rules.gd")
	var districts := {}
	for d in case[1]:
		districts[d] = rules.fresh(d)
		districts[d].completed = true
		districts[d].champion = "player"
		districts[d].rewardClaimed = true
	if not districts.is_empty(): player.championship = {"version": rules.VERSION, "districts": districts}
	else: player.erase("championship")
	return player

func run() -> void:
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	session = Session.new()
	root.add_child(session)
	session._store = Store.new("user://regioes-" + State.new_id())
	check(session.start("slot-1").status == "ok", "slot isolado")
	var encounters := Encounters.new(session)
	for id in CASES:
		var case: Array = CASES[id]
		var region: Dictionary = Regions.REGIONS[id]
		# Abertura: fechada antes do marco, aberta depois (fora do modo QA).
		KStory.qa_override = 0
		check(not Atlas.can_travel(region.scenes[0], {"flags": {}}), id + ": fechada no começo")
		var player := fresh_player(case)
		check(Regions.open(player, id) and Atlas.can_travel(region.scenes[0], player), id + ": abre no marco da campanha")
		KStory.qa_override = -1
		check(session.checkpoint(CP.make(region.scenes[0], CP.spawn(region.scenes[0]), CP.SPACE), player).status == "ok", id + ": entra")
		# Selvagens: espécies com arte, aceitas pelo save em todas as áreas; há chão com encontros.
		for scene in region.scenes:
			for row in Wild.table(scene):
				check(content.combat.has(str(row.modelo)), scene + ": arte de " + str(row.modelo))
			check(Wild.table(scene) != Wild.data().padrao, scene + ": tabela própria")
			for roll in 3:
				var m := Model.new({"id": "p", "modelId": "rabbito", "xp": 9000}, {"modelId": Wild.choose(scene, roll / 3.0 + .1, false), "level": Pacing.wild_level(scene, roll)})
				check(State.valid_encounter({"id": "x", "kind": "wild", "scene": scene, "space": CP.SPACE, "dropRoll": .5, "returnPoint": [1, 1], "state": m.snapshot(), "rewardXp": 10}), scene + ": selvagem válido")
			var model = CP.model_for(scene)
			var grass := 0
			for v in range(int(model.data.h)):
				for u in range(int(model.data.w)):
					if Pacing.weight(model, Vector2(u + .5, v + .5)) > 0: grass += 1
			check(grass > 200, scene + ": chão com encontros (%d)" % grass)
		check(Regions.objective(session.snapshot().player, region.scenes[0]) == region.quests[0].hint, id + ": objetivo começa pela primeira missão")
		# Missão de buscar: pedido, itens escondidos antes, coleta em várias áreas, entrega.
		var fetch: Dictionary = region.quests[0]
		check(talk(id, fetch.action).status == "ok", id + ": pedido de " + fetch.item)
		var picked := 0
		for scene in region.scenes:
			for event in CP.data(scene).events:
				if event.type != "item" or event.props.get("item", "") != fetch.item: continue
				check(not CP.allowed(event, {"flags": {}}, scene), scene + ": item escondido antes do pedido")
				go(scene, at(event))
				check(Bosque.new(session).collect(str(int(event.id)), at(event)).status == "ok", scene + ": pega " + fetch.item)
				picked += 1
		check(picked == int(fetch.count), id + ": %d itens no mapa" % picked)
		var coins: int = session.snapshot().player.coins
		check(talk(id, fetch.action).status == "ok", id + ": entrega")
		var after: Dictionary = session.snapshot().player
		check(after.flags.get(fetch.done_flag, false) and after.coins == coins + int(fetch.reward.coins) and not after.inventory.has(fetch.item), id + ": recompensa da busca")
		check(talk(id, fetch.action).status == "already_applied", id + ": não repete")
		# Missão de achar alguém: aparece depois do pedido, volta para casa, recompensa.
		var find: Dictionary = region.quests[1]
		var lost: Array = find_action(id, find.target)
		check(not lost.is_empty() and not CP.allowed(lost[1], session.snapshot().player, lost[0]), id + ": perdido escondido antes do pedido")
		check(talk(id, find.action).status == "ok", id + ": pedido de busca")
		check(CP.allowed(lost[1], session.snapshot().player, lost[0]), id + ": perdido aparece")
		check(talk(id, find.target).status == "ok", id + ": acha " + str(lost[1].name))
		check(not CP.allowed(lost[1], session.snapshot().player, lost[0]), id + ": volta para casa")
		var home := false
		for scene in region.scenes:
			for event in CP.data(scene).events:
				if event.props.get("requer", "") == find.found_flag and event.type == "npc": home = CP.allowed(event, session.snapshot().player, scene)
		check(home, id + ": aparece em casa")
		check(talk(id, find.action).status == "ok" and session.snapshot().player.flags.get(find.reward_flag, false), id + ": recompensa da busca de pessoa")
		check(Regions.objective(session.snapshot().player, region.scenes[0]) == region.guardian.text, id + ": objetivo aponta o guardião")
		# Guardião.
		var g: Array = Encounters.GUARDIANS[case[2]]
		var boss: Array = find_action(id, g[1])
		check(not boss.is_empty() and boss[0] == g[0], id + ": guardião no mapa")
		var near := beside(g[0], boss[1])
		go(g[0], near)
		check(encounters.start_guardian(case[2], near).status == "ok", id + ": duelo com " + g[5])
		var enc: Dictionary = session.snapshot().player.get("encounter", {})
		if enc.is_empty(): continue
		check(enc.get("kind", "") == case[2] and enc.state.enemyModelId == g[2] and int(enc.state.enemyLevel) == g[3], id + ": guardião certo")
		var won := Model.new()
		won.restore(enc.state)
		won.outcome = "won"
		var p: Dictionary = session.snapshot().player
		p.encounter.state = won.snapshot()
		session.checkpoint({"kind": "encounter"}, p)
		check(encounters.settle().status == "ok", id + ": vitória grava")
		after = session.snapshot().player
		check(after.flags.get(g[4], false) and int(after.inventory.get(g[6], 0)) == 1 and not CP.allowed(boss[1], after, g[0]), id + ": rabiola e guardião sai")
		check(Regions.objective(after, region.scenes[0]) == region.peace, id + ": região em paz")
	print("side_regions_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)
