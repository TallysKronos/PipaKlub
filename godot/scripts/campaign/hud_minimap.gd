extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
## Local, schematic map. No NPC, chest or exit markers; discovery remains in the world.
const Hud = preload("res://scripts/campaign/hud.gd")
var subject: Node2D
var floors: Array[PackedVector2Array] = []
var last_position := Vector2.INF
var heading := Vector2.UP
var timer := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1
	anchor_right = 1
	offset_left = -180
	offset_right = -20
	offset_top = 20
	offset_bottom = 180
	if subject.has_method("map_polygons"):
		floors.assign(subject.map_polygons())
	elif subject.get("ground") != null:
		floors.assign(subject.ground.floors)
	else:
		for rect in subject.data.walkable:
			var bounds:=Rect2(rect[0],rect[1],rect[2],rect[3]) if rect is Array else Rect2(rect.x,rect.y,rect.w,rect.h)
			floors.append(PackedVector2Array([bounds.position,bounds.position+Vector2(bounds.size.x,0),bounds.end,bounds.position+Vector2(0,bounds.size.y)]))
func _process(delta: float) -> void:
	timer += delta
	if timer >= .1:
		timer = 0
		queue_redraw()
func _draw() -> void:
	if not is_instance_valid(subject): return
	var center := size/2
	var field:=Rect2(Vector2(2,2),size-Vector2(4,4))
	var boundary:=preload("res://scripts/campaign/exploration_frame.gd").outline(field,14)
	draw_colored_polygon(boundary,Tokens.LOBBY_SHADOW)
	var origin: Vector2 = subject.get("player") if subject.get("player")!=null else subject.actor
	var projection:=Callable(subject,"minimap_point") if subject.has_method("minimap_point") else Callable(subject,"project")
	if projection.is_valid(): origin = projection.call(origin)
	if last_position.is_finite():
		var travel:=origin-last_position
		if travel.length_squared()>.04:heading=travel.normalized()
	last_position=origin
	for floor_polygon in floors:
		var local := PackedVector2Array()
		for point in floor_polygon:
			var position: Vector2 = projection.call(point) if projection.is_valid() else point
			local.append(center + (position - origin) * .17)
		for clipped in Geometry2D.intersect_polygons(local, boundary):
			# Clipping a floor at the diamond's corner can leave a sliver that cannot be drawn.
			if Geometry2D.triangulate_polygon(clipped).is_empty(): continue
			draw_colored_polygon(clipped, Tokens.LOBBY_INSET_EDGE)
	boundary.append(boundary[0])
	draw_polyline(boundary,Tokens.LOBBY_STRIP_LINE,2,true)
	draw_circle(center,9,Tokens.LOBBY_SHADOW,true,-1,true)
	var side:=heading.orthogonal()
	draw_colored_polygon(PackedVector2Array([center+heading*8,center-heading*5+side*5,center-heading*2,center-heading*5-side*5]),Tokens.CEU)
	draw_line(Vector2(center.x-5,3),Vector2(center.x+5,3),Tokens.PAPEL,2,true)
