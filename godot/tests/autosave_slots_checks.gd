extends SceneTree
const Session = preload("res://scripts/campaign/session.gd")
const State = preload("res://scripts/campaign/state.gd")
const Preferences = preload("res://scripts/campaign/preferences.gd")
const Front = preload("res://scripts/campaign/front_end.gd")
var checks := 0
var failures := 0
var starts := 0
var finishes: Array[String] = []
class FaultStore extends "res://scripts/campaign/save_store.gd":
	var deny := false
	func _write_checked(path: String, data: Dictionary) -> Error:
		if deny: return ERR_FILE_CANT_WRITE
		return super(path, data)
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL autosave slots: ", description)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for frame in 8: await process_frame
func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var found := find_button(child, prefix)
		if found != null: return found
	return null
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := "res://tmp/autosave-slots"
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
func run() -> void:
	var directory := "user://autosave-slots-" + State.new_id()
	var store := FaultStore.new(directory)
	var session := Session.new()
	session._store = store; session.separate_autosave = true
	root.add_child(session)
	session.saving_started.connect(func(): starts += 1)
	session.saving_finished.connect(func(status: String): finishes.append(status))
	var prefs := Preferences.new()
	check(prefs.autosave, "default enabled")
	check(session.start("slot-0").status == "invalid_slot", "cannot start in reserved slot")
	check(session.start("slot-1").status == "ok", "create manual baseline")
	check(starts == 1 and finishes == ["ok"], "new journey reports initial write")
	starts = 0; finishes.clear()
	var manual_hash := FileAccess.get_sha256(directory.path_join("slot-1.json"))
	var saved: Dictionary = session.snapshot()
	saved.player.coins = 7
	check(session.checkpoint(saved.checkpoint, saved.player).status == "ok", "automatic write")
	check(store.load_slot("slot-0").data.player.coins == 7, "automatic state in slot zero")
	check(FileAccess.get_sha256(directory.path_join("slot-1.json")) == manual_hash, "manual file untouched")
	check(starts == 1 and finishes == ["ok"], "write signals paired")
	check(session.snapshot().slotId == "slot-0", "session follows autosave revision")
	var auto_hash := FileAccess.get_sha256(directory.path_join("slot-0.json"))
	session.autosave_enabled = false
	saved = session.snapshot(); saved.player.coins = 11
	check(session.commit_operation("test-reward", saved.checkpoint, saved.player).status == "ok", "disabled keeps reward in memory")
	check(session.commit_operation("test-reward", saved.checkpoint, saved.player).status == "already_applied", "disabled reward remains idempotent")
	check(session.snapshot().player.coins == 11 and session.has_unpersisted_changes, "memory dirty")
	check(FileAccess.get_sha256(directory.path_join("slot-0.json")) == auto_hash, "disabled does not write autosave")
	check(starts == 1, "disabled emits no saving signal")
	check(session.save_manual("slot-2", -1).status == "ok", "explicit save to empty manual")
	check(not session.has_unpersisted_changes, "manual persists memory")
	check(store.load_slot("slot-2").data.player.coins == 11, "manual carries latest reward")
	check(FileAccess.get_sha256(directory.path_join("slot-0.json")) == auto_hash, "manual does not change autosave")
	check(session.save_manual("slot-2", -1).status == "stale", "stale overwrite rejected")
	check(session.save_manual("slot-0", 1).status == "invalid_slot", "manual cannot target zero")
	check(session.save_manual("slot-2", 1).status == "ok", "confirmed revision overwrites manual")
	var restart := Session.new(); restart._store = store; restart.separate_autosave = true
	root.add_child(restart)
	check(restart.resume_slot("slot-2").status == "ok", "restart from manual")
	check(restart.snapshot().player.coins == 11 and "test-reward" in restart.snapshot().player.completedOperations, "reward and receipt survive restart")
	check(restart.resume_slot("slot-0").status == "ok" and restart.snapshot().player.coins == 7, "autosave independently resumable")
	session.autosave_enabled = true
	saved = session.snapshot(); saved.player.coins = 15
	store.deny = true
	var before := session.snapshot()
	check(session.checkpoint(saved.checkpoint, saved.player).status == "io_error", "write error reported")
	check(session.snapshot() == before, "failed autosave does not publish mutation")
	check(FileAccess.get_sha256(directory.path_join("slot-0.json")) == auto_hash, "failed write preserves file")
	check(finishes.back() == "io_error", "indicator receives error")
	store.deny = false
	check(session.checkpoint(saved.checkpoint, saved.player).status == "ok", "retry after error")
	check(store.load_slot("slot-0").data.player.coins == 15, "re-enabled autosave persists latest state")
	check(FileAccess.get_sha256(directory.path_join("slot-1.json")) == manual_hash, "baseline still untouched")
	var future: Dictionary = State.fresh("slot-3")
	future.schemaVersion = State.SCHEMA_VERSION + 1
	var future_file := FileAccess.open(directory.path_join("slot-3.json"), FileAccess.WRITE)
	future_file.store_string(JSON.stringify(future)); future_file.close()
	var future_hash := FileAccess.get_sha256(directory.path_join("slot-3.json"))
	check(session.save_manual("slot-3", -1).status == "future", "manual copy refuses newer-format target")
	check(FileAccess.get_sha256(directory.path_join("slot-3.json")) == future_hash, "newer-format target preserved")
	var competing: Dictionary = store.load_slot("slot-0").data
	check(store.save_slot(competing).status == "ok", "external revision fixture")
	check(session.checkpoint(saved.checkpoint, saved.player).status == "stale", "concurrent revision cannot be overwritten")
	prefs.autosave = false
	check(prefs.save_settings(directory.path_join("settings.cfg")) == OK, "persist preference")
	var loaded := Preferences.new(); loaded.load_settings(directory.path_join("settings.cfg"))
	check(not loaded.autosave, "preference survives restart")
	session.free(); restart.free()
	var front := Front.new(); front.session._store = store
	front.preferences.storage_path = directory.path_join("settings.cfg")
	root.add_child(front); front.preferences.reduced_motion = true
	front.settings_tab = "Jornada"; front._show_settings(); await settle()
	check(not front.preferences.autosave and not front.session.autosave_enabled, "frontend applies persisted preference")
	await capture("settings")
	front._show_slots(false); await settle()
	var zero := false
	for child in front.page.get_children():
		if child.get("slot_id") == "slot-0": zero = true
	check(zero, "load list includes autosave")
	await capture("slots")
	front._show_slots(true); await settle()
	zero = false
	for child in front.page.get_children():
		if child.get("slot_id") == "slot-0": zero = true
	check(not zero, "new journey never offers autosave")
	front.session.separate_autosave = true
	check(front.session.resume_slot("slot-2").status == "ok", "frontend manual fixture")
	front._show_manual_slots(); await settle(); await capture("manual")
	check(find_button(front.page, "Espaço 3").disabled, "unreadable manual destination disabled")
	var old_manual := FileAccess.get_sha256(directory.path_join("slot-1.json"))
	find_button(front.page, "Espaço 1").pressed.emit(); await settle()
	var dialogs := get_nodes_in_group("manga_dialogue")
	check(dialogs.size() == 1, "manual overwrite asks confirmation")
	check(root.gui_get_focus_owner() == dialogs[0].decline, "overwrite initially focuses cancel")
	dialogs[0].canceled.emit(); await settle()
	check(FileAccess.get_sha256(directory.path_join("slot-1.json")) == old_manual, "cancel does not write")
	find_button(front.page, "Espaço 1").pressed.emit(); await settle()
	dialogs = get_nodes_in_group("manga_dialogue")
	dialogs[0].confirmed.emit(); await settle()
	check(store.load_slot("slot-1").data.player.coins == 11, "UI confirmation writes selected slot")
	for dialog in get_nodes_in_group("manga_dialogue"): dialog.confirmed.emit()
	await settle()
	saved = front.session.snapshot(); saved.player.coins = 19
	front.session.checkpoint(saved.checkpoint, saved.player)
	front._return_to_menu(); await settle()
	dialogs = get_nodes_in_group("manga_dialogue")
	check(dialogs.size() == 1 and dialogs[0].dialog_text.contains("avanços"), "disabled autosave warns before exit")
	dialogs[0].canceled.emit(); await settle()
	check(front.session.snapshot().player.coins == 19, "cancel exit preserves live progress")
	front._return_to_menu(); await settle()
	dialogs = get_nodes_in_group("manga_dialogue")
	dialogs[0].confirmed.emit(); await settle()
	check(front.session.snapshot().is_empty() and front.last_scene_key == "menu", "confirmed discard closes live session")
	front.session.resume_slot("slot-2")
	check(front.session.snapshot().player.coins == 11, "discarded progress was not written")
	front._show_manual_slots(); await settle()
	front.save_status.started()
	check(front.save_status.label.visible and "Gravando" in front.save_status.label.text, "busy status")
	front.save_status.finished("io_error")
	check("Falha" in front.save_status.label.text, "failed status never claims saved")
	await capture("error")
	front.save_status.finished("ok")
	check("salva" in front.save_status.label.text, "success status")
	await capture("saved")
	await create_timer(2.6).timeout
	check(not front.save_status.label.visible, "status clears")
	var streams: Array[WeakRef] = []
	for child in front.sound.get_children():
		if child is AudioStreamPlayer and child.stream != null: streams.append(weakref(child.stream))
	front.free(); await settle()
	var deadline := Time.get_ticks_msec() + 2000
	var pending := true
	while pending and Time.get_ticks_msec() < deadline:
		pending = false
		for ref: WeakRef in streams:
			if ref.get_ref() != null: pending = true
		if pending: await create_timer(.02).timeout
	check(not pending, "audio teardown")
	print("AUTOSAVE SLOTS ", checks, " checks; ", failures, " failures")
	quit(0 if failures == 0 else 1)
