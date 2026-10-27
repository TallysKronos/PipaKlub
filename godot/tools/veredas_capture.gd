extends SceneTree
## PIP-86: native art review, no campaign save, rewards or simulated input.
const View = preload("res://scripts/overworld/view.gd")
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280,720)
	var stage := "antes" if "--before" in OS.get_cmdline_user_args() else "depois"
	var output := ProjectSettings.globalize_path("res://../documentation/overworld/veredas/"+stage)
	DirAccess.make_dir_recursive_absolute(output)
	var view := View.new()
	view.area_id = "veredas-piloto"
	view.art_preview = true
	root.add_child(view)
	view.set_physics_process(false)
	var frames := [
		{"area":"veredas-piloto","file":"piloto-inteiro","point":Vector2(18,15),"zoom":.60,"offset":40},
		{"area":"veredas-piloto","file":"ponte","point":Vector2(16.5,20.5),"zoom":1.7,"offset":40},
		{"area":"veredas-piloto","file":"rampa-mirante","point":Vector2(9,10),"zoom":1.55,"offset":55},
		{"area":"veredas-piloto","file":"rampa-entrada","point":Vector2(9,12.5),"zoom":1.6,"offset":65},
		{"area":"veredas-do-encanamento","file":"veredas-inteiras","point":Vector2(25,16),"zoom":.43,"offset":35},
		{"area":"veredas-do-encanamento","file":"rampa-mirante-principal","point":Vector2(12,9.5),"zoom":1.4,"offset":35},
		{"area":"veredas-do-encanamento","file":"rampa-encosta","point":Vector2(27,9.5),"zoom":1.4,"offset":35},
		{"area":"veredas-do-encanamento","file":"rampa-patio-meio","point":Vector2(38,9.5),"zoom":1.4,"offset":35},
		{"area":"veredas-do-encanamento","file":"rampa-patio-topo","point":Vector2(38,7.5),"zoom":1.4,"offset":35},
		{"area":"veredas-do-encanamento","file":"rampa-patio-base","point":Vector2(38,12.5),"zoom":1.4,"offset":35},
		{"area":"veredas-do-encanamento","file":"patio","point":Vector2(44,5),"zoom":1.1,"offset":55}
	]
	for frame in frames:
		if view.area_id != frame.area: view.load_area(frame.area)
		view.camera.position_smoothing_enabled = false
		view.player = frame.point
		view.follower = frame.point+Vector2(1,0)
		view._refresh_positions()
		view.camera.zoom = Vector2.ONE*float(frame.zoom)
		view.camera.position = view.model.project(frame.point)-Vector2(0,float(frame.offset))
		view.hint.text = "PIP-86 · prova visual das Veredas · sem salvar campanha"
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(str(frame.file)+"-1280x720.png"))
		if str(frame.file).begins_with("rampa-"):
			view.hide_characters()
			for i in 2: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(str(frame.file)+"-sem-personagens-1280x720.png"))
			view.player_root.show()
			view.follower_root.show()
	view.free()
	print("Veredas: ",frames.size()," capturas nativas 1280x720; etapa ",stage,". Sem suite de testes.")
	quit()
