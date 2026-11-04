extends SceneTree
## Native visual review only: no campaign save, rewards, map edits or battle events.
const NAMES := ["caio", "seyran", "oruvo", "kessai", "veldren"]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var view = load("res://scripts/overworld/view.gd").new()
	view.area_id = "kronasta-palafitas-a"
	view.art_preview = true
	root.add_child(view)
	view.set_physics_process(false)
	view.interface.hide()
	view.follower_root.hide()
	var origin: Vector2 = view.player
	var spot := origin
	for offset: Vector2 in [Vector2(2,0),Vector2(-2,0),Vector2(0,-2),Vector2(0,2)]:
		if view.model.point_walkable(origin+offset):
			spot = origin+offset
			break
	assert(spot != origin, "Need a walkable review position beside Kael")
	var sprite := Sprite2D.new()
	var actor := Node2D.new()
	view.actors.add_child(actor)
	actor.add_child(sprite)
	sprite.offset = Vector2(0,-56)
	sprite.scale = Vector2.ONE*84.0/112.0 # Same 84px static-NPC contract as view.gd.
	view._place_actor(actor,sprite,spot,84)
	view.camera.position_smoothing_enabled = false
	view.camera.zoom = Vector2.ONE*1.4
	view.camera.position = (view.model.project(origin)+view.model.project(spot))*.5
	view.camera.reset_smoothing()
	var output := "res://../documentation/qa/palafitas-art-v1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for id: String in NAMES:
		var texture: Texture2D = load("res://assets/npc-ds/palafitas-v1/"+id+".png")
		assert(texture != null and texture.get_height() == 112)
		sprite.texture = texture
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(output+"/"+id+"-native.png")
		assert(error == OK)
	print("PALAFITAS ART: 5 native captures; same walkable point beside Kael; no campaign integration")
	view.free()
	quit()
