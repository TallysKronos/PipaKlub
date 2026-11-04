extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Mural=preload("res://scripts/campaign/mural_story.gd")
var checks:=0
var failures:=0
class FailedStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func _initialize()->void:
	var session=Session.new();session._store=Store.new("user://mural-"+State.new_id())
	check(session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=session.snapshot().player
	check(not Mural.available(p),"locked before Feira")
	var district:=Rules.fresh("feira");district.completed=true;district.rewardClaimed=true;district.champion="player";Rules.store(p,"feira",district)
	p.flags.feiraApitoVerdadeiro=true
	check(not Mural.available(p),"requires actual whistle")
	p.inventory["apito-de-vento"]=1
	check(Mural.available(p),"canonical access")
	p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":20,"structure":30}}];p.equippedPartnerId="r"
	check(session.checkpoint(CP.make("caverna-mural-c",Mural.AT,CP.SPACE),p).status=="ok","cave checkpoint accepted")
	var service=Mural.new(session)
	check(service.advance(0,Vector2.INF).status=="wrong_step","invalid point")
	check(service.advance(1,Mural.AT).status=="wrong_step","cannot skip panel")
	check(service.advance(0,Vector2(25.5,37.5)).status=="wrong_step","cannot read remotely")
	check(session.resume_slot("slot-1").status=="ok","normalize persisted fixture")
	var before:Dictionary=session.snapshot().player.duplicate(true)
	for i:int in 3:
		check(service.advance(i,Mural.AT).status=="ok","read panel "+str(i))
		check(session.resume_slot("slot-1").status=="ok","resume partial reading")
		check(Mural.step(session.snapshot().player)==i+1,"persistent ordered progress")
	check(service.advance(2,Mural.AT).status=="already_applied","completion idempotent")
	var after:Dictionary=session.snapshot().player
	check(after.partners==before.partners and after.inventory==before.inventory and after.coins==before.coins,"no duplicate reward or health change")
	check(session.checkpoint(CP.make("caverna-mural-b",Mural.REST,CP.SPACE),after).status=="ok","rest checkpoint")
	check(service.advance(0,Mural.AT).status=="wrong_step","wrong scene rejected")
	check(service.rest(Mural.REST).status=="ok","rest recovers partners")
	check(session.snapshot().player.partners[0].condition.line==100,"recovered")
	check(service.rest(Mural.REST).status=="already_applied","healthy rest unchanged")
	var bad=Session.new();bad._store=FailedStore.new("user://mural-failed");bad._snapshot=session.snapshot();bad._snapshot.checkpoint=CP.make("caverna-mural-c",Mural.AT,CP.SPACE)
	for flag:String in Mural.FLAGS:bad._snapshot.player.flags.erase(flag)
	bad._snapshot.player.completedOperations=[]
	var copy:Dictionary=bad.snapshot()
	check(Mural.new(bad).advance(0,Mural.AT).status=="io_error","failed write reported")
	check(bad.snapshot()==copy,"failed write rolls back progress")
	bad.free();session.free()
	print("MURAL CAMPAIGN: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)

