extends SceneTree
const Model=preload("res://scripts/overworld/map_model.gd")
const Floor=preload("res://scripts/overworld/forest_structures.gd")
const Forest=preload("res://scripts/overworld/kronasta_forest.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",label)
func _initialize() -> void:
 for part in ["a","b","c","d"]:
  var model:=Model.new();model.setup(JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/mina-ferro-"+part+".json")))
  var trimmed:=0
  for v in int(model.data.h):
   for u in int(model.data.w):
    var cell:Dictionary=model.cell_at(Vector2i(u,v));var cut:float=Floor.mine_cut_height(model,u,v)
    if cut<=-999:continue
    trimmed+=1
    check(cell.material=="rocha" and not model.walkable(Vector2i(u,v)),"cut is confined to solid rock")
    var root:=Node2D.new();root.position=Floor.iso(Vector2(u,v))+Vector2(0,2)
    var poly:=Polygon2D.new()
    var corners:Array=[Vector2(u,v),Vector2(u+1,v),Vector2(u+1,v+1),Vector2(u,v+1)]
    var visible:=false
    for y in range(v-3,v+4):
     for x in range(u-3,u+4):
      if model.walkable(Vector2i(x,y)):visible=true
    Floor.floor_cut(model,root,poly,corners,u,v)
    if visible:check(is_instance_valid(poly),"visible cut keeps a closed cap instead of orphan walls")
    if is_instance_valid(poly):
     check(poly.polygon.size()==4,"cut cap remains closed")
     for i in 4:
      var wall_height:float=Forest._corner_height(model,u,v,corners[i])
      var cap_point:Vector2=poly.polygon[i]+root.position
      check(cap_point.distance_to(Floor.iso(corners[i],wall_height*64))<.001,"cap and wall share exact corners")
    root.free()
  check(trimmed>0,"fixture exercises camera-side section")
  model.data.forest.mine=false
  check(Floor.mine_cut_height(model,20,30)==-999,"other biomes bypass mine section")
 print("MINA CUTAWAY ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
