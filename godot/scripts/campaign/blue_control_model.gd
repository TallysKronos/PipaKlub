extends RefCounted
## Isolated evaluation: no HP, inventory, captured partner, or battle outcome.
const TARGET=Rect2(.58,.25,.22,.25)
var position:=Vector2(.25,.5)
var phase:=0
var held_time:=0.0
var energy:=35.0
var armed:=false
var timer:=0.0
var signals:=0
var previous_guard:=false
var waiting_release:=false
var complete:=false
var message:="Mantenha o Carcará na faixa azul por dois segundos."
func tick(delta:float,input:Dictionary)->void:
 if complete or not is_finite(delta) or delta<=0:return
 var dt:=minf(delta,.05)
 var direction:Vector2=input.get("direction",Vector2.ZERO)
 if not direction.is_finite():return
 var pointer:Vector2=input.get("pointer",Vector2(-1,-1))
 if direction.length()>.1:position+=direction.limit_length()*dt*.4
 elif pointer.is_finite() and pointer.x>=0:position=position.move_toward(pointer,dt*.4)
 position=position.clamp(Vector2(.05,.05),Vector2(.95,.95))
 var line:bool=input.get("line",false);var guard:bool=input.get("guard",false);var cut:bool=input.get("cut",false)
 var rising:=guard and not previous_guard;previous_guard=guard
 if phase==0:
  held_time=held_time+dt if TARGET.has_point(position) else 0.0
  if held_time>=2:phase=1;message="Segure Linha para preparar a rajada; solte ao aviso ALIVIAR."
 elif phase==1:
  if not armed:
   if line:armed=true;timer=0;energy=35
   return
  timer+=dt
  if timer<1.2 and not line:
   armed=false;timer=0;message="Mantenha Linha até aparecer ALIVIAR; a janela para soltar é ampla."
   return
  message="RAJADA EM BREVE · prepare-se para soltar Linha." if timer<1.2 else "ALIVIAR · solte Linha para recuperar pelo menos 60 de energia."
  if timer>=1.2:
   if line or cut:energy=maxf(0,energy-dt*15)
   else:energy=minf(100,energy+dt*20)
   if energy>=60:phase=2;timer=0;message="Aguarde o sinal PROTEGER. Pressione Defesa e solte entre os sinais."
   elif timer>6:armed=false;timer=0;message="A tensão ficou alta. Repita: segure Linha e solte ao aviso ALIVIAR."
 elif phase==2:
  if waiting_release:
   if not guard:waiting_release=false;timer=0
   message="Solte Defesa antes do próximo sinal."
   return
  timer+=dt
  message="AGUARDAR · não ataque. Sinal %d de 3."%(signals+1) if timer<1 else "PROTEGER · pressione Defesa. Sinal %d de 3."%(signals+1)
  if cut or line or (rising and timer<1):
   signals=0;timer=0;message="Aguarde o aviso. Não é preciso atacar; repita os três sinais."
  elif rising and timer<=3.5:
   signals+=1;waiting_release=true
   if signals==3:phase=3;complete=true;message="Controle demonstrado. Registre a etapa e volte a Dona Cida."
  elif timer>4:signals=0;timer=0;message="Sinal não respondido. Tente novamente, sem penalidade."
