extends RefCounted
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
const Lesson=preload("res://scripts/campaign/marisol_row.gd")
const Motion=preload("res://scripts/campaign/row_motion.gd")
var session:Node
func _init(active:Node)->void:session=active
static func data()->Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/marisol-row-v1/links.json"))
static func link(id:String)->Dictionary:
 for entry:Dictionary in data().links:
  if entry.id==id:return entry.duplicate(true)
 return {}
static func point(raw:Array)->Vector2:return Vector2(raw[0],raw[1])
static func allowed(player:Dictionary)->bool:return Lesson.eligible(player) and Lesson.learned(player)
static func valid_link(entry:Dictionary)->bool:
 if entry.is_empty():return false
 var model=CP.model_for(data().scene);var a:=point(entry.from);var b:=point(entry.to)
 if not a.is_finite() or not b.is_finite() or a.distance_to(b)<3 or a.distance_to(b)>9:return false
 if not is_equal_approx(a.x,b.x) and not is_equal_approx(a.y,b.y):return false
 if model.clear_segment(a,b):return false
 for end in [a,b]:
  if not model.point_walkable(end) or model.cell_at(Vector2i(end.floor())).get("ramp")!=null:return false
  if not model.clear_segment(end,end+Vector2(.5,0)) or not model.clear_segment(end,end-Vector2(.5,0)):return false
 if model.height_at(a)!=0 or model.height_at(b)!=0:return false
 for i in range(1,int(a.distance_to(b))):
  var cell:=Vector2i(a.move_toward(b,i).floor());var terrain:Dictionary=model.cell_at(cell)
  if terrain.is_empty() or terrain.material!="agua" or terrain.level!=0 or model.solid.has(model.key(cell)):return false
 return true
static func events()->Array:
 var out:Array=[]
 for i in data().links.size():
  var entry:Dictionary=data().links[i]
  out.append({"id":19200+i,"type":"interacao","name":"Remar com a capivara de Marisol","u":int(entry.from[0]),"v":int(entry.from[1]),"props":{"acao":"marisolRow","rowLink":entry.id}})
 return out
static func valid_record(value:Variant)->bool:
 return value is Dictionary and value.size()==4 and value.get("version")==1 and value.get("id") is String and not value.id.is_empty() and value.id.length()<=64 and value.get("link") is String and not link(value.link).is_empty() and value.get("scene")==data().scene
func begin(id:String,at:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint;var entry:=link(id)
 if cp.get("kind")!="world" or cp.get("scene")!=data().scene or cp.get("space")!=CP.SPACE or not allowed(saved.player) or not valid_link(entry) or not at.is_finite():return {"status":"wrong_step"}
 if saved.player.has("marisolRowTrip") or saved.player.has("ninaGlideFlight"):return {"status":"wrong_step"}
 var origin:=point(entry.from)
 # Same reach as the interact prompt (1.8), like Planar: the trip starts from the bank anyway.
 if at.distance_to(origin)>1.8 or not CP.model_for(cp.scene).clear_segment(at,origin):return {"status":"wrong_step"}
 saved.player.marisolRowTrip={"version":1,"id":State.new_id(),"link":id,"scene":data().scene}
 return session.checkpoint(CP.make(cp.scene,origin,CP.SPACE),saved.player)
func finish(token:String,motion:RefCounted)->Dictionary:
 var saved:Dictionary=session.snapshot();var pending:Dictionary=saved.player.get("marisolRowTrip",{})
 if pending.is_empty() or not motion is Motion or not motion.complete or motion.token!=token or pending.id!=token or motion.link_id!=pending.link or saved.checkpoint.get("kind")!="world" or saved.checkpoint.get("scene")!=pending.scene:return {"status":"wrong_step"}
 var entry:=link(pending.link)
 if not valid_link(entry):return {"status":"invalid"}
 saved.player.erase("marisolRowTrip");saved.player.flags.marisolRemarPratica=true;saved.player.flags.canRemar=true
 return session.commit_operation("marisol-row-"+token,CP.make(data().scene,point(entry.to),CP.SPACE),saved.player)
func recover()->Dictionary:
 var saved:Dictionary=session.snapshot();var pending:Dictionary=saved.player.get("marisolRowTrip",{})
 if pending.is_empty():return {"status":"already_applied"}
 if not valid_record(pending):return {"status":"invalid"}
 saved.player.erase("marisolRowTrip")
 return session.checkpoint(CP.make(data().scene,point(link(pending.link).from),CP.SPACE),saved.player)
