extends SceneTree
## Revisão de arte da área de prova kronasta-coracao-d: câmeras fixas, sem salvar campanha.

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
	view.area_id = OS.get_environment("ELO_AREA") if OS.has_environment("ELO_AREA") else "kronasta-coracao-d"
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
	var frames := [{"file":"area-inteira","point":Vector2(23,24),"zoom":.50},{"file":"altar","point":Vector2(24,17),"zoom":1.0}]
	if view.area_id!="kronasta-coracao-d":
		var focus: Dictionary = view.model.data.events.filter(func(e):return int(e.id)==31002)[0]
		frames = [{"file":"area-inteira","point":Vector2(22,20),"zoom":.47},{"file":"resgate","point":Vector2(focus.u,focus.v),"zoom":1.0}]
	for frame in frames:
		view.player = Vector2(24.5,20.5)
		view.follower = Vector2(24.5,20.5)
		if frame.file=="resgate":
			view.player = frame.point+Vector2(.5,1.5)
			view.player_root.show()
		view._refresh_positions()
		view.camera.zoom = Vector2.ONE*float(frame.zoom)
		view.camera.position = view.model.project(frame.get("look",frame.point))-Vector2(0,40)
		for index in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(str(frame.file)+".png"))
	if OS.get_environment("ELO_SEQUENCIA")=="1":
		var chamber = preload("res://scripts/overworld/elo_chamber.gd")
		root.get_texture().get_image().save_png(output.path_join("01-antes.png"))
		var effect: Node2D = chamber.rupture(view)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("02-ruptura.png"))
		var creature: AnimatedSprite2D = chamber.awakening_sprite(view)
		if creature != null:
			creature.frame = 6
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("02b-rugido.png"))
		chamber.collapse(view)
		effect.queue_free()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("03-depois.png"))
	view.free()
	print("kronasta-coracao-d: ",frames.size()," capturas")
	quit()







