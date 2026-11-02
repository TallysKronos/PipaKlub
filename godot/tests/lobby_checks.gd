extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Identity=preload("res://scripts/campaign/pipeiro_identity.gd")
var app:Control
var checks:=0
var failures:=0
var output:="res://../documentation/qa/lobby-v1"
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 16:await process_frame
func capture(name:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	root.gui_disable_input=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:=ProjectSettings.globalize_path("res://../tmp/lobby-"+State.new_id())
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder);app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"};player.coins=3560
	player.partners=[{"id":"lobby-partner","modelId":"rabbito","xp":1380,"condition":{"line":100,"structure":100}}];player.equippedPartnerId="lobby-partner"
	Identity.issue_into(player);player.flags.pipeiroDocumentsSeen=true;player.flags.ninaAccepted=true;player.inventory["rabiola-raio"]=1
	check(app.session.checkpoint({"kind":"world","scene":"morro-area-5","position":[300,300]},player).status=="ok","world fixture")
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768)]:
		root.size=viewport
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		app._show_saved();await settle();app._pause_game();await settle()
		check(app.park.paused,"lobby freezes overworld")
		check(app.pause_overlay.buttons.size()==11,"eight cards and three footer actions")
		check(root.gui_get_focus_owner()==app.pause_overlay.buttons.team,"Pipamons selected initially")
		for button in app.pause_overlay.buttons.values():check(root.get_visible_rect().encloses(button.get_global_rect()),"lobby action fits viewport")
		await capture("lobby-%dx%d"%[viewport.x,viewport.y])
		app._resume_game();check(not app.park.paused,"resume restores movement")
	root.size=Vector2i(1280,720)
	app._pause_game();await settle()
	for action in ["missions","workshop","identity","bag","team","settings"]:
		app.pause_overlay.buttons[action].pressed.emit();await settle()
		check(not is_instance_valid(app.pause_overlay),"page replaces lobby "+action)
		if action=="identity":
			var screen:Control
			for child in app.get_children():
				if child.get_script()==load("res://scripts/campaign/hud_pipeiro_identity.gd"):screen=child
			check(screen.tabs.size()==2 and screen.tabs[1].text=="Histórico","identity keeps only profile and history")
			await capture("identidade-simplificada")
		if action in ["missions","workshop"]:await capture(action)
		app._return_to_game();await settle()
		check(is_instance_valid(app.pause_overlay) and root.gui_get_focus_owner()==app.pause_overlay.buttons[action],"return restores lobby focus "+action)
	var before:Dictionary=app.session.snapshot().player.inventory
	app.pause_overlay.buttons.save.pressed.emit();await settle()
	check(app.pause_overlay.buttons.save.text=="Jornada salva","save feedback")
	check(app.session._store.load_slot("slot-1").data.player.inventory==JSON.parse_string(JSON.stringify(before)),"save preserves inventory")
	app.pause_overlay.buttons.emblems.grab_focus();app.pause_overlay.buttons.emblems.pressed.emit();await settle()
	var book:Control
	for child in app.get_children():
		if child.has_meta("emblem_case"):book=child
	check(is_instance_valid(book) and not app.pause_overlay.visible,"emblems open as own screen")
	book.back.pressed.emit();await settle()
	check(app.pause_overlay.visible and root.gui_get_focus_owner()==app.pause_overlay.buttons.emblems,"emblems close to lobby")
	app._resume_game();await settle()
	check(not is_instance_valid(app.pause_overlay) and not app.park.paused,"world resumes after menus")
	var locked=load("res://scripts/campaign/hud_pause.gd").new();locked.player={};root.add_child(locked);await settle()
	check(locked.buttons.identity.disabled and locked.buttons.emblems.disabled and locked.buttons.workshop.disabled,"early story locks unavailable features")
	locked.free();app.free();await settle()
	print("LOBBY: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
