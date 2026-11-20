extends SceneTree
const Store = preload("res://scripts/campaign/save_store.gd")
const Session = preload("res://scripts/campaign/session.gd")
const State = preload("res://scripts/campaign/state.gd")
const Opening = preload("res://scripts/campaign/opening.gd")
const Front = preload("res://scripts/campaign/front_end.gd")
var checks := 0
var failures := 0
class FaultStore extends "res://scripts/campaign/save_store.gd":
	var copies := 0
	var deny_copy_at := -1
	var removals := 0
	var deny_remove_at := -1
	var deny_marker := ""
	var deny_restore := false
	func _copy_file(source: String, destination: String) -> Error:
		copies += 1
		if copies == deny_copy_at or (deny_restore and destination.ends_with(".restore-tmp")): return ERR_FILE_CANT_WRITE
		return super(source, destination)
	func _remove_file(path: String) -> Error:
		removals += 1
		if deny_remove_at > 0 and removals >= deny_remove_at: return ERR_FILE_CANT_WRITE
		return super(path)
	func _replace_file(source: String, destination: String) -> Error:
		if not deny_marker.is_empty() and destination.ends_with(deny_marker): return ERR_FILE_CANT_WRITE
		return super(source, destination)
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL campaign reset: ", description)
func _initialize() -> void: call_deferred("run")
func fixture() -> Dictionary:
	var directory := "user://campaign-reset-" + State.new_id()
	var store := FaultStore.new(directory.path_join("campaign"))
	var session := Session.new(); session._store = store; session.separate_autosave = true
	root.add_child(session)
	check(session.start("slot-1").status == "ok", "fixture starts")
	var saved: Dictionary = session.snapshot()
	saved.player.flags.ancientTailAttached = true
	check(session.checkpoint({"kind":"opening", "step":10}, saved.player).status == "ok", "fixture reaches birth")
	check(Opening.new(session).name_partner("").status == "ok", "fixture grants Rabbito")
	check(session.save_manual("slot-1", 1).status == "ok", "fixture manual one")
	check(session.save_manual("slot-2", -1).status == "ok", "fixture manual two")
	check(store.create_slot("slot-3").status == "ok", "unrelated journey has same player name")
	var sentinel := directory.path_join("account-bank-sentinel.json")
	var file := FileAccess.open(sentinel, FileAccess.WRITE)
	file.store_string('{"scope":"test-only-account","partners":[{"id":"preserved-mon"}]}'); file.close()
	return {"store":store, "session":session, "sentinel":sentinel,
		"bankHash":FileAccess.get_sha256(sentinel), "otherHash":FileAccess.get_sha256(store._path("slot-3")),
		"partner":session.snapshot().player.partners[0].id, "campaign":session.snapshot().campaignId}
func plan(f: Dictionary) -> Dictionary:
	return f.store.plan_campaign_archive("slot-1", int(f.store.load_slot("slot-1").data.revision))
func check_removed(store: RefCounted) -> void:
	for id in ["slot-0", "slot-1", "slot-2"]: check(store.load_slot(id).status == "missing", "removed " + id)
func settle() -> void:
	for frame in 8: await process_frame
