extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Scene=preload("res://scripts/campaign/heleana_confession.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize()->void:
	var session:=Session.new();session._store=Store.new("user://heleana-"+State.new_id())
	check(session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":0}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	var cp:Dictionary={"kind":"world","scene":"kael-home","position":[1040,912]}
	check(session.checkpoint(cp,p).status=="ok","home checkpoint accepted")
	var service:=Scene.new(session)
	var bank_only:Dictionary=p.duplicate(true)
	bank_only.partners.append({"id":"ret-bank","modelId":"retalho-original","xp":0})
	check(not Scene.available(bank_only),"Retalho stored in bank does not count as accompanying Kael")
	check(not Scene.available(p),"postpone or absent Retalho never triggers refusal route")
	check(service.advance(0,Scene.AT).status=="wrong_step","without Retalho blocked")
	p.flags.retalhoRecusadoKael=true
	check(session.checkpoint(cp,p).status=="ok","explicit refusal, no partner or emblem")
	check(service.advance(1,Scene.ENTRY).status=="wrong_step","cannot skip grunt")
	check(service.advance(0,Scene.ENTRY).status=="ok","grunt at entry")
	check(session.resume_slot("slot-1").status=="ok","resume grunt")
	check(service.advance(1,Scene.ENTRY).status=="ok","leave house together")
	check(session.snapshot().checkpoint.scene=="quintal","outside checkpoint persisted")
	check(service.advance(2,Scene.AT).status=="wrong_step","outside requires real city position")
	var home:=preload("res://scripts/campaign/neighborhood_checkpoint.gd").HOME
	for i in range(2,8):
		check(service.advance(i,home).status=="ok","outside confession "+str(i))
		check(session.resume_slot("slot-1").status=="ok","resume outside")
	p=session.snapshot().player
	check(Scene.done(p) and Scene.recognition(p),"confession complete reunion pending")
	var partners:Array=p.partners.duplicate(true)
	for i in 5:check(service.advance(i,home).status=="ok","reunion "+str(i))
	p=session.snapshot().player
	check(p.flags.get("retalhoParceiraHeleana",false),"old memories and bond restored")
	check(preload("res://scripts/campaign/kronasta_story.gd").beat_done(p,"retalho-confianca"),"refused arc resolves through Heleana reunion")
	check(preload("res://scripts/campaign/retalho_trust.gd").new(session).claim(Vector2.ZERO).status=="already_applied","reunited Retalho cannot be claimed later")
	check(p.partners==partners and p.coins==0,"no capture duplication XP or reward")
	check(service.advance(5,home).status=="already_applied","reunion once")
	# A fresh save branch cannot be switched by later inventory changes.
	check(session.start("slot-2").status=="ok","second branch save")
	var accepted:Dictionary=State.fresh("slot-2").player
	accepted.partners=[{"id":"ret","modelId":"retalho-original","personalName":"Nuvem","xp":100}];accepted.equippedPartnerId="ret";accepted.journey={"phase":"complete","lesson":5}
	accepted.flags.retalhoAcolhido=true
	check(session.checkpoint(cp,accepted).status=="ok","accepted fixture")
	check(service.advance(0,Scene.ENTRY).status=="wrong_step","accepted branch requires proximity to mother")
	for i in 8:check(service.advance(i,Scene.AT).status=="ok","accepted confession")
	check(Scene.nodes(session.snapshot().player)[3][1].contains("não vão voltar"),"old memories do not return under new bond")
	for i in 5:check(service.advance(i,Scene.AT).status=="ok","accepted recognition")
	accepted=session.snapshot().player
	check(not accepted.flags.get("retalhoParceiraHeleana",false) and accepted.partners[0].personalName=="Nuvem","new bond and player name preserved")
	session.free()
	print("HELEANA CONFESSION: %d checks; %d failures"%[checks,failures]);quit(0 if failures==0 else 1)



