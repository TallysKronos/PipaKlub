extends Control
const Hud=preload("res://scripts/campaign/hud.gd")
var polygons:Array[PackedVector2Array]=[]
var regions:Array[Dictionary]=[]
var landmarks:Array[Dictionary]=[]
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
	for region in regions:
		for point in region.polygon:bounds=bounds.expand(point)
	var factor:=minf((size.x-64)/maxf(bounds.size.x,1),(size.y-64)/maxf(bounds.size.y,1))
	var offset:=size/2-bounds.get_center()*factor
	draw_rect(Rect2(Vector2.ZERO,size),Hud.INK)
	draw_rect(Rect2(Vector2.ONE*2,size-Vector2.ONE*4),Hud.CYAN,false,2)
	var fills: Array=regions if not regions.is_empty() else polygons.map(func(p):return {"polygon":p,"color":Hud.MUTED})
	for region in fills:
		var points:=PackedVector2Array()
		for point in region.polygon:points.append(offset+point*factor)
		if points.size()<3:continue
		draw_colored_polygon(points,region.color)
		if regions.is_empty():
			points.append(points[0])
			draw_polyline(points,Hud.PAPER,2,true)
	for marker in landmarks:
		var at: Vector2=offset+marker.point*factor
		draw_circle(at,5,Hud.GOLD)
		var label_size:=Hud.font().get_string_size(marker.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
		var label_at:=at+Vector2(9,-9)
		label_at.x=clampf(label_at.x,12,size.x-label_size.x-12)
		label_at.y=clampf(label_at.y,24,size.y-12)
		draw_rect(Rect2(label_at-Vector2(4,17),label_size+Vector2(8,4)),Hud.INK)
		draw_string(Hud.font(),label_at,marker.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Hud.PAPER)
	var position:=offset+player*factor
	draw_circle(position,15,Hud.INK)
	draw_colored_polygon(PackedVector2Array([position+Vector2(0,-12),position+Vector2(9,9),position+Vector2(0,4),position+Vector2(-9,9)]),Hud.CYAN)
