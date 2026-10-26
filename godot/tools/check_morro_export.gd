extends SceneTree
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const Model = preload("res://scripts/campaign/morro_model.gd")
func _initialize() -> void:
	call_deferred("run_check")
func run_check() -> void:
	var front := Front.new()
	root.add_child(front)
	await process_frame
	var saved := State.fresh("slot-1")
	saved.player.partners = [{"id": "pack-review", "modelId": "basica", "xp": 0}]
	saved.player.equippedPartnerId = "pack-review"
	saved.player.journey = {"phase": "complete", "lesson": 5}
	for scene in Morro.maps():
		saved.checkpoint = {"kind": "world", "scene": scene, "position": Morro.maps()[scene].spawn}
		front.session._snapshot = saved
		front._show_saved()
		await process_frame
		print("PACK MAP: ", front.park.data.name)
	var model := Model.new(saved.player.partners[0], "morro-3")
	saved.checkpoint = {"kind": "encounter"}
	saved.player.encounter = {"kind": "morro", "state": model.snapshot()}
	front.session._snapshot = saved
	front._show_saved()
	await process_frame
	print("PACK FIGHTERS: ", front.battle.model.actors.size())
	front.free()
	quit()
