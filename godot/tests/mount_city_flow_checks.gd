extends SceneTree
const Quest=preload("res://scripts/campaign/mount_quest.gd")
const Identity=preload("res://scripts/campaign/pipeiro_identity.gd")
var checks:=0
var failures:=0
var app:Control
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:call_deferred("run")
func settle(frames:int=10) -> void:
	for i in frames:await process_frame
func capture(label:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/mount-city-quest-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func finish_loading() -> void:
	for i in 600:
		await process_frame
		if not is_instance_valid(app.scene_loading):return
	check(false,"loading terminates")
func dialog() -> Control:
	var list=get_nodes_in_group("manga_dialogue")
	return list[-1] if not list.is_empty() else null
func place(point:Vector2) -> void:
	app.park.cell=point;app.park.surface=app.park.world.cell_id(floori(point.x),floori(point.y))
	app.park.elevation=app.park.world.support(point);app.park._refresh_visuals();app.park._update_hint()
	app.park.camera.position=app.park.player_root.position-Vector2(0,35);app.park.camera.reset_smoothing()
func run() -> void:
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	app=load("res://scripts/campaign/front_end.gd").new()
	var dir:="user://mount-city-ui-"+preload("res://scripts/campaign/state.gd").new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(dir);app.preferences.storage_path=dir+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	app.session.start("slot-1")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"};player.partners=[{"id":"mount-test","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];player.equippedPartnerId="mount-test"
	Identity.issue_into(player);player.flags.pipeiroDocumentsSeen=true
	app.session.checkpoint({"kind":"world","scene":"quintal","space":"bairro-inicial-v2","position":[22,18.5]},player)
	app._show_saved();await finish_loading();await settle()
	check(is_instance_valid(app.park),"city loads after remote integration")
	check(not app.park.can_mount(),"city mount locked before quest")
	app.park.exploration_hud._layout();check(not app.park.exploration_hud.mount_button.visible,"no prototype mount button before reward")
	app.park.toggle_mount();check(not app.park.avatar.mounted,"direct mount action also gated")
	place(Vector2(22,18.5));app.park.interact();await settle()
	check(is_instance_valid(dialog()) and dialog().title=="Zeca","Zeca quest dialogue")
	check(app.flow_busy and app.park.paused,"dialogue freezes city")
	dialog()._finish(false);await settle();check(Quest.stage(app.session.snapshot().player)==0,"cancel keeps quest available")
	app.park.interact();await settle();await capture("01-zeca-quest")
	dialog()._finish(true);await settle()
	check(Quest.stage(app.session.snapshot().player)==1 and not app.flow_busy,"accept restores movement and saves quest")
	place(Vector2(25,-.6));app.park.interact();await settle()
	check(dialog().title=="Lia","Lia delivers clasp")
	dialog()._finish(true);await settle();check(Quest.stage(app.session.snapshot().player)==2,"clasp is saved")
	place(Vector2(22,18.5));app.park.interact();await settle();dialog()._finish(true)
	await settle(2)
	for child in app.get_children():
		if child.has_meta("key_item_banner"):child.elapsed=.65;child.queue_redraw()
	await capture("02-apito-reward")
	for i in 600:
		await process_frame
		if not app.flow_busy:break
	check(Quest.owned(app.session.snapshot().player),"reward earned through UI")
	if is_instance_valid(dialog()):dialog()._finish(true)
	await settle();check(not app.park.paused and app.park.can_mount(),"reward restores movement and unlocks mount")
	var key:=InputEventKey.new();key.pressed=true;key.physical_keycode=KEY_B
	app._unhandled_input(key);check(app.park.avatar.mounted,"B mounts after reward")
	app.park.exploration_hud._layout();check("Desmontar" in app.park.exploration_hud.mount_button.text,"HUD reflects mounted state")
	app.park.avatar.moving=true;app.park.avatar.running=true;app.park.avatar.facing="sw";app.park.avatar._process(0)
	check(app.park.avatar.mount_rig.animation_key=="run-sw","city running animation")
	app.park.set_physics_process(false);await capture("03-mounted-city")
	app._show_bag();await settle()
	var bag:Control
	for child in app.page.get_children():
		if child.get_script()!=null and child.get_script().resource_path.ends_with("hud_inventory.gd"):bag=child;break
	check(is_instance_valid(bag),"inventory item screen")
	bag.select_item(Quest.ITEM);check(bag.use_button.visible and not bag.use_button.disabled,"whistle action in inventory")
	bag.use_button.pressed.emit();await finish_loading();await settle()
	check(app.park.avatar.mounted,"bag whistle waits for city loading before mounting")
	check(app.session.resume_slot("slot-1").status=="ok" and Quest.owned(app.session.snapshot().player),"reward survives restart")
	app.free();print("Mount city flow: ",checks," checks, ",failures," failures; isolated save ",dir)
	quit(1 if failures else 0)
