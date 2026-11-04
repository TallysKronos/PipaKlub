extends SceneTree
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Service=preload("res://scripts/campaign/district_campaign.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
const Travel=preload("res://scripts/campaign/bosque_campaign.gd")
var checks:=0
var failures:Array[String]=[]
var session:Node
func check(value:bool,text:String)->void:
	checks+=1
	if not value:failures.append(text);printerr("FAIL "+text)
func target(id:String)->Vector2:
	var entry:=Service.stage(id)
	for event:Dictionary in CP.data(entry.scene).events:
		if event.props.get("duel","")==id:return Vector2(event.u+.5,event.v+.5)
	return Vector2.INF
func enter(id:String)->Vector2:
	var saved:Dictionary=session.snapshot()
	var at:=target(id)
	check(at.is_finite(),"authored duel position "+id)
	if at.is_finite():check(session.checkpoint(CP.make(Service.stage(id).scene,at,CP.SPACE),saved.player).status=="ok","checkpoint "+id)
	return at
func terminal(outcome:String)->void:
	var saved:Dictionary=session.snapshot();var model:=Model.new();model.restore(saved.player.encounter.state)
	model.outcome=outcome
	if outcome=="won":model.p.rounds=model.rounds_to_win
	if outcome=="lost":model.q.rounds=model.rounds_to_win
	saved.player.encounter.state=model.snapshot()
	check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","terminal saved "+outcome)
func _initialize()->void:
	session=Session.new();session._store=Store.new("user://bambuzal-checks-"+State.new_id())
	check(session.start("slot-1").status=="ok","isolated slot")
	var p:Dictionary=session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	check(session.checkpoint({"kind":"world","scene":"quintal","position":[1792,1808]},p).status=="ok","journey fixture")
	check(Story.state(p,"bambuzal")=="fechado" and Travel.new(session).travel("kronasta-bambuzal-a").status=="wrong_step","locked before Mikka even through travel API")
	check(not Story.park_access(p,"park-clearing") and Travel.new(session).travel("park-clearing").status=="wrong_step","new journey cannot bypass Lohan by fast travel")
	var legacy:Dictionary=p.duplicate(true);legacy.flags.ninaAccepted=true
	check(Story.park_access(legacy,"park-clearing"),"already accepted legacy quest retains its route")
	legacy.flags.ninaBambuzalOrder=true
	check(not Story.park_access(legacy,"park-clearing"),"new Nina quest waits for Lohan")
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	check(session.checkpoint({"kind":"world","scene":"quintal","position":[1792,1808]},p).status=="ok","legacy Morro victory")
	check(Story.state(p,"bambuzal")=="aberto" and Travel.new(session).travel("kronasta-bambuzal-a").status=="ok","Mikka unlocks actual travel")
	var service:=Service.new(session)
	var at:=enter("bambuzal-1")
	check(service.start("bambuzal-1",Vector2.INF).status=="wrong_step" and service.start("bambuzal-1",at+Vector2(8,8)).status=="wrong_step","remote/NaN battle forbidden")
	check(service.start("bambuzal-2",at).status=="wrong_step","sequence enforced")
	for outcome in ["lost","fled"]:
		check(service.start("bambuzal-1",at).status=="ok","loss fixture starts")
		terminal(outcome);check(service.settle().status=="ok","loss/flee settles")
		check(Rules.entry(session.snapshot().player,"bambuzal").qualification.is_empty(),"loss/flee never advances")
	for i in 5:
		var id:="bambuzal-"+str(i+1);at=enter(id)
		var result:Dictionary=service.start(id,at)
		check(result.status=="ok","duel starts "+id+" "+result.status)
		if result.status!="ok":session.free();quit(1);return
		check(session.snapshot().player.encounter.state.q.level==Service.stage(id).level,"enemy actual level matches catalog")
		check(session.resume_slot("slot-1").status=="ok","suspended duel resumes")
		var round_model:=Model.new();round_model.restore(session.snapshot().player.encounter.state);round_model._new_round()
		check(round_model.q.level==Service.stage(id).level and round_model.p.has("level"),"level retained between rounds")
		terminal("won")
		var before:Dictionary=session.snapshot();var preview_model:=Model.new();preview_model.restore(before.player.encounter.state)
		var preview:Dictionary=preload("res://scripts/campaign/hud_rewards.gd").preview(before.player,before.player.encounter,preview_model)
		check(service.settle().status=="ok","victory settles "+id)
		check(session.snapshot().player.coins-before.player.coins==preview.coins and session.snapshot().player.partners[0].xp-before.player.partners[0].xp==preview.xp,"reward screen matches committed reward")
		var coins:int=session.snapshot().player.coins
		check(service.settle().status=="wrong_step" and session.snapshot().player.coins==coins,"receipt cannot pay twice")
		check(service.start(id,at).status=="already_applied","story duel never replays")
	check(Story.state(session.snapshot().player,"bambuzal")=="vencido" and Story.can_travel(session.snapshot().player,"bambuzal"),"won district stays explorable")
	check(Rules.unlocked(session.snapshot().player,"beira-canal") and "park-clearing" in Rules.unlocked_areas(session.snapshot().player),"next district and story area unlock")
	check(Story.park_access(session.snapshot().player,"park-clearing"),"Lohan opens the actual Clareira route")
	check(session.snapshot().player.districtEmblems.has("bairro-02"),"second emblem persisted")
	at=enter("bambuzal-1")
	check(service.offer_defense("bambuzal-1",at).status=="ok","title challenge offered")
	check(session.resume_slot("slot-1").status=="ok" and service.start("bambuzal-1",at,true).status=="ok","pending defense resumes into native encounter")
	terminal("lost");check(service.settle().status=="ok","title lost")
	check(Rules.entry(session.snapshot().player,"bambuzal").champion=="bambu-1","Nara becomes current champion")
	for i in 5:
		var id:="bambuzal-"+str(i+1);at=enter(id)
		check(service.start(id,at).status=="ok","requalification "+id)
		if i==4:check(session.snapshot().player.encounter.state.q.name=="Nara","reclaim fights current champion")
		terminal("won");check(service.settle().status=="ok","requalification result")
	check(Rules.status(session.snapshot().player,"bambuzal")=="won" and not session.snapshot().player.lastDistrict.emblem,"reclaim keeps unique emblem")
	for part in "abc":
		var scene:="kronasta-bambuzal-"+part
		var data:Dictionary=CP.data(scene)
		for event:Dictionary in data.events:
			var point:=Vector2(event.u+.5,event.v+.5)
			if event.type=="item":
				check(session.checkpoint(CP.make(scene,point,CP.SPACE),session.snapshot().player).status=="ok","item checkpoint")
				var collector:=Travel.new(session)
				check(collector.collect(str(int(event.id)),point).status=="ok","authored item collectible "+part)
				check(collector.collect(str(int(event.id)),point).status=="already_applied","item receipt unique")
			if event.props.get("acao","")=="bambuzalClue":
				check(session.checkpoint(CP.make(scene,point,CP.SPACE),session.snapshot().player).status=="ok","clue checkpoint")
				check(service.inspect_clue(str(int(event.id)),point).status=="ok" and session.snapshot().player.flags.bambuzalCorteDescoberto,"clue persists")
			if event.props.get("acao","")=="wildRest":
				check(session.checkpoint(CP.make(scene,point,CP.SPACE),session.snapshot().player).status=="ok","rest checkpoint")
				check(preload("res://scripts/campaign/exploration.gd").new(session).rest(point).status=="ok","authored rest usable")
	check(session.resume_slot("slot-1").status=="ok","complete save loads")
	session.free()
	print("BAMBUZAL CAMPAIGN: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
