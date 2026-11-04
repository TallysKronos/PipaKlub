extends SceneTree
## Real view/controller and in-memory save fixture. No persistence or rewards.
const View = preload("res://scripts/campaign/park_view.gd")
const Park = preload("res://scripts/campaign/park_data.gd")
var view: Node2D
var failures: Array[String]=[]
var report: Array[Dictionary]=[]
var output := "res://../documentation/overworld/veredas-modular-v5"
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
	var began := Time.get_ticks_msec()
	root.add_child(view);view.set_physics_process(false);view.paused=true
	var build_ms := Time.get_ticks_msec()-began
	print("Native terrain; warp valid=",view.landscape.warp.valid," floors=",view.data.floors.size()," graph=",view.navigation.get_point_count())
	var targets := {"entry":Park.ENTRY,"nina":Park.NINA,"boss":Park.BOSS,"tail":Park.TAIL}
	for id in Park.CHESTS:targets[id]=Park.CHESTS[id].point
	for id in targets:
		var point: Vector2=targets[id]
		var supported: bool=view.ground.walkable(point)
		var route: PackedVector2Array=view._path(Park.ENTRY,point)
		var route_size := route.size()
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
		var error: float=view.camera.get_screen_center_position().distance_to(view.landscape.project(point))
		if error>2:failures.append(id+": camera")
		if view.landscape.unproject(view.landscape.project(point)).distance_to(point)>.1:failures.append(id+": mouse inverse")
		report.append({"id":id,"supported":supported,"routePoints":route_size,"cameraError":error,"screenFeet":[screen.x,screen.y]})
	for connection in [
		["west-bridge",Vector2(520,500),Vector2(647,465)],
		["south-bridge",Vector2(986,750),Vector2(1100,688)],
		["lookout-stairs",Vector2(496,309),Vector2(457,198)],
		["courtyard-ramp",Vector2(894,342),Vector2(944,236)]]:
		var a: Vector2=view.landscape.warp.transform(connection[1],true)
		var b: Vector2=view.landscape.warp.transform(connection[2],true)
		if not view.ground.clear_segment(a,b):failures.append(connection[0]+": direct crossing blocked")
		for direction in [[a,b],[b,a]]:
			var route: PackedVector2Array=view._path(direction[0],direction[1])
			if route.is_empty():failures.append(connection[0]+": disconnected")
			view.player=direction[0];view.follower=direction[0];view.trail.assign([direction[0]]);view.route=route
			var steps := 0
			while not view.route.is_empty() and steps<3000:
				view._follow_route(145.0/60);view._follow_companion(145.0/60);steps+=1
			if view.player.distance_to(direction[1])>3:failures.append(connection[0]+": traversal")
	# Existing progression flags still control separate native sprites.
	var won: Dictionary=view.saved_player.duplicate(true)
	won.flags.guardianDefeated=true;won.openedChests=Park.CHESTS.keys()
	view.refresh(won)
	if view.guardian.visible or not view.tail.visible:failures.append("boss flags")
	for chest in view.chest_nodes.values():
		if chest.visible:failures.append("opened chest flag")
	won.flags.ninaTail=true;view.refresh(won)
	if view.tail.visible:failures.append("tail collected flag")
	won.flags={"ninaAccepted":true};won.openedChests=[];view.refresh(won)
	view.overview=true;view.camera.position_smoothing_enabled=false
	view.camera.position=Vector2(768,460);view.camera.zoom=Vector2.ONE*.65
	for child in view.get_children():
		if child is CanvasLayer:child.hide()
	await capture("map-overview")
	view.actors.hide()
	for prop in view.landscape.prop_nodes:prop.hide()
	for sample in [["stair-joints",Vector2(481,240)],["ramp-joints",Vector2(945,280)],["bridge-west",Vector2(587,482)],["bridge-south",Vector2(1044,723)]]:
		view.camera.position=sample[1];view.camera.zoom=Vector2.ONE*2
		await capture(sample[0])
	view.landscape.hide()
	var blockout=load("res://scripts/overworld/veredas_modular_landscape.gd").new()
	blockout.geometry_only=true;blockout.show_props=false;view.add_child(blockout);blockout.build("park-veredas",view.data)
	view.camera.position=Vector2(768,460);view.camera.zoom=Vector2.ONE*.65
	await capture("geometry-only")
	FileAccess.open(output.path_join("review.json"),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"samples":report,"campaignWrites":false,"buildMs":build_ms,"navigationNodes":view.navigation.get_point_count()},"  "))
	for failure in failures:push_error(failure)
	view.free();print("Modular Veredas native review; failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
