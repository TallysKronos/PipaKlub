extends SceneTree
## Planícies de Kronasta e Gruta do Moinho como região jogável (11/11/2026): abre depois do
## Lacertubo, criaturas selvagens próprias, as missões do Seu Bento e da Iara e o guardião
## Estratonte no Lago Subterrâneo.
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Atlas = preload("res://scripts/campaign/kronasta_atlas.gd")
const Story = preload("res://scripts/campaign/planicie_story.gd")
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

var failures := 0
var session: Node

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)

func _initialize() -> void:
	run.call_deferred()

func event_with(scene: String, key: String, value: String) -> Dictionary:
	for event in CP.data(scene).events:
		if str(event.props.get(key, "")) == value: return event
	return {}

func at(event: Dictionary) -> Vector2:
	return Vector2(event.u + .5, event.v + .5)

func go(scene: String, point: Vector2) -> void:
	check(session.checkpoint(CP.make(scene, point, CP.SPACE), session.snapshot().player).status == "ok", "vai para " + scene)

## Ponto andável ao lado do evento (o morador ou o guardião ocupa a própria célula).
func beside(scene: String, event: Dictionary) -> Vector2:
	var model = CP.model_for(scene)
	for d in [Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1)]:
		if model.point_walkable(at(event) + d): return at(event) + d
	return at(event)

