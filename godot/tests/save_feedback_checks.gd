extends SceneTree
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Slot = preload("res://scripts/campaign/hud_journey_slot.gd")
const Messages = preload("res://scripts/campaign/save_messages.gd")
var checks := 0
var failures := 0

class FaultStore extends "res://scripts/campaign/save_store.gd":
	var deny_read := false
	var deny_write := false
	func load_slot(id: String) -> Dictionary:
		if deny_read and id == "slot-1": return {"status":"io_error"}
		return super(id)
	func _write_checked(path: String, data: Dictionary) -> Error:
		if deny_write: return ERR_FILE_CANT_WRITE
		return super(path, data)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL save feedback: ", label)
func _initialize() -> void: call_deferred("run")
func write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()
func settle() -> void:
	for frame in 8: await process_frame
func tap_key() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ENTER; event.keycode = KEY_ENTER; event.pressed = true
	root.push_input(event, true)
	event = event.duplicate(); event.pressed = false; root.push_input(event, true)
	await settle()
func tap_pad() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A; event.pressed = true
	root.push_input(event, true)
	event = event.duplicate(); event.pressed = false; root.push_input(event, true)
	await settle()
func slots(front: Control) -> Dictionary:
	var found := {}
	for child in front.page.get_children():
		if child.get_script() == Slot: found[child.slot_id] = child
	return found
func notice(front: Control, message: String) -> Control:
	for child in front.get_children():
		if not child.is_queued_for_deletion() and child.get("dialog_text") == message: return child
	return null
func dismiss(front: Control, message: String, pad: bool) -> void:
	for attempt in 12:
		if notice(front, message) == null: return
		if pad: await tap_pad()
		else: await tap_key()
	check(notice(front, message) == null, "notice can be dismissed with active input")
