extends RefCounted
## Copy before committing deletion. Immutable journals make cleanup/undo resumable.
## Only the four campaign filenames are admitted; account/profile files are outside.
const State = preload("res://scripts/campaign/state.gd")
const SUFFIXES = ["", ".bak", ".tmp", ".bak.tmp"]
var store: RefCounted
func _init(owner_store: RefCounted) -> void: store = owner_store

func plan(id: String, revision: int) -> Dictionary:
	var selected: Dictionary = store.load_slot(id)
	if selected.status != "ok": return selected
	if int(selected.data.revision) != revision: return {"status":"stale"}
	var key := State.campaign_key(selected.data)
	var members: Dictionary = {}
	var unidentified: Array[String] = []
	for slot in ["slot-0", "slot-1", "slot-2", "slot-3"]:
		var saved: Dictionary = store.load_slot(slot)
		if saved.status == "missing": continue
		if saved.status != "ok": unidentified.append(slot); continue
		if State.campaign_key(saved.data) == key: members[slot] = int(saved.data.revision)
	return {"status":"ok", "slotId":id, "campaignId":key, "members":members,
		"legacy":not selected.data.has("campaignId"), "unidentified":unidentified}

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536: return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}

func _write(path: String, data: Dictionary) -> bool:
	# These journals are immutable and written before their corresponding side effect.
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data)); file.flush()
	var error := file.get_error(); file.close()
	if error != OK or _read(path + ".tmp") != JSON.parse_string(JSON.stringify(data)): return false
	return store._replace_file(path + ".tmp", path) == OK

func _valid(folder: String, journal: Dictionary) -> bool:
	if folder.get_base_dir() != store.directory.path_join("removed"): return false
	if journal.get("version") != 1 or not State.valid_slot(str(journal.get("slotId", ""))): return false
	if not folder.get_file().begins_with(str(journal.slotId) + "-"): return false
	if not journal.get("campaignId") is String or not journal.get("members") is Dictionary or not journal.get("files") is Dictionary: return false
	if journal.members.is_empty() or journal.files.is_empty() or not journal.members.has(journal.slotId): return false
	for slot: String in journal.members:
		if not State.valid_slot(slot) or not State.whole(journal.members[slot]): return false
		if not journal.files.has(slot + ".json") and not journal.files.has(slot + ".json.bak"): return false
	for filename: String in journal.files:
		var admitted := false
		for slot: String in journal.members:
			for suffix: String in SUFFIXES:
				if filename == slot + ".json" + suffix: admitted = true
		if not admitted or not journal.files[filename] is String or journal.files[filename].length() != 64: return false
	return true

func folders() -> Array[String]:
	var result: Array[String] = []
	var parent: String = store.directory.path_join("removed")
	if DirAccess.dir_exists_absolute(parent):
		for name in DirAccess.get_directories_at(parent):
			var folder := parent.path_join(name)
			if FileAccess.file_exists(folder.path_join("campaign.json")): result.append(folder)
	return result

func recover() -> String:
	for folder in folders():
		var journal := _read(folder.path_join("campaign.json"))
		if not _valid(folder, journal): return "archive_pending"
		if FileAccess.file_exists(folder.path_join("restored.json")):
			if _read(folder.path_join("restored.json")).get("campaignId") != journal.campaignId: return "archive_pending"
			continue
		if FileAccess.file_exists(folder.path_join("restore.json")):
			var status := _restore_files(folder, journal)
			if status != "ok": return status
			continue
		if FileAccess.file_exists(folder.path_join("deleted.json")):
			if _read(folder.path_join("deleted.json")).get("campaignId") != journal.campaignId: return "archive_pending"
			continue
		var status := _complete_delete(folder, journal)
		if status != "ok": return status
	return "ok"

func deleted(key: String) -> bool:
	for folder in folders():
		var journal := _read(folder.path_join("campaign.json"))
		if journal.get("campaignId") == key and not FileAccess.file_exists(folder.path_join("restored.json")): return true
	return false

func available(folder: String) -> bool:
	var journal := _read(folder.path_join("campaign.json"))
	if not _valid(folder, journal) or FileAccess.file_exists(folder.path_join("restored.json")): return false
	for slot: String in journal.members:
		for suffix: String in SUFFIXES:
			if FileAccess.file_exists(store._path(slot) + suffix): return false
	return true

