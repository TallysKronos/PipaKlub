extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(24, 36)

func _draw() -> void:
	for index in 3:
		var p := Vector2(1 + index * 3, index * 11)
		var triangle := PackedVector2Array([p,p+Vector2(18,4),p+Vector2(5,12)])
		draw_colored_polygon(triangle,Tokens.RABIOLA)
		triangle.append(triangle[0])
		draw_polyline(triangle,Tokens.NANQUIM,1.5,true)
