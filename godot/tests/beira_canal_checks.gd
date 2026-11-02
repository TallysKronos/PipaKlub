extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Session=preload("res://scripts/campaign/session.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const District=preload("res://scripts/campaign/district_campaign.gd")
const Gate=preload("res://scripts/campaign/canal_gate.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
var checks:=0
var failures:Array[String]=[]
var session:Node
class FailedStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL "+text)
func terminal(outcome:String)->void:
	var saved:Dictionary=session.snapshot();var model=Model.new() if saved.player.encounter.kind=="district" else preload("res://scripts/campaign/encounter_model.gd").new()
	model.restore(saved.player.encounter.state);model.outcome=outcome
	if saved.player.encounter.kind=="district":
		if outcome=="won":model.p.rounds=model.rounds_to_win
		if outcome=="lost":model.q.rounds=model.rounds_to_win
	saved.player.encounter.state=model.snapshot()
	check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","terminal persisted "+outcome)
func enter(id:String)->Vector2:
	var saved:Dictionary=session.snapshot();var stage:=District.stage(id)
	for e:Dictionary in CP.data(stage.scene).events:
		if e.props.get("duel")==id:
			var at:=Vector2(e.u+.5,e.v+.5)
			for p:Dictionary in saved.player.partners:p.condition={"line":100,"structure":100}
			check(session.checkpoint(CP.make(stage.scene,at,CP.SPACE),saved.player).status=="ok","enter "+id);return at
	return Vector2.INF
func _initialize()->void:
	session=Session.new();session._store=Store.new("user://beira-"+State.new_id());check(session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=session.snapshot().player;p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	for stage:Dictionary in Rules.definition("bambuzal").stages:
		var plan:=Rules.prepare(p,"bambuzal",stage.id);p=Rules.settle(p,plan.context,"won").player
	check(Story.state(p,"beira-canal")=="fechado","category required for map")
	p.flags.merge({"leagueGreen":true,"ninaGlideLoanAvailable":true,"guardianDefeated":true,"ninaReturned":true})
	check(Story.state(p,"beira-canal")=="aberto","category opens map")
	check(session.checkpoint(CP.make("kronasta-beira-canal-a",CP.spawn("kronasta-beira-canal-a"),CP.SPACE),p).status=="ok","arrival")
	var district:=District.new(session);var gate:=Gate.new(session)
	var at:=enter("beira-canal-1")
	check(district.start("beira-canal-1",Vector2.INF).status=="wrong_step","invalid position")
	check(district.start("beira-canal-2",at).status=="wrong_step","sequence enforced")
	for i in 4:
		var id:="beira-canal-"+str(i+1);at=enter(id)
		check(district.start(id,at).status=="ok","duel starts "+id)
		check(session.resume_slot("slot-1").status=="ok","suspended duel resumes")
		terminal("won");var before:int=session.snapshot().player.coins
		check(district.settle().status=="ok","duel settles")
		check(session.snapshot().player.coins>before,"first reward")
		check(district.settle().status=="wrong_step","duplicate settlement rejected")
	check(Rules.status(session.snapshot().player,"beira-canal")=="prerequisite","Kleie waits for valve")
	at=enter("beira-canal-5");check(district.start("beira-canal-5",at).status=="wrong_step","champion cannot bypass valve")
	check(session.checkpoint(CP.make("park-veredas",Gate.AT,CP.SPACE),session.snapshot().player).status=="ok","to valve")
	check(CP.model_for("park-veredas").point_walkable(Gate.AT) and not CP.model_for("park-veredas").path_to(CP.spawn("park-veredas"),Gate.AT).is_empty(),"valve reachable on firm ground")
	check(gate.open(Gate.AT).status=="wrong_step","cannot open before Grampo")
	check(gate.begin(Vector2.INF).status=="wrong_step","remote story battle rejected")
	for outcome in ["lost","fled","won"]:
		check(session.checkpoint(CP.make("park-veredas",Gate.AT,CP.SPACE),session.snapshot().player).status=="ok","valve retry fixture")
		p=session.snapshot().player;p.partners[0].condition={"line":100,"structure":100};session.checkpoint(session.snapshot().checkpoint,p)
		check(gate.begin(Gate.AT).status=="ok","Grampo starts "+outcome)
		if session.snapshot().checkpoint.kind!="encounter":session.free();quit(1);return
		check(session.resume_slot("slot-1").status=="ok","story battle resumes")
		terminal(outcome);var coins:int=session.snapshot().player.coins
		check(gate.settle().status=="ok","story battle settles")
		check(session.snapshot().player.coins==coins and session.snapshot().player.flags.get("grampoVeredasVencido",false)==(outcome=="won"),"only victory advances, no loot")
	check(gate.open(Gate.AT).status=="ok","valve persists")
	check(gate.open(Gate.AT).status=="already_applied","valve idempotent")
	check(session.snapshot().player.flags.guardianDefeated,"old guardian stays defeated")
	at=enter("beira-canal-5");check(district.start("beira-canal-5",at).status=="ok","Kleie now accepts")
	terminal("won");check(district.settle().status=="ok","Kleie settlement")
	check(Rules.completed(session.snapshot().player,"beira-canal") and session.snapshot().player.districtEmblems.has("bairro-03"),"third emblem and completion")
	check(Rules.unlocked(session.snapshot().player,"feira") and Story.state(session.snapshot().player,"feira")=="aberto","next authored district opens after Kleie")
	at=enter("beira-canal-1");check(district.offer_defense("beira-canal-1",at).status=="ok","defense offered")
	check(district.start("beira-canal-1",at,true).status=="ok","defense starts")
	terminal("lost");check(district.settle().status=="ok","title lost")
	check(Rules.entry(session.snapshot().player,"beira-canal").qualification.is_empty() and Rules.completed(session.snapshot().player,"beira-canal"),"requalification resets but historical completion remains")
	check(session.resume_slot("slot-1").status=="ok","final reload")
	p=session.snapshot().player;p.coins=20;p.partners[0].condition={"line":20,"structure":40}
	check(session.checkpoint(CP.make("kronasta-beira-canal-b",Vector2(22.5,30.5),CP.SPACE),p).status=="ok","rest fixture")
	var disk:RefCounted=session._store;session._store=FailedStore.new()
	check(gate.rest(Vector2(22.5,30.5)).status=="io_error" and session.snapshot().player.coins==20,"failed rest save never charges")
	session._store=disk
	check(gate.rest(Vector2(22.5,30.5)).status=="ok" and session.snapshot().player.coins==8 and session.snapshot().player.partners[0].condition.line==100,"paid rest recovers once")
	check(gate.rest(Vector2(22.5,30.5)).status=="already_applied" and session.snapshot().player.coins==8,"healthy team pays nothing")
	session.free();print("BEIRA CANAL: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
