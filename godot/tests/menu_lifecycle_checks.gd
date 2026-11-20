extends SceneTree
## Exercises real menu/music/UI teardown; never opens a player campaign.
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL menu lifecycle: ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	preload("res://scripts/campaign/kronasta_story.gd").qa_override = 0
	var baseline_nodes := -1
	var baseline_orphans := -1
	for cycle in 5:
		var front := Front.new()
		front.preferences.storage_path = "user://menu-lifecycle-" + State.new_id() + ".cfg"
		root.add_child(front)
		front.preferences.reduced_motion = true
		for frame in 4: await process_frame
		front._menu()
		front._show_settings()
		front._menu()
		front._title()
		front.sound.play_music("opening")
		front.sound.play_music("menu")
		front.sound.play_music("opening")
		front.sound.play_music("menu")
		for frame in 4: await process_frame
		var music_players := 0
		for child in front.sound.get_children():
			if child.has_meta("soul_music"): music_players += 1
		check(music_players <= 2 and front.sound.music_id == "menu","rapid changes keep only the current and outgoing themes")
		var released := [weakref(front), weakref(front.session), weakref(front.sound)]
		check(is_instance_valid(front.sound.music), "music is active before teardown")
		if is_instance_valid(front.sound.music):
			released.append(weakref(front.sound.music))
			released.append(weakref(front.sound.music.stream))
		front.sound.play_event("ui.confirm")
		check(not front.sound.voices.is_empty(), "UI voice is active before teardown")
		front.sound.observer._damage({"body":true,"critical":true,"cut_line":true,"broke_hull":true})
		check(front.sound.connected_events.has("battle.hull_break") and not front.sound.connected_events.has("battle.hull_hit") and not front.sound.connected_events.has("battle.critical") and not front.sound.connected_events.has("battle.line_snap"), "a decisive impact plays only the break cue")
		for voice: AudioStreamPlayer in front.sound.voices:
			if is_instance_valid(voice) and voice.stream != null:
				released.append(weakref(voice))
				released.append(weakref(voice.stream))
		front.free()
		await process_frame
		await process_frame
		# Playback disposal is asynchronous on the audio mixer, not tied to a
		# fixed number of fast headless frames. Poll weak refs with a deadline.
		var deadline := Time.get_ticks_msec() + 2000
		while Time.get_ticks_msec() < deadline:
			var pending := false
			for reference: WeakRef in released:
				if reference.get_ref() != null: pending = true
			if not pending: break
			await create_timer(0.02).timeout
		for reference: WeakRef in released:
			check(reference.get_ref() == null, "actor/player/stream released in cycle " + str(cycle))
		var node_count := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var orphan_count := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		if cycle == 0:
			baseline_nodes = node_count
			baseline_orphans = orphan_count
		else:
			check(node_count == baseline_nodes, "node count returns to warm baseline")
			check(orphan_count == baseline_orphans, "orphan count does not grow")
	print("MENU LIFECYCLE ", checks, " checks; ", failures, " failures; 5 cycles; node baseline ", baseline_nodes, "; orphan baseline ", baseline_orphans)
	quit(0 if failures == 0 else 1)
