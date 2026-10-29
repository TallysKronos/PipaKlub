extends SceneTree
const View = preload("res://scripts/overworld/view.gd")
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280,720)
	var view := View.new()
	view.art_preview = true
	root.add_child(view)
	view.load_area("clareira-do-papel")
	view.set_physics_process(false)
	view.interface.hide()
	view.hide_characters()
	view.camera.position_smoothing_enabled = false
	view.camera.zoom = Vector2(1.5,1.5)
	view.camera.position = view.model.project(Vector2(31.5,30.5))-Vector2(0,35)
	var folder := ProjectSettings.globalize_path("res://../art/overworld/revisao/parque-abc/animacao")
	DirAccess.make_dir_recursive_absolute(folder)
	for frame in range(16):
		view.parque_surfaces.water_material.set_shader_parameter("preview_time",float(frame)*.25)
		for tick in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("agua-%02d.png"%frame))
	print("16 quadros reais do ciclo de quatro segundos")
	quit(0)
