extends SceneTree
## Rendered blockout evidence; no campaign state, save access or live rewards.
var View
const AREAS = ["jardim-das-pipas", "clareira-do-papel", "veredas-do-encanamento"]
var view: Node2D
var output: String
var records: Array = []

func _initialize() -> void:
	call_deferred("capture")

func settled() -> void:
	for tick in 5: await process_frame
	await RenderingServer.frame_post_draw

func save_image(file: String, scope: String) -> void:
	await settled()
	root.get_texture().get_image().save_png(output.path_join(file + ".png"))
	records.append({"file":file + ".png", "area":view.area_id, "scope":scope, "size":[root.size.x,root.size.y], "zoom":view.camera.zoom.x})

func geometry_only(node: Node) -> void:
	if node is Sprite2D: node.hide()
	if node is Polygon2D:
		node.material = null
		node.texture = null
		if str(node.name).begins_with("AguaRebaixada"): node.color = Color("3c8194")
	for child in node.get_children(): geometry_only(child)

func capture() -> void:
	View = load("res://scripts/overworld/view.gd")
	if DisplayServer.get_name() == "headless":
		printerr("Requer renderer para a conferência visual.")
		quit(1)
		return
	output = ProjectSettings.globalize_path("res://../documentation/overworld/material-recovery/after")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="): output = argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	RenderingServer.set_default_clear_color(Color("141e29"))
	view = View.new()
	root.add_child(view)
	await settled()
	view.set_physics_process(false)
	for id in AREAS:
		for art in [false, true]:
			view.art_preview = art
			view.load_area(id)
			view.interface.hide()
			view.hide_characters()
			var w := int(view.model.data.w)
			var h := int(view.model.data.h)
			root.size = Vector2i((w+h)*32+128,(w+h)*16+384)
			view.camera.position_smoothing_enabled = false
			view.camera.zoom = Vector2.ONE
			view.camera.position = Vector2((w-h)*16,(w+h)*8-140)
			await save_image(id + ("-kit-estudo-1x" if art else "-geometria-1x"), "whole area; source cells and current kit; not final paint")
		root.size = Vector2i(1280,720)
		view.camera.zoom = Vector2.ONE
		var focal := Vector2(29.5,35.5) if id == AREAS[0] else Vector2(32.5,30.5) if id == AREAS[1] else Vector2(49.5,17.5)
		view.player = Vector2(28.5,36.5) if id == AREAS[0] else Vector2(32.5,34.5) if id == AREAS[1] else Vector2(49.5,24.5)
		view.follower = view.player + Vector2(1,0)
		view._refresh_positions()
		view.player_root.show()
		view.follower_root.show()
		for actor in view.npc_nodes:
			# The fixture doesn't show the legacy Nina event reserved for later visits.
			if id == AREAS[2] and actor.point == Vector2(30.5,40.5): continue
			actor.root.show()
		view.camera.position = view.model.project(focal)-Vector2(0,60)
		await save_image(id + "-escala-jogo", "fixed game-scale fixture, player/NPCs; no campaign integration claim")
		view.hide_characters()
		# Inspect joints without trees, furniture or grass hiding the opening.
		var hidden_props: Array[CanvasItem] = []
		for actor in view.actors.get_children():
			if actor.get_script() == preload("res://scripts/overworld/prop.gd") and actor.visible:
				hidden_props.append(actor)
				actor.hide()
		root.size = Vector2i(960,640)
		view.camera.zoom = Vector2(3,3)
		var ramp := Vector2(15.5,23.5) if id == AREAS[0] else Vector2(16.5,25.5) if id == AREAS[1] else Vector2(48.5,29.5)
		view.camera.position = view.model.project(ramp)
		await save_image(id + "-rampa-3x", "ramp joints; no characters")
		for actor in hidden_props: actor.show()
		if id == AREAS[1]:
			view.camera.position = view.model.project(Vector2(32.5,30.5))
			await save_image(id + "-ponte-3x", "bridge banks and deck; current preview art")
			root.size = Vector2i(1280,720)
			view.camera.zoom = Vector2(1.5,1.5)
			view.player = Vector2(32.5,30.5)
			view.follower = Vector2(32.5,31.5)
			view._refresh_positions()
			view.player_root.show()
			view.follower_root.show()
			view.camera.position = view.model.project(Vector2(31.5,30.5))-Vector2(0,35)
			await save_image(id + "-riacho-manga", "native bridge at 1.5x, player on deck and recessed stream; review fixture")
			view.hide_characters()
			for second in [0,8,32]:
				view.parque_surfaces.water_material.set_shader_parameter("preview_time",float(second))
				await save_image(id+"-agua-t"+str(second),"existing water animation; fixed time; no characters")
			geometry_only(view.actors)
			await save_image(id+"-margens-geometria","same measured shore and recessed bed, no textures, sprites or effects")
	var report := FileAccess.open(output.path_join("capturas.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"captures":records,"scope":"regional blockout, current kit, no real campaign data"},"  "))
	print("PARQUE ABC: ", records.size(), " capturas reais")
	quit(0)
