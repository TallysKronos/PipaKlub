extends SceneTree
const Pixels=preload("res://scripts/npc_pixel_sprite.gd")
const State=preload("res://scripts/campaign/state.gd")
var count:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	count+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func run() -> void:
	var sprite:=Sprite2D.new();root.add_child(sprite)
	Pixels.setup(sprite,"mae",88)
	var base:Texture2D=sprite.texture
	for row in 8:
		Pixels.face(sprite,Pixels.DIRECTIONS[row])
		var frames:Array[Rect2]=[]
		for seconds in [0.0,.16,.29,.43]:
			Pixels.animate_walk(sprite,true,seconds)
			frames.append(sprite.region_rect)
			check(sprite.region_rect.position.y==row*96,"walk retains direction")
		check(frames[0]!=frames[1] and frames[1]!=frames[2] and frames[2]!=frames[3],"four distinct frames per direction")
		Pixels.reveal(sprite,.5)
		check(sprite.material.get_shader_parameter("rows")==8.0,"stairs mask uses walk atlas height")
		Pixels.animate_walk(sprite,false,0);Pixels.reveal(sprite,1)
		check(sprite.texture==base and sprite.material.get_shader_parameter("rows")==2.0,"rest restores base atlas and mask")
	check(Pixels.mother_walk.get_size()==Vector2(256,768),"authored atlas dimensions")
	sprite.free()
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	app.session._store=load("res://scripts/campaign/save_store.gd").new("user://mother-walk-"+State.new_id())
	app.preferences.storage_path="user://mother-walk.cfg";root.add_child(app);app.preferences.reduced_motion=true
	load("res://tools/player_audit_fixtures.gd").show(app,"opening-5")
	await create_timer(.25).timeout
	check(app.room.mother_walking and app.room.mother_stair==1,"mother climbs using walking state")
	var first:Rect2=app.room.mother_sprite.region_rect
	await create_timer(.17).timeout
	check(first!=app.room.mother_sprite.region_rect,"frames advance during actual ascent")
	if "--capture" in OS.get_cmdline_user_args():
		var output:="res://../documentation/qa/tutorial-guidance-v1"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output.path_join("mae-subindo.png"))
	# The enlarged house (kit contemporâneo) makes the walk length vary; wait for arrival.
	for i in 80:
		if not app.room.mother_walking: break
		await create_timer(.1).timeout
	await create_timer(.1).timeout
	check(not app.room.mother_walking and not app.room.mother_sprite.get_meta("walking",false),"mother rests after arriving")
	# Let Kael's response to her entrance finish before starting the next beat.
	for i in 300:
		if not app.opening_busy:break
		await create_timer(.02).timeout
	app.room.mother_point=Vector2(528,816);app.room.mother_reveal=1
	load("res://scripts/campaign/opening_staging.gd").walk(app.room,"mother",[Vector2(528,928)],150,-1)
	await create_timer(.25).timeout
	check(app.room.mother_stair==-1 and app.room.mother_sprite.get_meta("walking",false),"descent also animates legs")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://../documentation/qa/tutorial-guidance-v1/mae-descendo.png")
	for i in 40:
		if not app.room.mother_walking: break
		await create_timer(.1).timeout
	check(not app.room.mother_walking,"descent returns to resting pose")
	app.free();await process_frame
	print("MOTHER WALK: %d checks; %d failures"%[count,failures]);quit(1 if failures else 0)
