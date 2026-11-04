extends SceneTree
## Native visual review only. No campaign, rewards or input simulation.
const View = preload("res://scripts/overworld/view.gd")
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280,720)
	var output := ProjectSettings.globalize_path("res://../documentation/overworld/parque/captures")
	DirAccess.make_dir_recursive_absolute(output)
	var view := View.new()
	view.area_id = "jardim-das-pipas"
	view.art_preview = true
	root.add_child(view)
	view.set_physics_process(false)
	var frames := [
		{"area":"jardim-das-pipas","file":"jardim-inteiro","point":Vector2(12,8),"zoom":.72,"offset":55},
		{"area":"jardim-das-pipas","file":"coreto","point":Vector2(5.5,6.5),"zoom":1.5,"offset":65},
		{"area":"jardim-das-pipas","file":"entrada-jardim","point":Vector2(5,11.5),"zoom":1.4,"offset":65},
		{"area":"clareira-do-papel","file":"clareira-inteira","point":Vector2(12,8),"zoom":.72,"offset":55},
		{"area":"clareira-do-papel","file":"capim","point":Vector2(16,7.5),"zoom":1.5,"offset":65},
		{"area":"clareira-do-papel","file":"entrada-clareira","point":Vector2(5,11.5),"zoom":1.4,"offset":65}
	]
	for frame in frames:
		if view.area_id != frame.area: view.load_area(frame.area)
		view.camera.position_smoothing_enabled = false
		view.player = frame.point
		view.follower = frame.point+Vector2(1,0)
		view._refresh_positions()
		view.camera.zoom = Vector2.ONE*float(frame.zoom)
		view.camera.position = view.model.project(frame.point)-Vector2(0,float(frame.offset))
		view.hint.text = "PIP-85 · revisão visual do Parque · sem salvar campanha"
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(str(frame.file)+"-1280x720.png"))
		if frame.file == "capim":
			for moment in 12:
				for i in 4: await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("vento-%02d.png" % moment))
	root.size = Vector2i(1280,800)
	view.player = Vector2(16,7.5)
	view.follower = view.player+Vector2(1,0)
	view._refresh_positions()
	view.camera.zoom = Vector2.ONE*1.4
	view.camera.position = view.model.project(view.player)-Vector2(0,65)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("capim-formato-deck-1280x800.png"))
	view.free()
	print("Parque: ",frames.size()," capturas nativas 1280x720. Sem suite de testes ou campanha.")
	quit()
