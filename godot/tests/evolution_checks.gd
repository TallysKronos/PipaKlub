extends SceneTree
## Evolução dos Soulmonsters: tabela, disponibilidade por nível, ramos, troca de forma,
## nome, bônus de atributos, arte provisória e gravação na sessão.
const Evo = preload("res://scripts/campaign/evolution.gd")
const Levels = preload("res://scripts/campaign/partner_levels.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")

var failures := 0

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)

func partner(model: String, level: int, name: String = "") -> Dictionary:
	return {"id": "p-" + model, "modelId": model, "personalName": name if name else Evo.display_name(model, model), "xp": Levels.xp_for_level(level), "craftBonus": 0, "condition": {"line": 100, "structure": 100}}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	# Toda forma evoluída tem arte carregável e cadeia ligada à família.
	for id in Evo.data().forms:
		var form: Dictionary = Evo.form(id)
		if form.has("source"):
			check(content.combat.has(id), id + ": entrada combat")
			check(load("res://assets/campaign/" + content.combat[id].image) is Texture2D, id + ": arte carrega")
			check(not form.from.is_empty(), id + ": tem forma anterior")
		for previous in form.from:
			check(not Evo.form(previous).is_empty(), id + ": anterior " + previous + " existe")
	for model in ["rabbito", "basica", "mata", "raio", "azulao", "doberman-c"]:
		check(Evo.next_level(model) > 0, model + ": tem evolução")
	check(Evo.next_level("lacertubo") == 0 and Evo.next_level("retalho-original") == 0, "Lacertubo e Retalho não evoluem")

	# Disponibilidade por nível.
	check(Evo.options(partner("rabbito", 15)).is_empty(), "Rabbito Nv.15 ainda não evolui")
	check(Evo.options(partner("rabbito", 16)) == ["rastro-dos-ventos"], "Rabbito Nv.16 → Rastro dos Ventos")
	check(Evo.options(partner("azulao", 20)).size() == 3, "Azulão escolhe entre 3 formas jovens")
	check(Evo.options(partner("raio", 20)).is_empty() and Evo.options(partner("raio", 32)) == ["solguarda"], "Raio de Sol pula para Solguarda no Nv.32")
	check(Evo.options(partner("doberman-c", 32)) == ["dobracula"], "Dóber → Dobrácula")

	# Evoluir: troca a forma, mantém id/XP/condição, renomeia o nome da espécie.
	var player := {"partners": [partner("rabbito", 33), partner("basica", 17, "Faísca")], "equippedPartnerId": "p-rabbito", "tamerXp": 0, "inventory": { "papel-seda": 2 }}
	var refused := Evo.evolve(player.duplicate(true), "p-rabbito", "mestre-dos-fios")
	check(refused.status == "not_ready", "não pula estágio (Rabbito → adulto direto)")
	var empty := player.duplicate(true)
	empty.inventory.clear()
	check(Evo.evolve(empty, "p-rabbito", "rastro-dos-ventos").status == "missing_requirements", "falta de papel bloqueia")
	var step := Evo.evolve(player, "p-rabbito", "rastro-dos-ventos")
	check(player.inventory.get("papel-seda") == 1, "consumo único")
	check(Evo.evolve(player, "p-rabbito", "rastro-dos-ventos").status == "not_ready" and player.inventory.get("papel-seda") == 1, "repetição não consome")
	check(step.status == "ok", "Rabbito evolui")
	var rabbito: Dictionary = player.partners[0]
	check(rabbito.modelId == "rastro-dos-ventos" and rabbito.id == "p-rabbito" and rabbito.xp == Levels.xp_for_level(33), "forma nova, mesmo id e XP")
	check(rabbito.personalName == "Rastro dos Ventos", "nome da espécie acompanha: " + str(rabbito.personalName))
	check(rabbito.evolvedFrom == ["rabbito"], "histórico da evolução")
	check(Evo.options(rabbito).size() == 5, "Rastro dos Ventos Nv.33 escolhe entre 5 adultos")
	check(Evo.evolve(player, "p-rabbito", "tecelao-da-aurora").status == "ok", "segunda evolução")
	check(Evo.root(rabbito.modelId) == "rabbito", "raiz da família continua Rabbito")
	check(Evo.evolve(player, "p-basica", "caravento").status == "ok", "Carcará evolui")
	check(player.partners[1].personalName == "Faísca", "nome dado pelo jogador fica")
	check("caravento" in player.get("acquiredModels", []), "forma nova entra na coleção")

	# Bônus de atributos do estágio.
	var base := Model.new(partner("rabbito", 33), {"modelId": "basica", "level": 30})
	var evolved := Model.new(rabbito, {"modelId": "basica", "level": 30})
	check(is_equal_approx(evolved.p.stats.line, base.p.stats.line * 1.12), "adulto +12%% na linha (%s × %s)" % [evolved.p.stats.line, base.p.stats.line])
	check(evolved.p.color == base.p.color, "cor da linha segue a família")
	check(Evo.art("tecelao-da-aurora") == "tecelao-da-aurora" and Evo.art("rabbito") == "rabbito" and Evo.art("lacertubo", "") == "", "arte da forma")

	# Gravação real na sessão (validação do save aceita a forma nova).
	var session := Session.new()
	root.add_child(session)
	session._store = Store.new("user://evolution-" + State.new_id())
	check(session.start("slot-1").status == "ok", "slot isolado")
	var live: Dictionary = session.snapshot().player
	live.partners = [partner("mata", 16)]
	live.equippedPartnerId = "p-mata"
	live.journey = {"phase": "complete", "lesson": 5}
	check(session.checkpoint(session.snapshot().checkpoint, live).status == "ok", "fixture")
	var saved := session.snapshot()
	var done := Evo.evolve(saved.player, "p-mata", "folhante")
	check(done.status == "ok", "Mata Verde → Folhante")
	var stored: Dictionary = session.commit_operation("evolve-test", saved.checkpoint, done.player)
	check(stored.status == "ok", "save aceita a evolução: " + str(stored.get("status")))
	check(session.snapshot().player.partners[0].modelId == "folhante", "forma gravada")
	var app: Control = load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store = Store.new("user://evolution-ui-" + State.new_id())
	root.add_child(app)
	check(app.session.start("slot-1").status == "ok", "sessão isolada da interface")
	var ui_save: Dictionary = app.session.snapshot()
	ui_save.player.partners = [partner("rabbito", 16)]
	ui_save.player.equippedPartnerId = "p-rabbito"
	ui_save.player.inventory["papel-seda"] = 2
	check(app.session.checkpoint(ui_save.checkpoint, ui_save.player).status == "ok", "preparação da interface")
	app._confirm_evolution("p-rabbito", "rastro-dos-ventos")
	await capture("01-confirmacao")
	check(app.session.snapshot().player.inventory["papel-seda"] == 2, "abrir confirmação não consome")
	app._show_evolution("p-rabbito")
	check(app.session.snapshot().player.partners[0].modelId == "rabbito", "voltar antes de confirmar não evolui")
	app.preferences.reduced_motion = false
	app._execute_evolution("p-rabbito", "rastro-dos-ventos")
	var ritual: Control
	for child in app.page.get_children():
		if child.has_method("skip"): ritual = child
	check(is_instance_valid(ritual), "ritual abriu após gravar")
	if is_instance_valid(ritual):
		for viewport_size in [Vector2i(960, 540), Vector2i(1920, 1080)]:
			root.size = viewport_size
			await process_frame
			check(ritual.size.x > 0 and ritual.size.y > 0, "ritual cabe em " + str(viewport_size))
		ritual.elapsed = 6.8
		await capture("02-ritual")
		ritual.elapsed = 8.5
		await process_frame
		check(ritual.creature.texture is AtlasTexture, "revelação usa o spritesheet")
		await capture("04-revelacao")
		ritual.skip()
	check(app.last_scene_key == "page:EVOLUÇÃO CONCLUÍDA!", "pular mostra o resultado")
	check(app.session.snapshot().player.partners[0].modelId == "rastro-dos-ventos" and app.session.snapshot().player.inventory["papel-seda"] == 1, "resultado após pular preserva evolução e custo")
	await capture("03-resultado")
	app.queue_free()
	await process_frame
	print("evolution_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)

func capture(name: String) -> void:
	var folder := OS.get_environment("EVOLUTION_CAPTURES")
	if folder.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK, "captura " + name)
