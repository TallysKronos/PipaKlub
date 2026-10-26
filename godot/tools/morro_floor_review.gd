extends SceneTree
const View = preload("res://scripts/overworld/view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280,720)
	var destination := ProjectSettings.globalize_path("res://../documentation/overworld/pisos-morro/after")
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
		root.get_texture().get_image().save_png(destination.path_join(area+"-1280x720.png"))
		records.append({"area":area,"size":[1280,720],"decals":view.get_meta("grass_decal_count",0),"floor":"generated surfaces with continuous world UV"})
	view.camera.enabled = false
	view.hide()
	view.interface.hide()
	# Exercise all three materials, shared edges and a three-material junction.
	for material_name in ["grama","calcada","piso","encontros"]:
		var field := Node2D.new()
		root.add_child(field)
		for v in 8:
			for u in 8:
				var corners: Array = []
				for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
					var vertex: Vector2i = Vector2i(u,v)+offset
					corners.append(material_name if material_name != "encontros" else "grama" if vertex.x<4 else "calcada" if vertex.y<4 else "piso")
				var tile := view._painted_floor(Vector2i(u,v),{"level":0,"corners":corners})
				tile.position = Vector2((u-v)*32,(u+v)*16)
				field.add_child(tile)
		var camera := Camera2D.new()
		camera.position = Vector2(0,112)
		camera.zoom = Vector2(1.4,1.4)
		field.add_child(camera)
		RenderingServer.set_default_clear_color(Color.BLACK)
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(destination.path_join(material_name+"-8x8-godot-1280x720.png"))
		field.free()
	var output := FileAccess.open(destination.path_join("capture.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(records,"\t"))
	view.free()
	print("MORRO FLOOR CAPTURES: 2 maps + 4 native 8x8 fields at 1280x720")
	quit()
