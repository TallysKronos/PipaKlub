extends RefCounted
## Explicit isolated package check. The host runner must supply a disposable profile.
const Store = preload("res://scripts/campaign/save_store.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL package journey: ", label)
	return ok

func run(tree: SceneTree) -> int:
	if not check(OS.get_environment("SOULMONSTERS_PACKAGE_PROBE") == "1", "explicit probe opt-in"):
		return 1
	check(not OS.has_feature("editor"), "runs in the release template, not the editor")
	var args := OS.get_cmdline_user_args()
	var mode: String = args[1] if args.size() == 2 else ""
	if not check(mode in ["create", "resume"], "known probe mode"):
		return 1
	var front = load("res://scenes/campaign.tscn").instantiate()
	front.session._store = Store.new("user://package-probe")
	front.preferences.storage_path = "user://package-probe-settings.cfg"
	tree.root.add_child(front)
	for frame in 4: await tree.process_frame
	check(front.last_scene_key == "title", "actual main scene opens the title")
	check(front.sound.is_inside_tree(), "audio director is part of the application")
	if mode == "create":
		check(front.session.inspect_slot("slot-1").status == "missing", "fresh isolated profile")
		if check(front.session.start("slot-1").status == "ok", "create a real campaign slot"):
			var saved: Dictionary = front.session.snapshot()
			saved.player.name = "Kael Pacote"
			saved.player.coins = 17
			check(front.session.checkpoint(saved.checkpoint, saved.player).status == "ok", "commit through game save API")
	else:
		check(front.session.resume_slot("slot-1").status == "ok", "resume in a separate process/location")
	var snapshot: Dictionary = front.session.snapshot()
	check(snapshot.get("player", {}).get("name") == "Kael Pacote", "player name survives")
	check(snapshot.get("player", {}).get("coins") == 17, "inventory state survives")
	check(snapshot.get("checkpoint", {}).get("kind") == "opening", "checkpoint survives")
	check(int(snapshot.get("revision", 0)) >= 1, "committed revision survives")
	front._show_saved()
	for frame in 4: await tree.process_frame
	check(front.room != null, "loaded checkpoint builds the opening room")
	var streams: Array[WeakRef] = []
	for child: Node in front.sound.get_children():
		if child is AudioStreamPlayer and child.stream != null: streams.append(weakref(child.stream))
	front.free()
	await tree.process_frame
	await tree.process_frame
	var deadline := Time.get_ticks_msec() + 2000
	var pending := true
	while pending and Time.get_ticks_msec() < deadline:
		pending = false
		for reference: WeakRef in streams:
			if reference.get_ref() != null: pending = true
		if pending: await tree.create_timer(0.02).timeout
	check(not pending, "audio released before probe shutdown")
	print("PACKAGE JOURNEY ", mode, ": ", checks, " checks; ", failures, " failures")
	return 0 if failures == 0 else 1
