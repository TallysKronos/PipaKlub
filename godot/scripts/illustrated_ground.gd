extends RefCounted
## Support surfaces in plate pixels. Canopies are visual; roots are solid.
var floors: Array[PackedVector2Array] = []
var obstacles: Array[PackedVector2Array] = []
var edges: Array[PackedVector2Array] = []
var floor_bounds: Array[Rect2] = []
var obstacle_bounds: Array[Rect2] = []

func _init(layout: Dictionary) -> void:
	for zone in layout.floors: floors.append(_polygon(zone.points))
	var entries: Array=layout.obstacles.duplicate()
	for tree in layout.get("separated_trees",[]):
		entries.append({"center":[tree.position[0]+tree.root_offset[0],tree.position[1]+tree.root_offset[1]],"radius":tree.root_radius})
	for obstacle in entries:
		if obstacle.has("points"):
			obstacles.append(_polygon(obstacle.points))
		else:
			var outline:=PackedVector2Array()
			for i in 24:
				var angle:=TAU*i/24.0
				outline.append(Vector2(obstacle.center[0]+cos(angle)*obstacle.radius[0],obstacle.center[1]+sin(angle)*obstacle.radius[1]))
			obstacles.append(outline)
	edges.assign(floors+obstacles)
	for polygon in floors: floor_bounds.append(_bounds(polygon))
	for polygon in obstacles: obstacle_bounds.append(_bounds(polygon))

func _bounds(polygon: PackedVector2Array) -> Rect2:
	var bounds:=Rect2(polygon[0],Vector2.ZERO)
	for point in polygon: bounds=bounds.expand(point)
	return bounds.grow(.01)

func _polygon(points: Array) -> PackedVector2Array:
	var polygon:=PackedVector2Array()
	for point in points: polygon.append(Vector2(point[0],point[1]))
	return polygon

func supported(point: Vector2) -> bool:
	for i in obstacles.size():
		if obstacle_bounds[i].has_point(point) and Geometry2D.is_point_in_polygon(point,obstacles[i]): return false
	for i in floors.size():
		if floor_bounds[i].has_point(point) and Geometry2D.is_point_in_polygon(point,floors[i]): return true
	return false

func walkable(point: Vector2,padding: float=0.0) -> bool:
	if not supported(point): return false
	# Sole ellipse 12x6 px, never the head or the whole sprite silhouette.
	var x:=6+padding
	var y:=3+padding
	for offset in [Vector2(x,0),Vector2(-x,0),Vector2(0,y),Vector2(0,-y),Vector2(x*.707,y*.707),Vector2(-x*.707,y*.707),Vector2(x*.707,-y*.707),Vector2(-x*.707,-y*.707)]:
		if not supported(point+offset): return false
	return true

func clear_segment(a: Vector2,b: Vector2,padding: float=0.0) -> bool:
	var count:=maxi(1,int(ceil(a.distance_to(b)/2.0)))
	for i in range(1,count+1):
		if not walkable(a.lerp(b,float(i)/count),padding): return false
	return true

func slide_step(point: Vector2,motion: Vector2) -> Vector2:
	if walkable(point+motion): return point+motion
	var best:=point
	var best_progress:=0.0
	# Slide along the diagonal shore/root edge, without favoring horizontal motion.
	for polygon in edges:
		for i in polygon.size():
			var a:=polygon[i]
			var b:=polygon[(i+1)%polygon.size()]
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))>12: continue
			var tangent:=a.direction_to(b)
			var candidate:=point+tangent*motion.dot(tangent)
			var progress: float=(candidate-point).dot(motion)
			if progress>best_progress and clear_segment(point,candidate):
				best=candidate
				best_progress=progress
	return best
