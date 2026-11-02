extends RefCounted
const SCENE="parque-patio-liga"
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Prep=preload("res://scripts/campaign/blue_exam_preparation.gd")
const Escort=preload("res://scripts/campaign/blue_escort_model.gd")
const ControlModel=preload("res://scripts/campaign/blue_control_model.gd")
const CIDA=Vector2(18.5,23.5)
const OBSERVE=Vector2(10.5,8.5)
const CONTROL=Vector2(23.5,12.5)
var session:Node
func _init(active:Node)->void:session=active
static func fresh()->Dictionary:return {"version":1,"observed":false,"care":false,"escort":0,"control":false}
static func record(p:Dictionary)->Dictionary:return p.get("blueExam",fresh()).duplicate(true)
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.size()!=5 or value.get("version")!=1 or not value.get("observed") is bool or not value.get("care") is bool or not value.get("control") is bool:return false
 var n:Variant=value.get("escort")
 if not (n is float or n is int) or not is_finite(float(n)) or n<0 or n>3 or floor(float(n))!=n:return false
 return (not value.care or value.observed) and (n==0 or value.care) and (not value.control or n==3)
static func promoted(p:Dictionary)->bool:return p.get("flags",{}).get("leagueBlue",false)
static func stage(p:Dictionary)->int:
 if promoted(p):return 4
 var r:=record(p)
 return 0 if not r.care else 1 if r.escort<3 else 2 if not r.control else 3
static func objective(p:Dictionary)->String:
 return ["Examine o Carcará na bancada elevada e escolha o cuidado adequado.","Acompanhe o Carcará pelos três marcos, no ritmo dele.","Demonstre condução de voo no campo de controle.","Volte ao posto de Dona Cida para registrar sua aprovação.","Categoria Rabiola Azul conquistada · treinos não concedem novas recompensas."][stage(p)]
static func escort_start(p:Dictionary)->Vector2:
 var n:int=record(p).escort
 return Escort.START if promoted(p) or n==0 else Escort.ROUTE[n-1]
func near(point:Vector2,target:Vector2)->bool:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if cp.get("kind")!="world" or cp.get("scene")!=SCENE or cp.get("space")!=CP.SPACE or not Prep.eligible(saved.player) or not point.is_finite():return false
 var model=CP.model_for(SCENE)
 return model.point_walkable(point) and point.distance_to(target)<=1.8 and absf(model.height_at(point)-model.height_at(target))<.25
func observe(point:Vector2)->Dictionary:
 if not near(point,OBSERVE):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var r:=record(saved.player)
 if r.observed:return {"status":"already_applied"}
 r.observed=true;saved.player.blueExam=r
 return session.commit_operation("blue-observation-v1",CP.make(SCENE,point,CP.SPACE),saved.player)
func care(action:String,point:Vector2)->Dictionary:
 if not near(point,OBSERVE):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var r:=record(saved.player)
 if not r.observed:return {"status":"wrong_step"}
 if action!="rest":return {"status":"try_again","hint":"A armação e a linha estão íntegras. O sinal é cansaço: oferecer descanso é o cuidado adequado."}
 if r.care:return {"status":"already_applied"}
 r.care=true;saved.player.blueExam=r
 return session.commit_operation("blue-care-v1",CP.make(SCENE,point,CP.SPACE),saved.player)
func escort_checkpoint(model:RefCounted,point:Vector2)->Dictionary:
 if not model is Escort or not model.evidence():return {"status":"wrong_step"}
 if not near(point,model.position) or point.distance_to(model.position)>1.5:return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var r:=record(saved.player)
 if promoted(saved.player):return {"status":"already_applied"}
 if not r.care or model.checkpoint!=int(r.escort):return {"status":"wrong_step"}
 r.escort+=1;saved.player.blueExam=r
 return session.commit_operation("blue-escort-"+str(r.escort)+"-v1",CP.make(SCENE,point,CP.SPACE),saved.player)
func control(model:RefCounted,point:Vector2)->Dictionary:
 if not model is ControlModel or not model.complete or model.phase!=3 or model.signals!=3 or not near(point,CONTROL):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var r:=record(saved.player)
 if r.escort!=3:return {"status":"wrong_step"}
 if r.control:return {"status":"already_applied"}
 r.control=true;saved.player.blueExam=r
 return session.commit_operation("blue-control-v1",CP.make(SCENE,point,CP.SPACE),saved.player)
func claim(point:Vector2)->Dictionary:
 if not near(point,CIDA):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot()
 if promoted(saved.player):return {"status":"already_applied"}
 if stage(saved.player)!=3:return {"status":"wrong_step"}
 saved.player.flags.leagueBlue=true
 saved.player.inventory["certificado-rabiola-azul"]=1
 return session.commit_operation("league-blue-v1",CP.make(SCENE,point,CP.SPACE),saved.player)
