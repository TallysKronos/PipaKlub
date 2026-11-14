extends SceneTree
## Run with the graphical editor binary using --path godot --script res://tests/exploration_performance.gd.
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Performance probe requires a graphics renderer.")
		quit(2)
		return
	var front := Front.new()
	var directory := "user://exploration-performance-" + State.new_id()
	front.session._store = Store.new(directory)
	front.preferences.storage_path = directory.path_join("settings.cfg")
	root.add_child(front)
	var created := front.session.start("slot-1")
	var scene := "park-trail"
	var checkpoint := Checkpoint.make(scene, Checkpoint.spawn(scene), Checkpoint.SPACE)
	if created.status != "ok" or front.session.checkpoint(checkpoint, created.data.player).status != "ok":
		front.free()
		quit(1)
		return
	var runs: Array[Dictionary] = []
	for pass_index in 2:
		if front.session.resume_slot("slot-1").status != "ok":
			front.free()
			quit(1)
			return
		var started := Time.get_ticks_usec()
		front._show_saved()
		var deadline := Time.get_ticks_msec() + 15000
		while (not is_instance_valid(front.park) or is_instance_valid(front.scene_loading)) and Time.get_ticks_msec() < deadline:
			await process_frame
		if not is_instance_valid(front.park) or is_instance_valid(front.scene_loading):
			printerr("Exploration did not become ready.")
			front.free()
			quit(1)
			return
		var load_ms := float(Time.get_ticks_usec() - started) / 1000.0
		var frames: Array[float] = []
		var previous := Time.get_ticks_usec()
		for sample in 240:
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			frames.append(float(now - previous) / 1000.0)
			previous = now
		frames.sort()
		runs.append({"pass":pass_index+1,"load_ms":load_ms,"median_ms":frames[120],"p95_ms":frames[227],"max_ms":frames.back(),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
		front._title()
		await process_frame
	print("EXPLORATION PERFORMANCE ", JSON.stringify({"scene":scene,"window":[root.size.x,root.size.y],"gpu":RenderingServer.get_video_adapter_name(),"runs":runs}))
	var released := await preload("res://tests/audio_teardown.gd").free_view(self,front)
	quit(0 if released else 1)
