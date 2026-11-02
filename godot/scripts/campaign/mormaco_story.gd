extends RefCounted
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const A="kronasta-pantano-a"
const C="kronasta-pantano-c"
const SIGNAL=Vector2(24.5,31.5)
const AT=Vector2(24.5,28.5)
const REST=Vector2(21.5,30.5)
var session:Node
func _init(active:Node)->void:session=active
static func available(p:Dictionary)->bool:return p.get("flags",{}).get("leagueBlue",false) and p.get("flags",{}).get("canRemar",false)
static func won(p:Dictionary)->bool:return p.get("flags",{}).get("mormacoLacosDesfeitos",false)
static func freed(p:Dictionary)->bool:return p.get("flags",{}).get("mormacoLiberto",false)
static func objective(p:Dictionary)->String:
 if freed(p):return "Mormaço livre · o frio sabe onde estão os outros Ventos."
 if won(p):return "Converse com Mormaço na margem do lago e escute seu enigma."
 if not p.get("flags",{}).get("mormacoVentosPararam",false):return "Observe o ar parado na Entrada alagada, perto do caminho de chegada."
 return "Siga pelas margens até o lago da parte C · Mormaço está amarrado. Duelo Nv.27; você pode recuar."
static func events(scene:String)->Array:
 if scene==A:return [{"id":19300,"type":"interacao","name":"O vento parou","u":24,"v":31,"props":{"acao":"mormacoSignals"}}]
 if scene==C:return [{"id":19301,"type":"interacao","name":"Mormaço · o primeiro Vento","u":24,"v":28,"props":{"acao":"mormacoStory"}}]
 return []
func near(scene:String,target:Vector2,point:Vector2)->bool:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if cp.get("kind")!="world" or cp.get("scene")!=scene or cp.get("space")!=CP.SPACE or not available(saved.player) or not point.is_finite():return false
 var map=CP.model_for(scene)
 return map.point_walkable(point) and point.distance_to(target)<=1.8 and absf(map.height_at(point)-map.height_at(target))<.25
func observe(point:Vector2)->Dictionary:
 if not near(A,SIGNAL,point):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot()
 if saved.player.flags.get("mormacoVentosPararam",false):return {"status":"already_applied"}
 saved.player.flags.mormacoVentosPararam=true
 return session.commit_operation("mormaco-wind-still-v1",CP.make(A,point,CP.SPACE),saved.player)
func begin(point:Vector2)->Dictionary:
 if not near(C,AT,point):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot()
 if won(saved.player):return {"status":"already_applied"}
 if not saved.player.flags.get("mormacoVentosPararam",false):return {"status":"wrong_step"}
 var partner:Dictionary=preload("res://scripts/campaign/park_training.gd").active(saved.player)
 if partner.is_empty() or partner.get("condition",{}).get("line",100)<=0 or partner.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
 var model:=Model.new(partner,{"modelId":"mormaco-possuido","level":27})
 model.q.boss=true;model.q.color=3;model.q.name="Mormaço · Possuído";model.q.bossTitle="Mormaço · Possuído";model.duration=150
 model.q.stats.line*=1.6;model.q.hp=model.q.stats.line;model.q.hull=model.q.stats.line;model.q.stats.speed*=.8
 saved.player.encounter={"id":State.new_id(),"kind":"mormaco-story","scene":C,"space":CP.SPACE,"returnPoint":[point.x,point.y],"rewardXp":0,"state":model.snapshot()}
 return session.checkpoint({"kind":"encounter"},saved.player)
func settle()->Dictionary:
 var saved:Dictionary=session.snapshot()
 if saved.checkpoint.kind!="encounter" or saved.player.get("encounter",{}).get("kind")!="mormaco-story":return {"status":"wrong_step"}
 var e:Dictionary=saved.player.encounter;var state:Dictionary=e.state
 if not State.valid_encounter(e) or not available(saved.player) or state.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
 for partner:Dictionary in saved.player.partners:
  if partner.id==state.partnerId:partner.condition={"line":clampf(state.p.hp/state.p.stats.line*100,0,100),"structure":clampf(state.p.hull/state.p.stats.line*100,0,100)}
 if state.outcome=="won":saved.player.flags.mormacoLacosDesfeitos=true
 saved.player.lastMormaco=state.outcome;saved.player.erase("encounter")
 return session.commit_operation("encounter-"+e.id,CP.make(C,CP.spawn(C) if state.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1]),CP.SPACE),saved.player)
func release(point:Vector2)->Dictionary:
 if not near(C,AT,point):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot()
 if freed(saved.player):return {"status":"already_applied"}
 if not won(saved.player):return {"status":"wrong_step"}
 saved.player.flags.mormacoLiberto=true
 return session.commit_operation("mormaco-free-v1",CP.make(C,point,CP.SPACE),saved.player)
func rest(point:Vector2)->Dictionary:
 if not near(C,REST,point):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var changed:=false
 for partner:Dictionary in saved.player.partners:
  if partner.get("condition",{}).get("line",100)<100 or partner.get("condition",{}).get("structure",100)<100:partner.condition={"line":100,"structure":100};changed=true
 if not changed:return {"status":"already_applied"}
 return session.commit_operation("mormaco-rest-"+State.new_id(),CP.make(C,point,CP.SPACE),saved.player)
