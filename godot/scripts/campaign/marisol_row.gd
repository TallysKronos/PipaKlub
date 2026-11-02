extends RefCounted
## Orientation only: no borrowed creature and no navigation permission yet.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
var session:Node
var step:=0
func _init(active:Node)->void:session=active
static func data()->Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/marisol-row-v1/lesson.json"))
static func eligible(p:Dictionary)->bool:return p.get("flags",{}).get("leagueBlue",false) and Rules.completed(p,"cais")
static func learned(p:Dictionary)->bool:return p.get("flags",{}).get("marisolRemarOrientado",false)
func near(point:Vector2)->bool:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if not eligible(saved.player) or cp.get("kind")!="world" or cp.get("scene")!="kronasta-cais-c" or cp.get("space")!=CP.SPACE or not point.is_finite():return false
 var model=CP.model_for(cp.scene)
 if not model.point_walkable(point):return false
 for event:Dictionary in model.data.events:
  if event.props.get("duel","")!="cais-5":continue
  var target:=Vector2(event.u+.5,event.v+.5)
  return point.distance_to(target)<=1.8 and absf(model.height_at(point)-model.height_at(target))<.25
 return false
func answer(choice:String,point:Vector2)->Dictionary:
 if not near(point) or step>=data().lessons.size():return {"status":"wrong_step"}
 var lesson:Dictionary=data().lessons[step]
 if choice!=lesson.answer:return {"status":"try_again","hint":lesson.hint}
 step+=1
 return {"status":"ok"}
func finish(point:Vector2)->Dictionary:
 if not near(point):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot()
 if learned(saved.player):return {"status":"already_applied"}
 if step!=data().lessons.size():return {"status":"wrong_step"}
 saved.player.flags.marisolRemarOrientado=true
 return session.commit_operation(data().id,CP.make("kronasta-cais-c",point,CP.SPACE),saved.player)
