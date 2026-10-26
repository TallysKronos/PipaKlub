extends Control
## 450ms ink reveal on a separate CanvasLayer, with no input or simulation ownership.
const Hud = preload("res://scripts/campaign/hud.gd")
var progress := 0.0
var reduced_motion := false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	var tween := create_tween()
	tween.tween_method(func(value: float):
		progress = value
		queue_redraw(), 0.0, 1.0, .12 if reduced_motion else .45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(get_parent().queue_free)
func _draw() -> void:
	if reduced_motion:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Hud.INK, (1 - progress) * .5))
		return
	var extent := size.x * 1.3
	var edge := lerpf(size.x + size.y * .25 + 20, -256, progress)
	draw_colored_polygon(PackedVector2Array([Vector2(-extent, 0), Vector2(edge, 0), Vector2(edge - size.y * .21, size.y), Vector2(-extent, size.y)]), Hud.INK)
	var splat := Hud.artwork("splat")
	for index in 4:
		var y := size.y * (.12 + .23 * index)
		var width := minf(210, size.x * .16)
		draw_texture_rect(splat, Rect2(edge - y * .21 - width * .68, y - width * .35, width, width * .75), false, Hud.INK)
