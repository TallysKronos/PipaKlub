extends SceneTree
const Store = preload("res://scripts/campaign/save_store.gd")
const Session = preload("res://scripts/campaign/session.gd")
const State = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0
var test_root := "user://save-resilience-" + State.new_id()

class FaultStore extends "res://scripts/campaign/save_store.gd":
	var fault := ""
	func _read(path: String, slot_id: String) -> Dictionary:
		if fault == "primary-read" and path.ends_with(".json"): return {"status":"io_error"}
		if fault == "backup-read" and path.ends_with(".bak"): return {"status":"io_error"}
		return super(path, slot_id)
	func _write_checked(path: String, data: Dictionary) -> Error:
		if fault == "primary-temp" and path.ends_with(".json.tmp"): return ERR_FILE_CANT_WRITE
		if fault == "backup-temp" and path.ends_with(".bak.tmp"): return ERR_FILE_CANT_WRITE
		return super(path, data)
	func _replace_file(source: String, destination: String) -> Error:
		if fault == "backup-replace" and destination.ends_with(".bak"): return ERR_CANT_CREATE
		if fault in ["primary-replace", "primary-gap"] and destination.ends_with(".json"):
			if fault == "primary-gap":
				# Model interrupted delete-then-rename on Windows, fixture files only.
				if DirAccess.remove_absolute(destination) != OK: return ERR_FILE_CANT_WRITE
			return ERR_CANT_CREATE
		return super(source, destination)
	func _copy_file(source: String, destination: String) -> Error:
		if fault == "preserve-damaged": return ERR_FILE_CANT_WRITE
		return super(source, destination)

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL save resilience: ", label)
	return ok

func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not check(file != null, "fixture writable"): return
	file.store_string(text)
	file.close()

func serialized(value: Dictionary) -> Dictionary:
	# JSON returns numbers as floats; compare the persistence representation.
	return JSON.parse_string(JSON.stringify(value))

func _initialize() -> void:
	for fault in ["primary-temp", "backup-temp", "backup-replace", "primary-replace", "primary-gap", "preserve-damaged"]:
		test_failed_reward(fault)
	test_formats_and_debris()
	test_read_failures()
	test_creation_retry()
	test_invalid_payloads()
	print("SAVE RESILIENCE ", checks, " checks; ", failures, " failures; isolated directory ", test_root)
	quit(0 if failures == 0 else 1)

func seeded(directory: String) -> Session:
	var session := Session.new()
	session._store = FaultStore.new(directory)
	check(session.start("slot-1").status == "ok", "seed slot")
	for coins in [11, 22]:
		var saved: Dictionary = session.snapshot()
		saved.player.coins = coins
		check(session.checkpoint(saved.checkpoint, saved.player).status == "ok", "seed revision")
	return session

func test_failed_reward(fault: String) -> void:
	var directory := test_root.path_join(fault)
	var session := seeded(directory)
	var store: RefCounted = session._store
	var path := directory.path_join("slot-1.json")
	var primary_hash := FileAccess.get_sha256(path)
	var damaged_hash := ""
	var backup_hash := FileAccess.get_sha256(path + ".bak")
	if fault == "preserve-damaged":
		write_text(path, "{interrupted reward")
		damaged_hash = FileAccess.get_sha256(path)
		check(session.resume_slot("slot-1").get("recovered", false), "resume from backup")
	var previous: Dictionary = session.snapshot()
	var player: Dictionary = previous.player.duplicate(true)
	player.coins += 7
	var changed := [0]
	var errors := [0]
	session.changed.connect(func(_value: Dictionary): changed[0] += 1)
	session.storage_failed.connect(func(_status: String): errors[0] += 1)
	store.fault = fault
	var receipt := "reward-" + fault
	check(session.commit_operation(receipt, previous.checkpoint, player).status == "io_error", fault + " returns an error")
	check(session.snapshot() == previous, fault + " leaves in-memory progress unchanged")
	check(changed[0] == 0 and errors[0] == 1, fault + " emits failure, not success")
	var loaded: Dictionary = Store.new(directory).load_slot("slot-1")
	check(loaded.status == "ok" and loaded.data == serialized(previous), fault + " retains last committed disk state")
	check(receipt not in loaded.data.player.completedOperations, fault + " does not mark unpaid reward complete")
	if fault == "primary-gap":
		check(loaded.recovered and not FileAccess.file_exists(path), "backup recovers missing primary after interrupted rename")
	elif fault == "preserve-damaged":
		check(FileAccess.get_sha256(path) == damaged_hash, "failed preservation keeps damaged source")
	else:
		check(FileAccess.get_sha256(path) == primary_hash, fault + " keeps primary bytes")
	store.fault = ""
	check(session.commit_operation(receipt, previous.checkpoint, player).status == "ok", fault + " can be retried")
	check(session.snapshot().player.coins == previous.player.coins + 7, fault + " grants reward once")
	check(session.commit_operation(receipt, previous.checkpoint, player).status == "already_applied", fault + " refuses duplicate reward")
	var reopened := Session.new()
	reopened._store = Store.new(directory)
	check(reopened.resume_slot("slot-1").status == "ok", fault + " reloads in a fresh session")
	check(reopened.snapshot() == serialized(session.snapshot()), fault + " persisted state matches memory")
	if fault == "preserve-damaged":
		check(FileAccess.file_exists(path + ".damaged-" + damaged_hash), "damaged original archived after successful recovery")
		check(FileAccess.get_sha256(path + ".damaged-" + damaged_hash) == damaged_hash, "damaged original preserved byte for byte")
		check(FileAccess.get_sha256(path + ".bak") == backup_hash, "good backup never replaced by damaged primary")
	reopened.free()
	session.free()

