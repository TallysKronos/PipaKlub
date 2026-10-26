extends SceneTree
const Controls = preload("res://scripts/campaign/controls.gd")
const Preferences = preload("res://scripts/campaign/preferences.gd")
const State = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	Controls.install()
	check(Controls.validate(Controls.DEFAULTS), "defaults valid")
	check(Controls.conflict("cut", KEY_Q) == "skill", "detect conflicting action")
	check(Controls.conflict("cut", KEY_ESCAPE) == "reserved", "reserve escape")
	check(Controls.conflict("cut", KEY_ENTER) == "reserved", "reserve confirm")
	var changed := Controls.DEFAULTS.duplicate()
	changed.cut = KEY_T
	Controls.install(changed)
	key(KEY_SPACE, true)
	await process_frame
	check(not Controls.held("cut"), "old key no longer attacks")
	key(KEY_SPACE, false)
	key(KEY_T, true)
	await process_frame
	check(Controls.held("cut"), "rebound key attacks")
	check(Controls.prompt("cut") == "T", "prompt follows remap")
	key(KEY_T, false)
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_X
	button.pressed = true
	Controls.observe(button)
	Input.parse_input_event(button)
	await process_frame
	check(Controls.held("cut"), "simulated pad attacks after keyboard remap")
	check(Controls.prompt("cut") == "X / □", "pad prompt switches")
	button.pressed = false
	Input.parse_input_event(button)
	var axis := InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = .1
	Input.parse_input_event(axis)
	await process_frame
	check(Controls.direction().length() == 0, "deadzone ignores slight drift")
	axis.axis_value = .8
	Input.parse_input_event(axis)
	await process_frame
	check(Controls.direction().x > .5, "analog moves beyond deadzone")
	axis.axis_value = 0
	Input.parse_input_event(axis)
	key(KEY_RIGHT, true)
	await process_frame
	check(Controls.direction().x > .9, "arrows remain available")
	key(KEY_RIGHT, false)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	check(Controls.pressed(event, "interact"), "interact edge recognized")
	event.echo = true
	check(not Controls.pressed(event, "interact"), "key repeats do not double interact")
	var directory := "user://controls-checks-" + State.new_id()
	DirAccess.make_dir_recursive_absolute(directory)
	var prefs := Preferences.new()
	prefs.bindings = changed
	check(prefs.save_settings(directory.path_join("settings.cfg")) == OK, "persist isolated bindings")
	var loaded := Preferences.new()
	loaded.load_settings(directory.path_join("settings.cfg"))
	check(loaded.bindings.cut == KEY_T, "reload preserves remap")
	var invalid := changed.duplicate()
	invalid.guard = KEY_T
	check(not Controls.validate(invalid), "duplicate saved key rejected")
	Controls.install(invalid)
	check(Controls.bindings == Controls.DEFAULTS, "invalid config falls back to usable defaults")
	var config := ConfigFile.new()
	config.set_value("controls", "keys", invalid)
	config.save(directory.path_join("invalid.cfg"))
	loaded.load_settings(directory.path_join("invalid.cfg"))
	check(loaded.bindings == Controls.DEFAULTS, "corrupt persisted mapping repaired in memory")
	Controls.install()
	Controls.gamepad = false
	print("CONTROLS CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
