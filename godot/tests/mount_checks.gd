extends SceneTree
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func settle() -> void:
	for i in 6:await process_frame
func capture(label:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	var out:=ProjectSettings.globalize_path("res://../documentation/qa/mount-doberman-v2")
	DirAccess.make_dir_recursive_absolute(out)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(label+".png"))
func run() -> void:
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	app.preferences.storage_path="user://mount-test.cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	for scenario in ["street","trail","morro"]:
		Fixtures.show(app,scenario);await settle()
		var view:Node2D=app.park
		view.set_physics_process(false);view.paused=false
		var original:Vector2=view.player
		check(view.has_method("toggle_mount"),scenario+" mount available")
		view.saved_player.inventory["apito-de-elo"]=1
		preload("res://scripts/campaign/mount_quest.gd").grant_partner(view.saved_player)
		view.toggle_mount();await settle()
		check(view.avatar.mounted and view.avatar.mount_rig.visible,scenario+" mounted visual")
		check(view.avatar.travel_multiplier()>1,scenario+" travel modifier")
		check(view.player==original,scenario+" mounting never teleports")
		for facing in ["s","sw","w","nw","n","ne","e","se"]:
			view.avatar.facing=facing;view.avatar._process(0)
			check(view.avatar.mount_rig.facing==facing,"direction synchronized "+scenario+facing)
			check(view.avatar.mount_rig.rider.get_parent()==view.avatar.mount_rig.seat,"rider attached to socket")
			check(view.avatar.mount_rig.seat.position.y<0,"socket above ground")
			var rig:Node2D=view.avatar.mount_rig
			check(rig.far_leg.z_index<rig.body.z_index and rig.rider.z_index>rig.body.z_index,"legs straddle body layers")
			check(rig.far_leg.region_rect==rig.rider.region_rect and rig.far_leg.position.is_equal_approx(rig.rider.position.rotated(rig.far_leg.rotation)),"distant limb rotates around shared hip")
			check(rig.far_leg.material.get_shader_parameter("far_layer")==true and rig.rider.material.get_shader_parameter("far_layer")==false,"complementary leg masks")
			check(rig.seat.z_index==0,"whole rider never hidden behind creature")
		view.avatar.facing="se";view.avatar._process(0);await settle()
		await capture(scenario)
		if scenario=="trail":
			for direction in view.avatar.DIRECTIONS:
				view.avatar.facing=direction;view.avatar._process(0);await settle();await capture("map-"+direction)
		view.paused=true;view.toggle_mount()
		check(view.avatar.mounted,scenario+" paused toggle rejected")
		view.paused=false;view.toggle_mount()
		check(not view.avatar.mounted and not view.avatar.mount_rig.visible,scenario+" dismount restores walking")
		check(view.avatar.travel_multiplier()==1,scenario+" walking speed restored")
		view.toggle_mount();view.avatar.set_motion_action("subir")
		check(not view.avatar.mounted,scenario+" ladder/staging dismounts safely")
		view.avatar.set_motion_action("")
		var key:=InputEventKey.new();key.pressed=true;key.physical_keycode=KEY_B
		app._unhandled_input(key)
		check(view.avatar.mounted,scenario+" B input mounts through campaign")
		view.avatar.set_mounted(false)
	app.free();await settle()
	var field=load("res://scripts/overworld/view.gd").new();field.area_id="gelo-a";field.art_preview=true
	root.add_child(field);await settle();field.set_physics_process(false)
	field.toggle_mount()
	var controls=load("res://scripts/campaign/controls.gd");controls.install()
	var locomotion=load("res://scripts/campaign/locomotion.gd");locomotion.toggled=true
	var distance:=0.0
	for direction in ["right","down","left","up"]:
		Input.action_press("campaign_"+direction)
		for step in 120:
			var old:Vector2=field.player;field._physics_process(1.0/60);distance+=old.distance_to(field.player)
			check(field.model.point_walkable(field.player),"mounted movement stays supported")
		Input.action_release("campaign_"+direction)
		check(field.player.distance_to(field.follower)<2,"companion keeps up with mounted sprint")
		check(field.camera.position==field.model.project(field.player),"camera follows mount ground")
	check(distance>1,"mounted input actually moves")
	locomotion.toggled=false;field.free();await settle()
	var stage:=Node2D.new();root.add_child(stage)
	for i in 8:
		var avatar=load("res://scripts/avatar.gd").new();stage.add_child(avatar)
		avatar.position=Vector2(160+(i%4)*320,330+(i/4)*350)
		avatar.scale=Vector2.ONE*1.5;avatar.facing=avatar.DIRECTIONS[i];avatar.set_mounted(true)
	await settle();await capture("directional-fit")
	# One pose at a time at larger scale exposes seams that the overview can hide.
	for child in stage.get_children():child.hide()
	for index in [0,1,2,3,4,5,6,7]:
		var subject:Node2D=stage.get_child(index);subject.show();subject.position=Vector2(640,590);subject.scale=Vector2.ONE*3.2
		await settle();await capture("detail-"+subject.facing)
		subject.hide()
	var foot=load("res://scripts/avatar.gd").new();stage.add_child(foot);foot.position=Vector2(430,540);foot.scale=Vector2.ONE*2.2
	var mounted:Node2D=stage.get_child(7);mounted.show();mounted.position=Vector2(800,540);mounted.scale=Vector2.ONE*2.2
	await settle();await capture("kael-scale-comparison")
	stage.free();await settle()
	print("MOUNTS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