func test_read_failures() -> void:
	for fault in ["primary-read", "backup-read"]:
		var directory := test_root.path_join(fault)
		var session := seeded(directory)
		var store: RefCounted = session._store
		var saved: Dictionary = session.snapshot()
		var path := directory.path_join("slot-1.json")
		var hashes := [FileAccess.get_sha256(path), FileAccess.get_sha256(path + ".bak")]
		store.fault = fault
		check(store.load_slot("slot-1").status == "io_error", fault + " does not silently roll back")
		check(session.checkpoint(saved.checkpoint, saved.player).status == "io_error", fault + " blocks writing")
		check(session.snapshot() == saved, fault + " preserves active session")
		check([FileAccess.get_sha256(path), FileAccess.get_sha256(path + ".bak")] == hashes, fault + " preserves both files")
		store.fault = ""
		check(store.load_slot("slot-1").data == serialized(saved), fault + " can resume after IO is restored")
		session.free()

func test_creation_retry() -> void:
	var store := FaultStore.new(test_root.path_join("first-save"))
	var session := Session.new()
	session._store = store
	store.fault = "primary-replace"
	check(session.start("slot-1").status == "io_error", "first save reports failed publication")
	check(session.snapshot().is_empty(), "failed first save does not start an unsaved journey")
	check(store.load_slot("slot-1").status == "missing", "uncommitted first temp is not a journey")
	store.fault = ""
	check(session.start("slot-1").status == "ok", "first save may be retried")
	check(store.create_slot("slot-1").status == "occupied", "successful retry cannot be overwritten")
	check(store.load_slot("slot-1").data == serialized(session.snapshot()), "first save reloads consistently")
	session.free()

func test_invalid_payloads() -> void:
	var directory := test_root.path_join("invalid-payloads")
	var session := seeded(directory)
	var store := Store.new(directory)
	var path := directory.path_join("slot-1.json")
	var good: Dictionary = session.snapshot()
	for kind in ["oversized", "negative-coins", "wrong-slot"]:
		if kind == "oversized":
			var bytes := PackedByteArray()
			bytes.resize(Store.MAX_BYTES + 1)
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(bytes)
			file.close()
		else:
			var invalid := good.duplicate(true)
			if kind == "negative-coins": invalid.player.coins = -1
			else: invalid.slotId = "slot-2"
			write_text(path, JSON.stringify(invalid))
		var digest := FileAccess.get_sha256(path)
		var loaded := store.load_slot("slot-1")
		check(loaded.status == "ok" and loaded.recovered, kind + " recovers validated backup")
		check(loaded.data.player.coins == 11, kind + " restores committed previous state")
		check(FileAccess.get_sha256(path) == digest, kind + " load is nondestructive")
	session.free()

func test_formats_and_debris() -> void:
	var directory := test_root.path_join("formats")
	var session := seeded(directory)
	var store := Store.new(directory)
	var path := directory.path_join("slot-1.json")
	var good: Dictionary = session.snapshot()
	write_text(path + ".tmp", JSON.stringify(State.fresh("slot-1")))
	write_text(path + ".bak.tmp", "unfinished")
	check(store.load_slot("slot-1").data == serialized(good), "temporary debris is never promoted implicitly")
	for field in ["schemaVersion", "contentVersion", "rulesVersion"]:
		var unknown := good.duplicate(true)
		unknown[field] = 999 if field == "schemaVersion" else "unknown-release"
		write_text(path, JSON.stringify(unknown))
		var digest := FileAccess.get_sha256(path)
		check(store.load_slot("slot-1").status in ["future", "unsupported"], "unknown format blocks old backup: " + field)
		check(store.save_slot(good).status in ["future", "unsupported"], "unknown format blocks writing: " + field)
		check(FileAccess.get_sha256(path) == digest, "unknown primary remains intact: " + field)
	write_text(path, JSON.stringify(good))
	var before := FileAccess.get_sha256(path)
	var future := good.duplicate(true)
	future.schemaVersion = 999
	write_text(path + ".bak", JSON.stringify(future))
	check(store.load_slot("slot-1").status == "future", "future backup is not silently discarded")
	check(FileAccess.get_sha256(path) == before, "valid primary preserved when backup is newer-format")
	write_text(path, "truncated")
	write_text(path + ".bak", "also truncated")
	check(store.load_slot("slot-1").status == "corrupt", "both damaged copies report corruption")
	check(store.create_slot("slot-1").status == "occupied", "corruption does not permit implicit overwrite")
	check(store.load_slot("../slot-1").status == "invalid_slot", "path traversal refused")
	session.free()
