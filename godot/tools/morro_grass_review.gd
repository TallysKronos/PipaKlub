extends SceneTree
const View = preload("res://scripts/overworld/view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var phase := "after"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--phase="): phase = argument.trim_prefix("--phase=")
	root.size = Vector2i(1280,720)
	var destination := ProjectSettings.globalize_path("res://../documentation/overworld/grama-morro/"+phase)
	DirAccess.make_dir_recursive_absolute(destination)
	var view := View.new()
	view.art_preview = true
	root.add_child(view)
	view.set_physics_process(false)
	var records: Array = []
	for area in ["morro-parque-dos-ventos","morro-praca-da-chegada"]:
		view.load_area(area)
		view.set_physics_process(false)
		view.camera.position_smoothing_enabled = false
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		var path := destination.path_join(area+"-1280x720.png")
		root.get_texture().get_image().save_png(path)
		records.append({"area":area,"size":[root.size.x,root.size.y],"image":path.get_file(),"decals":view.get_meta("grass_decal_count",0),"scope":"isolated overworld preview; campaign saves untouched"})
	var output := FileAccess.open(destination.path_join("capture.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(records,"\t"))
	# Exercise the real floor material with fractional zoom and no underlay.
	var field := Node2D.new()
	root.add_child(field)
	for v in 8:
		for u in 8:
			var tile := view._grass_surface("res://assets/overworld/kits/morro/chao/grama-"+str(view._grass_hash(Vector2i(u,v))%8)+".png")
			tile.position = Vector2((u-v)*32,(u+v)*16)
			field.add_child(tile)
	view.free()
	var camera := Camera2D.new()
	camera.position = Vector2(0,112)
	camera.zoom = Vector2(1.4,1.4)
	field.add_child(camera)
	RenderingServer.set_default_clear_color(Color.BLACK)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(destination.path_join("grama-8x8-godot-1280x720.png"))
	print("MORRO GRASS CAPTURES: ",records.size()," at 1280x720")
	quit()
