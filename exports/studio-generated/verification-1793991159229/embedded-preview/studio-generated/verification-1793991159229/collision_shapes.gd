extends RefCounted
static func distance(point: Vector2,definition: Dictionary) -> float:
	var p := point-Vector2(definition.get("x",0),definition.get("y",0))
	var shape: String=definition.get("shape","circle")
	if shape=="circle":
		return p.length()-float(definition.get("radius",12))
	if shape=="rect":
		var d := p.abs()-Vector2(definition.width,definition.height)/2
		return Vector2(maxf(d.x,0),maxf(d.y,0)).length()+minf(maxf(d.x,d.y),0)
	var points := PackedVector2Array()
	for q: Array in definition.points:
		points.append(Vector2(q[0],q[1]))
	var nearest := INF
	for i: int in range(points.size()):
		nearest=minf(nearest,p.distance_to(Geometry2D.get_closest_point_to_segment(p,points[i],points[(i+1)%points.size()])))
	return -nearest if Geometry2D.is_point_in_polygon(p,points) else nearest
