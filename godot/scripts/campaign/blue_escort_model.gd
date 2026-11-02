extends RefCounted
const START=Vector2(21.5,24.5)
const ROUTE=[Vector2(29.5,24.5),Vector2(29.5,18.5),Vector2(22.5,18.5)]
var checkpoint:=0
var position:=START
var distance_walked:=0.0
var away_time:=0.0
var ready:=false
var complete:=false
var message:="Acompanhe o Carcará. Ele caminha no próprio ritmo."
func _init(saved_checkpoint:int=0)->void:
 checkpoint=clampi(saved_checkpoint,0,3);position=anchor();complete=checkpoint==3
func anchor()->Vector2:return START if checkpoint==0 else ROUTE[checkpoint-1]
func tick(delta:float,player:Vector2)->void:
 if complete or ready or not is_finite(delta) or delta<=0 or not player.is_finite():return
 var dt:=minf(delta,.05)
 if player.distance_to(position)>3:
  away_time+=dt;message="Carcará parou. Aproxime-se; não deixe o parceiro para trás."
  if away_time>=3:position=anchor();distance_walked=0;away_time=0;message="Retome junto do último marco seguro. Nenhuma etapa aprovada foi perdida."
  return
 away_time=0
 var target:Vector2=ROUTE[checkpoint]
 var next:=position.move_toward(target,dt*1.4)
 distance_walked+=position.distance_to(next);position=next
 message="Acompanhe o Carcará · marco %d de 3"%(checkpoint+1)
 if position.distance_to(target)<.02:
  message="Aproxime-se do Carcará para confirmar o marco."
  ready=player.distance_to(target)<=1.5
func evidence()->bool:
 return not complete and ready and position.distance_to(ROUTE[checkpoint])<.02 and distance_walked>=anchor().distance_to(ROUTE[checkpoint])-.05
func accept()->void:
 if not evidence():return
 checkpoint+=1;ready=false;distance_walked=0;complete=checkpoint==3
 message="Condução concluída. Siga ao campo de controle." if complete else "Marco confirmado. Continue acompanhando."
