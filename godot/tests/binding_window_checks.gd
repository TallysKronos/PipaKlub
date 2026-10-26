extends SceneTree
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
func _initialize() -> void:
	call_deferred("run_check")
func run_check() -> void:
	var front := Front.new()
	front.preferences.storage_path = "user://binding-window-" + State.new_id() + ".cfg"
	root.add_child(front)
	front._show_controls()
	for frame in 5: await process_frame
	front._capture_binding("cut")
	for frame in 5: await process_frame
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_T
		event.keycode = KEY_T
		event.pressed = down
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	for frame in 5: await process_frame
	var success: bool = front.preferences.bindings.cut == KEY_T and front.binding_target.is_empty()
	print("BINDING WINDOW: ", "PASS" if success else "FAIL", " cut=", front.preferences.bindings.cut)
	front.free()
	quit(0 if success else 1)
