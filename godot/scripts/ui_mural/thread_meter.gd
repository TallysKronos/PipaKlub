extends Control
const T=preload("res://scripts/campaign/ui_tokens.gd")
var value:=100.0
var maximum:=100.0
var color:=T.MURAL_MINT
func _ready() -> void:custom_minimum_size.y=18;resized.connect(queue_redraw)
func _draw() -> void:
	var left:=Vector2(7,size.y/2);var right:=Vector2(size.x-7,size.y/2)
	draw_line(left,right,T.alpha(T.MURAL_PAPER,.22),5,true)
	var end:=left.lerp(right,clampf(value/maxf(1,maximum),0,1))
	draw_line(left,end,T.MURAL_INK,8,true);draw_line(left,end,color,4,true)
	for fraction in [.25,.5,.75]:
		var point:=left.lerp(right,fraction)
		if point.x<=end.x:
			draw_line(point+Vector2(-3,-5),point+Vector2(3,5),T.MURAL_INK,6,true);draw_line(point+Vector2(-3,-5),point+Vector2(3,5),color,3,true)
	draw_circle(end,5,color);draw_arc(end,5,0,TAU,12,T.MURAL_INK,1.5,true)
