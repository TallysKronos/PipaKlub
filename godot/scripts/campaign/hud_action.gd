extends Control
const Ink = preload("res://scripts/campaign/battle_ink.gd")
var title := "Cortar"
var lock_reason := ""
var selected := false
var lettering: Font = load("res://assets/campaign/ui-modern/fonts/Bangers-Regular.ttf")
const Hud = preload("res://scripts/campaign/hud.gd")
signal held_changed(held: bool)
var icon_id := "attack"
var key_text := ""
var cooldown := 0.0
var cost := 0
var enough_energy := true
var frame_style: StyleBox
var ripped_style: StyleBoxTexture
func _ready() -> void:
	frame_style = Hud.panel()
	ripped_style = Hud.sliced_panel(load(Ink.ROOT + "card-ripped-v2.svg"), Vector4(30, 24, 30, 24))
	custom_minimum_size = Vector2(105, 132)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _draw() -> void:
	var fill: Color = Ink.COLORS.get(icon_id, Hud.CYAN)
	var active := selected
	var box := Rect2(5, 9, size.x - 13, size.y - 17)
	if active:
		var burst := PackedVector2Array([Vector2(2, 14), Vector2(25, 8), Vector2(17, 1), Vector2(size.x * .44, 7), Vector2(size.x * .53, 1), Vector2(size.x - 19, 8), Vector2(size.x - 2, 1), Vector2(size.x - 8, 35), Vector2(size.x - 1, 29), Vector2(size.x - 7, size.y - 12), Vector2(size.x - 28, size.y - 7), Vector2(size.x - 18, size.y - 1), Vector2(17, size.y - 6), Vector2(1, size.y - 1), Vector2(8, size.y - 38), Vector2(1, size.y - 31)])
		draw_colored_polygon(burst, Color("ff315c"))
		burst.append(burst[0])
		draw_polyline(burst, Ink.WHITE, 4, true)
	ripped_style.modulate_color = fill if enough_energy else fill.darkened(.35)
	draw_style_box(ripped_style, box)
	# Diagonal dry-brush scratches and halftone retain a fixed pitch.
	for x in range(20, int(size.x) - 20, 9):
		for y in range(21, 71, 9):
			if x < size.x * .48: draw_circle(Vector2(x, y), 1.1, Color(0, 0, 0, .15))
	var brush_art := Ink.brush(3)
	draw_texture_rect(brush_art, Hud.fit_texture(brush_art, Rect2(13, 5, minf(150, size.x - 25), 88)), false, Color(1, 1, 1, .17))
	var icon := Ink.icon(icon_id)
	draw_texture_rect(icon, Hud.fit_texture(icon, Rect2((size.x - 57) / 2, 17, 57, 45)), false)
	if active:
		draw_colored_polygon(Ink.shape(Rect2(10, 72, size.x - 26, 22), 5), Color(1, 1, 1, .3))
	var caption := Ink.ellipsis(title.to_upper(), lettering, 24, size.x - 32)
	var text_width := lettering.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(lettering, Vector2((size.x - text_width) / 2, 88), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Ink.BLACK)
	var cost_box := Rect2(size.x / 2 - 39, 96, 78, 26)
	Ink.plate(self, cost_box, Ink.BLACK, Ink.BLACK, 6)
	draw_colored_polygon(PackedVector2Array([Vector2(cost_box.position.x + 20, 100), Vector2(cost_box.position.x + 12, 112), Vector2(cost_box.position.x + 19, 111), Vector2(cost_box.position.x + 16, 121), Vector2(cost_box.position.x + 28, 107), Vector2(cost_box.position.x + 20, 108)]), Color("ffda32"))
	draw_string(Hud.font(true), Vector2(cost_box.position.x + 35, 117), str(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Ink.WHITE)
	var key_width := maxf(30, Hud.font(true).get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 16)
	Ink.plate(self, Rect2(size.x - key_width - 7, 0, key_width, 25), Ink.WHITE, Ink.BLACK, 4)
	draw_string(Hud.font(true), Vector2(size.x - key_width + 1, 18), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Ink.BLACK)
	if cooldown > 0 or not enough_energy or not lock_reason.is_empty():
		var state_box := Rect2(11, 52, size.x - 27, 22)
		Ink.plate(self, state_box, Ink.BLACK, Ink.BLACK, 6)
		var state := lock_reason if not lock_reason.is_empty() else "%.1f s" % cooldown if cooldown > 0 else "SEM ENERGIA"
		var state_width := Hud.font(true).get_string_size(state, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(Hud.font(true), Vector2((size.x - state_width) / 2, 68), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Ink.WHITE)
	if active or has_focus():
		draw_line(Vector2(20, size.y - 5), Vector2(size.x - 20, size.y - 8), Ink.WHITE, 4, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		held_changed.emit(event.pressed)
		accept_event()
	elif event.is_action_pressed("ui_accept") and (event is InputEventJoypadButton or (event is InputEventKey and event.physical_keycode == KEY_ENTER)):
		held_changed.emit(true)
		accept_event()
	elif event.is_action_released("ui_accept") and (event is InputEventJoypadButton or (event is InputEventKey and event.physical_keycode == KEY_ENTER)):
		held_changed.emit(false)
		accept_event()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_MOUSE_EXIT:
		held_changed.emit(false)
