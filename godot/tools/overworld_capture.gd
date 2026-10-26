extends SceneTree
## Rendered evidence only; campaign fixtures use isolated stores and no real saves.
const View = preload("res://scripts/overworld/view.gd")
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
var sizes := [Vector2i(1270,710),Vector2i(1280,720),Vector2i(1024,768),Vector2i(1280,800),Vector2i(1600,900),Vector2i(960,540),Vector2i(1920,1080)]
var records: Array = []
var findings: Array = []
var output := ""
var concepts := false

func _initialize() -> void:
	call_deferred("run")

func wait_frame() -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw

func save_image(path: String) -> void:
	root.get_texture().get_image().save_png(path)

func measure(node: Node, id: String) -> void:
	if node is Label or node is Button:
		var control: Control = node
		if control.is_visible_in_tree() and control.size.x > 0:
			var r := control.get_global_rect()
			var visible := r.intersection(root.get_visible_rect())
			if visible.size.x * visible.size.y < r.size.x*r.size.y*.98: findings.append({"id":id,"text":node.text,"kind":"clipped"})
	for child in node.get_children(): measure(child,id)

func run() -> void:
	if DisplayServer.get_name()=="headless":printerr("ERROR: capturas exigem renderer, não headless");quit(1);return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	concepts = "--concepts" in OS.get_cmdline_user_args()
	output = ProjectSettings.globalize_path("res://../" + ("art/overworld/conceitos" if concepts else "documentation/overworld/captures"))
	DirAccess.make_dir_recursive_absolute(output)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/index.json"))
	var view := View.new()
	view.art_preview = true
	root.add_child(view)
	await wait_frame()
	view.set_physics_process(false)
	if concepts:
		root.content_scale_size = Vector2i.ZERO
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		RenderingServer.set_default_clear_color(Color("F5E9CB"))
		for area in index.areas:
			if area.biome != "morro":continue
			view.art_preview = true
			view.load_area(area.id)
			view.interface.hide()
			view.hide_characters()
			var w := int(view.model.data.w)
			var h := int(view.model.data.h)
			root.size = Vector2i((w+h)*32+128,(w+h)*16+448)
			view.camera.position_smoothing_enabled = false
			view.camera.zoom = Vector2.ONE
			view.camera.position = Vector2((w-h)*16,(w+h)*8-160)
			await wait_frame()
			save_image(output.path_join(area.id+"-conceito.png"))
			# Same exact camera, grid and dimensions for the exported reference.
			view.art_preview = false
			view.load_area(area.id)
			view.interface.hide();view.hide_characters()
			view.camera.position_smoothing_enabled = false
			view.camera.zoom = Vector2.ONE
			view.camera.position = Vector2((w-h)*16,(w+h)*8-160)
			await wait_frame()
			save_image(output.path_join(area.id+"-referencia.png"))
			records.append({"id":area.id,"size":[root.size.x,root.size.y],"source":view.model.data.source,"terrainDisplacementPx":0,"method":"same compiled cells and camera in reference and kit assembly"})
	else:
		for requested in sizes:
			root.size = requested
			await wait_frame()
			for area in index.areas:
				if area.id == "veredas-piloto":continue
				for art in [false,true]:
					view.art_preview = art
					view.load_area(area.id)
					view.set_physics_process(false)
					await wait_frame()
					var mode := "art-study" if art else "draft"
					var id := "%s-%s-%dx%d" % [area.id,mode,requested.x,requested.y]
					measure(view.interface,id)
					save_image(output.path_join(id+".png"))
					records.append({"id":id,"area":area.id,"mode":mode,"size":[requested.x,requested.y]})
		# Before screenshots of unchanged campaign; these are visual fixtures.
		view.hide();view.interface.hide()
		var front := Front.new()
		front.session._store = Store.new("user://overworld-before-"+State.new_id())
		front.preferences.storage_path = "user://overworld-before-settings-"+State.new_id()+".cfg"
		root.add_child(front)
		await wait_frame()
		var fixture_names := {"quintal":"street","park-trail":"trail","park-clearing":"clearing","park-veredas":"park"}
		for requested in sizes:
			root.size = requested
			for area in index.areas:
				if area.id == "veredas-piloto":continue
				Fixtures.show(front,fixture_names.get(area.scene,area.scene))
				await wait_frame()
				var id := "%s-before-%dx%d" % [area.id,requested.x,requested.y]
				save_image(output.path_join(id+".png"))
				records.append({"id":id,"area":area.id,"mode":"before-fixture","size":[requested.x,requested.y]})
		front.queue_free()
	view.queue_free()
	var f := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"captures":records,"findings":findings,"scope":"visual fixtures; new review maps do not replace campaign"},"  "))
	f.close()
	print("CAPTURES ",records.size(),"; findings ",findings.size())
	quit(0 if findings.is_empty() else 1)
