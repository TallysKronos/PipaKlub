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
	offset_top = 88
	offset_bottom = 280
	if subject.get("ground") != null:
		floors.assign(subject.ground.floors)
	else:
		for rect in subject.data.walkable:
			floors.append(PackedVector2Array([Vector2(rect.x, rect.y), Vector2(rect.x + rect.w, rect.y), Vector2(rect.x + rect.w, rect.y + rect.h), Vector2(rect.x, rect.y + rect.h)]))
func _process(delta: float) -> void:
	timer += delta
	if timer >= .1:
		timer = 0
		queue_redraw()
func _draw() -> void:
	if not is_instance_valid(subject): return
	var center := Vector2(size.x / 2, 80)
	var diamond := PackedVector2Array([Vector2(center.x, 5), Vector2(size.x - 5, center.y), Vector2(center.x, 155), Vector2(5, center.y)])
	draw_colored_polygon(diamond, Tokens.TINTA)
	var origin: Vector2 = subject.player
	var projected := subject.has_method("project")
	if projected: origin = subject.project(origin)
	for floor_polygon in floors:
		var local := PackedVector2Array()
		for point in floor_polygon:
			var position: Vector2 = subject.project(point) if projected else point
			local.append(center + (position - origin) * .17)
		for clipped in Geometry2D.intersect_polygons(local, diamond): draw_colored_polygon(clipped, Tokens.PAPEL_2)
	var outline := diamond.duplicate()
	outline.append(diamond[0])
	draw_polyline(outline, Hud.PAPER, 3, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -9), center + Vector2(7, 7), center + Vector2(0, 3), center + Vector2(-7, 7)]), Hud.CYAN)
	draw_string(Hud.font(true), Vector2(center.x - 5, 20), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Hud.CORAL)
	draw_style_box(Hud.flat_panel(), Rect2(0, 164, size.x, 28))
	draw_string(Hud.font(true), Vector2(15, 184), "▲ Você · caminhos", HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 16, Hud.PAPER)