func run() -> void:
	# Criaturas e níveis próprios; a Caverna do Mural continua com a tabela de antes.
	var plains: Array = Wild.table("planicie-b").map(func(row): return str(row.modelo))
	var cave: Array = Wild.table("caverna-b").map(func(row): return str(row.modelo))
	check("cristim" in plains and "papisco" in plains and "basica" not in plains, "planícies com espécies próprias " + str(plains))
	check("vertim" in cave and "ossito" in cave, "gruta com espécies próprias " + str(cave))
	check(Wild.table("caverna-mural-a") == Wild.data().padrao, "Caverna do Mural sem mudança")
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	for id in plains + cave + ["estratonte"]:
		check(content.combat.has(id) and ResourceLoader.exists("res://assets/campaign/" + content.combat[id].image), id + ": arte de batalha")
	check(Wild.level_band("planicie-a") == Vector2i(10, 12) and Wild.level_band("caverna-c") == Vector2i(14, 16), "níveis 10–16")
	# Abre depois do Lacertubo (fora do modo QA).
	KStory.qa_override = 0
	check(not Atlas.can_travel("planicie-a", {"flags": {}}), "fechada antes do Lacertubo")
	check(Atlas.can_travel("planicie-a", {"flags": {"guardianDefeated": true}}), "abre depois do Lacertubo")
	KStory.qa_override = -1

	session = Session.new()
	root.add_child(session)
	session._store = Store.new("user://planicie-" + State.new_id())
	check(session.start("slot-1").status == "ok", "slot isolado")
	var player: Dictionary = session.snapshot().player
	player.partners = [{"id": "p", "modelId": "rabbito", "xp": Levels.xp_for_level(14), "craftBonus": 0, "condition": {"line": 100, "structure": 100}}]
	player.equippedPartnerId = "p"
	player.journey = {"phase": "complete", "lesson": 5}
	player.flags = {"guardianDefeated": true}
	check(session.checkpoint(CP.make("planicie-a", CP.spawn("planicie-a"), CP.SPACE), player).status == "ok", "entra nos Campos do Vento")
	check(Story.objective(session.snapshot().player, "planicie-a").contains("Bento"), "objetivo aponta o Seu Bento")

	# Encontro selvagem no capim das planícies: espécie e nível da região, aceito pelo save.
	var encounters := Encounters.new(session)
	var model = CP.model_for("planicie-a")
	var grass := Vector2.INF
	for v in range(int(model.data.h)):
		for u in range(int(model.data.w)):
			var point := Vector2(u + .5, v + .5)
			if not grass.is_finite() and Pacing.weight(model, point) > 0 and CP.valid_position("planicie-a", point): grass = point
	check(grass.is_finite(), "há capim com encontros")
	go("planicie-a", grass)
	var wild := encounters.start_wild(grass)
	check(wild.status == "ok", "encontro selvagem começa: " + str(wild.get("status")))
	var enc: Dictionary = session.snapshot().player.get("encounter", {})
	check(enc.get("state", {}).get("enemyModelId", "") in plains and int(enc.get("state", {}).get("enemyLevel", 0)) in [10, 11, 12], "selvagem da região: " + str(enc.get("state", {}).get("enemyModelId")))
	var fled := Model.new()
	fled.restore(enc.state)
	fled.outcome = "fled"
	var p: Dictionary = session.snapshot().player
	p.encounter.state = fled.snapshot()
	session.checkpoint({"kind": "encounter"}, p)
	check(encounters.settle().status == "ok", "fuga grava")

	# Missão do moinho: pedido, três pás (só aparecem depois do pedido) e a entrega.
	var story := Story.new(session)
	var bento := event_with("planicie-a", "acao", "planicieMoinho")
	go("planicie-a", beside("planicie-a", bento))
	check(story.talk("planicieMoinho", beside("planicie-a", bento)).status == "ok", "Seu Bento pede as pás")
	var pas := 0
	for scene in Story.SCENES:
		for event in CP.data(scene).events:
			if event.type != "item" or event.props.get("item", "") != Story.ITEM: continue
			check(not CP.allowed(event, {"flags": {}}, scene), scene + ": pá escondida antes do pedido")
			check(CP.allowed(event, session.snapshot().player, scene), scene + ": pá aparece depois do pedido")
			go(scene, at(event))
			check(Bosque.new(session).collect(str(int(event.id)), at(event)).status == "ok", scene + ": pega a pá")
			pas += 1
	check(pas == Story.PAS, "três pás no mapa (%d)" % pas)
	go("planicie-a", beside("planicie-a", bento))
	var coins: int = session.snapshot().player.coins
	check(story.talk("planicieMoinho", beside("planicie-a", bento)).status == "ok", "entrega as pás")
	var after: Dictionary = session.snapshot().player
	check(after.flags.get("planicieMoinhoConsertado", false) and after.coins == coins + 60 and not after.inventory.has(Story.ITEM), "moinho consertado e recompensa")
	check(story.talk("planicieMoinho", beside("planicie-a", bento)).status == "already_applied", "não repete a recompensa")

	# Missão do Tito: a Iara pede, o Tito aparece na gruta, volta para casa e a Iara agradece.
	var iara := event_with("planicie-b", "acao", "grutaIara")
	var tito := event_with("caverna-b", "acao", "grutaTito")
	var tito_home := event_with("planicie-b", "npcIdentity", "juninho")
	check(not tito.is_empty() and not CP.allowed(tito, session.snapshot().player, "caverna-b"), "Tito escondido antes do pedido")
	go("planicie-b", beside("planicie-b", iara))
	check(story.talk("grutaIara", beside("planicie-b", iara)).status == "ok", "Iara pede ajuda")
	check(CP.allowed(tito, session.snapshot().player, "caverna-b"), "Tito aparece na gruta")
	check(Story.objective(session.snapshot().player, "caverna-b").contains("Tito"), "objetivo aponta o Tito")
	go("caverna-b", beside("caverna-b", tito))
	check(story.talk("grutaTito", beside("caverna-b", tito)).status == "ok", "encontra o Tito")
	check(not CP.allowed(tito, session.snapshot().player, "caverna-b") and CP.allowed(tito_home, session.snapshot().player, "planicie-b"), "Tito volta para casa")
	go("planicie-b", beside("planicie-b", iara))
	check(story.talk("grutaIara", beside("planicie-b", iara)).status == "ok" and session.snapshot().player.flags.get("grutaTitoRecompensa", false), "Iara agradece")
	check(story.talk("grutaTito", beside("caverna-b", tito)).status == "wrong_step", "longe do Tito não conversa")

	# Guardião: só perto dele, a vitória dá a rabiola e o remove do lago.
	var boss := event_with("caverna-c", "acao", "grutaBoss")
	check(not boss.is_empty(), "Estratonte no lago")
	go("caverna-c", CP.spawn("caverna-c"))
	check(encounters.start_gruta_boss(CP.spawn("caverna-c")).status == "wrong_step", "longe do guardião não começa")
	var near := beside("caverna-c", boss)
	go("caverna-c", near)
	check(encounters.start_gruta_boss(near).status == "ok", "duelo com o Estratonte começa")
	enc = session.snapshot().player.get("encounter", {})
	check(enc.get("kind", "") == "gruta-boss" and enc.state.enemyModelId == "estratonte" and int(enc.state.enemyLevel) == Encounters.GRUTA_GUARDIAN_LEVEL, "Estratonte Nv.18")
	var won := Model.new()
	won.restore(enc.state)
	won.outcome = "won"
	p = session.snapshot().player
	p.encounter.state = won.snapshot()
	session.checkpoint({"kind": "encounter"}, p)
	check(encounters.settle().status == "ok", "vitória grava")
	after = session.snapshot().player
	check(after.flags.get("grutaEstratonteVencido", false) and int(after.inventory.get("rabiola-estratonte", 0)) == 1, "rabiola do Estratonte")
	check(not CP.allowed(boss, after, "caverna-c"), "guardião sai do lago")
	check(Story.objective(after, "caverna-c").contains("paz"), "região concluída")
	print("planicie_story_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)
