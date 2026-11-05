extends RefCounted
## One-time story confrontation; no capture, repeatable XP, or invented loot.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const State=preload("res://scripts/campaign/state.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const AT=Vector2(24.5,10.5)
var session:Node
func _init(active:Node)->void:session=active
static func available(p:Dictionary)->bool:return preload("res://scripts/campaign/kronasta_story.gd").serra_open(p)
func begin(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if cp.kind!="world" or cp.get("scene")!="kronasta-montanha-c" or cp.get("space")!=CP.SPACE or not available(saved.player) or not point.is_finite():return {"status":"wrong_step"}
 var map=CP.model_for(cp.scene)
 if not map.point_walkable(point) or point.distance_to(AT)>1.8 or absf(map.height_at(point)-map.height_at(AT))>=.25:return {"status":"wrong_step"}
 if saved.player.flags.get("tufanocorteLiberto",false):return {"status":"already_applied"}
 var active:Dictionary=preload("res://scripts/campaign/park_training.gd").active(saved.player)
 if active.is_empty() or active.get("condition",{}).get("line",100)<=0 or active.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
 var model:=Model.new(active,{"modelId":"tufanocorte","level":29});model.q.name="Tufanocorte";model.q.boss=true;model.duration=150
 saved.player.encounter={"id":State.new_id(),"kind":"tufanocorte-story","scene":cp.scene,"space":CP.SPACE,"returnPoint":[point.x,point.y],"rewardXp":0,"state":model.snapshot()}
 return session.checkpoint({"kind":"encounter"},saved.player)
func settle()->Dictionary:
 var saved:Dictionary=session.snapshot()
 if saved.checkpoint.kind!="encounter" or saved.player.encounter.kind!="tufanocorte-story":return {"status":"wrong_step"}
 var e:Dictionary=saved.player.encounter;var s:Dictionary=e.state
 if not State.valid_encounter(e) or s.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
 for p:Dictionary in saved.player.partners:
  if p.id==s.partnerId:p.condition={"line":clampf(s.p.hp/s.p.stats.line*100,0,100),"structure":clampf(s.p.hull/s.p.stats.line*100,0,100)}
 if s.outcome=="won":
  saved.player.flags.tufanocorteLiberto=true
  saved.player.flags.canCorrenteDeAr=true
 saved.player.erase("encounter")
 return session.commit_operation("encounter-"+e.id,CP.make(e.scene,CP.spawn(e.scene) if s.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1]),CP.SPACE),saved.player)

const TATU:=Vector2(26.5,10.5)
const DIG:=Vector2(24.5,12.5)

static func lesson_events(player:Dictionary)->Array:
 if not player.get("flags",{}).get("tufanocorteLiberto",false):return []
 return [
  {"id":19401,"type":"npc","name":"Tatutrama","u":int(TATU.x),"v":int(TATU.y),"props":{"acao":"learnDig","bloqueia":false,"storySpritePath":"res://assets/campaign/tatutrama-overworld.png"}},
  {"id":19402,"type":"interacao","name":"Terra fofa","u":int(DIG.x),"v":int(DIG.y),"props":{"acao":"serraDig"}}
 ]

func learn_dig(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if not _near_lesson(saved,point,TATU):return {"status":"wrong_step"}
 if saved.player.flags.get("canCavar",false):return {"status":"already_applied"}
 saved.player.flags.canCavar=true
 return session.commit_operation("serra-cavar-v1",saved.checkpoint,saved.player)

func dig(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if not _near_lesson(saved,point,DIG) or not saved.player.flags.get("canCavar",false):return {"status":"wrong_step"}
 if "serra-primeira-escavacao-v1" in saved.player.completedOperations:return {"status":"already_applied"}
 saved.player.inventory["vareta-bambu"]=int(saved.player.inventory.get("vareta-bambu",0))+1
 return session.commit_operation("serra-primeira-escavacao-v1",saved.checkpoint,saved.player)

func _near_lesson(saved:Dictionary,point:Vector2,target:Vector2)->bool:
 if saved.checkpoint.get("kind")!="world" or saved.checkpoint.get("scene")!="kronasta-montanha-c" or saved.checkpoint.get("space")!=CP.SPACE:return false
 if not saved.player.flags.get("tufanocorteLiberto",false) or not point.is_finite():return false
 var map=CP.model_for("kronasta-montanha-c")
 return map.point_walkable(point) and point.distance_to(target)<=1.8 and absf(map.height_at(point)-map.height_at(target))<.25

const GALLERY := "mina-ferro-a"
const GALLERY_RECEIPT := "serra-galeria-cavar-v1"

static func gallery_events(player:Dictionary)->Array:
 if GALLERY_RECEIPT not in player.get("completedOperations",[]):return []
 var point:=CP.spawn(GALLERY)
 return [{"id":19403,"type":"interacao","name":"Subir para a Serra","u":floori(point.x),"v":floori(point.y),"props":{"acao":"serraGalleryReturn"}}]

func enter_gallery(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if not _near_lesson(saved,point,DIG) or not saved.player.flags.get("canCavar",false) or "serra-primeira-escavacao-v1" not in saved.player.completedOperations:return {"status":"wrong_step"}
 var target:=CP.make(GALLERY,CP.spawn(GALLERY),CP.SPACE)
 if GALLERY_RECEIPT in saved.player.completedOperations:return session.checkpoint(target,saved.player)
 return session.commit_operation(GALLERY_RECEIPT,target,saved.player)

func leave_gallery(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if saved.checkpoint.get("kind")!="world" or saved.checkpoint.get("scene")!=GALLERY or saved.checkpoint.get("space")!=CP.SPACE:return {"status":"wrong_step"}
 if GALLERY_RECEIPT not in saved.player.completedOperations or not point.is_finite():return {"status":"wrong_step"}
 var hatch:=CP.spawn(GALLERY)
 var map=CP.model_for(GALLERY)
 if point.distance_to(hatch)>1.8 or not map.point_walkable(point) or absf(map.height_at(point)-map.height_at(hatch))>=.25:return {"status":"wrong_step"}
 return session.checkpoint(CP.make("kronasta-montanha-c",DIG,CP.SPACE),saved.player)

const WIND_START:=Vector2(18.5,20.5)
const WIND_END:=Vector2(18.5,17.5)
const WIND_RECEIPT:="serra-corrente-de-ar-v1"

static func wind_events(player:Dictionary)->Array:
 # F18: the wall opens after the Cavar lesson and the gallery.
 if not player.get("flags",{}).get("canCorrenteDeAr",false) or GALLERY_RECEIPT not in player.get("completedOperations",[]):return []
 return [{"id":19404,"type":"interacao","name":"Corrente de Ar","u":int(WIND_START.x),"v":int(WIND_START.y),"props":{"acao":"serraWind"}}]

func ride_wind(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if not saved.player.flags.get("canCorrenteDeAr",false) or GALLERY_RECEIPT not in saved.player.completedOperations or not _near_lesson(saved,point,WIND_START):return {"status":"wrong_step"}
 var map=CP.model_for("kronasta-montanha-c")
 if not map.point_walkable(WIND_END) or map.height_at(WIND_END)<=map.height_at(WIND_START):return {"status":"wrong_step"}
 var target:=CP.make("kronasta-montanha-c",WIND_END,CP.SPACE)
 if WIND_RECEIPT in saved.player.completedOperations:return session.checkpoint(target,saved.player)
 return session.commit_operation(WIND_RECEIPT,target,saved.player)
