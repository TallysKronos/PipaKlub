extends SceneTree
## Revisão de arte da área de prova kronasta-bosque-a: câmeras fixas, sem salvar campanha.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var View = load("res://scripts/overworld/view.gd")
	root.size = Vector2i(1280,720)
	var output := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="): output = argument.trim_prefix("--out=")
	if output.is_empty(): output = ProjectSettings.globalize_path("res://../documentation/overworld/kronasta/captures")
	DirAccess.make_dir_recursive_absolute(output)
	var view = View.new()
	view.area_id = "kronasta-bosque-a"
	view.art_preview = true
	root.add_child(view)
	if view.camera == null:
		quit(1)
		return
	view.set_physics_process(false)
	view.camera.position_smoothing_enabled = false
	var frames := [
		{"file":"entrada","point":Vector2(27.5,38.5),"zoom":1.0},
		{"file":"plato-leste","point":Vector2(34.5,22.5),"zoom":1.0},
		{"file":"trilha-centro","point":Vector2(24.5,24.5),"zoom":1.0},
		{"file":"plato-oeste","point":Vector2(14.5,28.5),"zoom":1.0},
		{"file":"rampa-detalhe","point":Vector2(24.5,24.5),"zoom":2.0},
		# Bocas de rampa ampliadas, sem personagem na junta (AGENTS.md, continuidade de terreno).
		{"file":"rampa-leste","point":Vector2(25.5,18.5),"look":Vector2(36,26.5),"zoom":2.2},
		{"file":"rampa-sudeste","point":Vector2(25.5,18.5),"look":Vector2(39,36.5),"zoom":2.2},
		{"file":"rampa-noroeste","point":Vector2(25.5,18.5),"look":Vector2(15,10),"zoom":2.2},
		{"file":"rampa-oeste","point":Vector2(25.5,18.5),"look":Vector2(16.5,31),"zoom":2.2},
		{"file":"area-inteira","point":Vector2(26,22),"zoom":.36}
	]
	for frame in frames:
		view.player = frame.point
		view.follower = frame.point+Vector2(1,0)
		view._refresh_positions()
		view.camera.zoom = Vector2.ONE*float(frame.zoom)
		view.camera.position = view.model.project(frame.get("look",frame.point))-Vector2(0,40)
		for index in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(str(frame.file)+".png"))
	view.free()
	print("kronasta-bosque-a: ",frames.size()," capturas")
	quit()
