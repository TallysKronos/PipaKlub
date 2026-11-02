extends Control
## Real level milestones; these are not invented evolution forms or unlocks.
const T=preload("res://scripts/campaign/ui_tokens.gd")
var level:=1
var text_scale:=1.0
func _ready() -> void:custom_minimum_size.y=100*text_scale;resized.connect(queue_redraw)
func _draw() -> void:
	var levels:Array[int]=[]
	for value in [1,level,mini(level+1,50),50]:
		if value not in levels:levels.append(value)
	var y:=26.0
	var first:=44.0;var last:=size.x-44
	draw_line(Vector2(first,y),Vector2(last,y),T.MURAL_MUTED,3,true)
	for index in levels.size():
		var center:=Vector2(lerpf(first,last,float(index)/maxi(1,levels.size()-1)),y)
		var active:bool=levels[index]==level
		var color:=T.MURAL_SUN if active else T.MURAL_TEAL if levels[index]<level else T.MURAL_PAPER
		var shape:=PackedVector2Array([center+Vector2(0,-14),center+Vector2(12,0),center+Vector2(0,18),center+Vector2(-12,0)])
		draw_colored_polygon(shape,color);shape.append(shape[0]);draw_polyline(shape,T.MURAL_INK,2,true)
		var label:="Nv. %d"%levels[index];var font:=roundi(18*text_scale);var width:=T.label().get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font).x
		draw_string(T.label(),center+Vector2(-width/2,44*text_scale),label,HORIZONTAL_ALIGNMENT_LEFT,-1,font,T.MURAL_INK)
