extends Node2D
## Small readable prop, attached to Tyler's overworld visual and its terrain height.
func _draw()->void:
	draw_circle(Vector2.ZERO,7,Color("33242d"))
	draw_circle(Vector2.ZERO,5.5,Color("c79e58"))
	draw_arc(Vector2.ZERO,3.2,0,TAU,16,Color("724c39"),1.4)
	draw_line(Vector2(-4,2),Vector2(5,-3),Color("e8e0c8"),2)
	draw_line(Vector2(1,-1),Vector2(4,-3),Color("75aaa3"),2.5)
