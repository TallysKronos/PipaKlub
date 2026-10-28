extends Control
const Hud=preload("res://scripts/campaign/hud.gd")
var polygons:Array[PackedVector2Array]=[]
var player:=Vector2.ZERO
func _ready() -> void:
	custom_minimum_size=Vector2(400,300)
	size_flags_horizontal=SIZE_EXPAND_FILL
	size_flags_vertical=SIZE_EXPAND_FILL
	mouse_filter=MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var bounds:=Rect2(player,Vector2.ONE)
	for polygon in polygons:
		for point in polygon:bounds=bounds.expand(point)
	var factor:=minf((size.x-64)/maxf(bounds.size.x,1),(size.y-64)/maxf(bounds.size.y,1))
	var offset:=size/2-bounds.get_center()*factor
	draw_rect(Rect2(Vector2.ZERO,size),Hud.INK)
	draw_rect(Rect2(Vector2.ONE*2,size-Vector2.ONE*4),Hud.CYAN,false,2)
	for polygon in polygons:
		var points:=PackedVector2Array()
		for point in polygon:points.append(offset+point*factor)
		if points.size()<3:continue
		draw_colored_polygon(points,Hud.MUTED)
		points.append(points[0])
		draw_polyline(points,Hud.PAPER,2,true)
	var position:=offset+player*factor
	draw_circle(position,15,Hud.INK)
	draw_colored_polygon(PackedVector2Array([position+Vector2(0,-12),position+Vector2(9,9),position+Vector2(0,4),position+Vector2(-9,9)]),Hud.CYAN)
