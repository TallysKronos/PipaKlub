extends SceneTree
## Acts 4-6 (endgame_story.gd + kronasta_story.gd): every new step is placed on a
## reachable cell, opens only in story order, records its flag once, survives a
## loss mid-sequence, and the places, night and final follow the bible (§7.5-7.7).
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Endgame = preload("res://scripts/campaign/endgame_story.gd")
const Story = preload("res://scripts/campaign/kronasta_story.gd")
const Ruins = preload("res://scripts/campaign/ruinas_elo.gd")
var checks := 0
var failures := 0
var session: Node

func check(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ", message)
	return value

func _initialize() -> void:
	Story.qa_override = 0
	session = Session.new()
	session._store = Store.new("user://endgame-check-" + State.new_id())
	root.add_child(session)
	check(session.start("slot-1").status == "ok", "fixture slot")
	var player: Dictionary = session.snapshot().player
	player.partners = [{"id":"test","modelId":"basica","xp":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId = "test"
	player.journey = {"phase":"complete","lesson":5}
	# Everything before act 4's new steps: seven districts, Mormaço, Serra, Aracati.
	for id in ["morro","bambuzal","beira-canal","feira","cais","industrial","palafitas","alto-da-serra"]:
		win_district(player, id)
	# Acts 1-3 and the start of act 4, as the existing beats record them.
	for flag in ["ninaAccepted","guardianDefeated","ninaReturned","ninaGlideTutorialDone","leagueGreen","tylerClareiraMet","bosqueClareiraDescoberta","comportaVeredasAberta","muralPrimeiroLaco","feiraApitoComprado","feiraApitoFalsoTestado","feiraApitoVerdadeiro","retalhoBosqueVencido","fotoExpedicaoLida","golliaCarretelVencida","pipaDragaoDesatadaVencida","exameAzulOrientadoV2","leagueBlue","marisolRemarOrientado","marisolRemarPratica","canRemar","assisReconheceuNoRetalho","retalhoAcolhido","mormacoVentosPararam","mormacoLiberto","tufanocorteLiberto","canCavar","canCorrenteDeAr"]:
		player.flags[flag] = true
	player.completedOperations.append("serra-corrente-de-ar-v1")
	check(save(player), "persist act 4 fixture")

	# Every step sits on a walkable cell the area entrance reaches.
	for id in Endgame.ORDER:
		var step: Dictionary = Endgame.STEPS[id]
		var at: Vector2 = Endgame.point(step.scene, step.anchor)
		check(at.is_finite(), id + " has a reachable spot in " + step.scene)
		check(CP.data(step.scene).events.any(func(e): return e.props.get("step","") == id), id + " is placed on its map")

	if Story.current_beat(player).get("id","") != "rabiolava": print("BEAT ", Story.current_beat(player))
	check(Story.current_beat(player).id == "rabiolava", "after Dona Neve the story points to Aracati")
	check(not Endgame.ready(player, "trovareta"), "Trovareta waits for the Rabiolava")
	check(Story.state(player, "centro") == "fechado", "Centro closed before the storm")
	player.flags.aracatiRabiolavaLivre = true
	check(Endgame.storm_active(player), "storm over the Bosque after Aracati")
	check(Story.current_beat(player).id == "trovareta", "story points to the storm")
	# Aracati no longer hosts the Rato's invitation.
	var rato_aracati: Dictionary = CP.data("kronasta-aracati-c").events.filter(func(e): return e.props.get("acao","") == "aracatiRato")[0]
	check(not CP.allowed(rato_aracati, player, "kronasta-aracati-c"), "Rato hidden in Aracati")
	check(save(player), "persist storm")

	# Trovareta: lose to Navalha once, then win both duels; Rato appears in the outro.
	check(duel("trovareta", "lost"), "Navalha loss settles")
	check(Endgame.duel_index(session.snapshot().player, "trovareta") == 0, "loss keeps Navalha next")
	check(duel("trovareta", "won") and duel("trovareta", "won"), "Navalha and Trovareta won")
	player = session.snapshot().player
	check(player.flags.get("trovaretaLivre", false) and not Endgame.storm_active(player), "Trovareta free, storm over")
	check(Endgame.after(player, "trovareta").contains("Rato:"), "Rato's invitation after the storm")
	check(Endgame.new(session).begin("trovareta", spot("trovareta")).status == "already_applied", "no replay")
	check(Story.state(player, "centro") == "aberto", "Centro opens after the storm")
	check(not Rules.unlocked(player, "centro"), "Centro district still waits for the Pipa TV")

	check(talk("reuniao"), "champions' meeting")
	check(Endgame.new(session).begin("exame-vermelho", spot("pipa-tv")).status == "wrong_step", "exam only next to Dona Cida")
	check(duel("exame-vermelho", "won") and duel("exame-vermelho", "won"), "Red exam: two duels")
	player = session.snapshot().player
	check(Story.category(player) == "Rabiola Vermelha", "Red category")
	check(talk("pipa-tv"), "Pipa TV request")
	player = session.snapshot().player
	check(Rules.unlocked(player, "centro"), "Centro district opens with the request")
	check(Story.current_beat(player).id == "leo-antena", "story points to Leo Antena")

	# Act 5: Leo Antena, Pipeiro Fantasma and the lab are existing pieces.
	win_district(player, "centro")
	player.flags.pipeiroFantasmaResolvido = true
	check(save(player), "persist Centro")
	check(Story.current_beat(player).id == "homunculo", "story points to the lab")
	player.flags.tylerCreatedKnown = true
	check(save(player), "persist homunculus")
	check(Endgame.night_active(player), "night of the cerol begins after the lab")
	check(Story.state(player, "aracati") == "fechado" and Story.state(player, "porto") == "fechado", "night closes the other places")
	check(Story.state(player, "centro") == "vencido" and Story.state(player, "rua-dos-ventos") == "aberto", "night keeps Vila and Centro")
	check(Story.state(player, "lajes") == "fechado", "Condomínio needs the bracelet")
	var exit_b: Dictionary = CP.data("kronasta-centro-a").events.filter(func(e): return e.type == "saida" and str(e.props.get("destino","")) == "kronasta-centro-b")[0]
	var barrier_at := CP.make("kronasta-centro-a", Vector2(exit_b.u + .5, exit_b.v + .5), CP.SPACE)
	check(CP.allowed(exit_b, player, "kronasta-centro-a"), "night exit stays visible")
	check(CP.exit_target(barrier_at, str(int(exit_b.id)), player).status == "night_barrier", "Bando barrier holds Centro A")
	check(duel("barreira", "won"), "barrier capanga")
	player = session.snapshot().player
	check(player.flags.get("bracadeiraBando", false) and int(player.inventory.get(Endgame.BRACELET, 0)) == 1, "bracelet recorded")
	check(CP.exit_target(barrier_at, str(int(exit_b.id)), player).status == "ok", "bracelet opens the barrier")
	check(Story.state(player, "lajes") == "aberto", "Condomínio opens at night")
	check(Endgame.ready(player, "desalmado-centro"), "optional Desalmados appear")
	check(Story.current_beat(player).id == "taina", "story points to Tainá")
	win_district(player, "lajes")
	check(save(player), "persist Tainá")
	check(Story.state(player, "industrial") == "aberto", "Vila Operária reachable for the warehouse")
	check(Story.released(player).any(func(e): return e.id == "industrial"), "warehouse listed in travel at night")
	for i in 5: check(duel("galpao", "won"), "warehouse duel %d" % i)
	check(duel("gollia-bando", "won") and duel("gollia-bando", "won"), "Gollia and his partner")
	player = session.snapshot().player
	check(Story.state(player, "montanha") == "aberto", "Serra reopens for the generator")
	check(talk("gerador"), "generator")
	player = session.snapshot().player
	check(not Endgame.night_active(player), "the Winds end the night")
	check(Story.state(player, "aracati") == "vencido" or Story.state(player, "aracati") == "aberto", "places reopen after the night")
	check(not Rules.unlocked(player, "porto"), "Porto waits for the Gold category")
	for i in 3: check(duel("copa-relampago", "won"), "Copa Relâmpago round %d" % i)
	player = session.snapshot().player
	check(Story.category(player) == "Rabiola Dourada" and Rules.unlocked(player, "porto"), "Gold category opens Porto")

	# Act 6: Jurandir, Ruínas, Gollia's repentance before the Rato, Eremor, Ícaro, final.
	win_district(player, "porto")
	for flag in ["ruinasNinaLivre","ruinasMikkaLivre","ruinasJamileLivre"]: player.flags[flag] = true
	check(save(player), "persist allies freed")
	check(Story.current_beat(player).id == "gollia-arrependimento", "story points to the chamber door")
	var altar := Vector2(24.5, 18.5)
	check(session.checkpoint(CP.make("kronasta-coracao-d", altar, CP.SPACE), player).status == "ok", "at the altar")
	check(Ruins.begin(session, altar).status == "wrong_step", "Rato waits for Gollia at the door")
	check(talk("gollia-arrependimento"), "Gollia holds the door")
	player = session.snapshot().player
	check(Story.current_beat(player).id == "rato", "story points to the Rato")
	player.flags.ruinasChefeVencido = true
	player.flags.enamorDerrotado = true
	check(save(player), "persist Rato and Eremor")
	check(Rules.unlocked(player, "mirante"), "Eremor opens the Mirante")
	check(Story.region_objective(player,"kronasta-coracao-d").contains("Alto do Mirante"), "Ruins direct the player to the final district")
	check(not Rules.city_final_unlocked(player), "final waits for Ícaro")
	win_district(player, "mirante")
	check(save(player), "persist Ícaro")
	check(Rules.city_final_unlocked(player) and Story.state(player, "estadio") == "aberto", "12 districts, Rato and Eremor open the final")
	check(Story.current_beat(player).id == "final", "story points to the final")
	check(Story.region_objective(player,"kronasta-mirante-c").contains("Estádio"), "Mirante points to stadium travel")
	check(Story.region_objective(player,"kronasta-estadio-a").contains("atendente"), "lobby explains next-round interaction")
	check(Ruins.INTRO["kronasta-estadio-a"].contains("Gollia") and Ruins.INTRO["kronasta-estadio-a"].contains("Grampo"), "Gollia and Grampo in the stands")
	player.flags.campeaoKronasta = true
	check(Story.current_beat(player).is_empty() and Story.category(player) == "Campeão de Kronasta", "story complete")
	print("ENDGAME STORY: %d checks; %d failures" % [checks, failures])
	session.queue_free()
	quit(1 if failures else 0)

func win_district(player: Dictionary, id: String) -> void:
	var entry: Dictionary = Rules.entry(player, id)
	entry.completed = true
	entry.rewardClaimed = true
	entry.champion = "player"
	for stage: Dictionary in Rules.definition(id).stages.slice(0, 4):
		if stage.id not in entry.qualification: entry.qualification.append(stage.id)
	Rules.store(player, id, entry)

func save(player: Dictionary) -> bool:
	var cp: Dictionary = session.snapshot().checkpoint
	if cp.get("kind") != "world": cp = CP.make("kronasta-centro-a", CP.spawn("kronasta-centro-a"), CP.SPACE)
	return session.checkpoint(cp, player).status == "ok"

func spot(id: String) -> Vector2:
	return Endgame.point(Endgame.STEPS[id].scene, Endgame.STEPS[id].anchor)

func stand_at(id: String) -> bool:
	var at := spot(id)
	return session.checkpoint(CP.make(Endgame.STEPS[id].scene, at, CP.SPACE), session.snapshot().player).status == "ok"

func talk(id: String) -> bool:
	if not stand_at(id): return false
	var result: Dictionary = Endgame.new(session).talk(id, spot(id))
	return result.status == "ok" and Endgame.done(session.snapshot().player, id)

## Opens the next duel of a step, forces its outcome and settles it.
func duel(id: String, outcome: String) -> bool:
	if not stand_at(id): return false
	if Endgame.new(session).begin(id, spot(id)).status != "ok": return false
	var saved: Dictionary = session.snapshot()
	if saved.player.encounter.kind != "endgame-step" or not State.valid_encounter(saved.player.encounter): return false
	saved.player.encounter.state.outcome = outcome
	if session.checkpoint(saved.checkpoint, saved.player).status != "ok": return false
	return Endgame.new(session).settle().status == "ok"
