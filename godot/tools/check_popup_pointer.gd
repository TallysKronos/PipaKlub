extends SceneTree
func _initialize() -> void:
	call_deferred("run_check")
func run_check() -> void:
	root.size = Vector2i(1270, 710)
	var popup := ConfirmationDialog.new()
	popup.dialog_text = "Verificação isolada de clique no popup."
	popup.dialog_hide_on_ok = false
	root.add_child(popup)
	popup.popup_centered(Vector2i(620, 200))
	for frame in 6: await process_frame
	var button := popup.get_ok_button()
	print("RECT ", button.get_global_rect(), " popupPos ", popup.position, " canvas ", button.get_global_transform_with_canvas(), " viewport ", button.get_viewport().get_visible_rect())
	button.pressed.connect(func(): print("CLICK RECEIVED"))
	for offset in [Vector2.ZERO, -Vector2(popup.position), Vector2(popup.position)]:
		print("TRY ", offset)
		var motion := InputEventMouseMotion.new()
		motion.position = button.get_global_rect().get_center() + offset
		popup.push_input(motion, true)
		print("HOVER ", popup.gui_get_hovered_control(), " disabled ", popup.gui_disable_input, " id ", popup.get_window_id())
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center() + offset
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			popup.push_input(event, true)
		await process_frame
	print("TRY ROOT WINDOW INPUT")
	var center := Vector2(popup.position) + button.get_global_rect().get_center()
	var root_motion := InputEventMouseMotion.new()
	root_motion.position = center
	root_motion.global_position = center
	Input.parse_input_event(root_motion)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = center
		click.global_position = center
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		Input.parse_input_event(click)
	Input.flush_buffered_events()
	await process_frame
	print("TRY KEY")
	button.grab_focus()
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_ENTER
		event.keycode = KEY_ENTER
		event.pressed = down
		popup.push_input(event, true)
	quit()
