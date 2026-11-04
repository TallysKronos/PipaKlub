extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Session=preload("res://scripts/campaign/session.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Tyler=preload("res://scripts/campaign/tyler_clareira.gd")
const Drafts=preload("res://scripts/campaign/bambuzal_wild_drafts.gd")
const Encounters=preload("res://scripts/campaign/encounters.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
class FailedStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
var checks:=0
var fails:Array[String]=[]
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:fails.append(text);printerr("FAIL "+text)
func _initialize()->void:
	var session:=Session.new();session._store=Store.new("user://tyler-checks-"+State.new_id());check(session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=session.snapshot().player;p.partners=[{"id":"r","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	var at:=Tyler.point()+Vector2.DOWN
	check(CP.model_for("park-clearing").point_walkable(at) and not CP.model_for("park-clearing").path_to(CP.spawn("park-clearing"),at).is_empty(),"Tyler circle reachable from arrival")
	check(session.checkpoint(CP.make("park-clearing",at,CP.SPACE),p).status=="ok","scene checkpoint")
	var service:=Tyler.new(session)
	check(service.advance(0,at).status=="wrong_step","no introduction before Lohan")
	for stage:Dictionary in Rules.definition("bambuzal").stages:
		var plan:=Rules.prepare(p,"bambuzal",stage.id);p=Rules.settle(p,plan.context,"won").player
	check(session.checkpoint(CP.make("park-clearing",at,CP.SPACE),p).status=="ok","Lohan won")
	check(service.advance(0,Vector2.INF).status=="wrong_step","invalid position rejected")
	var original_store:RefCounted=session._store;session._store=FailedStore.new()
	check(service.advance(0,at).status=="io_error" and Tyler.step(session.snapshot().player)==0,"failed write does not consume line")
	session._store=original_store
	var coins:int=p.coins;var inventory:Dictionary=p.inventory.duplicate(true)
	for i in Tyler.nodes().size():
		check(service.advance(i,at).status=="ok","line persisted "+str(i))
		check(session.resume_slot("slot-1").status=="ok" and Tyler.step(session.snapshot().player)==i+1,"resume at next line")
		check(service.advance(i,at).status in ["stale","already_applied"],"duplicate line ignored")
	check(Tyler.done(session.snapshot().player) and service.advance(0,at).status=="already_applied","scene completes once")
	check(session.snapshot().player.coins==coins and session.snapshot().player.inventory==inventory,"scene never invents quest reward or duplicate tail")
	check(not session.snapshot().player.flags.get("ninaTail",false),"existing tail quest preserved")
	check(Drafts.choose(0)==Drafts.IDS[0] and Drafts.choose(.5)=="mata" and Drafts.choose(.9)==Drafts.IDS[1],"three authored pool branches")
	var scene:="kronasta-bambuzal-a";var map=CP.model_for(scene);var grass:=Vector2.INF
	for v in int(map.data.h):
		for u in int(map.data.w):
			var point:=Vector2(u+.5,v+.5)
			if CP.encounter_weight(CP.make(scene,point,CP.SPACE),point)>0:grass=point;break
		if grass.is_finite():break
	check(grass.is_finite(),"optional encounter grass exists")
	for id:String in Drafts.IDS:
		p=session.snapshot().player;p.encounterGraceUntil=0
		check(session.checkpoint(CP.make(scene,grass,CP.SPACE),p).status=="ok","wild position")
		check(Encounters.new(session).start_wild(grass).status=="ok","real wild encounter entry")
		var s:Dictionary=session.snapshot();var model:=Model.new(s.player.partners[0],{"modelId":id,"level":8});model.outcome="won"
		s.player.encounter.state=model.snapshot();s.player.encounter.dropRoll=0.0
		check(session.checkpoint(s.checkpoint,s.player).status=="ok" and session.resume_slot("slot-1").status=="ok","draft battle persists and reloads")
		check(Encounters.new(session).settle().status=="ok","draft victory settles")
		check(session.snapshot().player.inventory.get("rabiola-"+id,0)==1,"correct draft rabiola drops")
		check(Encounters.new(session).settle().status=="wrong_step","wild settlement cannot repeat")
	session.free();print("TYLER AND WILD DRAFTS: %d checks, %d failures"%[checks,fails.size()]);quit(0 if fails.is_empty() else 1)
