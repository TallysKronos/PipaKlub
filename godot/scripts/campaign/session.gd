extends Node
## Scenes work on copies; publish state only after successful disk commit.
signal changed(snapshot: Dictionary)
signal storage_failed(status: String)
signal backup_recovered
signal saving_started
signal saving_finished(status: String)

const Store = preload("res://scripts/campaign/save_store.gd")
var _store := Store.new()
var _snapshot: Dictionary = {}
var _unsaved_play_seconds:=0.0
## Enabled by the player-facing frontend; old tooling keeps its direct-slot contract.
var separate_autosave := false
var autosave_enabled := true
var _auto_revision := -1
var has_unpersisted_changes := false
func _process(delta:float) -> void:
	if not _snapshot.is_empty():_unsaved_play_seconds+=maxf(0,delta)
func _with_play_time(value:Dictionary) -> Dictionary:
	if not value.has("playSeconds"):value.playTimePartial=true
	value.playSeconds=float(value.get("playSeconds",0))+_unsaved_play_seconds
	return value

func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

func start(slot_id: String) -> Dictionary:
	if slot_id == "slot-0": return {"status":"invalid_slot"}
	if separate_autosave: saving_started.emit()
	var result := _accept(_store.create_slot(slot_id))
	_prepare_autosave()
	if separate_autosave: saving_finished.emit(str(result.status))
	return result

func resume_slot(slot_id: String) -> Dictionary:
	var result := _accept(_store.load_slot(slot_id))
	_prepare_autosave()
	return result

func _prepare_autosave() -> void:
	if not separate_autosave or _snapshot.is_empty(): return
	if not _snapshot.has("campaignId"): _snapshot.campaignId = preload("res://scripts/campaign/state.gd").new_id()
	if not _snapshot.has("originSlotId"): _snapshot.originSlotId = _snapshot.slotId
	var automatic := _store.load_slot("slot-0")
	_auto_revision = int(automatic.data.revision) if automatic.status == "ok" else -1

func _persist(next: Dictionary) -> Dictionary:
	if not separate_autosave: return _accept(_store.save_slot(next))
	if not autosave_enabled:
		var changed_state: bool = next.checkpoint != _snapshot.checkpoint or next.player != _snapshot.player
		return _accept({"status":"ok", "data":next, "persisted":not (has_unpersisted_changes or changed_state)})
	saving_started.emit()
	var result := _store.copy_to_slot(next, "slot-0", _auto_revision)
	if result.status == "ok": _auto_revision = int(result.data.revision)
	var accepted := _accept(result)
	saving_finished.emit(str(result.status))
	return accepted

func save_manual(slot_id: String, expected_revision: int) -> Dictionary:
	if _snapshot.is_empty(): return {"status":"no_session"}
	if slot_id == "slot-0": return {"status":"invalid_slot"}
	saving_started.emit()
	var result := _store.copy_to_slot(_with_play_time(snapshot()), slot_id, expected_revision)
	if result.status == "ok":
		_snapshot.playSeconds = result.data.playSeconds
		_unsaved_play_seconds = 0
		has_unpersisted_changes = false
	else: storage_failed.emit(str(result.status))
	saving_finished.emit(str(result.status))
	return result

func inspect_slot(slot_id: String) -> Dictionary:
	return _store.load_slot(slot_id)

func checkpoint(checkpoint_data: Dictionary, player_data: Dictionary) -> Dictionary:
	if _snapshot.is_empty():
		return _accept({"status": "no_session"})
	var next := snapshot()
	next.checkpoint = checkpoint_data.duplicate(true)
	next.player = player_data.duplicate(true)
	# Receipts may only be added through commit_operation, never removed by a scene.
	next.player.completedOperations = _snapshot.player.completedOperations.duplicate()
	return _persist(_with_play_time(next))

func commit_operation(operation_id: String, checkpoint_data: Dictionary, player_data: Dictionary) -> Dictionary:
	if _snapshot.is_empty():
		return _accept({"status": "no_session"})
	if operation_id.is_empty() or operation_id.length() > 128:
		return _accept({"status": "invalid_operation"})
	if operation_id in _snapshot.player.completedOperations:
		return {"status": "already_applied", "data": snapshot()}
	var next := snapshot()
	next.checkpoint = checkpoint_data.duplicate(true)
	next.player = player_data.duplicate(true)
	next.player.completedOperations = _snapshot.player.completedOperations.duplicate()
	next.player.completedOperations.append(operation_id)
	# Reward and receipt share one snapshot, so a restarted caller can reuse its ID.
	return _persist(_with_play_time(next))

func close_session() -> void:
	_snapshot.clear()
	_unsaved_play_seconds=0
	has_unpersisted_changes = false
	changed.emit({})

func _accept(result: Dictionary) -> Dictionary:
	if result.status == "ok":
		_snapshot = result.data.duplicate(true)
		has_unpersisted_changes = not result.get("persisted", true)
		_unsaved_play_seconds=0
		changed.emit(snapshot())
		if result.get("recovered", false):
			backup_recovered.emit()
	else:
		storage_failed.emit(str(result.status))
	return result.duplicate(true)
