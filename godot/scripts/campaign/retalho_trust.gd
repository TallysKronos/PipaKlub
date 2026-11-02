extends RefCounted
## Retalho chooses a partner. Receipts, pending adoption and the creature share the save.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Care=preload("res://scripts/campaign/retalho_care.gd")
const State=preload("res://scripts/campaign/state.gd")
const Levels=preload("res://scripts/campaign/partner_levels.gd")
const CAPACITY=30
const ORIGIN="retalho-trust-partner-v1"
const A="kronasta-pantano-a"
const B="kronasta-pantano-b"
const C="kronasta-palafitas-c"
const SICK=Vector2(20.5,28.5)
const HERB=Vector2(32.5,19.5)
const RESCUE=Vector2(24.5,7.5)
const FLAGS=["retalhoVaralLivre","retalhoFugiuVaral","retalhoDoentePantano","retalhoRemedioColetado","retalhoTratadoPantano","retalhoPalafitasLivre","retalhoEscolheuKael","retalhoAcolhido"]
var session:Node
func _init(active:Node)->void:session=active
static func available(p:Dictionary)->bool:return Care.available(p) and p.get("flags",{}).get("assisReconheceuNoRetalho",false)
static func stage(p:Dictionary)->int:
 for i in FLAGS.size():
  if not p.get("flags",{}).get(FLAGS[i],false):return i
 return FLAGS.size()
static func nodes()->Array:
 return JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/retalho-care-v1/trust.json")).nodes
static func objective(p:Dictionary)->String:
 if not available(p):return "Cuide de Retalho no ateliê."
 return "Retalho escolheu acompanhar você." if stage(p)==8 else str(nodes()[stage(p)].objective)
static func swamp_open(p:Dictionary)->bool:return available(p) and stage(p)>=2
static func docks_open(p:Dictionary)->bool:return available(p) and stage(p)>=5
static func event(scene:String)->Dictionary:
 var point:Vector2
 var name:String
 if scene==A:point=SICK;name="Retalho"
 elif scene==B:point=HERB;name="Material para o remédio"
 elif scene==C:point=RESCUE;name="Retalho · linha tensionada"
 else:return {}
 return {"id":19001 if scene==A else 19002 if scene==B else 19003,"type":"npc","name":name,"u":int(point.x),"v":int(point.y),"props":{"acao":"retalhoTrust","trustScene":scene,"bloqueia":false,"storySpritePath":"res://assets/overworld/kits/comum/pecas/flores-azul.png" if scene==B else "res://assets/campaign/retalho-v1/overworld.png"}}
static func visible(scene:String,p:Dictionary)->bool:
 if not available(p):return false
 var n:=stage(p)
 return (scene==A and n in [2,3,4]) or (scene==B and n==3) or (scene==C and n in [5,6,7])
func near(scene:String,point:Vector2)->bool:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if cp.get("kind")!="world" or cp.get("scene")!=scene or not available(saved.player) or not point.is_finite():return false
 if scene==Care.SPACE:return Care.walkable(point) and point.distance_to(Care.AT)<=110
 if cp.get("space")!=CP.SPACE or scene not in [A,B,C]:return false
 var at:Vector2=SICK if scene==A else HERB if scene==B else RESCUE
 var map=CP.model_for(scene)
 return map.point_walkable(point) and point.distance_to(at)<=1.8 and absf(map.height_at(point)-map.height_at(at))<.25
