extends RefCounted

const SEGMENTS := 24
var points := PackedVector2Array()
var previous := PackedVector2Array()
var length := 0.0
var tension := 0.0

func reset(anchor: Vector2, tip: Vector2) -> void:
	length = anchor.distance_to(tip) + 28.0
	points.resize(SEGMENTS + 1)
	for i in SEGMENTS + 1:
		var t := float(i) / SEGMENTS
		points[i] = anchor.lerp(tip, t) + Vector2(18, 0) * sin(t * PI)
	previous = points.duplicate()
	tension = 0.0

func advance(anchor: Vector2, tip: Vector2, reel: float, wind: float, dt: float) -> Vector2:
	if points.is_empty(): reset(anchor, tip)
	length = clampf(length + reel * 145.0 * dt, 155.0, 760.0)
	var distance := anchor.distance_to(tip)
	tension = lerpf(tension, clampf((distance - length) / 48.0, 0, 1), 1 - exp(-dt * 12))
	return tip.direction_to(anchor) * tension * 570.0

func solve(anchor: Vector2, tip: Vector2, wind: float, dt: float) -> void:
	if points.is_empty(): reset(anchor, tip)
	var force := Vector2(65 + wind * 4, 85) * dt * dt
	for i in range(1, SEGMENTS):
		var current := points[i]
		points[i] += (current - previous[i]) * .94 + force
		previous[i] = current
	points[0] = anchor
	points[SEGMENTS] = tip
	var rest := maxf(length, anchor.distance_to(tip)) / SEGMENTS
	for pass_index in 8:
		for offset in SEGMENTS:
			var i := offset if pass_index % 2 == 0 else SEGMENTS - 1 - offset
			var span := points[i + 1] - points[i]
			var distance := span.length()
			if distance < .001: continue
			var correction := span * (1.0 - rest / distance)
			if i == 0:
				points[i + 1] -= correction
			elif i + 1 == SEGMENTS:
				points[i] += correction
			else:
				points[i] += correction * .5
				points[i + 1] -= correction * .5

static func crossing(a: PackedVector2Array, b: PackedVector2Array) -> Dictionary:
	var best := {}
	for i in a.size() - 1:
		var r := a[i + 1] - a[i]
		for j in b.size() - 1:
			var v := b[j + 1] - b[j]
			var point: Variant = Geometry2D.segment_intersects_segment(a[i], a[i + 1], b[j], b[j + 1])
			if point == null: continue
			var angle := absf(r.cross(v)) / maxf(.001, r.length() * v.length())
			var u := (i + a[i].distance_to(point) / maxf(.001, r.length())) / (a.size() - 1)
			var w := (j + b[j].distance_to(point) / maxf(.001, v.length())) / (b.size() - 1)
			if angle < .2 or u <= .05 or u >= .98 or w <= .05 or w >= .98: continue
			var valid := u >= .35 and u <= .95 and w >= .3 and w <= .85
			if best.is_empty() or (valid and not best.valid) or (valid == best.valid and angle > best.angle):
				best = {"point": point, "own": u, "enemy": w, "angle": angle, "valid": valid, "perfect": w >= .52 and w <= .68}
	return best
