extends RefCounted
## Single-process local store. Backups cover interrupted replacement on Windows.
## Does not promise fsync/power-loss durability or online certification.
const State = preload("res://scripts/campaign/state.gd")
const DIRECTORY := "user://campaign"
const MAX_BYTES := 8 * 1024 * 1024
var directory: String
var bank_directory: String
const PartnerBank = preload("res://scripts/campaign/partner_bank.gd")
var _recovering_archives := false
const CampaignArchive = preload("res://scripts/campaign/campaign_archive.gd")

func _init(storage_directory: String = DIRECTORY) -> void:
	directory = storage_directory
	bank_directory = "user://account/partner-bank" if directory == DIRECTORY else directory.path_join("profile-bank")

func _path(slot_id: String) -> String:
	return directory.path_join(slot_id + ".json")

func _read(path: String, slot_id: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "io_error"}
	if file.get_length() > MAX_BYTES:
		return {"status": "invalid"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"status": "invalid"}
	var status: String = State.inspect(parser.data, slot_id)
	return {"status": status, "data": parser.data if status == "ok" else {}}

func load_slot(slot_id: String) -> Dictionary:
	if not State.valid_slot(slot_id):
		return {"status": "invalid_slot"}
	var recovered := _recover_archives()
	if recovered != "ok": return {"status":recovered}
	var primary := _read(_path(slot_id), slot_id)
	var backup := _read(_path(slot_id) + ".bak", slot_id)
	# Never silently fall back to an old backup over an unknown/newer format.
	for candidate in [primary, backup]:
		if candidate.status in ["future", "unsupported", "io_error"]:
			return {"status": candidate.status}
	if primary.status == "ok":
		return {"status": "ok", "data": State.migrate_progression(primary.data), "recovered": false,"modifiedAt":FileAccess.get_modified_time(_path(slot_id))}
	if backup.status == "ok":
		return {"status": "ok", "data": State.migrate_progression(backup.data), "recovered": true,"modifiedAt":FileAccess.get_modified_time(_path(slot_id)+".bak")}
	return {"status": "missing" if primary.status == "missing" and backup.status == "missing" else "corrupt"}

func create_slot(slot_id: String) -> Dictionary:
	if not State.valid_slot(slot_id):
		return {"status": "invalid_slot"}
	var recovered := _recover_archives()
	if recovered != "ok": return {"status":recovered}
	if FileAccess.file_exists(_path(slot_id)) or FileAccess.file_exists(_path(slot_id) + ".bak"):
		return {"status": "occupied"}
	return _save(State.fresh(slot_id), true)

func save_slot(snapshot: Dictionary) -> Dictionary:
	return _save(snapshot, false)

## Explicit copy to another slot. Existing validation, backups and revision check
## still apply; never overwrite an unreadable or newer-format destination.
func copy_to_slot(snapshot: Dictionary, slot_id: String, expected_revision: int) -> Dictionary:
	if not State.valid_slot(slot_id): return {"status":"invalid_slot"}
	var current := load_slot(slot_id)
	if current.status not in ["ok", "missing"]: return current
	var revision := int(current.data.revision) if current.status == "ok" else -1
	if revision != expected_revision: return {"status":"stale"}
	var next := snapshot.duplicate(true)
	next.slotId = slot_id
	next.revision = maxi(0, revision)
	return _save(next, current.status == "missing")

# Keep filesystem boundaries individually testable without changing production
# ordering or relying on platform-specific permissions/locks for fault injection.
func _replace_file(source: String, destination: String) -> Error:
	return DirAccess.rename_absolute(source, destination)

func _copy_file(source: String, destination: String) -> Error:
	return DirAccess.copy_absolute(source, destination)

func _remove_file(path: String) -> Error:
	return DirAccess.remove_absolute(path)

func _recover_archives() -> String:
	if _recovering_archives: return "ok"
	_recovering_archives = true
	var status: String = PartnerBank.new(self).recover()
	if status == "ok": status = CampaignArchive.new(self).recover()
	_recovering_archives = false
	return status

func plan_campaign_archive(slot_id: String, revision: int) -> Dictionary:
	return CampaignArchive.new(self).plan(slot_id, revision)

func _bank_write_json(path: String, envelope: Dictionary) -> Error:
	var text := JSON.stringify(envelope)
	if text.to_utf8_buffer().size() > PartnerBank.MAX_BYTES: return ERR_OUT_OF_MEMORY
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(text); file.flush()
	var error := file.get_error(); file.close()
	if error != OK: return error
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return ERR_FILE_CORRUPT
	return OK if parser.data == JSON.parse_string(text) else ERR_FILE_CORRUPT

func archive_campaign(plan: Dictionary) -> Dictionary:
	return CampaignArchive.new(self).erase(plan)

func _write_checked(path: String, data: Dictionary) -> Error:
	var text := JSON.stringify(data, "\t")
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return ERR_OUT_OF_MEMORY
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	var check := _read(path, str(data.slotId))
	# JSON reads numbers as floats; compare against the serialized representation.
	if check.status != "ok" or check.data != JSON.parse_string(text):
		return ERR_FILE_CORRUPT
	return OK

