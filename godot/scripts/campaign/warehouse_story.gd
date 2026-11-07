extends RefCounted
## Local narrative receipts; no capture or repeatable boss loot.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const B="kronasta-industrial-b"
const D="kronasta-industrial-d"
const GOLLIA=Vector2(29.5,13.5)
const AT=Vector2(24.5,24.5)
const BEATS=["galpaoPressaoVista","galpaoRetalhoProtegeu","galpaoTylerDesatou"]
var session:Node
func _init(active:Node)->void:session=active
static func available(p:Dictionary)->bool:
 return Rules.completed(p,"cais") and p.flags.get("retalhoBosqueVencido",false) and p.flags.get("fotoExpedicaoLida",false)
static func step(p:Dictionary)->int:
 for i in BEATS.size():
  if not p.flags.get(BEATS[i],false):return i
 return BEATS.size()
static func objective(p:Dictionary)->String:
 if not available(p):return "Conclua o encontro com Retalho e examine a foto da expedição no ateliê."
 if not p.flags.get("golliaCarretelVencida",false):return "Encontre Gollia junto ao depósito da parte B · duelo Nv. 23."
 if p.flags.get("pipaDragaoDesatadaVencida",false):return "Pipa-Dragão livre · volte ao campeonato e cuide de Retalho no ateliê."
 return "Observe o confronto no salão · você pode recuar até o banco." if step(p)<3 else "Enfrente a Pipa-Dragão desatada · Nv. 25. O banco recupera a equipe."
static func nodes()->Array[Dictionary]:
 return [
  {"title":"Três rabiolas, um só corpo","text":"Kael: Três rabiolas… Elas foram costuradas juntas!\n\nA Pipa-Dragão tensiona as três linhas. O chão vibra antes do avanço. Rabbito recua: disputar força agora colocaria todos em risco.\n\nKael: Precisamos sair da frente!"},
  {"title":"Retalho entra na frente","text":"Retalho salta entre Kael e a Pipa-Dragão. As linhas se chocam; o impulso o arremessa para trás. Ele tenta se erguer, mas suas patas cedem.\n\nKael: Retalho! Você veio me proteger…\n\nA criatura prepara outro avanço. Kael se coloca ao lado de Retalho, procurando uma saída."},
  {"title":"Desatar, não cortar","text":"Tyler: Não dispute as três linhas! Elas não pertencem ao mesmo corpo.\n\nTyler se aproxima pelo lado e afrouxa um nó. Depois, o segundo. Duas luzes se desprendem das rabiolas e ganham o ar.\n\nA Pipa-Dragão encolhe. Continua exausta e assustada, mas já não carrega a pressão das três almas.\n\nTyler: Agora podemos encerrar o confronto sem cortar a rabiola."}
 ]
func near(scene:String,at:Vector2,point:Vector2)->bool:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if cp.get("kind")!="world" or cp.get("scene")!=scene or cp.get("space")!=CP.SPACE or not point.is_finite():return false
 var map=CP.model_for(scene)
 return available(saved.player) and map.point_walkable(point) and point.distance_to(at)<=1.8 and absf(map.height_at(point)-map.height_at(at))<.25
func advance(expected:int,point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if not near(D,AT,point) or not saved.player.flags.get("golliaCarretelVencida",false) or saved.player.flags.get("pipaDragaoDesatadaVencida",false) or expected!=step(saved.player) or expected<0 or expected>=BEATS.size():return {"status":"wrong_step"}
 saved.player.flags[BEATS[expected]]=true
 return session.commit_operation("warehouse-beat-"+str(expected)+"-v1",CP.make(D,point,CP.SPACE),saved.player)
func begin(opponent:String,point:Vector2)->Dictionary:
 if opponent not in ["gollia","dragon"]:return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var p:Dictionary=saved.player
 if not near(B if opponent=="gollia" else D,GOLLIA if opponent=="gollia" else AT,point):return {"status":"wrong_step"}
 if opponent=="gollia" and p.flags.get("golliaCarretelVencida",false):return {"status":"already_applied"}
 if opponent=="dragon" and (not p.flags.get("golliaCarretelVencida",false) or step(p)!=3 or p.flags.get("pipaDragaoDesatadaVencida",false)):return {"status":"wrong_step"}
 var partner:Dictionary=preload("res://scripts/campaign/park_training.gd").active(p)
 if partner.is_empty() or partner.get("condition",{}).get("line",100)<=0 or partner.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
 var model:=Model.new(partner,{"modelId":"azulao" if opponent=="gollia" else "pipa-dragao-desatada","level":23 if opponent=="gollia" else 25})
 model.q.name="Gollia" if opponent=="gollia" else ""
 model.q.color=3 if opponent=="gollia" else 2
 model.duration=90.0
 p.encounter={"id":State.new_id(),"kind":"warehouse-story","warehouseOpponent":opponent,"scene":B if opponent=="gollia" else D,"space":CP.SPACE,"returnPoint":[point.x,point.y],"rewardXp":0,"state":model.snapshot()}
 return session.checkpoint({"kind":"encounter"},p)
func rest(point:Vector2)->Dictionary:
 var scene:String=session.snapshot().checkpoint.get("scene","")
 if scene not in [B,D] or not near(scene,Vector2(21.5,25.5) if scene==B else Vector2(14.5,30.5),point):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var changed:=false
 for partner:Dictionary in saved.player.partners:
  if partner.get("condition",{}).get("line",100)<100 or partner.get("condition",{}).get("structure",100)<100:
   partner.condition={"line":100,"structure":100};changed=true
 if not changed:return {"status":"already_applied"}
 return session.commit_operation("warehouse-rest-"+State.new_id(),CP.make(scene,point,CP.SPACE),saved.player)
func settle()->Dictionary:
 var saved:Dictionary=session.snapshot()
 if saved.checkpoint.kind!="encounter" or saved.player.get("encounter",{}).get("kind")!="warehouse-story":return {"status":"wrong_step"}
 var e:Dictionary=saved.player.encounter;var s:Dictionary=e.state
 if not State.valid_encounter(e) or not available(saved.player) or s.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
 if e.warehouseOpponent=="dragon" and (step(saved.player)!=3 or not saved.player.flags.get("golliaCarretelVencida",false)):return {"status":"wrong_step"}
 for partner:Dictionary in saved.player.partners:
  if partner.id==s.partnerId:partner.condition={"line":clampf(s.p.hp/s.p.stats.line*100,0,100),"structure":clampf(s.p.hull/s.p.stats.line*100,0,100)}
 if s.outcome=="won":preload("res://scripts/campaign/progression.gd").story_win(saved.player,s)
 if s.outcome=="won":
  if e.warehouseOpponent=="gollia":saved.player.flags.golliaCarretelVencida=true
  else:
   saved.player.flags.pipaDragaoDesatadaVencida=true
   saved.player.inventory["agulha-desatar"]=maxi(1,int(saved.player.inventory.get("agulha-desatar",0)))
 saved.player.lastWarehouse={"opponent":e.warehouseOpponent,"outcome":s.outcome}
 saved.player.erase("encounter")
 return session.commit_operation("encounter-"+e.id,CP.make(e.scene,CP.spawn(e.scene) if s.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1]),CP.SPACE),saved.player)
