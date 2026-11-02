extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Service=preload("res://scripts/campaign/district_campaign.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
var checks:=0
var failures:=0
var session:Node
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func visit(id:String)->Vector2:
	var stage:=Service.stage(id)
	var event:Dictionary=CP.data(stage.scene).events.filter(func(e):return e.props.get("duel","")==id)[0]
	var point:=Vector2(event.u+.5,event.v+.5)
	var saved:Dictionary=session.snapshot()
	for partner:Dictionary in saved.player.partners:partner.condition={"line":100,"structure":100}
	check(session.checkpoint(CP.make(stage.scene,point,CP.SPACE),saved.player).status=="ok","visit "+id)
	return point
func finish(outcome:String)->void:
	var saved:Dictionary=session.snapshot()
	var model:=Model.new();model.restore(saved.player.encounter.state);model.outcome=outcome
	saved.player.encounter.state=model.snapshot()
	check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","persist terminal")
func _initialize()->void:
	session=Session.new();session._store=Store.new("user://vila-"+State.new_id())
	check(session.start("slot-1").status=="ok","isolated save")
	var player:Dictionary=session.snapshot().player
	player.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="r";player.journey={"phase":"complete","lesson":5}
	var prior:=Rules.fresh("cais");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(player,"cais",prior)
	check(session.checkpoint(CP.make("kronasta-industrial-a",CP.spawn("kronasta-industrial-a"),CP.SPACE),player).status=="ok","preview fixture")
	var service:=Service.new(session)
	check(service.start("industrial-1",Vector2.INF).status=="wrong_step","invalid point")
	for i in 4:
		var id:="industrial-"+str(i+1)
		for outcome:String in (["fled","lost","won"] if i==0 else ["won"]):
			var point:=visit(id)
			check(service.start(id,point+Vector2(8,0)).status=="wrong_step","remote duel rejected")
			var started:Dictionary=service.start(id,point)
			check(started.status=="ok","start "+id+" "+outcome+" "+str(started))
			if started.status!="ok":session.free();quit(1);return
			check(session.resume_slot("slot-1").status=="ok","suspended duel resumes")
			finish(outcome)
			check(service.settle().status=="ok","settle "+id+" "+outcome)
			check((id in Rules.entry(session.snapshot().player,"industrial").qualification)==(outcome=="won"),"only win progresses")
			var copy:Dictionary=session.snapshot()
			check(service.settle().status=="wrong_step" and session.snapshot()==copy,"no duplicate receipt or reward")
	var point:=visit("industrial-5")
	check(service.start("industrial-5",point).status=="wrong_step","four wins cannot bypass warehouse")
	check(service.objective(session.snapshot().player,"industrial").contains("Pipa-Dragão"),"warehouse objective is accurate")
	var saved:Dictionary=session.snapshot()
	# Isolated prerequisite fixture; the real warehouse receipt is covered in warehouse_story_checks.gd.
	saved.player.flags.pipaDragaoDesatadaVencida=true
	check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","test warehouse result")
	check(service.start("industrial-5",point).status=="ok","champion after prerequisite")
	finish("won");check(service.settle().status=="ok","champion settlement")
	check(Rules.completed(session.snapshot().player,"industrial") and session.snapshot().player.districtEmblems.has("bairro-06"),"sixth emblem recorded")
	check(session.resume_slot("slot-1").status=="ok" and Rules.completed(session.snapshot().player,"industrial"),"completion persists")
	session.free()
	print("VILA OPERARIA CAMPAIGN: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
