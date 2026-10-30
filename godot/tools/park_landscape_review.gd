extends SceneTree
## In-memory review: no save writes or campaign reward operations.
var output := "res://../documentation/overworld/parque-veredas-v2"
func _initialize() -> void:call_deferred("start")
func shot(view: Node2D,id: String,point: Vector2,zoom: float) -> void:
	view.player=point
	view.follower=point+Vector2(24,14)
	if view.has_method("_refresh"):view._refresh()
	else:view._refresh_positions()
	view.camera.position_smoothing_enabled=false
	view.camera.limit_left=-10000;view.camera.limit_right=10000
	view.camera.limit_top=-10000;view.camera.limit_bottom=10000
	view.camera.zoom=Vector2.ONE*zoom
	view.camera.position=view.landscape.project(point)-Vector2(0,60)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))

func start() -> void:
	root.size=Vector2i(1280,720)
	RenderingServer.set_default_clear_color(Color("0c1624"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var maps: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
	var player_data := {"name":"Kael","partners":[],"flags":{},"openedChests":[],"coins":0,"inventory":{}}
	for id in ["park-trail","park-clearing","park-veredas"]:
		var view: Node2D
		if id=="park-veredas":view=load("res://scripts/campaign/park_view.gd").new()
		else:
			view=load("res://scripts/campaign/park_route_view.gd").new()
			view.data=maps[id];view.content=content
		view.saved_player=player_data
		root.add_child(view);view.set_physics_process(false)
		if id=="park-veredas":
			await shot(view,"veredas-geral",Vector2(768,500),.70)
			await shot(view,"veredas-ponte",Vector2(690,460),1.6)
			await shot(view,"veredas-encosta",Vector2(1165,345),1.4)
			await shot(view,"veredas-boss",Vector2(1300,154),1.4)
		else:
			await shot(view,id+"-geral",Vector2(768,568),.52)
			await shot(view,id+"-entrada",Vector2(208,816),1.1)
			await shot(view,id+"-rampa",Vector2(1184 if id=="park-clearing" else 928,540),1.35)
			await shot(view,id+"-patamar",Vector2(920,350),1.1)
		for prop in view.landscape.prop_nodes:prop.hide()
		view.avatar.hide();view.companion.hide()
		await shot(view,id+"-sem-ocupantes",Vector2(1165,345) if id=="park-veredas" else Vector2(1184 if id=="park-clearing" else 928,460),1.6)
		if id!="park-veredas":
			var ramp_x := 1184.0 if id=="park-clearing" else 928.0
			for y in [444,640]:await shot(view,id+"-encaixe-"+str(y),Vector2(ramp_x,y),2.1)
		view.free()
		var geometry: Node2D=load("res://scripts/overworld/park_landscape.gd").new()
		geometry.geometry_only=true
		root.add_child(geometry)
		geometry.build(id,JSON.parse_string(FileAccess.get_file_as_string("res://assets/illustrated/routes-v2.json")) if id=="park-veredas" else maps[id])
		var camera := Camera2D.new();camera.zoom=Vector2.ONE*(.65 if id=="park-veredas" else .52)
		camera.position=geometry.project(Vector2(768,500 if id=="park-veredas" else 568))-Vector2(0,60)
		geometry.add_child(camera)
		for i in 4:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+"-geometria.png")))
		geometry.free()
	print("Park landscapes: native captures completed. No slots or rewards changed.")
	quit()
