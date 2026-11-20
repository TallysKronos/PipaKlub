extends SceneTree
## Isolated art review. No map edits, saves, rewards or campaign unlocks.
class ReviewView extends "res://scripts/overworld/view.gd":
	var review_events: Array[Dictionary] = []
	func _build_events() -> void:
		var origin := Vector2(float(model.data.spawn.u)+.5, float(model.data.spawn.v)+.5)
		var selected: Array[Vector2] = []
		var names := ["Vasken", "Rivka", "Odrik", "Teyra", "Bruno Solda"]
		var ids := ["vasken", "rivka", "odrik", "teyra", "bruno-solda"]
		# Select connected, level, non-ramp cells near the actual entrance.
		for radius in range(3, 24):
			for dv in range(-radius, radius + 1):
				for du in range(-radius, radius + 1):
					if selected.size() == names.size(): break
					var cell := Vector2i(origin.floor()) + Vector2i(du, dv)
					var point := Vector2(cell) + Vector2(.5, .5)
					if not model.walkable(cell) or model.cell_at(cell).get("ramp") != null: continue
					var clear := true
					for y in range(-1, 2):
						for x in range(-1, 2):
							var neighbor := cell+Vector2i(x,y)
							if not model.walkable(neighbor) or model.cell_at(neighbor).get("level",0) != model.cell_at(cell).get("level",0): clear=false
					if not clear: continue
					if point.distance_to(origin) < 2.5: continue
					if selected.any(func(p: Vector2): return p.distance_to(point) < 2.5): continue
					if selected.any(func(p: Vector2): return model.project(p).distance_to(model.project(point)) < 125): continue
					if model.path_to(origin, point).is_empty(): continue
					selected.append(point)
		if selected.size() != names.size(): push_error("Not enough connected review cells"); return
		for i in names.size():
			var point: Vector2 = selected[i]
			var event := {"id": 99000+i, "type": "npc", "name": names[i], "u": int(point.x), "v": int(point.y), "props": {"storySpritePath": "res://assets/npc-ds/vila-operaria-v1/"+ids[i]+".png"}}
			interaction_events.append(event)
			review_events.append(event)
		super()

func _initialize() -> void: call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 720)
	var output := ProjectSettings.globalize_path("res://../documentation/qa/vila-operaria-npcs")
	DirAccess.make_dir_recursive_absolute(output)
	var view := ReviewView.new()
	view.area_id = "kronasta-industrial-a"
	view.art_preview = true
	root.add_child(view)
	await process_frame
	view.set_physics_process(false)
	view.interface.hide()
	view.player_root.hide()
	view.follower_root.hide()
	view.camera.position_smoothing_enabled = false
	if view.review_events.size() != 5: view.free(); quit(1); return
	var report: Array[Dictionary] = []
	var center := Vector2.ZERO
	for event in view.review_events:
		var point := Vector2(event.u+.5, event.v+.5)
		center += view.model.project(point)
		var route: PackedVector2Array = view.model.path_to(view.player, point)
		if route.is_empty(): push_error("Unreachable review NPC"); view.free(); quit(1); return
		var texture: Texture2D = load(event.props.storySpritePath)
		if texture == null or texture.get_size() != Vector2(64, 64): view.free(); quit(1); return
		report.append({"name":event.name,"point":[point.x,point.y],"route_points":route.size(),"source_height":texture.get_height(),"render_height":84,"static":true})
	center /= 5.0
	view.camera.zoom = Vector2.ONE*1.3
	view.camera.position = center-Vector2(0,50)
	await shot(output.path_join("00-grupo.png"))
	for event in view.review_events:
		for actor in view.npc_nodes:
			actor.root.visible = int(actor.root.get_meta("event",{}).get("id",0)) == int(event.id)
		view.camera.zoom = Vector2.ONE*2.0
		view.camera.position = view.model.project(Vector2(event.u+.5,event.v+.5))-Vector2(0,45)
		await shot(output.path_join(event.name.to_lower().replace(" ","-")+".png"))
	var file := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	view.free()
	print("PASS: 5 real-renderer NPCs; 64x64 cells, 84px world frame, connected review cells; 6 captures; no saves/rewards/map edits")
	quit()

func shot(path: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	if error != OK: push_error("Capture failed: "+path); quit(1)
