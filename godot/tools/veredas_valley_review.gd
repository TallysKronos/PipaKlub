extends SceneTree
## Native art + real camera regression fixture; no Session or persistent writes.
const View = preload("res://scripts/campaign/park_view.gd")
const Park = preload("res://scripts/campaign/park_data.gd")
var view: Node2D
var output := "res://../documentation/overworld/veredas-valley-v3"
var report: Array[Dictionary]=[]
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("start")
func capture(id: String) -> void:
	for i in 16:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))
func start() -> void:
	root.size=Vector2i(1280,720)
	var before := "--before" in OS.get_cmdline_user_args()
	output+="/before" if before else "/after"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	view=View.new()
	view.saved_player={"name":"Kael","partners":[],"flags":{},"openedChests":[],"coins":0,"inventory":{}}
	view.spawn_point=Park.CHESTS.lookout.point
	root.add_child(view);view.set_physics_process(false);view.paused=true
	for id in Park.CHESTS:
		var point: Vector2=Park.CHESTS[id].point
		if not before:
			# Replay the real route controller and companion trail to the chest.
			# No keyboard/UI injection and no campaign grant or persistence.
			view.player=Park.ENTRY;view.follower=Park.ENTRY;view.trail.assign([Park.ENTRY])
			view.route=view._path(view.player,point)
			if view.route.is_empty():failures.append(id+": missing walk route")
			var steps := 0
			while not view.route.is_empty() and steps<2400:
				view._follow_route(145.0/60.0)
				view._follow_companion(145.0/60.0)
				steps+=1
			if view.player.distance_to(point)>3:failures.append(id+": real controller did not reach chest")
			if not view.ground.walkable(view.follower):failures.append(id+": companion left support")
		view.player=point;view.follower=point+Vector2(24,12)
		view._refresh_positions();view._physics_process(0)
		view.camera.reset_smoothing()
		await capture(id+"-normal-camera")
		var expected: Vector2=view.landscape.project(point)
		var center: Vector2=view.camera.get_screen_center_position()
		var screen: Vector2=view.avatar.get_global_transform_with_canvas().origin
		var error := center.distance_to(expected)
		report.append({"id":id,"point":[point.x,point.y],"cameraError":error,"screenFeet":[screen.x,screen.y]})
		if not before and (error>2.0 or screen.y<100 or screen.y>620 or screen.x<100 or screen.x>1180):failures.append(id+": camera follow/frame")
	if not before:
		view.overview=true
		view.camera.position_smoothing_enabled=false
		view.camera.zoom=Vector2.ONE*.64
		view.camera.position=Vector2(780,485)
		await capture("valley-general")
		view.camera.zoom=Vector2.ONE*1.35;view.camera.position=Vector2(865,385)
		await capture("valley-between-ridges")
		view.camera.position=Vector2(680,525)
		await capture("river-bank-bridge")
		for prop in view.landscape.prop_nodes:prop.hide()
		view.avatar.hide();view.companion.hide();view.nina.hide()
		view.camera.position=Vector2(780,485);view.camera.zoom=Vector2.ONE*.64
		await capture("valley-without-props")
	var file := FileAccess.open(output.path_join("camera-review.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"before":before,"samples":report,"failures":failures},"  "))
	for failure in failures:push_error(failure)
	view.free()
	print("Veredas valley: camera and native frames; failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
