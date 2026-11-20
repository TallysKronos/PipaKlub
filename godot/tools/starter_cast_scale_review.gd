extends SceneTree

const View = preload("res://scripts/campaign/neighborhood_view.gd")
const State = preload("res://scripts/campaign/state.gd")
const Npc = preload("res://scripts/npc_pixel_sprite.gd")
const OUTPUT := "res://../documentation/qa/starter-cast-scale"
var failures := 0
var measurements: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var view := View.new()
	view.saved_player = State.fresh("slot-1").player
	view.saved_player.journey = {"phase": "complete", "lesson": 5}
	view.checkpoint_position = Vector2(10.5, 20.5)
	root.add_child(view)
	view.set_process(false)
	view.set_physics_process(false)
	view.avatar.set_process(false)
	view.avatar.facing = "se"
	var idle: Image = view.avatar.resting.get_image()
	var bounds := idle.get_region(Rect2i(0, 7 * 96, 64, 96)).get_used_rect()
	var kael_height: float = bounds.size.y * view.avatar.scale.y
	for person: Dictionary in view.world.people:
		var art: MeshInstance2D = person.art
		var image_bounds := art.texture.get_image().get_used_rect()
		var mesh_bounds := art.mesh.get_aabb()
		var visible_height: float = mesh_bounds.size.y * image_bounds.size.y / art.texture.get_height()
		var id: String = "professor" if person.id == "assis" else person.id
		var expected: float = Npc.RELATIVE_HEIGHTS.get(id, 1.0)
		var ratio := visible_height / kael_height
		var ok := absf(ratio - expected) <= .015
		if not ok:
			failures += 1
			printerr("Wrong scale for ", person.id, ": ", ratio, " expected ", expected)
		measurements.append({"npc": person.id, "kaelHeight": kael_height, "npcHeight": visible_height, "ratio": ratio, "expected": expected})
		view.cell = person.p + Vector2(-.7, .4)
		view.surface = view.world.cell_id(floori(view.cell.x), floori(view.cell.y))
		view.elevation = view.world.support(view.cell)
		view.follower = view.cell + Vector2(-.6, .5)
		view.follower_surface = view.world.cell_id(floori(view.follower.x), floori(view.follower.y))
		view.follower_height = view.world.support(view.follower)
		view._refresh_visuals()
		view._update_hint()
		view.camera.position_smoothing_enabled = false
		view.camera.position = view.player_root.position - Vector2(0, 35)
		view.camera.reset_smoothing()
		if DisplayServer.get_name() != "headless":
			for i in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT.path_join(str(person.id) + ".png"))) != OK:
				failures += 1
	FileAccess.open(OUTPUT.path_join("measurements.json"), FileAccess.WRITE).store_string(JSON.stringify(measurements, "  "))
	print("Starter cast scale: ", measurements.size(), " NPCs; ", failures, " failures")
	view.free()
	quit(int(failures > 0))
