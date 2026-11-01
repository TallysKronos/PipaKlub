extends SceneTree
var Front: GDScript
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
var front: Control
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ", message)
func _initialize() -> void:
	call_deferred("run_checks")
func settle() -> void:
	for frame in 6: await process_frame
func escape() -> void:
	for down in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_ESCAPE
		key.keycode = KEY_ESCAPE
		key.pressed = down
		root.push_input(key, true)
func run_checks() -> void:
	Front=load("res://scripts/campaign/front_end.gd")
	front = Front.new()
	var test_root: String=OS.get_environment("PIPA_TEST_ROOT")
	var storage: String=(test_root.path_join("player-flow-") if not test_root.is_empty() else "user://player-flow-")+State.new_id()
	front.session._store = Store.new(storage)
	front.preferences.storage_path = storage+"-settings.cfg"
	root.add_child(front)
	front.preferences.reduced_motion = true
	Fixtures.show(front, "lesson-0")
	await settle()
	var practice: Control = front._practice_view()
	front._pause_game()
	var before: float = practice.model.time
	practice._process(.2)
	check(practice.paused and practice.model.time == before, "pause actually stops tutorial simulation")
	front._resume_game()
	practice._process(.1)
	check(not practice.paused and practice.model.time > before, "tutorial resumes without resetting lesson")
	practice.set_process(false)
	front._show_bag()
	await settle()
	escape()
	await settle()
	check(is_instance_valid(front._practice_view()) and not is_instance_valid(front.pause_overlay), "Escape from bag returns to game, not another pause over the bag")
	Fixtures.show(front, "settings")
	await settle()
	escape()
	await settle()
	check(front.last_scene_key == "menu", "Escape from title settings returns to title")
	Fixtures.show(front, "controls")
	await settle()
	escape()
	await settle()
	check(front.last_scene_key == "page:Configurações", "Escape from bindings returns one level to settings")
	Fixtures.show(front, "opening-10")
	await settle()
	var edit: LineEdit = front.name_input
	var color := edit.get_theme_color("font_placeholder_color")
	var background: Color = (edit.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	var foreground_linear := color.srgb_to_linear()
	var background_linear := background.srgb_to_linear()
	var foreground_luminance := .2126 * foreground_linear.r + .7152 * foreground_linear.g + .0722 * foreground_linear.b
	var background_luminance := .2126 * background_linear.r + .7152 * background_linear.g + .0722 * background_linear.b
	var contrast := (maxf(foreground_luminance,background_luminance)+.05)/(minf(foreground_luminance,background_luminance)+.05)
	check(contrast >= 4.5, "name placeholder maintains 4.5:1 contrast against its actual Theme background")
	Fixtures.show(front, "won")
	await settle()
	var button: Button = front.battle.finish_button
	var parent := button.get_parent()
	var rect := button.get_global_rect()
	var visible := rect.intersection(root.get_visible_rect())
	while parent != null:
		if parent is Control and parent.clip_contents: visible = visible.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	check(visible.size.y >= rect.size.y - 1, "result footer keeps continue outside clipping")
	front.free()
	print("PLAYER FLOW: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
