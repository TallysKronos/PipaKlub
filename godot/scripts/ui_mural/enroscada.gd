extends RefCounted
## Read-only projection of contact, quality and action availability; no new combat state.
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Paint=preload("res://scripts/ui_mural/battle_hud.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
static func state(model:RefCounted) -> Dictionary:
	if model.intro>0 or not model.outcome.is_empty() or (model.get("intermission")!=null and model.intermission>0):return {}
	var rivals:Array=model.actors.slice(1) if model.get("actors")!=null else [model.q]
	var best:Dictionary={}
	for rival:Dictionary in rivals:
		if rival.get("signatureWindup",0)>0 or model.attack_notice(rival).active:return {}
	for rival:Dictionary in rivals:
		if rival.hp<=0 or rival.hull<=0:continue
		var hint:Dictionary=model.contact_hint(model.p,rival)
		if hint.is_empty():continue
		var contact:Dictionary=model.contact(model.p,rival)
		var valid:bool=not contact.is_empty() and contact.get("valid",false)
		var quality:Dictionary=model.cut_quality(model.p,contact) if valid else {}
		var ready:bool=valid and model.p.energy>=12 and model.p.attackCooldown<=0 and model.p.evade<=0 and model.p.guardTime<=0 and model.p.signatureWindup<=0 and model.p.lineMove.is_empty() and model.p.hp>0 and model.p.hull>0
		var message:="Abra o ângulo" if hint.angle<.2 else "Cruze a faixa da linha rival" if not valid else "Sem energia para cortar" if model.p.energy<12 else "Corte recarregando" if model.p.attackCooldown>0 else "Aguarde a manobra" if not ready else Controls.prompt("cut")+" · Corte crítico!" if quality.get("critical",false) else Controls.prompt("cut")+" · Cortar agora"
		var priority:int=(100 if ready else 50 if valid else 0)+(10 if quality.get("critical",false) else 0)
		if best.is_empty() or priority>int(best.priority):best={"hint":hint,"contact":contact,"quality":quality,"ready":ready,"message":message,"rival":rival.get("name","Rival"),"priority":priority}
	return best
static func region(size:Vector2,rivals:int,scale:float,boss:bool=false) -> Rect2:
	var boxes:=Paint.regions(size,rivals,scale)
	if size.x<1160 or scale>1.1:
		if scale>1.1:
			var height:=Paper.inset(.35)*2+Paper.height(roundi(22*scale))+Paper.height(roundi(18*scale))+8
			return Rect2(24,size.y-24-Paint.action_size(scale).y-height-16,size.x*.4,height)
		var x:float=boxes.partner.end.x+16
		return Rect2(x,boxes.partner.position.y,size.x-x-24,Paper.inset(.35)*2+Paper.height(roundi(22*scale))+Paper.height(roundi(18*scale))+8)
	var height:=Paper.inset(.35)*2+Paper.height(roundi(22*scale))+Paper.height(roundi(18*scale))+8
	return Rect2(size.x-544,size.y-24-Paint.action_size(scale).y-height-16,520,height)
static func draw_on(view:Control,model:RefCounted,scale:float) -> void:
	var status:=state(model)
	if status.is_empty():return
	var box:=region(view.size,model.actors.size()-1 if model.get("actors")!=null else 1,scale,model.q.get("boss",false))
	Paint.paper(view,box,"MuralSunPanel" if status.ready else "MuralPaperPanel")
	var safe:=Paper.content(box,.35)
	var h:=Paper.height(roundi(22*scale))
	Paper.label(view,Rect2(safe.position,Vector2(safe.size.x,h)),"ENROSCADA"+(" · "+str(status.rival) if model.get("actors")!=null and model.actors.size()>2 else ""),roundi(22*scale),T.MURAL_INK,false,safe)
	Paper.label(view,Rect2(safe.position+Vector2(0,h+8),Vector2(safe.size.x,Paper.height(roundi(18*scale)))),status.message,roundi(18*scale),T.MURAL_INK,false,safe)
