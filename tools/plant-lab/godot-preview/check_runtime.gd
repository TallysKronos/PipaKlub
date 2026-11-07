extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.load_layout("res://layout.json")
	assert(scene.layout.customAssets.size()==1)
	var custom: Sprite2D=null
	for node in scene.world.get_children():
		if node.get_meta("asset","")=="custom-native-check":
			custom=node
	assert(custom!=null)
	assert(custom.texture.get_width()==16)
	assert(custom.get_meta("collision").shape=="rect")
	scene.test_seconds=1.0
	var point: Vector2=scene.event_position(scene.layout.events[0])
	assert(absf(point.x-124.0)<0.01)
	var bridge=load("res://area_bridge.gd").new()
	root.add_child(bridge)
	await process_frame
	assert(bridge.get_area_events().size()==1)
	bridge.set_player_position(Vector2(120,350))
	assert(bridge.get_player_position()==Vector2(120,350))
	print("PASS: native custom atlas/pivot/collision, NPC patrol and bridge runtime.")
	scene.queue_free()
	bridge.queue_free()
	await process_frame
	quit()
