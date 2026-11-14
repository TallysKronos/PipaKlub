extends RefCounted
## One-time story confrontation; no capture, repeatable XP, or invented loot.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const State=preload("res://scripts/campaign/state.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const AT=Vector2(33.5,12.5)
var session:Node
func _init(active:Node)->void:session=active
static func available(p:Dictionary)->bool:return Rules.completed(p,"cais")
func begin(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if cp.kind!="world" or cp.get("scene")!="kronasta-bosque-d" or cp.get("space")!=CP.SPACE or not available(saved.player) or not point.is_finite():return {"status":"wrong_step"}
 var map=CP.model_for(cp.scene)
 if not map.point_walkable(point) or point.distance_to(AT)>1.8 or absf(map.height_at(point)-map.height_at(AT))>=.25:return {"status":"wrong_step"}
 if saved.player.flags.get("retalhoBosqueVencido",false):return {"status":"already_applied"}
 var active:Dictionary=preload("res://scripts/campaign/park_training.gd").active(saved.player)
 if active.is_empty() or active.get("condition",{}).get("line",100)<=0 or active.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
 var model:=Model.new(active,{"modelId":"retalho-original","level":22});model.q.name="Retalho"
 saved.player.encounter={"id":State.new_id(),"kind":"retalho-story","scene":cp.scene,"space":CP.SPACE,"returnPoint":[point.x,point.y],"rewardXp":0,"state":model.snapshot()}
 return session.checkpoint({"kind":"encounter"},saved.player)
func settle()->Dictionary:
 var saved:Dictionary=session.snapshot()
 if saved.checkpoint.kind!="encounter" or saved.player.encounter.kind!="retalho-story":return {"status":"wrong_step"}
 var e:Dictionary=saved.player.encounter;var s:Dictionary=e.state
 if not State.valid_encounter(e) or s.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
 for p:Dictionary in saved.player.partners:
  if p.id==s.partnerId:p.condition={"line":clampf(s.p.hp/s.p.stats.line*100,0,100),"structure":clampf(s.p.hull/s.p.stats.line*100,0,100)}
 if s.outcome=="won":preload("res://scripts/campaign/progression.gd").story_win(saved.player,s)
 if s.outcome=="won":saved.player.flags.retalhoBosqueVencido=true
 saved.player.erase("encounter")
 return session.commit_operation("encounter-"+e.id,CP.make(e.scene,CP.spawn(e.scene) if s.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1]),CP.SPACE),saved.player)
