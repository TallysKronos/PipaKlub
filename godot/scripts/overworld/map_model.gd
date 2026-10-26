extends RefCounted
## Independent port of overworld-1. Oracle edges are used only by verification.
const DIRS := {"u+": Vector2i(1, 0), "u-": Vector2i(-1, 0), "v+": Vector2i(0, 1), "v-": Vector2i(0, -1)}
const PASSABLE := ["grama", "terra", "mato", "ponte", "piso", "calcada", "asfalto"]
var data: Dictionary = {}
var solid: Dictionary = {}
var graph := AStar2D.new()

func setup(source: Dictionary) -> void:
	data = source
	solid.clear()
	graph.clear()
	for piece in data.pieces:
		if not piece.blocks: continue
		for du in int(piece.fu):
			for dv in int(piece.fv): solid[(int(piece.v) + dv) * int(data.w) + int(piece.u) + du] = true
	for v in int(data.h):
		for u in int(data.w):
			var cell := Vector2i(u, v)
			if walkable(cell): graph.add_point(key(cell), Vector2(u + .5, v + .5))
	for id in graph.get_point_ids():
		var cell := Vector2i(id % int(data.w), id / int(data.w))
		for delta in DIRS.values():
			var next: Vector2i = cell + delta
			if can_step(cell, next): graph.connect_points(id, key(next), false)

func key(cell: Vector2i) -> int:
	return cell.y * int(data.w) + cell.x

func cell_at(cell: Vector2i) -> Dictionary:
	if cell.x < 0 or cell.y < 0 or cell.x >= int(data.w) or cell.y >= int(data.h): return {}
	return data.cells[key(cell)]

func walkable(cell: Vector2i) -> bool:
	var terrain := cell_at(cell)
	return not terrain.is_empty() and terrain.material in PASSABLE and not solid.has(key(cell))

func can_step(a: Vector2i, b: Vector2i) -> bool:
	var delta := b - a
	if absi(delta.x) + absi(delta.y) != 1 or not walkable(a) or not walkable(b): return false
	var ca := cell_at(a)
	var cb := cell_at(b)
	var ra := str(ca.get("ramp", "")) if ca.get("ramp") != null else ""
	var rb := str(cb.get("ramp", "")) if cb.get("ramp") != null else ""
	if not ra.is_empty() and DIRS[ra] == delta: return cb.level == ca.level + 1
	if not rb.is_empty() and DIRS[rb] == -delta: return ca.level == cb.level + 1
	if not ra.is_empty() or not rb.is_empty():
		var direction: Vector2i = DIRS[ra if not ra.is_empty() else rb]
		if direction.x * delta.x + direction.y * delta.y == 0: return ra == rb and ca.level == cb.level
	return ca.level == cb.level

func height_at(point: Vector2) -> float:
	var cell := Vector2i(floori(point.x), floori(point.y))
	var c := cell_at(cell)
	if c.is_empty(): return 0
	if c.get("ramp") == null: return float(c.level)
	var direction: Vector2i = DIRS[c.ramp]
	var f := point - Vector2(cell)
	var rise := f.x if direction.x > 0 else 1.0 - f.x if direction.x < 0 else f.y if direction.y > 0 else 1.0 - f.y
	return float(c.level) + rise

func project(point: Vector2, raised: bool = true) -> Vector2:
	return Vector2((point.x - point.y) * 32.0, (point.x + point.y) * 16.0 - (height_at(point) * 64.0 if raised else 0.0))

func path_to(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := Vector2i(floori(from.x), floori(from.y))
	var b := Vector2i(floori(to.x), floori(to.y))
	if not walkable(a) or not walkable(b): return PackedVector2Array()
	return graph.get_point_path(key(a), key(b))

func clear_segment(a: Vector2, b: Vector2) -> bool:
	var previous := Vector2i(floori(a.x), floori(a.y))
	if not walkable(previous): return false
	for i in range(1, maxi(2, ceili(a.distance_to(b) * 32)) + 1):
		var p := a.lerp(b, float(i) / maxi(2, ceili(a.distance_to(b) * 32)))
		var next := Vector2i(floori(p.x), floori(p.y))
		if previous != next and not can_step(previous, next): return false
		if not walkable(next): return false
		previous = next
	return true
