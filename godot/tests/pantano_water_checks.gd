extends SceneTree
const Model=preload("res://scripts/overworld/map_model.gd")
var failures:=0
func _initialize() -> void:
 for part in ["a","b","c"]:
  var model:=Model.new()
  model.setup(JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/kronasta-pantano-"+part+".json")))
  var shore:=0;var bridge:=0
  for v in int(model.data.h):
   for u in int(model.data.w):
    if not model.walkable(Vector2i(u,v)):continue
    for du in [.1,.5,.9]:
     for dv in [.1,.5,.9]:
      var p:=Vector2(u+du,v+dv)
      var wet:=false
      for outline in model.water_contours:
       if Geometry2D.is_point_in_polygon(p,outline):wet=true
      if not wet:continue
      if model.cell_at(Vector2i(u,v)).material=="ponte":
       bridge+=1
       if not model.clear_segment(p,p):failures+=1
      else:
       shore+=1
       if model.clear_segment(p,p):failures+=1
  for point in model.graph.get_point_ids():
   for other in model.graph.get_point_connections(point):
    if not model.clear_segment(model.graph.get_point_position(point),model.graph.get_point_position(other)):failures+=1
  if bridge==0:failures+=1
  print("PANTANO ",part," · ",shore," shore samples blocked · ",bridge," bridge samples passable")
 print("PANTANO WATER ",failures," failures")
 quit(0 if failures==0 else 1)
