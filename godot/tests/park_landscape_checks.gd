extends SceneTree
## Reachability and projection checks for the new terrain, no saved slots.
const Landscape = preload("res://scripts/overworld/park_landscape.gd")
const Route = preload("res://scripts/campaign/park_route_view.gd")
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	if not value:failures.append(label)
func _initialize() -> void:
	var maps: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
	for id in maps:
		var world := Landscape.new();world.scene_id=id
		var route := Route.new();route.data=maps[id]
		if id=="park-trail":
			var kit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/kits/parque/kit.json"))
			world._gazebo(kit.pieces.coreto.variants.default,Vector2(336,420))
			route.data=route.data.duplicate(true)
			route.data.blocked=route.data.blocked.filter(func(b: Dictionary):return not str(b.name).begins_with("coreto-post-"))
			route.data.blocked.append_array(world.static_blockers)
			check(world.static_blockers.size()==4,"four measured gazebo supports")
		var points := {};var queue: Array[Vector2i]=[]
		for y in range(192,944,16):
			for x in range(80,1456,16):
				var p := Vector2i(x,y)
				if route.safe(Vector2(p)):points[p]=false
		var start := Vector2i(208,816)
		points[start]=true;queue.append(start)
		var index := 0
		while index<queue.size():
			var current := queue[index];index+=1
			for d in [Vector2i(16,0),Vector2i(-16,0),Vector2i(0,16),Vector2i(0,-16)]:
				var next: Vector2i=current+d
				if not points.has(next) or points[next]:continue
				if not world.connected(Vector2(current),Vector2(next)):continue
				var clear := true
				for step in 8:
					if not route.safe(Vector2(current).lerp(Vector2(next),float(step+1)/8)):clear=false;break
				if clear:points[next]=true;queue.append(next)
		for place: Dictionary in maps[id].places:
			var target := Vector2(place.point[0],place.point[1])
			check(queue.any(func(p: Vector2i):return Vector2(p).distance_to(target)<60),id+": unreachable "+str(place.id))
		var ramp_x := 1184.0 if id=="park-clearing" else 928.0
		check(world.connected(Vector2(ramp_x,430),Vector2(ramp_x,660)),id+": ramp both landings")
		check(not world.connected(Vector2(770,430),Vector2(770,470)),id+": cliff cannot be walked through")
		route.free();world.free()
	var veredas := Landscape.new();veredas.scene_id="park-veredas"
	for y in range(35,950,7):
		var p := Vector2(1100,y)
		check(veredas.unproject(veredas.project(p)).distance_to(p)<.001,"Veredas click projection "+str(y))
	veredas.free()
	for failure in failures:push_error(failure)
	print("Park terrain: destinations, both ramp landings, cliff restrictions and raised click projection; failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
