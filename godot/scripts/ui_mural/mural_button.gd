extends Button
## Native Button owns hitbox/input/disabled/pressed; art and focus never animate text.
const Mural = preload("res://scripts/ui_mural/mural_theme.gd")
const T = preload("res://scripts/campaign/ui_tokens.gd")
var icon_id := ""
var variant := "MuralButton"

func _ready() -> void:
	custom_minimum_size = Vector2(264, 82)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = true
	if not icon_id.is_empty(): icon = Mural.icon(icon_id)
	focus_entered.connect(_sync)
	focus_exited.connect(_sync)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	set_available(not disabled)

func set_available(available:bool) -> void:
	disabled=not available
	focus_mode=Control.FOCUS_ALL if available else Control.FOCUS_NONE
	_sync()

func _sync() -> void:
	theme_type_variation = "MuralFocusButton" if has_focus() else variant
	queue_redraw()

func _draw() -> void:
	if disabled or not has_focus(): return
	# A static paper-kite corner distinguishes focus without relying on color.
	var p := Vector2(size.x-18, 15)
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-7),p+Vector2(7,0),p+Vector2(0,9),p+Vector2(-7,0)]),T.MURAL_INK)
	draw_polyline(PackedVector2Array([p+Vector2(0,9),p+Vector2(5,13),p+Vector2(1,17)]),T.MURAL_INK,2,true)
