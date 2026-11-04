extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
## Fixed-size kite pin, deliberately outside the stretchable panel surface.
var ink := Tokens.NANQUIM
var paper := Tokens.PAPEL
var accent := Tokens.RABIOLA
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(20, 28)
	resized.connect(queue_redraw)
func _draw() -> void:
	var points := PackedVector2Array([Vector2(10, 1), Vector2(19, 10), Vector2(10, 23), Vector2(1, 10)])
	var shadow := PackedVector2Array()
	for point in points: shadow.append(point + Vector2(2, 3))
	draw_colored_polygon(shadow, Color(ink, .8))
	draw_colored_polygon(points, accent)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), ink, 2, true)
	draw_line(Vector2(10, 3), Vector2(10, 21), ink, 1.5, true)
	draw_line(Vector2(3, 10), Vector2(17, 10), ink, 1.5, true)
	draw_line(Vector2(10, 23), Vector2(13, 27), paper, 2, true)
