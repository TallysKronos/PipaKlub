extends SceneTree
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Messages = preload("res://scripts/campaign/save_messages.gd")
var checks := 0
var failures := 0
class FaultStore extends "res://scripts/campaign/save_store.gd":
	var deny_write := false
	func _write_checked(path: String, data: Dictionary) -> Error:
		if deny_write: return ERR_FILE_CANT_WRITE
		return super(path, data)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL autosave recovery: ", label)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for frame in 8: await process_frame
func warning(front: Control) -> Control:
	for child in front.get_children():
		if not child.is_queued_for_deletion() and child.get("dialog_text") == Messages.error("io_error"): return child
	return null
func close_warning(front: Control) -> void:
	# Same confirmation signal as the dialog's input path, already tested in save_feedback_checks.
	var dialog := warning(front)
	if dialog != null: dialog.confirmed.emit()
	await settle()
func run() -> void:
	var directory := "user://autosave-recovery-" + State.new_id()
	var store := FaultStore.new(directory)
	var front := Front.new()
	front.session._store = store
	front.preferences.storage_path = directory.path_join("settings.cfg")
	root.add_child(front)
	front.preferences.reduced_motion = true
	front.session.separate_autosave = true
	check(front.session.start("slot-1").status == "ok", "create fixture")
	var saved: Dictionary = front.session.snapshot()
	saved.player.partners = [{"id":"fixture-rabbito", "modelId":"rabbito", "personalName":"Rabbito", "xp":0, "craftBonus":0, "condition":{"line":100, "structure":100}}]
	saved.player.equippedPartnerId = "fixture-rabbito"
	saved.player.journey = {"lesson":5, "phase":"complete"}
	saved.player.flags.ninaAccepted = true
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(saved.player)
	saved.player.flags.pipeiroDocumentsSeen = true
	var point: Dictionary = CP.make("park-trail", CP.spawn("park-trail"), CP.SPACE)
	check(front.session.checkpoint(point, saved.player).status == "ok", "seed real exploration checkpoint")
	front._show_saved()
	var deadline := Time.get_ticks_msec() + 10000
	while (not is_instance_valid(front.park) or is_instance_valid(front.scene_loading)) and Time.get_ticks_msec() < deadline: await process_frame
	if not is_instance_valid(front.park):
		check(false, "real map loads")
		front.free(); quit(1); return
	front.park.set_process(false)
	front.park.paused = false
	var previous: Dictionary = front.session.snapshot()
	var path := directory.path_join("slot-0.json")
	var hash_before := FileAccess.get_sha256(path)
	store.deny_write = true
	front._park_action("autosave")
	await settle()
	check(warning(front) != null and front.park.paused, "failed exploration autosave opens a blocking explanation")
	check(front.session.snapshot() == previous, "failure does not publish progress")
	check(FileAccess.get_sha256(path) == hash_before, "failure preserves saved bytes")
	await close_warning(front)
	check(not front.park.paused, "acknowledgement restores exploration instead of trapping player")
	store.deny_write = false
	front._park_action("autosave")
	await settle()
	check(int(front.session.snapshot().revision) == int(previous.revision) + 1, "retry actually commits once")
	check(warning(front) == null and not front.park.paused, "successful retry leaves no error or pause")
	check(store.load_slot("slot-0").data.revision == front.session.snapshot().revision, "retry is persisted")
	front.park.paused = true
	store.deny_write = true
	check(not front._save_park(), "paused context also reports IO failure")
	await settle()
	await close_warning(front)
	check(front.park.paused, "pre-existing pause is preserved")
	front.park.paused = false
	front._pause_game()
	front.pause_overlay.chosen.emit("save")
	await settle()
	check(front.last_scene_key == "page:SALVAR JORNADA", "manual recovery remains accessible while automatic writes fail")
	var streams: Array[WeakRef] = []
	for child: Node in front.sound.get_children():
		if child is AudioStreamPlayer and child.stream != null: streams.append(weakref(child.stream))
	front.free()
	await process_frame
	await process_frame
	deadline = Time.get_ticks_msec() + 2000
	var pending := true
	while pending and Time.get_ticks_msec() < deadline:
		pending = false
		for reference: WeakRef in streams:
			if reference.get_ref() != null: pending = true
		if pending: await create_timer(0.02).timeout
	check(not pending, "audio teardown completes")
	print("AUTOSAVE RECOVERY ", checks, " checks; ", failures, " failures; real exploration map, injected write failure")
	quit(0 if failures == 0 else 1)