func _save(snapshot: Dictionary, creating: bool) -> Dictionary:
	var slot_id: String = str(snapshot.get("slotId", ""))
	var inspection: String = State.inspect(snapshot, slot_id)
	if inspection != "ok":
		return {"status": inspection}
	var current := load_slot(slot_id)
	if current.status == "archive_pending": return current
	if CampaignArchive.new(self).deleted(State.campaign_key(snapshot)): return {"status":"campaign_removed"}
	if creating:
		if current.status != "missing":
			return {"status": "occupied"}
	else:
		if current.status != "ok":
			return current
		if snapshot.revision != current.data.revision:
			return {"status": "stale"}
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return {"status": "io_error", "error": error}
	var next := State.migrate_progression(snapshot)
	next.revision = int(snapshot.revision) + 1
	next.savedAt=int(Time.get_unix_time_from_system())
	var path := _path(slot_id)
	error = _write_checked(path + ".tmp", next)
	if error != OK:
		return {"status": "io_error", "error": error}
	# On recovery, leave the good backup untouched. Preserve the damaged primary
	# separately before replacing it, so recovery never destroys the sole good copy.
	if not creating and current.recovered and FileAccess.file_exists(path):
		var damaged := path + ".damaged-" + FileAccess.get_sha256(path)
		if not FileAccess.file_exists(damaged):
			error = _copy_file(path, damaged)
			if error != OK:
				return {"status": "io_error", "error": error}
	elif not creating and not current.recovered:
		# load_slot migrates in memory. Keep the original on-disk rules in the
		# backup on the first write, so a rollback can still read the old format.
		var previous := _read(path, slot_id)
		if previous.status != "ok" or previous.data.revision != current.data.revision:
			return {"status":"stale"}
		error = _write_checked(path + ".bak.tmp", previous.data)
		if error == OK:
			error = _replace_file(path + ".bak.tmp", path + ".bak")
		if error != OK:
			return {"status": "io_error", "error": error}
	error = _replace_file(path + ".tmp", path)
	if error != OK:
		return {"status": "io_error", "error": error}
	return {"status": "ok", "data": next, "recovered": current.get("recovered", false)}

func archive_slot(slot_id:String,revision:int) -> Dictionary:
	if not State.valid_slot(slot_id):return {"status":"invalid_slot"}
	var current:=load_slot(slot_id)
	if current.status!="ok":return current
	if int(current.data.revision)!=revision:return {"status":"stale"}
	var folder:=directory.path_join("removed").path_join(slot_id+"-"+State.new_id())
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:return {"status":"io_error"}
	var moved:Array[String]=[]
	for suffix in ["",".bak"]:
		var source:String=_path(slot_id)+suffix
		if not FileAccess.file_exists(source):continue
		if DirAccess.rename_absolute(source,folder.path_join(slot_id+".json"+suffix))!=OK:
			for done in moved:DirAccess.rename_absolute(folder.path_join(slot_id+".json"+done),_path(slot_id)+done)
			return {"status":"io_error"}
		moved.append(suffix)
	return {"status":"ok","archive":folder,"slotId":slot_id}
func restore_slot(receipt:Dictionary) -> Dictionary:
	var id:String=receipt.get("slotId","")
	var folder:String=receipt.get("archive","")
	if not State.valid_slot(id) or folder.get_base_dir()!=directory.path_join("removed") or not folder.get_file().begins_with(id+"-"):return {"status":"invalid_slot"}
	var recovered := _recover_archives()
	if recovered != "ok": return {"status":recovered}
	if FileAccess.file_exists(folder.path_join("campaign.json")): return CampaignArchive.new(self).restore(receipt)
	if FileAccess.file_exists(_path(id)) or FileAccess.file_exists(_path(id)+".bak"):return {"status":"occupied"}
	var copied:Array[String]=[]
	for suffix in ["",".bak"]:
		var source:=folder.path_join(id+".json"+suffix)
		if not FileAccess.file_exists(source):continue
		if DirAccess.copy_absolute(source,_path(id)+suffix)!=OK:
			for done in copied:DirAccess.remove_absolute(_path(id)+done)
			return {"status":"io_error"}
		copied.append(suffix)
	return load_slot(id)
func latest_removed() -> Dictionary:
	if _recover_archives() != "ok": return {}
	var parent:=directory.path_join("removed")
	if not DirAccess.dir_exists_absolute(parent):return {}
	var chosen:Dictionary={}
	var newest:=0
	for folder in DirAccess.get_directories_at(parent):
		if folder.contains("-campaign-") and not FileAccess.file_exists(parent.path_join(folder).path_join("campaign.json")): continue
		if FileAccess.file_exists(parent.path_join(folder).path_join("restored.json")): continue
		var id:=folder.left(6)
		if not State.valid_slot(id) or not folder.begins_with(id+"-"):continue
		if FileAccess.file_exists(_path(id)) or FileAccess.file_exists(_path(id)+".bak"):continue
		if FileAccess.file_exists(parent.path_join(folder).path_join("campaign.json")) and not CampaignArchive.new(self).available(parent.path_join(folder)): continue
		var path:=parent.path_join(folder).path_join(id+".json")
		if _read(path,id).status != "ok": path += ".bak"
		var modified:=FileAccess.get_modified_time(path)
		if modified>=newest and _read(path,id).status=="ok":
			newest=modified
			chosen={"archive":parent.path_join(folder),"slotId":id}
	return chosen
