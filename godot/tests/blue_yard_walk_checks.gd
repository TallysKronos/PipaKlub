extends SceneTree
## Exercise the real click-to-walk controller, without campaign rewards or encounters.
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 for part in ["liga"]:
  var view=load("res://scripts/overworld/view.gd").new()
  view.area_id="parque-patio-liga";view.art_preview=true
  root.add_child(view);view.set_physics_process(false)
  var start:Vector2=view.player
  var targets:Array=[]
  for e:Dictionary in view.model.data.events:targets.append(Vector2(e.u+.5,e.v+.5))
  for v in int(view.model.data.h):
   for u in int(view.model.data.w):
    var cell:Dictionary=view.model.cell_at(Vector2i(u,v))
    if cell.get("ramp")!=null:
     targets.append(Vector2(u+.5,v+.5)+Vector2(0,1));targets.append(Vector2(u+.5,v+.5)-Vector2(0,2))
  for target:Vector2 in targets:
   check(view.model.point_walkable(target),"walkable target "+part+str(target))
   for goal:Vector2 in [target,start]:
    if view.player.distance_to(goal)<.08:continue
    check(view.walk_to(goal),"click path "+part+str(goal))
    for tick in 18000:
     if view.player.distance_to(goal)<.08:break
     view._physics_process(1.0/60)
     if tick==17999:check(false,"controller reaches "+part+str(goal))
    check(view.player.distance_to(goal)<.08,"arrived "+part+str(goal))
  view.free();await process_frame
 print("BLUE YARD WALK ",checks," checks; ",failures," failures; scripted controller, not physical input")
 quit(0 if failures==0 else 1)
