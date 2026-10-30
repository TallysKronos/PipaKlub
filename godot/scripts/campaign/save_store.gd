extends RefCounted
## Single-process local store. Backups cover interrupted replacement on Windows.
## Does not promise fsync/power-loss durability or online certification.
const State = preload("res://scripts/campaign/state.gd")
const DIRECTORY := "user://campaign"
const MAX_BYTES := 8 * 1024 * 1024
var directory: String

func _init(storage_directory: String = DIRECTORY) -> void:
	directory = storage_directory

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
	if FileAccess.file_exists(_path(slot_id)) or FileAccess.file_exists(_path(slot_id) + ".bak"):
		return {"status": "occupied"}
	return _save(State.fresh(slot_id), true)

func save_slot(snapshot: Dictionary) -> Dictionary:
	return _save(snapshot, false)

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
			error = DirAccess.copy_absolute(path, damaged)
			if error != OK:
				return {"status": "io_error", "error": error}
	elif not creating:
		error = _write_checked(path + ".bak.tmp", current.data)
		if error == OK:
			error = DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak")
		if error != OK:
			return {"status": "io_error", "error": error}
	error = DirAccess.rename_absolute(path + ".tmp", path)
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
	var parent:=directory.path_join("removed")
	if not DirAccess.dir_exists_absolute(parent):return {}
	var chosen:Dictionary={}
	var newest:=0
	for folder in DirAccess.get_directories_at(parent):
		var id:=folder.left(6)
		if not State.valid_slot(id) or not folder.begins_with(id+"-") or load_slot(id).status!="missing":continue
		var path:=parent.path_join(folder).path_join(id+".json")
		var modified:=FileAccess.get_modified_time(path)
		if modified>=newest and _read(path,id).status=="ok":
			newest=modified
			chosen={"archive":parent.path_join(folder),"slotId":id}
	return chosen