func advance(expected:int,point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot();var p:Dictionary=saved.player
 var n:=stage(p)
 if not available(p) or expected!=n or n not in [0,1,2,3,4,6]:return {"status":"wrong_step"}
 var scene:String=Care.SPACE if n<2 else A if n in [2,4] else B if n==3 else C
 if not near(scene,point):return {"status":"wrong_step"}
 p.flags[FLAGS[n]]=true
 var cp:Dictionary={"kind":"world","scene":scene,"position":[point.x,point.y]} if n<2 else CP.make(scene,point,CP.SPACE)
 return session.commit_operation("retalho-trust-beat-"+str(n)+"-v1",cp,p)
func begin(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if stage(saved.player)!=5 or not near(C,point):return {"status":"wrong_step"}
 var partner:Dictionary=preload("res://scripts/campaign/park_training.gd").active(saved.player)
 if partner.is_empty() or partner.get("condition",{}).get("line",100)<=0 or partner.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
 var battle=preload("res://scripts/campaign/encounter_model.gd").new(partner,{"modelId":"mata","level":24})
 battle.q.name="Valentões das Palafitas"
 saved.player.encounter={"id":State.new_id(),"kind":"retalho-rescue","scene":C,"space":CP.SPACE,"returnPoint":[point.x,point.y],"rewardXp":0,"state":battle.snapshot()}
 return session.checkpoint({"kind":"encounter"},saved.player)
func settle()->Dictionary:
 var saved:Dictionary=session.snapshot();var e:Dictionary=saved.player.get("encounter",{})
 if saved.checkpoint.get("kind")!="encounter" or e.get("kind")!="retalho-rescue" or not State.valid_encounter(e) or stage(saved.player)!=5 or not available(saved.player):return {"status":"wrong_step"}
 var s:Dictionary=e.state
 if s.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
 for partner:Dictionary in saved.player.partners:
  if partner.id==s.partnerId:partner.condition={"line":clampf(s.p.hp/s.p.stats.line*100,0,100),"structure":clampf(s.p.hull/s.p.stats.line*100,0,100)}
 if s.outcome=="won":saved.player.flags.retalhoPalafitasLivre=true
 saved.player.erase("encounter")
 return session.commit_operation("encounter-"+e.id,CP.make(C,CP.spawn(C) if s.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1]),CP.SPACE),saved.player)
func claim(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot();var p:Dictionary=saved.player
 if not near(C,point):return {"status":"wrong_step"}
 if stage(p)==8:return {"status":"already_applied"}
 if stage(p)!=7:return {"status":"wrong_step"}
 if p.partners.size()>=CAPACITY:return {"status":"bank_full"}
 if p.partners.any(func(partner):return partner.get("origin","")==ORIGIN):return {"status":"already_applied"}
 p.partners.append({"id":State.new_id(),"modelId":"retalho-original","personalName":"Retalho","xp":Levels.xp_for_level(22),"craftBonus":0,"condition":{"line":100,"structure":100},"origin":ORIGIN,"certification":"unverified"})
 preload("res://scripts/campaign/progression.gd").acquire(p,"retalho-original")
 p.flags.retalhoAcolhido=true
 return session.commit_operation(ORIGIN,CP.make(C,point,CP.SPACE),p)
func rest(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot();var scene:="kronasta-palafitas-b";var at:=Vector2(12.5,30.5)
 if saved.checkpoint.get("kind")!="world" or saved.checkpoint.get("scene")!=scene or saved.checkpoint.get("space")!=CP.SPACE or not docks_open(saved.player) or not point.is_finite() or point.distance_to(at)>1.8:return {"status":"wrong_step"}
 var model=CP.model_for(scene)
 if not model.point_walkable(point) or absf(model.height_at(point)-model.height_at(at))>=.25:return {"status":"wrong_step"}
 var changed:=false
 for partner:Dictionary in saved.player.partners:
  if partner.get("condition",{}).get("line",100)<100 or partner.get("condition",{}).get("structure",100)<100:partner.condition={"line":100,"structure":100};changed=true
 if not changed:return {"status":"already_applied"}
 return session.commit_operation("retalho-trust-rest-"+State.new_id(),CP.make(scene,point,CP.SPACE),saved.player)
func release(partner_id:String)->Dictionary:
 var saved:Dictionary=session.snapshot();var p:Dictionary=saved.player
 if stage(p)!=7 or not available(p) or saved.checkpoint.get("scene")!=C or saved.checkpoint.get("kind")!="world":return {"status":"wrong_step"}
 if partner_id==p.get("equippedPartnerId",""):return {"status":"equipped"}
 var found:bool=p.partners.any(func(partner):return partner.id==partner_id and partner.get("origin","")!=ORIGIN)
 if not found:return {"status":"wrong_step"}
 p.partners=p.partners.filter(func(partner):return partner.id!=partner_id)
 return session.commit_operation("retalho-bank-release-"+partner_id,saved.checkpoint,p)