func erase(expected: Dictionary) -> Dictionary:
	var current := plan(str(expected.get("slotId", "")), int(expected.get("members", {}).get(expected.get("slotId", ""), -1)))
	if current.status != "ok": return current
	if current.campaignId != expected.get("campaignId") or current.members != expected.get("members"): return {"status":"stale"}
	var folder: String = store.directory.path_join("removed").path_join(str(current.slotId) + "-campaign-" + State.new_id())
	if DirAccess.make_dir_recursive_absolute(folder) != OK: return {"status":"io_error"}
	var journal := {"version":1, "slotId":current.slotId, "campaignId":current.campaignId, "members":current.members, "files":{}}
	for slot: String in current.members:
		for suffix: String in SUFFIXES:
			var name := slot + ".json" + suffix
			var path: String = store.directory.path_join(name)
			if not FileAccess.file_exists(path): continue
			var hash := FileAccess.get_sha256(path)
			if hash.is_empty() or store._copy_file(path, folder.path_join(name)) != OK: return {"status":"io_error"}
			if FileAccess.get_sha256(folder.path_join(name)) != hash: return {"status":"io_error"}
			journal.files[name] = hash
	# Re-check all participants after copying; no live file has been removed yet.
	var verified := plan(str(current.slotId), int(current.members[current.slotId]))
	if verified.status != "ok" or verified.get("members") != current.members: return {"status":"stale"}
	for name: String in journal.files:
		if FileAccess.get_sha256(store.directory.path_join(name)) != journal.files[name]: return {"status":"stale"}
	if not _write(folder.path_join("campaign.json"), journal): return {"status":"io_error"}
	var status := _complete_delete(folder, journal)
	return {"status":status, "archive":folder, "slotId":current.slotId}

func _complete_delete(folder: String, journal: Dictionary) -> String:
	var status := _cleanup(folder, journal)
	if status != "ok": return status
	# Completed deletion needs only its tiny journal on subsequent loads, not
	# re-hashing every archived save on each checkpoint throughout the next game.
	return "ok" if _write(folder.path_join("deleted.json"), {"campaignId":journal.campaignId}) else "archive_pending"

func _cleanup(folder: String, journal: Dictionary) -> String:
	for name: String in journal.files:
		if FileAccess.get_sha256(folder.path_join(name)) != journal.files[name]: return "archive_pending"
	for name: String in journal.files:
		var path: String = store.directory.path_join(name)
		if not FileAccess.file_exists(path): continue
		if FileAccess.get_sha256(path) != journal.files[name]:
			# An occupied slot may now hold a genuinely new campaign. Never remove it.
			var slot := name.left(6)
			var saved: Dictionary = store._read(store._path(slot), slot)
			if saved.status == "ok" and State.campaign_key(saved.data) != journal.campaignId: continue
			return "archive_pending"
		if store._remove_file(path) != OK: return "archive_pending"
	return "ok"

func restore(receipt: Dictionary) -> Dictionary:
	var folder: String = receipt.get("archive", "")
	var journal := _read(folder.path_join("campaign.json"))
	if not _valid(folder, journal) or receipt.get("slotId") != journal.slotId: return {"status":"invalid_slot"}
	if FileAccess.file_exists(folder.path_join("restored.json")): return {"status":"occupied"}
	for slot: String in journal.members:
		for suffix: String in SUFFIXES:
			if FileAccess.file_exists(store._path(slot) + suffix): return {"status":"occupied"}
	for name: String in journal.files:
		if FileAccess.get_sha256(folder.path_join(name)) != journal.files[name]: return {"status":"corrupt"}
	if not _write(folder.path_join("restore.json"), {"campaignId":journal.campaignId}): return {"status":"io_error"}
	var status := _restore_files(folder, journal)
	if status != "ok": return {"status":status}
	return store.load_slot(str(journal.slotId))

func _restore_files(folder: String, journal: Dictionary) -> String:
	if _read(folder.path_join("restore.json")).get("campaignId") != journal.campaignId: return "archive_pending"
	for name: String in journal.files:
		var source := folder.path_join(name)
		var destination: String = store.directory.path_join(name)
		if FileAccess.get_sha256(source) != journal.files[name]: return "archive_pending"
		if FileAccess.file_exists(destination):
			if FileAccess.get_sha256(destination) == journal.files[name]: continue
			return "archive_pending"
		if store._copy_file(source, destination + ".restore-tmp") != OK: return "archive_pending"
		if FileAccess.get_sha256(destination + ".restore-tmp") != journal.files[name]: return "archive_pending"
		if store._replace_file(destination + ".restore-tmp", destination) != OK: return "archive_pending"
	if not _write(folder.path_join("restored.json"), {"campaignId":journal.campaignId}): return "archive_pending"
	return "ok"
