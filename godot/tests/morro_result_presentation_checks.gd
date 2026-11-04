extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
var app:Control
var checks:=0
var failures:=0
var output:="res://../documentation/qa/morro-results-v2"
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 12:await process_frame
func capture(name:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://morro-result-"+State.new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder);app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	# The same native reward view is used by wild, boss and district battles.
	load("res://tools/player_audit_fixtures.gd").show(app,"morro-won");await settle()
	app.battle._physics_process(0);await settle()
	var card:Control=app.battle.reward_card
	check(card.get_script()==load("res://scripts/campaign/hud_reward_card.gd"),"Morro uses shared illustrated result")
	check(card.summary.stars>0 and card.summary.has("unlock"),"stars and next passage remain on reward card")
	check(app.battle.result_header.context.contains("MORRO DO SOL"),"context uses district header")
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=viewport
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		await settle();app.battle._layout_actions();await settle()
		check(root.get_visible_rect().encloses(card.get_global_rect()),"illustrated reward fits resolution")
		await capture("vitoria-%dx%d"%[viewport.x,viewport.y])
	app._clear();app.session.close_session();check(app.session.start("slot-1").status=="ok","isolated persisted return fixture")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"};player.coins=100
	player.partners=[{"id":"result-partner","modelId":"rabbito","xp":400,"condition":{"line":100,"structure":100}}];player.equippedPartnerId="result-partner"
	load("res://scripts/campaign/pipeiro_identity.gd").issue_into(player);player.flags.pipeiroDocumentsSeen=true
	root.size=Vector2i(1280,720)
	for outcome in ["won","lost","fled"]:
		player.lastMorro={"stage":"morro-3","outcome":outcome,"partnerXp":15,"coins":20,"stars":2,"drop":null}
		check(app.session.checkpoint({"kind":"world","scene":"morro-area-3","position":[300,300]},player).status=="ok","persist result "+outcome)
		var before:Dictionary=app.session.snapshot().player
		app._return_morro_result();await settle()
		var dialogs:=get_nodes_in_group("manga_dialogue")
		check(dialogs.size()==1 and dialogs[0].has_meta("morro_epilogue"),"one narrative epilogue for "+outcome)
		if dialogs.is_empty():quit(1);return
		var dialog:Control=dialogs[0]
		check(dialog.title!="Aviso" and dialog.ok_button_text=="Continuar explorando","NPC conversation replaces generic notice")
		check(not dialog.dialog_text.contains("Recompensas:") and not dialog.dialog_text.contains(" XP"),"no duplicate reward receipt")
		check(app.park.paused,"world waits for NPC conversation")
		if outcome=="won":await capture("dialogo-pos-vitoria")
		dialog.confirmed.emit();await settle()
		check(not app.park.paused,"conversation returns movement")
		check(app.session.snapshot().player.coins==before.coins and app.session.snapshot().player.partners==before.partners,"presentation grants no second reward")
	app.free();await settle()
	print("MORRO RESULT PRESENTATION: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
