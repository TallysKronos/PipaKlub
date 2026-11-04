extends SceneTree
## Repeatable desktop samples; not a minimum-hardware certification.
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const Model = preload("res://scripts/campaign/morro_model.gd")
func _initialize() -> void:
	call_deferred("run_profile")
func run_profile() -> void:
	root.size = Vector2i(1280, 720)
	Engine.max_fps = 60
	var front := Front.new()
	root.add_child(front)
	await process_frame
	var results: Array = []
	for scene in ["morro", "morro-area-2", "morro-area-3", "morro-area-4", "morro-area-5", "battle"]:
		var saved := State.fresh("slot-1")
		saved.player.partners = [{"id": "profile", "modelId": "basica", "xp": 0}]
		saved.player.equippedPartnerId = "profile"
		saved.player.journey = {"phase": "complete", "lesson": 5}
		if scene == "battle":
			var model := Model.new(saved.player.partners[0], "morro-3")
			saved.checkpoint = {"kind": "encounter"}
			saved.player.encounter = {"kind": "morro", "state": model.snapshot()}
		else: saved.checkpoint = {"kind": "world", "scene": scene, "position": Morro.maps()[scene].spawn}
		front.session._snapshot = saved
		var start := Time.get_ticks_usec()
		front._show_saved()
		var construction_ms := (Time.get_ticks_usec() - start) / 1000.0
		if scene != "battle":
			var place: Dictionary = front.park.data.places.filter(func(p): return p.has("stage"))[0]
			front.park.walk_to(Vector2(place.point[0], place.point[1]))
		var samples: Array[float] = []
		var cpu: Array[float] = []
		var physics: Array[float] = []
		var previous := Time.get_ticks_usec()
		for index in 210:
			await process_frame
			var now := Time.get_ticks_usec()
			if index >= 60:
				samples.append((now - previous) / 1000.0)
				cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
				physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
			previous = now
		samples.sort()
		cpu.sort()
		physics.sort()
		var result := {"scene": scene, "samples": samples.size(), "constructionMs": construction_ms, "frameMedianMs": samples[75], "frameP95Ms": samples[142], "frameMaxMs": samples.back(), "processP95Ms": cpu[142], "physicsP95Ms": physics[142]}
		results.append(result)
		print(JSON.stringify(result))
	front.free()
	var file := FileAccess.open("res://../tmp/morro-profile.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_video_adapter_name(), "viewport": [1280, 720], "fpsCap": 60, "results": results}, "\t"))
	file.close()
	quit()