func run() -> void:
	var f := fixture()
	var expected := plan(f)
	check(expected.members.size() == 3 and not expected.members.has("slot-3"), "group by identity, never player name")
	var before: Dictionary = {}
	for id in expected.members: before[id] = f.store.load_slot(id).data
	var receipt: Dictionary = f.store.archive_campaign(expected)
	check(receipt.status == "ok", "archive whole campaign")
	check_removed(f.store)
	check(FileAccess.get_sha256(f.sentinel) == f.bankHash, "external account fixture unchanged")
	check(FileAccess.get_sha256(f.store._path("slot-3")) == f.otherHash, "other campaign unchanged")
	check(not f.store.latest_removed().is_empty(), "undo discoverable after reopen")
	var old: Dictionary = f.session.snapshot()
	check(f.session.checkpoint(old.checkpoint, old.player).status != "ok", "stale live session cannot recreate autosave")
	check(f.session.save_manual("slot-2", -1).status == "campaign_removed", "deleted identity cannot be copied into empty slot")
	var restarted := Session.new(); restarted._store = f.store; restarted.separate_autosave = true
	root.add_child(restarted)
	check(restarted.start("slot-1").status == "ok", "new journey immediately after deletion")
	check(restarted.snapshot().campaignId != f.campaign and restarted.snapshot().player.completedOperations.is_empty(), "new identity and empty reward receipts")
	old = restarted.snapshot(); old.player.flags.ancientTailAttached = true
	check(restarted.checkpoint({"kind":"opening", "step":10}, old.player).status == "ok", "new journey reaches ritual")
	check(Opening.new(restarted).name_partner("Novo Rabbito").status == "ok", "new campaign can grant another Rabbito")
	check(restarted.snapshot().player.partners[0].id != f.partner, "new Rabbito has independent instance")
	check(Opening.new(restarted).name_partner("Duplicado").status != "ok" and restarted.snapshot().player.partners.size() == 1, "repeating ritual cannot duplicate partner")
	check(f.store.restore_slot(receipt).status == "occupied", "undo cannot overwrite new campaign")
	var new_plan: Dictionary = f.store.plan_campaign_archive("slot-1", int(f.store.load_slot("slot-1").data.revision))
	check(f.store.archive_campaign(new_plan).status == "ok", "archive replacement campaign")
	check(f.store.restore_slot(receipt).status == "ok", "restore whole original campaign when spaces free")
	for id: String in before: check(f.store.load_slot(id).data == before[id], "undo restores exact snapshot " + id)
	check(f.store.restore_slot(receipt).status == "occupied", "repeated undo is harmless")
	check(f.store.restore_slot({"slotId":"slot-1", "archive":"user://outside"}).status == "invalid_slot", "receipt traversal rejected")
	f.session.free(); restarted.free()
	# Failure before committing the journal leaves all live files intact.
	for fault in ["copy", "journal"]:
		f = fixture(); expected = plan(f)
		if fault == "copy": f.store.deny_copy_at = 2
		else: f.store.deny_marker = "campaign.json"
		check(f.store.archive_campaign(expected).status == "io_error", "precommit " + fault + " fails")
		for id in ["slot-0", "slot-1", "slot-2"]: check(f.store.load_slot(id).status == "ok", "precommit preserves " + id)
		check(f.store.latest_removed().is_empty(), "uncommitted copies not offered as undo")
		f.session.free()
	# New store instances simulate process interruption at every cleanup boundary.
	for boundary in range(1, 6):
		f = fixture(); expected = plan(f); f.store.deny_remove_at = boundary
		receipt = f.store.archive_campaign(expected)
		check(receipt.status == "archive_pending", "cleanup interrupted at boundary " + str(boundary))
		check(f.store.load_slot("slot-1").status == "archive_pending", "partial deletion cannot be loaded")
		var reopened := Store.new(f.store.directory)
		check_removed(reopened)
		check(FileAccess.get_sha256(f.sentinel) == f.bankHash, "recovery preserves external fixture")
		check(reopened.restore_slot(receipt).status == "ok", "recovered deletion can be undone")
		f.session.free()
	for fault in ["copy", "partial", "done"]:
		f = fixture(); receipt = f.store.archive_campaign(plan(f))
		if fault == "copy": f.store.deny_restore = true
		elif fault == "partial": f.store.deny_copy_at = f.store.copies + 2
		else: f.store.deny_marker = "restored.json"
		check(f.store.restore_slot(receipt).status == "archive_pending", "undo interruption " + fault)
		var reopened := Store.new(f.store.directory)
		check(reopened.load_slot("slot-0").status == "ok", "reopen completes interrupted undo")
		check(reopened.load_slot("slot-2").data.player.partners[0].id == f.partner, "undo preserves partner identity")
		check(reopened.restore_slot(receipt).status == "occupied", "no repeated undo writes")
		f.session.free()
	f = fixture(); f.store.deny_marker = "deleted.json"
	receipt = f.store.archive_campaign(plan(f))
	check(receipt.status == "archive_pending", "deletion completion marker can fail safely")
	check_removed(Store.new(f.store.directory))
	f.session.free()
	f = fixture(); receipt = f.store.archive_campaign(plan(f)); f.store.deny_marker = "restore.json"
	check(f.store.restore_slot(receipt).status == "io_error", "undo intent failure does not restore any file")
	check_removed(Store.new(f.store.directory))
	f.session.free()
	f = fixture(); f.store.deny_remove_at = 1; receipt = f.store.archive_campaign(plan(f))
	var corrupt := FileAccess.open(str(receipt.archive).path_join("slot-1.json"), FileAccess.WRITE)
	corrupt.store_string("damaged archive copy"); corrupt.close()
	check(Store.new(f.store.directory).load_slot("slot-1").status == "archive_pending", "damaged archive never authorizes remaining cleanup")
	check(FileAccess.file_exists(f.store._path("slot-1")), "last live copy preserved when archive corrupt")
	f.session.free()
	# Old files have no trustworthy cross-slot identity: do not infer it from names.
	var legacy_directory := "user://campaign-reset-legacy-" + State.new_id()
	var legacy_store := Store.new(legacy_directory)
	var legacy: Dictionary = legacy_store.create_slot("slot-1").data
	legacy.erase("campaignId")
	var legacy_file := FileAccess.open(legacy_directory.path_join("slot-1.json"), FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy)); legacy_file.close()
	var legacy_session := Session.new(); legacy_session._store = legacy_store; legacy_session.separate_autosave = true
	root.add_child(legacy_session)
	check(legacy_session.resume_slot("slot-1").status == "ok", "legacy save resumes without destructive migration")
	old = legacy_session.snapshot()
	check(legacy_session.checkpoint(old.checkpoint, old.player).status == "ok", "legacy autosave gets stable identity")
	var legacy_plan := legacy_store.plan_campaign_archive("slot-1", int(legacy.revision))
	check(legacy_plan.legacy and legacy_plan.members.size() == 2, "legacy identity matches subsequently generated autosave")
	check(legacy_store.archive_campaign(legacy_plan).status == "ok", "legacy campaign and identified autosave removed")
	check(legacy_store.load_slot("slot-0").status == "missing", "legacy linked autosave cannot resurrect deleted journey")
	legacy_session.free()
	f = fixture()
	var broken := FileAccess.open(f.store._path("slot-1"), FileAccess.WRITE)
	broken.store_string("truncated primary"); broken.close()
	check(f.store.load_slot("slot-1").get("recovered", false), "backup-only fixture")
	receipt = f.store.archive_campaign(plan(f))
	check(receipt.status == "ok", "campaign with corrupt primary can be archived safely")
	check(not f.store.latest_removed().is_empty(), "undo discoverable from valid archived backup")
	check(f.store.restore_slot(receipt).get("recovered", false), "undo retains original backup recovery behavior")
	f.session.free()
	f = fixture(); f.store.deny_remove_at = 1; receipt = f.store.archive_campaign(plan(f))
	var retry_front := Front.new(); retry_front.session._store = f.store
	retry_front.preferences.storage_path = f.store.directory.path_join("settings.cfg")
	root.add_child(retry_front); retry_front.preferences.reduced_motion = true
	retry_front._show_slots(false); await settle()
	var retry_card: Control
	for child in retry_front.page.get_children():
		if child.get("slot_id") == "slot-1": retry_card = child
	check(retry_card != null and not retry_card.action.disabled and retry_card.action.text == "Tentar novamente", "interrupted operation offers actionable retry")
	f.store.deny_remove_at = -1
	retry_card.action.pressed.emit(); await settle()
	check(retry_front.last_scene_key == "menu:slots" and retry_front.session.snapshot().is_empty(), "retry completes deletion and refreshes list without starting deleted journey")
	var retry_streams: Array[WeakRef] = []
	for child in retry_front.sound.get_children():
		if child is AudioStreamPlayer and child.stream != null: retry_streams.append(weakref(child.stream))
	retry_front.free(); f.session.free(); await settle()
	var retry_deadline := Time.get_ticks_msec() + 2000
	var retry_pending := true
	while retry_pending and Time.get_ticks_msec() < retry_deadline:
		retry_pending = false
		for ref: WeakRef in retry_streams:
			if ref.get_ref() != null: retry_pending = true
		if retry_pending: await create_timer(.02).timeout
	check(not retry_pending, "retry frontend audio teardown")
	f = fixture(); expected = plan(f)
	var changed: Dictionary = f.store.load_slot("slot-2").data
	check(f.store.save_slot(changed).status == "ok", "concurrent revision fixture")
	check(f.store.archive_campaign(expected).status == "stale", "changed related save invalidates confirmation")
	check(f.store.load_slot("slot-0").status == "ok", "stale deletion removes nothing")
	# Real frontend confirmation, cancellation and confirmed group deletion.
	var front := Front.new(); front.session._store = f.store
	front.preferences.storage_path = f.store.directory.path_join("settings.cfg")
	root.add_child(front); front.preferences.reduced_motion = true
	front._show_slots(false); await settle()
	front._confirm_erase_slot("slot-1", f.store.load_slot("slot-1"), false); await settle()
	var dialogs := get_nodes_in_group("manga_dialogue")
	check(dialogs.size() == 1 and root.gui_get_focus_owner() == dialogs[0].decline, "deletion initially focuses cancel")
	check(dialogs[0].dialog_text.contains("Autosave 0") and dialogs[0].dialog_text.contains("Pipamons"), "confirmation lists affected copies and losses")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://tmp/campaign-reset")
		root.get_texture().get_image().save_png("res://tmp/campaign-reset/confirmation.png")
	dialogs[0].canceled.emit(); await settle()
	check(f.store.load_slot("slot-1").status == "ok", "UI cancel preserves campaign")
	front._confirm_erase_slot("slot-1", f.store.load_slot("slot-1"), false); await settle()
	dialogs = get_nodes_in_group("manga_dialogue"); dialogs[0].confirmed.emit(); await settle()
	check_removed(f.store)
	check(FileAccess.get_sha256(f.sentinel) == f.bankHash, "UI deletion does not touch external fixture")
	var streams: Array[WeakRef] = []
	for child in front.sound.get_children():
		if child is AudioStreamPlayer and child.stream != null: streams.append(weakref(child.stream))
	front.free(); f.session.free(); await settle()
	var deadline := Time.get_ticks_msec() + 2000
	var pending := true
	while pending and Time.get_ticks_msec() < deadline:
		pending = false
		for ref: WeakRef in streams:
			if ref.get_ref() != null: pending = true
		if pending: await create_timer(.02).timeout
	check(not pending, "audio teardown")
	print("CAMPAIGN RESET ", checks, " checks; ", failures, " failures; isolated files and injected interruptions")
	quit(0 if failures == 0 else 1)
