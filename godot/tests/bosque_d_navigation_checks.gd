extends SceneTree
## Exercita o caminhante e o seguidor reais sobre todas as rampas e eventos, ida/volta.
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var View=load("res://scripts/overworld/view.gd")
 for part:String in ["c","d"]:
  var area:="kronasta-bosque-"+part
  var view:Node2D=View.new();view.area_id=area;view.art_preview=true;view.campaign_mode=true
  root.add_child(view);await process_frame;view.set_physics_process(false)
  var start:Vector2=view.player
  var targets:Array[Vector2]=[]
  for e:Dictionary in view.model.data.events:
   if e.type=="entrada":continue
   targets.append(Vector2(e.u+.5,e.v+.5))
  for index:int in view.model.data.cells.size():
   var c:Dictionary=view.model.data.cells[index]
   if c.get("ramp")==null:continue
   var u:int=index%int(view.model.data.w);var v:int=index/int(view.model.data.w)
   targets.append(Vector2(u+.5,v+.5))
  for destination:Vector2 in targets:
   for target:Vector2 in [destination,start]:
    view.path=view.model.path_to(view.player,target)
    if not check_route(view,area,target):continue
    var guard:=0
    while not view.path.is_empty() and guard<5000:
     view._physics_process(1.0/30);guard+=1
     if guard%30==0:
      check(view.model.point_walkable(view.player),area+" player remains on walkable surface")
      check(view.model.point_walkable(view.follower),area+" follower remains on walkable surface")
    check(view.player.distance_to(target)<.05,area+" arrived at "+str(target))
    for step:int in 35:view._physics_process(1.0/30)
    check(view.follower.distance_to(view.player)<1.3,area+" companion follows accepted footsteps")
  view.free();await process_frame
 print("BOSQUE D NAVIGATION: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
func check_route(view,area:String,target:Vector2)->bool:
 var exists:bool=not view.path.is_empty()
 check(exists,area+" graph route to "+str(target))
 return exists
