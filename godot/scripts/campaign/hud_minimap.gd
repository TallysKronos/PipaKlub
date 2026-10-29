extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
## Local, schematic map. No NPC, chest or exit markers; discovery remains in the world.
const Hud = preload("res://scripts/campaign/hud.gd")
var subject: Node2D
var floors: Array[PackedVector2Array] = []
var timer := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1
	anchor_right = 1
	offset_left = -180
	offset_right = -20
	offset_top = 20
	offset_bottom = 180
	if subject.get("ground") != null:
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
	var diamond := PackedVector2Array([Vector2(center.x, 5), Vector2(size.x - 5, center.y), Vector2(center.x, size.y-5), Vector2(5, center.y)])
	# Approved board: paper diamond with an ink contour and solid shadow; terrain as ink tint.
	var shadow := PackedVector2Array()
	for point in diamond: shadow.append(point+Vector2(4,5))
	draw_colored_polygon(shadow, Tokens.NANQUIM)
	draw_colored_polygon(diamond, Tokens.PAPEL)
	var origin: Vector2 = subject.get("player") if subject.get("player")!=null else subject.actor
	var projected := subject.has_method("project")
	if projected: origin = subject.project(origin)
	for floor_polygon in floors:
		var local := PackedVector2Array()
		for point in floor_polygon:
			var position: Vector2 = subject.project(point) if projected else point
			local.append(center + (position - origin) * .17)
		for clipped in Geometry2D.intersect_polygons(local, diamond): draw_colored_polygon(clipped, Tokens.alpha(Tokens.TINTA_3,.45))
	var outline := diamond.duplicate()
	outline.append(diamond[0])
	draw_polyline(outline, Tokens.NANQUIM, 5, true)
	var player := PackedVector2Array([center + Vector2(0, -7), center + Vector2(7, 0), center + Vector2(0, 7), center + Vector2(-7, 0)])
	draw_colored_polygon(player, Tokens.CEU)
	player.append(player[0])
	draw_polyline(player, Tokens.NANQUIM, 2, true)
	var north := "N"
	var width := Tokens.label().get_string_size(north,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
	draw_string(Tokens.label(),Vector2(center.x-width/2,26),north,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Tokens.RABIOLA)
