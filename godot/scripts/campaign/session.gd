extends Node
## Scenes work on copies; publish state only after successful disk commit.
signal changed(snapshot: Dictionary)
signal storage_failed(status: String)
signal backup_recovered

const Store = preload("res://scripts/campaign/save_store.gd")
var _store := Store.new()
var _snapshot: Dictionary = {}
var _unsaved_play_seconds:=0.0
func _process(delta:float) -> void:
	if not _snapshot.is_empty():_unsaved_play_seconds+=maxf(0,delta)
func _with_play_time(value:Dictionary) -> Dictionary:
	if not value.has("playSeconds"):value.playTimePartial=true
	value.playSeconds=float(value.get("playSeconds",0))+_unsaved_play_seconds
	return value

func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

func start(slot_id: String) -> Dictionary:
	return _accept(_store.create_slot(slot_id))

func resume_slot(slot_id: String) -> Dictionary:
	return _accept(_store.load_slot(slot_id))

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
	return _accept(_store.save_slot(_with_play_time(next)))

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
	return _accept(_store.save_slot(_with_play_time(next)))

func close_session() -> void:
	_snapshot.clear()
	_unsaved_play_seconds=0
	changed.emit({})

func _accept(result: Dictionary) -> Dictionary:
	if result.status == "ok":
		_snapshot = result.data.duplicate(true)
		_unsaved_play_seconds=0
		changed.emit(snapshot())
		if result.get("recovered", false):
			backup_recovered.emit()
	else:
		storage_failed.emit(str(result.status))
	return result.duplicate(true)
