extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Service=preload("res://scripts/campaign/district_campaign.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
var checks:=0
var failures:=0
var session:Node
class FailedStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",text)
func visit(id:String)->Vector2:
	var stage:=Service.stage(id);var saved:Dictionary=session.snapshot()
	for p:Dictionary in saved.player.partners:p.condition={"line":100,"structure":100}
	var map=CP.model_for(stage.scene)
	for e:Dictionary in map.data.events:
		if e.props.get("duel","")!=id:continue
		var at:=Vector2(e.u+.5,e.v+.5)
		check(session.checkpoint(CP.make(stage.scene,at,CP.SPACE),saved.player).status=="ok","visit "+id)
		return at
	check(false,"missing event "+id);return Vector2.INF
func finish(outcome:String)->void:
	var saved:Dictionary=session.snapshot();var model:=Model.new();model.restore(saved.player.encounter.state);model.outcome=outcome
	saved.player.encounter.state=model.snapshot();check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","persist result "+outcome)
func _initialize()->void:
	session=Session.new();session._store=Store.new("user://cais-"+State.new_id());check(session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5};p.coins=100
	check(Story.state(p,"cais")=="fechado","locked before Feira")
	var prior:=Rules.fresh("feira");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(p,"feira",prior)
	check(Story.can_travel(p,"cais"),"Feira opens Cais without requiring mural replay")
	check(session.checkpoint(CP.make("kronasta-cais-a",CP.spawn("kronasta-cais-a"),CP.SPACE),p).status=="ok","save new region")
	var shortcut:Dictionary=CP.data("kronasta-cais-c").events.filter(func(e):return e.props.get("atalho",false))[0]
	check(not CP.allowed(shortcut,p),"shortcut locked before championship")
	var collect=preload("res://scripts/campaign/bosque_campaign.gd").new(session)
	for part:String in ["a","b","c"]:
		var scene:="kronasta-cais-"+part
		for e:Dictionary in CP.data(scene).events:
			if e.type!="item":continue
			var saved_item:Dictionary=session.snapshot();var item_at:=Vector2(e.u+.5,e.v+.5)
			check(session.checkpoint(CP.make(scene,item_at,CP.SPACE),saved_item.player).status=="ok","visit item")
			check(collect.collect(str(int(e.id)),item_at).status=="ok","collect "+scene)
			var copy_item:Dictionary=session.snapshot()
			check(collect.collect(str(int(e.id)),item_at).status=="already_applied" and session.snapshot()==copy_item,"item receipt prevents duplicate")
	var service:=Service.new(session)
	check(service.start("cais-5",Vector2.INF).status=="wrong_step","invalid position rejected")
	var at:=visit("cais-5");check(service.start("cais-5",at).status=="wrong_step","champion waits for four wins")
	for i in 5:
		var id:="cais-"+str(i+1)
		for outcome:String in (["fled","lost","won"] if i==0 else ["won"]):
			at=visit(id)
			var before:int=session.snapshot().player.coins
			check(service.start(id,at).status=="ok","start "+id+" "+outcome)
			check(session.resume_slot("slot-1").status=="ok","suspended encounter reload")
			finish(outcome);check(service.settle().status=="ok","settle "+id+" "+outcome)
			check((id in Rules.entry(session.snapshot().player,"cais").wonDuels)==(outcome=="won"),"only win progresses")
			var copy:Dictionary=session.snapshot()
			check(service.settle().status=="wrong_step" and session.snapshot()==copy,"duplicate settlement cannot award again")
			if outcome!="won":check(session.snapshot().player.coins==before,"no loss or flee coins")
	check(Rules.completed(session.snapshot().player,"cais") and session.snapshot().player.districtEmblems.has("bairro-05"),"fifth emblem")
	check(CP.allowed(shortcut,session.snapshot().player),"shortcut unlocked by permanent district completion")
	check(Story.state(session.snapshot().player,"industrial")=="em-breve" or Story.qa(),"industrial not claimed as built story")
	at=visit("cais-1");check(service.offer_defense("cais-1",at).status=="ok","defense offer")
	check(session.resume_slot("slot-1").status=="ok","pending defense persists")
	check(service.start("cais-1",at,true).status=="ok","defense starts at challenger")
	finish("lost");check(service.settle().status=="ok","defense lost")
	check(Rules.status(session.snapshot().player,"cais")=="requalifying","loss requires all four again")
	check(session.snapshot().player.districtEmblems.size()==1,"permanent emblem retained")
	for i in 5:
		var id:="cais-"+str(i+1);at=visit(id);check(service.start(id,at).status=="ok","reclaim start "+id);finish("won");check(service.settle().status=="ok","reclaim settle "+id)
	check(session.snapshot().player.districtEmblems.size()==1 and Rules.status(session.snapshot().player,"cais")=="won","reclaim no duplicate emblem")
	var saved:Dictionary=session.snapshot();saved.player.partners[0].condition.line=10;saved.player.coins=12
	check(session.checkpoint(CP.make("kronasta-cais-b",Vector2(12.5,30.5),CP.SPACE),saved.player).status=="ok","rest fixture")
	check(service.rest(Vector2.INF).status=="wrong_step","rest invalid point")
	check(service.rest(Vector2(12.5,30.5)).status=="ok" and session.snapshot().player.coins==0,"repair charges 12")
	check(service.rest(Vector2(12.5,30.5)).status=="already_applied","healthy rest free")
	saved=session.snapshot();saved.player.partners[0].condition.line=10;session.checkpoint(saved.checkpoint,saved.player)
	check(service.rest(Vector2(12.5,30.5)).status=="not_enough_coins","poor rest no debt")
	var bad:Node=Session.new();bad._store=FailedStore.new("user://cais-failed");bad._snapshot=session.snapshot();bad._snapshot.player.coins=12
	var copy:Dictionary=bad.snapshot();check(Service.new(bad).rest(Vector2(12.5,30.5)).status=="io_error" and bad.snapshot()==copy,"failed write keeps coins and condition")
	bad.free();session.free();print("CAIS CAMPAIGN: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
