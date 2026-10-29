extends SceneTree
## Review captures only. No campaign state, save access or rewards.
const View = preload("res://scripts/overworld/view.gd")
var view: Node2D
var output: String
var records: Array = []

func _initialize() -> void:
	call_deferred("capture")

func settled() -> void:
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw

func save_frame(name: String) -> void:
	await settled()
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	records.append({"file": name + ".png", "zoom": view.camera.zoom.x, "camera": [view.camera.position.x, view.camera.position.y], "size": [root.size.x, root.size.y]})

func capture() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Captura requer renderer.")
		quit(1)
		return
	output = ProjectSettings.globalize_path("res://../art/overworld/revisao/jardim-das-pipas")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(2432, 1552)
	RenderingServer.set_default_clear_color(Color("141e29"))
	view = View.new()
	root.add_child(view)
	await settled()
	view.set_physics_process(false)
	for art in [false, true]:
		view.art_preview = art
		view.load_area("jardim-das-pipas")
		view.interface.hide()
		view.hide_characters()
		view.camera.position_smoothing_enabled = false
		view.camera.zoom = Vector2.ONE
		view.camera.position = Vector2(128, 416)
		await save_frame("godot-kit-existente-1x" if art else "godot-geometria-1x")
		root.size = Vector2i(960, 640)
		view.camera.zoom = Vector2(3, 3)
		for detail in [{"id": "rampa", "point": Vector2(-96, 352)}, {"id": "canto-externo", "point": Vector2(128, 400)}, {"id": "boca-alta", "point": Vector2(-64, 288)}]:
			view.camera.position = detail.point
			await save_frame(("kit-" if art else "geometria-") + detail.id + "-3x")
		root.size = Vector2i(2432, 1552)
	var report := FileAccess.open(output.path_join("capturas-godot.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"area": "jardim-das-pipas", "captures": records, "scope": "planta e kit existente; arte nova e gameplay narrativo não aprovados"}, "  "))
	print("JARDIM: ", records.size(), " capturas reais, sem personagem nas juntas")
	quit(0)
