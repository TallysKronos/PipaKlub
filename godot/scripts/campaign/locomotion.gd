extends RefCounted
## Exploration-only sprint; battle keeps its existing dodge binding.
const Controls = preload("res://scripts/campaign/controls.gd")
const RUN_MULTIPLIER := 1.8
static var toggled := false
static var _input_frame := -1

static func update() -> void:
	var frame := Engine.get_process_frames()
	if frame == _input_frame:return
	_input_frame=frame
	if Controls.gamepad and Input.is_action_just_pressed("campaign_run"):
		toggled=not toggled

static func requested() -> bool:
	return toggled or (not Controls.gamepad and Controls.held("run"))

static func multiplier() -> float:
	return RUN_MULTIPLIER if requested() else 1.0

static func toggle() -> void:
	toggled=not toggled
