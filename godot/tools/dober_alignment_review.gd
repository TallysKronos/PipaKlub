extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var port := SubViewport.new()
	port.size = Vector2i(512,512)
	port.transparent_bg = true
	port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(port)
	var actor = load("res://scripts/avatar.gd").new()
	port.add_child(actor)
	actor.scale = Vector2.ONE
	actor.position = Vector2(256,430)
	actor.set_process(false)
	actor.set_mounted(true)
	var rig = actor.mount_rig
	rig.set_process(false)
	var result := {}; var failures := 0
	for direction in actor.DIRECTIONS:
		actor.moving = false
		actor.facing = direction
		rig.set_facing(direction)
		await RenderingServer.frame_post_draw
		var still: Rect2i = port.get_texture().get_image().get_used_rect()
		var data := {"still":[still.position.x,still.position.y,still.size.x,still.size.y]}
		for state in ["walk","run"]:
			actor.moving = true
			actor.running = state == "run"
			rig.set_facing(direction)
			var clip: Dictionary = rig.animations[state+"-"+direction]
			var heights := []
			var bottoms := []
			for frame in int(clip.frames):
				rig.animation_clock = (frame+.25)*clip.durationMs/1000.0
				rig._update_animation()
				await RenderingServer.frame_post_draw
				var bounds: Rect2i = port.get_texture().get_image().get_used_rect()
				heights.append(bounds.size.y)
				bottoms.append(bounds.end.y)
			data[state] = {"heights":heights,"bottoms":bottoms}
			var mean_height := 0.0
			var mean_bottom := 0.0
			for i in heights.size():
				mean_height += heights[i] / float(heights.size())
				mean_bottom += bottoms[i] / float(bottoms.size())
			if absf(mean_height-still.size.y)>1.5 or absf(mean_bottom-still.end.y)>1.5:
				failures += 1
				printerr("ALIGNMENT " + direction + state + str([mean_height,still.size.y,mean_bottom,still.end.y]))
		result[direction] = data
	FileAccess.open("res://../documentation/qa/dober-city-playtest/scale.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("MOUNT ALIGNMENT: 16 clips; ", failures, " failures")
	quit(int(failures > 0))
