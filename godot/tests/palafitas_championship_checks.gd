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
	var at:=Vector2(stage.point[0]+.5,stage.point[1]+.5)
	var saved:Dictionary=session.snapshot()
	for partner:Dictionary in saved.player.partners:partner.condition={"line":100,"structure":100}
	check(session.checkpoint(CP.make(stage.scene,at,CP.SPACE),saved.player).status=="ok","visit "+id)
	return at
func finish(outcome:String)->void:
	var saved:Dictionary=session.snapshot()
	var model:=Model.new();model.restore(saved.player.encounter.state);model.outcome=outcome
	saved.player.encounter.state=model.snapshot()
	check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","terminal fixture")
func _initialize()->void:
	session=Session.new();session._store=Store.new("user://palafitas-save-"+State.new_id())
	check(session.start("slot-1").status=="ok","isolated save")
	var player:Dictionary=session.snapshot().player
	player.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="r";player.journey={"phase":"complete","lesson":5}
	var prior:=Rules.fresh("industrial");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(player,"industrial",prior)
	check(not Rules.unlocked(player,"palafitas"),"Mormaco gates championship even after Bruno")
	var events:Array=load("res://scripts/campaign/palafitas_championship.gd").events("kronasta-palafitas-a")
	check(events.size()==2 and not CP.allowed(events[0],player),"early rescue does not expose championship")
	player.flags.mormacoLiberto=true
	check(Rules.unlocked(player,"palafitas"),"both prerequisites unlock championship")
	check(session.checkpoint(CP.make("kronasta-palafitas-a",CP.spawn("kronasta-palafitas-a"),CP.SPACE),player).status=="ok","fixture ready")
	var service:=Service.new(session)
	check(service.start("palafitas-1",Vector2.INF).status=="wrong_step","invalid location rejected")
	check(service.start("palafitas-5",Vector2(26.5,12.5)).status=="wrong_step","cannot skip opponents")
	for i in 5:
		var id:="palafitas-"+str(i+1)
		var stage:=Service.stage(id)
		if i==4:check(Service.objective(session.snapshot().player,"palafitas").contains("Caio Garça"),"objective names final destination after qualification")
		var map=CP.model_for(stage.scene)
		var at:=Vector2(stage.point[0]+.5,stage.point[1]+.5)
		check(map.point_walkable(at) and FileAccess.file_exists(stage.storySpritePath),"reachable art "+id)
		check(map.data.events.filter(func(e):return e.props.get("duel","")==id).size()==1,"one event "+id)
		for outcome:String in (["fled","lost","won"] if i==0 or i==4 else ["won"]):
			var point:=visit(id)
			check(service.start(id,point+Vector2(8,0)).status=="wrong_step","remote rejected")
			var started:Dictionary=service.start(id,point)
			check(started.status=="ok","start "+id+" "+outcome+" "+str(started))
			if started.status!="ok":session.free();quit(1);return
			if i==4:
				var active:Dictionary=session.snapshot()
				var active_model:=Model.new();active_model.restore(active.player.encounter.state)
				check(active_model.enemy_model_id=="veskoro","Caio battle uses Veskoro")
				var legacy:Dictionary=active.player.encounter.duplicate(true)
				legacy.state.enemyModelId="mata";legacy.state.erase("veskoro")
				check(State.valid_encounter(legacy),"old in-progress Caio placeholder save remains loadable")
				var forged:Dictionary=active.player.encounter.duplicate(true)
				forged.districtContext.opponent="seyran"
				check(not State.valid_encounter(forged),"Veskoro cannot be attached to another owner")
				active_model.intro=0
				for tick in 190:active_model.tick(1.0/60,{})
				check(active_model.veskoro.phase=="warn","suspend while poison warning is active")
				active.player.encounter.state=active_model.snapshot()
				check(session.checkpoint(active.checkpoint,active.player).status=="ok","save active warning")
			check(session.resume_slot("slot-1").status=="ok","encounter resumes")
			finish(outcome)
			check(service.settle().status=="ok","settle "+outcome)
			if i<4:check((id in Rules.entry(session.snapshot().player,"palafitas").qualification)==(outcome=="won"),"only victory qualifies")
			else:check(Rules.completed(session.snapshot().player,"palafitas")== (outcome=="won"),"only champion victory completes")
			var saved:Dictionary=session.snapshot()
			check(service.settle().status=="wrong_step" and session.snapshot()==saved,"duplicate settlement has no effect")
	player=session.snapshot().player
	check(player.districtEmblems.has("bairro-07"),"seventh emblem recorded")
	check(Rules.completed(player,"palafitas") and Rules.unlocked(player,"alto-da-serra"),"historical next district unlock")
	check(not load("res://scripts/campaign/kronasta_story.gd").can_travel(player,"alto-da-serra"),"unbuilt Serra not falsely travelable")
	var offer:=Rules.offer(player,"palafitas","seyran","palafitas-defense","kronasta-palafitas-a")
	check(offer.status=="ok","defense offered")
	var defense:=Rules.prepare(offer.player,"palafitas","palafitas-5","palafitas-defense")
	var defeat:=Rules.settle(offer.player,defense.context,"lost")
	check(defeat.status=="ok" and Rules.entry(defeat.player,"palafitas").champion=="seyran" and Rules.entry(defeat.player,"palafitas").qualification.is_empty(),"title loss requires four victories again")
	check(Rules.completed(defeat.player,"palafitas") and defeat.player.districtEmblems.has("bairro-07"),"history and emblem survive defense loss")
	check(session.resume_slot("slot-1").status=="ok" and Rules.completed(session.snapshot().player,"palafitas"),"completion reloads")
	session.free()
	print("PALAFITAS CHAMPIONSHIP: %d checks; %d failures; terminal outcomes are fixtures"%[checks,failures])
	quit(0 if failures==0 else 1)
