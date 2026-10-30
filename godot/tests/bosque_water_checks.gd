extends SceneTree
const Model=preload("res://scripts/overworld/map_model.gd")
var failures:=0
func _initialize() -> void:
	var model:=Model.new()
	model.setup(JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/kronasta-bosque-b.json")))
	var protected_points:=0
	var bridge_points:=0
	for v in int(model.data.h):
		for u in int(model.data.w):
			if not model.walkable(Vector2i(u,v)):continue
			for du in [.1,.5,.9]:
				for dv in [.1,.5,.9]:
					var p:=Vector2(u+du,v+dv)
					var in_water:=false
					for outline in model.water_contours:
						if Geometry2D.is_point_in_polygon(p,outline):in_water=true
					if not in_water:continue
					if model.cell_at(Vector2i(u,v)).material=="ponte":
						bridge_points+=1
						if not model.clear_segment(p,p):failures+=1
					else:
						protected_points+=1
						if model.clear_segment(p,p):failures+=1
	if protected_points==0 or bridge_points==0:failures+=1
	for id in model.graph.get_point_ids():
		for next in model.graph.get_point_connections(id):
			if not model.clear_segment(model.graph.get_point_position(id),model.graph.get_point_position(next)):failures+=1
	print("BOSQUE WATER ",protected_points," curved shore points protected; ",bridge_points," bridge points passable; ",failures," failures")
	quit(0 if failures==0 else 1)
