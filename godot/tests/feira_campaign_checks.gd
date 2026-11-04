extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const District=preload("res://scripts/campaign/district_campaign.gd")
const Feira=preload("res://scripts/campaign/feira_story.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
var checks:=0
var failures:=0
var session:Node
class FailedStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",text)
func enter(key:String)->Vector2:
	var saved:Dictionary=session.snapshot();var place:Dictionary=Feira.POINTS[key]
	for p:Dictionary in saved.player.partners:p.condition={"line":100,"structure":100}
	check(session.checkpoint(CP.make(place.scene,place.at,CP.SPACE),saved.player).status=="ok","enter "+key)
	return place.at
func terminal(outcome:String)->void:
	var saved:Dictionary=session.snapshot();var model=Model.new();model.restore(saved.player.encounter.state);model.outcome=outcome
	saved.player.encounter.state=model.snapshot();check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","terminal "+outcome)
func _initialize()->void:
	session=Session.new();session._store=Store.new("user://feira-"+State.new_id());check(session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5};p.coins=100
	p.flags={"leagueGreen":true,"comportaVeredasAberta":true,"guardianDefeated":true}
	check(not Feira.unlocked(p),"story locked before Kleie")
	var prior:=Rules.fresh("beira-canal");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(p,"beira-canal",prior)
	check(Feira.unlocked(p),"story unlocked after Kleie")
	check(session.checkpoint(CP.make("kronasta-feira-a",CP.spawn("kronasta-feira-a"),CP.SPACE),p).status=="ok","new scene saves")
	var f:=Feira.new(session);var at:=enter("lalau")
	check(f.buy(Vector2.INF).status=="wrong_step","reject invalid point")
	check(f.begin("lalau",at).status=="wrong_step","cannot fight before detecting counterfeit")
	var poor:Dictionary=session.snapshot();poor.player.coins=0
	check(session.checkpoint(poor.checkpoint,poor.player).status=="ok","poor purchase fixture")
	check(f.buy(at).status=="feira_no_coins" and not session.snapshot().player.flags.get("feiraApitoComprado",false),"purchase cannot create debt or flag without coins")
	poor.player.coins=100;session.checkpoint(poor.checkpoint,poor.player)
	var before:int=session.snapshot().player.coins
	check(f.buy(at).status=="ok","purchase")
	check(session.snapshot().player.coins==before-20,"exact price")
	check(f.buy(at).status=="already_applied","purchase idempotent")
	check(session.snapshot().player.coins==before-20,"no duplicate charge")
	check(session.resume_slot("slot-1").status=="ok","reload purchase")
	check(Feira.phase(session.snapshot().player)=="door","phase persisted")
	at=enter("door");check(f.test_door(at).status=="ok","test door")
	check(f.test_door(at).status=="already_applied","door idempotent")
	check(Feira.phase(session.snapshot().player)=="lalau","return to Lalau")
	at=enter("grampo");check(f.begin("grampo",at).status=="wrong_step","Grampo cannot skip confession")
	at=enter("lalau")
	for outcome:String in ["fled","lost","won"]:
		at=enter("lalau");check(f.begin("lalau",at).status=="ok","Lalau retry "+outcome)
		check(session.resume_slot("slot-1").status=="ok","suspended battle resumes")
		terminal(outcome);check(f.settle().status=="ok","Lalau settle "+outcome)
		check(Feira.phase(session.snapshot().player)==("grampo" if outcome=="won" else "lalau"),"correct phase after "+outcome)
	check(session.snapshot().player.coins==before,"refund once")
	check(f.settle().status=="wrong_step","no duplicate settlement")
	for outcome:String in ["fled","lost","won"]:
		at=enter("grampo");check(f.begin("grampo",at).status=="ok","Grampo retry "+outcome)
		terminal(outcome);check(f.settle().status=="ok","Grampo settle "+outcome)
		check(session.snapshot().player.flags.get("feiraApitoVerdadeiro",false)==(outcome=="won"),"true whistle only on win")
	check(session.snapshot().player.inventory.get("apito-de-vento",0)==1,"one true whistle")
	check(not session.snapshot().player.inventory.has("apito-falso"),"discard counterfeit")
	check(f.begin("grampo",enter("grampo")).status=="already_applied","no repeat story reward")
	var changed:Dictionary=session.snapshot();changed.player.flags.feiraApitoVerdadeiro=false;check(session.checkpoint(changed.checkpoint,changed.player).status=="ok","prerequisite fixture")
	for stage:Dictionary in Rules.definition("feira").stages.slice(0,4):
		var planned:=Rules.prepare(changed.player,"feira",stage.id);check(planned.status=="ok","district sequence "+stage.id)
		changed.player=Rules.settle(changed.player,planned.context,"won").player
	check(Rules.status(changed.player,"feira")=="prerequisite","champion waits for whistle")
	changed.player.flags.feiraApitoVerdadeiro=true
	var plan:=Rules.prepare(changed.player,"feira","feira-5");check(plan.status=="ok","champion unlocked")
	var result:=Rules.settle(changed.player,plan.context,"won");check(result.status=="ok" and Rules.completed(result.player,"feira"),"district completed")
	check("caverna" in Rules.unlocked_areas(result.player),"mural unlock recorded")
	check(Rules.unlocked(result.player,"cais"),"next district unlocked")
	check(session.checkpoint(CP.make("kronasta-feira-b",Feira.POINTS.rest.at,CP.SPACE),result.player).status=="ok","rest save")
	check(f.rest(Feira.POINTS.rest.at).status=="already_applied","healthy rest free")
	changed=session.snapshot();changed.player.partners[0].condition.line=20;changed.player.coins=12;check(session.checkpoint(changed.checkpoint,changed.player).status=="ok","rest fixture")
	check(f.rest(Feira.POINTS.rest.at).status=="ok" and session.snapshot().player.coins==0,"rest charges 12")
	changed=session.snapshot();changed.player.partners[0].condition.line=10;changed.player.coins=0;session.checkpoint(changed.checkpoint,changed.player)
	check(f.rest(Feira.POINTS.rest.at).status=="not_enough_coins","poor rest rejected")
	var bad:Node=Session.new();bad._store=FailedStore.new("user://feira-failed");bad._snapshot=session.snapshot();bad._snapshot.checkpoint=CP.make("kronasta-feira-a",Feira.POINTS.lalau.at,CP.SPACE);bad._snapshot.player.flags={};bad._snapshot.player.completedOperations=[];bad._snapshot.player.coins=50
	var copy:Dictionary=bad.snapshot();var failed:Dictionary=Feira.new(bad).buy(Feira.POINTS.lalau.at);check(failed.status=="io_error","failed write rejected")
	check(bad.snapshot()==copy,"failed write keeps coins and flags unchanged")
	bad.free();session.free();print("FEIRA CAMPAIGN: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
