extends SceneTree
const Model=preload("res://scripts/campaign/first_flight_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func run() -> void:
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	app.preferences.storage_path="user://tutorial-qa.cfg";root.add_child(app);app.preferences.reduced_motion=true
	var output:="res://../documentation/qa/tutorial-guidance-v1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for lesson in 5:
		load("res://tools/player_audit_fixtures.gd").show(app,"lesson-%d"%lesson)
		for i in 10:await process_frame
		var view:Control=app._practice_view()
		view._process(0)
		check(view.spotlight.visible,"guide stays visible while practicing")
		view.highlight_age=100;view._process(0)
		check(view.spotlight.visible,"guide never expires on a timer")
		check(view.spotlight.mouse_filter==Control.MOUSE_FILTER_IGNORE,"guide does not block field or commands")
		check(view.spotlight.holes.size()>=4,"target, actor and instructions stay illuminated")
		check(not view.next_button.visible,"no disabled advance button during practice")
		var motion:=InputEventMouseMotion.new();motion.position=view._project(Vector2(700,180))
		view.mouse_target=Vector2(-1,-1);view._gui_input(motion)
		check(view.mouse_target==Vector2(-1,-1),"hover alone does not move the pipamon")
		var click:=InputEventMouseButton.new();click.position=motion.position;click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;view._gui_input(click)
		check(view.mouse_target.x>=0,"field click sets movement target")
		if lesson==3:
			for exercise in ["skill","dodge","line","guard"]:
				view.model.exercise=exercise;view._process(0)
				check(not view.guidance().is_empty(),"one clear instruction per tool")
			view.model.exercise="skill";view.model.p.skillTime=1;view._process(0)
			check("Agora" in view.guidance(),"skill activation changes instruction to cutting")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("lesson-%d.png"%lesson))
		view.model.complete=true;view._process(0)
		check(not view.spotlight.visible and view.next_button.visible,"completion removes dimming and reveals advance")
	var model:=Model.new(3);model.p.guardCooldown=20;model.p.skillCooldown=7;model.tick(.016,{})
	check(model.p.guardCooldown<=2 and model.p.skillCooldown<=1.5,"practice gives quick retries")
	app.free();await process_frame
	print("TUTORIAL GUIDANCE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
