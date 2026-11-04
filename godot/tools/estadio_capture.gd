extends SceneTree
## Revisão de arte da área de prova kronasta-estadio-a: câmeras fixas, sem salvar campanha.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var View = load("res://scripts/overworld/view.gd")
	root.size = Vector2i(1280,720)
	var output := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="): output = argument.trim_prefix("--out=")
	if output.is_empty(): output = ProjectSettings.globalize_path("res://../documentation/overworld/estadio/capturas")
	DirAccess.make_dir_recursive_absolute(output)
	var view = View.new()
	view.area_id = "kronasta-estadio-a"
	view.art_preview = true
	root.add_child(view)
	if view.camera == null:
		quit(1)
		return
	view.set_physics_process(false)
	view.interface.hide()
	view.player_root.hide()
	view.follower_root.hide()
	view.camera.position_smoothing_enabled = false
	var frames := [
		{"file":"entrada","point":Vector2(24.5,19.5),"zoom":1.0},
		{"file":"praca","point":Vector2(21.5,15.5),"zoom":1.0},
		{"file":"corredor","point":Vector2(24.5,14.5),"zoom":1.0},
		{"file":"recepcao","point":Vector2(24.5,6.5),"zoom":1.0},
		{"file":"espera-detalhe","point":Vector2(19.5,12.5),"zoom":2.0},
		{"file":"balcao-detalhe","point":Vector2(24.5,6.5),"zoom":2.0},
		{"file":"area-inteira","point":Vector2(24,12),"zoom":.43}
	]
	for frame in frames:
		view.player = Vector2(24.5,20.5)
		view.follower = Vector2(24.5,20.5)
		view._refresh_positions()
		view.camera.zoom = Vector2.ONE*float(frame.zoom)
		view.camera.position = view.model.project(frame.get("look",frame.point))-Vector2(0,40)
		for index in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(str(frame.file)+".png"))
	view.free()
	print("kronasta-estadio-a: ",frames.size()," capturas")
	quit()




