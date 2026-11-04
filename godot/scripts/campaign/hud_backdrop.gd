extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
## Decorative print layers only; never part of the content layout or input tree.
const Hud = preload("res://scripts/campaign/hud.gd")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_colored_polygon(PackedVector2Array([Vector2(w * .68, 0), Vector2(w, 0), Vector2(w, h), Vector2(w * .92, h), Vector2(w * .53, h * .22)]), Tokens.alpha(Tokens.PAPEL, .03))
	draw_colored_polygon(PackedVector2Array([Vector2(w * .82, 0), Vector2(w * .86, 0), Vector2(w * .47, h), Vector2(w * .43, h)]), Tokens.alpha(Tokens.RABIOLA, .03))
	var center := Vector2(w * .91, h * .24)
	var points := PackedVector2Array([center + Vector2(0, -84), center + Vector2(60, -16), center + Vector2(0, 100), center + Vector2(-60, -16), center + Vector2(0, -84)])
	draw_polyline(points, Tokens.alpha(Tokens.RABIOLA, .12), 3, true)
	draw_line(center + Vector2(0, -84), center + Vector2(0, 100), Tokens.alpha(Tokens.RABIOLA, .12), 2, true)
	draw_polyline(PackedVector2Array([center + Vector2(0, 100), center + Vector2(-20, 143), center + Vector2(5, 171), center + Vector2(-18, 204)]), Tokens.alpha(Tokens.RABIOLA, .12), 2, true)
	# Printed halftone stays at a stable pixel pitch, never stretched with a card.
	for x in range(0, int(w), 12):
		for y in range(0, int(h), 12):
			if x > w * .73 + y * .16:
				draw_circle(Vector2(x, y), 1.2, Tokens.alpha(Tokens.PAPEL, .04))
