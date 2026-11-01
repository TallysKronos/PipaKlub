extends Range
## Read-only semantic range: line is continuous, hull ribs, energy cells.
const T = preload("res://scripts/campaign/ui_tokens.gd")
var kind := "line"

func _ready() -> void:
	custom_minimum_size = Vector2(100,12)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_changed.connect(func(_value:float):queue_redraw())

func _draw() -> void:
	var fraction := clampf((value-min_value)/maxf(max_value-min_value,.001),0,1)
	var r := Rect2(0,2,size.x,maxf(6,size.y-4))
	draw_rect(r,T.alpha(T.MURAL_INK,.16))
	if kind == "line":
		draw_line(Vector2(0,size.y/2),Vector2(size.x*fraction,size.y/2),T.MURAL_TEAL,5,true)
		draw_circle(Vector2(size.x*fraction,size.y/2),3,T.MURAL_TEAL)
	else:
		for i in 10:
			var x := i*size.x/10
			var color := T.MURAL_INK if kind == "hull" else T.MURAL_TEAL
			if i >= ceili(fraction*10): continue
			if kind == "hull":
				draw_colored_polygon(PackedVector2Array([Vector2(x,2),Vector2(x+size.x/10-2,2),Vector2(x+size.x/10-6,size.y-2),Vector2(x-4,size.y-2)]),color)
			else: draw_rect(Rect2(x,2,size.x/10-3,size.y-4),color)
