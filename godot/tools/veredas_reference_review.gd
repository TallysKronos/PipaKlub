extends SceneTree
## Real view/controller and in-memory save fixture. No persistence or rewards.
const View = preload("res://scripts/campaign/park_view.gd")
const Park = preload("res://scripts/campaign/park_data.gd")
var view: Node2D
var failures: Array[String]=[]
var report: Array[Dictionary]=[]
var output := "res://../documentation/overworld/veredas-reference-v4"
func _initialize() -> void:call_deferred("start")
func capture(id: String) -> void:
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))
func start() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	view=View.new()
	view.saved_player={"name":"Kael","partners":[],"flags":{"ninaAccepted":true},"openedChests":[],"coins":0,"inventory":{}}
	root.add_child(view);view.set_physics_process(false);view.paused=true
	print("Reference warp valid=",view.landscape.warp.valid," floors=",view.data.floors.size()," graph=",view.navigation.get_point_count())
	var targets := {"entry":Park.ENTRY,"nina":Park.NINA,"boss":Park.BOSS,"tail":Park.TAIL}
	for id in Park.CHESTS:targets[id]=Park.CHESTS[id].point
	for id in targets:
		var point: Vector2=targets[id]
		var supported: bool=view.ground.walkable(point)
		var route: PackedVector2Array=view._path(Park.ENTRY,point)
		print(id," at ",view.landscape.project(point)," supported=",supported," route=",route.size())
		if not supported:failures.append(id+": support")
		if route.is_empty():failures.append(id+": no route")
		if supported and not route.is_empty():
			view.player=Park.ENTRY;view.follower=Park.ENTRY;view.trail.assign([Park.ENTRY]);view.route=route
			var steps := 0
			while not view.route.is_empty() and steps<3000:
				view._follow_route(145.0/60.0);view._follow_companion(145.0/60.0);steps+=1
			if view.player.distance_to(point)>3:failures.append(id+": traversal stalled")
		view.player=point;view.follower=point+Vector2(16,12)
		view._refresh_positions();view._physics_process(0);view.camera.reset_smoothing()
		await capture("point-"+str(id))
		var screen: Vector2=view.avatar.get_global_transform_with_canvas().origin
		report.append({"id":id,"supported":supported,"routePoints":route.size(),"cameraError":view.camera.get_screen_center_position().distance_to(view.landscape.project(point)),"screenFeet":[screen.x,screen.y]})
	view.overview=true;view.camera.position_smoothing_enabled=false
	view.camera.position=Vector2(768,510);view.camera.zoom=Vector2.ONE*.70
	await capture("map-overview")
	for mask in view.landscape.prop_nodes:mask.hide()
	# Rendering the authored support polygons directly gives a measurable plant,
	# not a second generated illustration.
	var overlay := Node2D.new();overlay.z_index=4090;view.add_child(overlay)
	for floor_data: Dictionary in view.landscape.layout.floors:
		var p := Polygon2D.new();p.polygon=view.landscape.polygon(floor_data.points);p.color=Color(.1,.8,.8,.25);overlay.add_child(p)
	await capture("support-overlay")
	FileAccess.open(output.path_join("review.json"),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"samples":report,"campaignWrites":false},"  "))
	for failure in failures:push_error(failure)
	view.free();print("Reference Veredas native review; failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
