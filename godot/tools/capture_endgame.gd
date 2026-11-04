extends SceneTree
## Review captures of the act 4-6 story steps (endgame_story.gd) in the real
## frontend: the player stands next to the step with the story flags that open it.
##   godot --path godot -s tools/capture_endgame.gd -- --step=trovareta [--dialog]
## Saves to tmp/endgame-review/<step>[-dialog].png
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const Endgame = preload("res://scripts/campaign/endgame_story.gd")

## Flags each step needs on top of the act 4 fixture, in story order.
const UNTIL := {
	"trovareta": ["aracatiRabiolavaLivre"],
	"reuniao": ["aracatiRabiolavaLivre","trovaretaLivre"],
	"exame-vermelho": ["aracatiRabiolavaLivre","trovaretaLivre","reuniaoCampeoes"],
	"pipa-tv": ["aracatiRabiolavaLivre","trovaretaLivre","reuniaoCampeoes","leagueRed"],
	"barreira": ["aracatiRabiolavaLivre","trovaretaLivre","reuniaoCampeoes","leagueRed","pipaTvPedido","pipeiroFantasmaResolvido","tylerCreatedKnown"],
	"desalmado-lajes": ["aracatiRabiolavaLivre","trovaretaLivre","reuniaoCampeoes","leagueRed","pipaTvPedido","pipeiroFantasmaResolvido","tylerCreatedKnown","bracadeiraBando"],
	"galpao": ["aracatiRabiolavaLivre","trovaretaLivre","reuniaoCampeoes","leagueRed","pipaTvPedido","pipeiroFantasmaResolvido","tylerCreatedKnown","bracadeiraBando"],
	"gerador": ["aracatiRabiolavaLivre","trovaretaLivre","reuniaoCampeoes","leagueRed","pipaTvPedido","pipeiroFantasmaResolvido","tylerCreatedKnown","bracadeiraBando","galpaoInvadido","golliaFugiu"],
	"gollia-arrependimento": ["aracatiRabiolavaLivre","trovaretaLivre","reuniaoCampeoes","leagueRed","pipaTvPedido","pipeiroFantasmaResolvido","tylerCreatedKnown","bracadeiraBando","galpaoInvadido","golliaFugiu","geradorLigado","leagueGold","ruinasNinaLivre","ruinasMikkaLivre","ruinasJamileLivre"],
}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var step_id := "trovareta"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--step="): step_id = argument.trim_prefix("--step=")
	var dialog := "--dialog" in OS.get_cmdline_user_args()
	if not Endgame.STEPS.has(step_id) or not UNTIL.has(step_id):
		printerr("unknown step ", step_id); quit(1); return
	root.size = Vector2i(1280, 720)
	var view := FrontEnd.new()
	root.add_child(view)
	view.preferences.reduced_motion = true
	view.preferences.fullscreen = false
	await process_frame
	var saved := State.fresh("slot-1")
	var p: Dictionary = saved.player
	p.partners = [{"id":"visual-review","modelId":"rabbito","personalName":"Rabbito","xp":40000,"condition":{"line":100,"structure":100}}]
	p.equippedPartnerId = "visual-review"
	p.journey = {"lesson":5,"phase":"complete"}
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(p)
	p.flags.pipeiroDocumentsSeen = true
	var districts := ["morro","bambuzal","beira-canal","feira","cais","industrial","palafitas","alto-da-serra"]
	if "pipeiroFantasmaResolvido" in UNTIL[step_id]: districts.append("centro")
	if step_id in ["galpao","gerador","gollia-arrependimento"]: districts.append("lajes")
	if step_id == "gollia-arrependimento": districts.append("porto")
	for id in districts:
		var entry: Dictionary = Rules.entry(p, id)
		entry.completed = true; entry.rewardClaimed = true; entry.champion = "player"
		for stage: Dictionary in Rules.definition(id).stages.slice(0, 4): entry.qualification.append(stage.id)
		Rules.store(p, id, entry)
	# Acts 1-3 and the start of act 4, as in tests/endgame_story_checks.gd.
	for flag in ["ninaAccepted","guardianDefeated","ninaReturned","ninaGlideTutorialDone","leagueGreen","tylerClareiraMet","bosqueClareiraDescoberta","comportaVeredasAberta","muralPrimeiroLaco","feiraApitoComprado","feiraApitoFalsoTestado","feiraApitoVerdadeiro","retalhoBosqueVencido","fotoExpedicaoLida","golliaCarretelVencida","pipaDragaoDesatadaVencida","exameAzulOrientadoV2","leagueBlue","marisolRemarOrientado","marisolRemarPratica","canRemar","assisReconheceuNoRetalho","retalhoAcolhido","mormacoVentosPararam","mormacoLiberto","tufanocorteLiberto","canCavar","canCorrenteDeAr"] + UNTIL[step_id]:
		p.flags[flag] = true
	p.completedOperations.append("serra-corrente-de-ar-v1")
	var step: Dictionary = Endgame.STEPS[step_id]
	var at: Vector2 = Endgame.point(step.scene, step.anchor)
	# Stand one cell in front of the character, facing it.
	var stand := at + Vector2(0, 1)
	if not CP.model_for(step.scene).point_walkable(stand): stand = at + Vector2(1, 0)
	saved.checkpoint = CP.make(step.scene, stand, CP.SPACE)
	view.session._store = preload("res://scripts/campaign/save_store.gd").new("user://endgame-capture-" + State.new_id())
	if view.session.start("slot-1").status != "ok" or view.session.checkpoint(saved.checkpoint, p).status != "ok":
		printerr("fixture rejected"); quit(1); return
	view._show_park()
	for frame in 600:
		await process_frame
		if is_instance_valid(view.park) and not is_instance_valid(view.scene_loading): break
	for frame in 30: await process_frame
	if "--debug" in OS.get_cmdline_user_args():
		var light: Node = view.park.get_node_or_null("StoryLight")
		var veil: Node = view.park.exploration_hud.get_parent().get_node_or_null("StoryLight")
		if "--black" in OS.get_cmdline_user_args() and veil != null: veil.color = Color(0.2,0.2,0.2)
		print("DBG veil=", veil, " storm=", Endgame.storm_active(view.park.saved_player), " night=", Endgame.night_active(view.park.saved_player), " objective='", view.park.exploration_hud.objective.text, "' region=", load("res://scripts/campaign/kronasta_story.gd").region_objective(view.park.saved_player, step.scene))
	if dialog:
		view._endgame_step(step_id)
		for frame in 30: await process_frame
	await create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://").get_base_dir().path_join("../tmp/endgame-review").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join(step_id + ("-dialog" if dialog else "") + ".png")
	root.get_texture().get_image().save_png(path)
	print(path)
	quit()
