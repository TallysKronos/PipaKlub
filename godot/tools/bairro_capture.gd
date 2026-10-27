extends SceneTree
## Art review only: fixed cameras, no input simulation, saves or rewards.
const View = preload("res://scripts/overworld/view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280,720)
	var output := ProjectSettings.globalize_path("res://../documentation/overworld/bairro/captures")
	DirAccess.make_dir_recursive_absolute(output)
	var view := View.new()
	view.area_id = "rua-dos-ventos"
	view.art_preview = true
	root.add_child(view)
	view.set_physics_process(false)
	view.camera.position_smoothing_enabled = false
	var frames := [
		{"file":"casa-kael","point":Vector2(7.5,10.5),"zoom":1.65},
		{"file":"casa-assis","point":Vector2(21.5,10.5),"zoom":1.65},
		{"file":"loja-pipas","point":Vector2(35.5,10.5),"zoom":1.65},
		{"file":"praca","point":Vector2(20.5,26.5),"zoom":1.65},
		{"file":"rua-inteira","point":Vector2(22,16),"zoom":.52}
	]
	for frame in frames:
		view.player = frame.point
		view.follower = frame.point+Vector2(1,0)
		view._refresh_positions()
		view.camera.zoom = Vector2.ONE*float(frame.zoom)
		view.camera.position = view.model.project(frame.point)-Vector2(0,95)
		view.hint.text = "PIP-84 · revisão de arte local · sem alterar campanha"
		for index in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(str(frame.file)+"-1280x720.png"))
	view.free()
	print("Bairro: cinco capturas de arte 1280x720; sem executar testes ou salvar campanha.")
	quit()
