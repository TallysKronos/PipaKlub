extends RefCounted
## Explicit, one-way connections. Never infer permission from a visual cliff.
const PREPARE := .12
const FLIGHT := .54
const LAND := .16
const DURATION := PREPARE + FLIGHT + LAND
var active := false
var elapsed := 0.0
var link: Dictionary = {}

func nearby(point: Vector2, links: Array, ground: RefCounted) -> Dictionary:
	if not ground.walkable(point): return {}
	for entry: Dictionary in links:
		if point.distance_to(entry.from) > 22: continue
		if entry.drop < 12 or entry.drop > 96: continue
		if not ground.walkable(entry.to, 2.0): continue
		if not ground.clear_segment(point, entry.from): continue
		return entry
	return {}

func begin(entry: Dictionary, point: Vector2, ground: RefCounted) -> bool:
	if active or entry.is_empty() or nearby(point, [entry], ground).is_empty(): return false
	link = entry.duplicate()
	link.approach = point
	elapsed = 0.0
	active = true
	return true

func advance(delta: float) -> bool:
	if not active: return false
	elapsed = minf(DURATION, elapsed + maxf(0, delta))
	if elapsed < DURATION: return false
	active = false
	return true

func progress() -> float:
	return clampf((elapsed - PREPARE) / FLIGHT, 0, 1)

func screen_position(project: Callable) -> Vector2:
	if elapsed < PREPARE:
		return project.call(link.approach).lerp(project.call(link.from), elapsed / PREPARE)
	var t := progress()
	# Height is interpolated across the discontinuity, never sampled on the wall.
	return project.call(link.from).lerp(project.call(link.to), t) - Vector2(0, sin(t * PI) * 24)

func pose_progress() -> float:
	return elapsed / DURATION