func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await settle()
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://../tmp/save-feedback")
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func run() -> void:
	var directory := "user://save-feedback-" + State.new_id()
	var store := FaultStore.new(directory)
	var saved: Dictionary = store.create_slot("slot-1").data
	for coins in [9, 19]:
		saved.player.coins = coins
		saved = store.save_slot(saved).data
	write(directory.path_join("slot-1.json"), "truncated")
	var future: Dictionary = store.create_slot("slot-2").data
	future.schemaVersion = 999
	write(directory.path_join("slot-2.json"), JSON.stringify(future))
	store.create_slot("slot-3")
	write(directory.path_join("slot-3.json"), "broken")
	write(directory.path_join("slot-3.json.bak"), "also broken")
	var front := Front.new()
	front.session._store = store
	front.preferences.storage_path = directory.path_join("preferences.cfg")
	root.add_child(front)
	front.preferences.reduced_motion = true
	root.size = Vector2i(1280, 720)
	front._show_slots(false)
	await settle()
	var cards := slots(front)
	check(cards.size() == 3, "all slots are shown")
	check(cards["slot-1"].action.text == "Recuperar" and not cards["slot-1"].action.disabled, "backup has explicit recovery action")
	check(cards["slot-1"].state_notice.text == Messages.BACKUP_AVAILABLE, "backup warns about previous progress")
	for pair in [["slot-2", "future"], ["slot-3", "corrupt"]]:
		check(cards[pair[0]].state_notice.text == Messages.error(pair[1]), "specific reason visible: " + pair[1])
		check(cards[pair[0]].action.disabled and cards[pair[0]].erase == null, "unsafe action unavailable: " + pair[1])
	await capture("slots")
	cards["slot-1"].action.grab_focus()
	await tap_key()
	check(front.session.snapshot().player.coins == 9, "keyboard loads backup state")
	check(notice(front, Messages.RECOVERED) != null, "recovery notice is actually visible")
	check(notice(front, Messages.RECOVERED).z_index > front.room.opening_tv.z_index, "system notice renders above opening film")
	check(front.room.story_paused and front.room.opening_tv.cinematic_paused, "recovery pauses the opening film")
	await capture("recovered")
	await dismiss(front, Messages.RECOVERED, false)
	check(notice(front, Messages.RECOVERED) == null, "keyboard dismisses recovery")
	check(not front.room.story_paused and not front.room.opening_tv.cinematic_paused, "opening resumes after acknowledgement")
	var previous: Dictionary = front.session.snapshot()
	var player: Dictionary = previous.player.duplicate(true)
	player.coins += 7
	store.deny_write = true
	front.room.can_walk = true # Exercise the shared notice handler's walk/restore contract.
	check(not front._result(front.session.checkpoint(previous.checkpoint, player)), "failed write is not reported as success")
	await settle()
	check(notice(front, Messages.error("io_error")) != null, "failed write has actionable notice")
	check(not front.room.can_walk, "notice blocks background walking")
	check(front.session.snapshot() == previous, "notice never advances failed progress")
	await capture("write-error")
	await dismiss(front, Messages.error("io_error"), true)
	check(front.room.can_walk, "gamepad dismissal restores prior walking state")
	front._notice("Primeiro aviso de teste")
	front._notice("Segundo aviso de teste")
	await settle()
	check(front.room.get_meta("system_notice_depth") == 2 and front.room.story_paused, "nested notices retain pause")
	notice(front, "Primeiro aviso de teste").confirmed.emit()
	await settle()
	check(front.room.story_paused and not front.room.can_walk, "closing lower notice cannot resume behind upper notice")
	await dismiss(front, "Segundo aviso de teste", true)
	check(front.room.can_walk and not front.room.story_paused, "last notice restores original state")
	store.deny_write = false
	front._show_slots(false)
	await settle()
	for pair in [["slot-2", "future"], ["slot-3", "corrupt"]]:
		var path := directory.path_join(pair[0] + ".json")
		var hash_before := FileAccess.get_sha256(path)
		front._choose(pair[0], false) # Same handler also guards a file changed since inspection.
		check(front.status.text == Messages.error(pair[1]), "load error displayed in slot list: " + pair[1])
		check(front.session.snapshot().is_empty() and front.last_scene_key == "menu:slots", "bad load stays in menu")
		check(FileAccess.get_sha256(path) == hash_before, "bad load never overwrites files")
	store.deny_read = true
	front._show_slots(false)
	await settle()
	cards = slots(front)
	check(cards["slot-1"].action.text == "Tentar novamente" and not cards["slot-1"].action.disabled, "IO error offers retry")
	check(cards["slot-1"].state_notice.text == Messages.error("io_error"), "IO reason is visible before retry")
	await capture("read-error")
	cards["slot-1"].action.grab_focus()
	await tap_pad()
	check(front.status.text == Messages.error("io_error") and front.session.snapshot().is_empty(), "retry while blocked remains safe")
	store.deny_read = false
	await tap_pad()
	check(front.session.snapshot().get("player", {}).get("coins") == 9, "same retry action succeeds after access is restored")
	check(notice(front, Messages.RECOVERED) != null, "retried recovery is also explained")
	await dismiss(front, Messages.RECOVERED, true)
	future.schemaVersion = State.SCHEMA_VERSION
	future.contentVersion = "unknown-release"
	write(directory.path_join("slot-2.json"), JSON.stringify(future))
	front._show_slots(false)
	await settle()
	cards = slots(front)
	check(cards["slot-2"].state_notice.text == Messages.error("unsupported"), "incompatible content has its own explanation")
	check(cards["slot-2"].action.disabled, "incompatible content cannot be resumed")
	var streams: Array[WeakRef] = []
	for child: Node in front.sound.get_children():
		if child is AudioStreamPlayer and child.stream != null: streams.append(weakref(child.stream))
	front.free()
	await process_frame
	await process_frame
	var deadline := Time.get_ticks_msec() + 2000
	var pending := true
	while pending and Time.get_ticks_msec() < deadline:
		pending = false
		for reference: WeakRef in streams:
			if reference.get_ref() != null: pending = true
		if pending: await create_timer(0.02).timeout
	check(not pending, "audio teardown completes")
	print("SAVE FEEDBACK ", checks, " checks; ", failures, " failures; isolated saves; simulated keyboard/gamepad")
	quit(0 if failures == 0 else 1)
