extends SceneTree
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Morro=preload("res://scripts/campaign/morro.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
var checks:=0
var failures:Array[String]=[]
var session:Node
class FailingStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
func same_data(a:Variant,b:Variant)->bool:
	return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL "+text)
func base_player()->Dictionary:
	var p:Dictionary=State.fresh("slot-1").player
	p.partners=[{"id":"test","modelId":"basica","xp":0,"condition":{"line":100,"structure":100}}]
	p.equippedPartnerId="test";p.journey={"phase":"complete","lesson":5}
	return p
func terminal(outcome:String)->void:
	var saved:Dictionary=session.snapshot()
	var model:=Model.new();model.restore(saved.player.encounter.state)
	model.outcome=outcome
	if outcome=="won":model.p.rounds=model.rounds_to_win
	if outcome=="lost":model.q.rounds=model.rounds_to_win
	saved.player.encounter.state=model.snapshot()
	check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","persist terminal "+outcome)
func goto_stage(index:int)->Vector2:
	var stage:Dictionary=Rules.definition("morro").stages[index]
	var place:Dictionary=Morro.maps()[stage.scene].places.filter(func(p):return p.has("stage"))[0]
	var saved:Dictionary=session.snapshot()
	saved.player.partners[0].condition={"line":100,"structure":100}
	check(session.checkpoint({"kind":"world","scene":stage.scene,"position":place.point},saved.player).status=="ok","visit stage "+str(index))
	return Vector2(place.point[0],place.point[1])
func pure_model()->void:
	var p:=base_player()
	check(Rules.catalog().size()==12,"twelve district definitions")
	for d:Dictionary in Rules.catalog():
		check(d.stages.size()==5 and d.stages.map(func(s):return s.part)==["A","A","B","B","C"],"AABB C "+d.id)
		check(Rules.unlocked(p,d.id),"previous victory unlocks "+d.id)
		for i in 5:
			var stage:Dictionary=d.stages[i]
			if i==4 and not d.prerequisiteFlag.is_empty():
				check(Rules.prepare(p,d.id,stage.id).status=="wrong_step","optional prerequisite blocks champion")
				p.flags[d.prerequisiteFlag]=true
			var plan:=Rules.prepare(p,d.id,stage.id)
			check(plan.status=="ok","prepare "+stage.id)
			if plan.status!="ok":return
			var serialized:Dictionary=JSON.parse_string(JSON.stringify(plan.context))
			check(Rules.same_context(plan.context,serialized),"context survives JSON "+stage.id)
			var settled:=Rules.settle(p,serialized,"won")
			check(settled.status=="ok" and settled.firstClear,"settle first "+stage.id)
			p=settled.player
			check(Rules.valid(p.championship),"schema "+stage.id)
			check(Rules.prepare(p,d.id,stage.id).status=="already_applied","no replay "+stage.id)
		check(Rules.award_emblem(p,d.id),"first emblem "+d.id)
		check(not Rules.award_emblem(p,d.id),"no duplicate emblem "+d.id)
		check(Story.neighbourhoods_won(p)==int(d.number),"story counts generic history")
	check(Rules.city_final_unlocked(p),"twelve historical completions open municipal final")
	check(p.districtEmblems.size()==12,"twelve emblem slots")
	var old:=base_player();old.morro=Morro.Rules.defaults();old.morro.stars={"morro-1":3,"morro-2":2,"morro-3":1,"morro-4":3,"morro-5":2}
	var copy:=old.duplicate(true)
	check(Rules.completed_count(old)==1 and old==copy,"legacy migration is additive and read only")
	check(Rules.entry(old,"morro").rewardClaimed,"legacy reward retained")
	var corrupt:Dictionary=p.championship.duplicate(true);corrupt.districts.morro.qualification=["invalid"]
	check(not Rules.valid(corrupt),"unknown qualification rejected")
func transactions()->void:
	session=Session.new();session._store=Store.new("user://pip92-"+State.new_id())
	check(session.start("slot-1").status=="ok","isolated slot")
	check(session.checkpoint({"kind":"world","scene":"morro","position":[528,752]},base_player()).status=="ok","initial world")
	var service:=Morro.new(session)
	for i in 5:
		var point:=goto_stage(i)
		var started:Dictionary=service.start(point)
		check(started.status=="ok","story start "+str(i)+" "+str(started.status))
		if started.status!="ok":session.free();return
		terminal("won")
		check(service.settle().status=="ok","story settle "+str(i))
	check(Rules.status(session.snapshot().player,"morro")=="won","initial title")
	check(session.snapshot().player.inventory["rabiola-raio"]==1,"first tail")
	var emblem:Dictionary=session.snapshot().player.districtEmblems.duplicate(true)
	var point:=goto_stage(0)
	check(service.offer_defense(point+Vector2(500,0)).status=="wrong_step","remote challenge rejected")
	check(service.offer_defense(point).status=="ok","NPC issues persisted challenge")
	var challenge:Dictionary=Rules.entry(session.snapshot().player,"morro").pendingDefense
	check(service.offer_defense(point).status=="already_applied","one pending challenge only")
	check(session.resume_slot("slot-1").status=="ok" and Rules.entry(session.snapshot().player,"morro").pendingDefense==challenge,"pending challenge reload")
	check(service.start(point).status=="defense_pending","normal battle cannot replace defense")
	var started:Dictionary=service.start_defense(point)
	check(started.status=="ok","defense start "+str(started.status))
	if started.status!="ok":session.free();return
	check(session.snapshot().player.encounter.state.q.name=="Zeca","challenger is the actual opponent")
	check(session.resume_slot("slot-1").status=="ok","mid defense resumes")
	terminal("won");check(service.settle().status=="ok","successful defense")
	check(Rules.status(session.snapshot().player,"morro")=="won","winning retains title")
	check(service.offer_defense(point).status=="ok","next explicit challenge")
	check(service.start_defense(point).status=="ok","defense starts again")
	terminal("lost")
	var before_failure:Dictionary=session.snapshot()
	var disk:RefCounted=session._store
	session._store=FailingStore.new()
	check(service.settle().status=="io_error" and same_data(session.snapshot(),before_failure),"failed save changes no title or reward")
	session._store=disk
	check(service.settle().status=="ok","lost defense retried after IO failure")
	var lost:Dictionary=Rules.entry(session.snapshot().player,"morro")
	check(lost.completed and lost.champion=="zeca" and lost.qualification.is_empty(),"loss changes holder, keeps history")
	check(Rules.unlocked(session.snapshot().player,"bambuzal") and "park-trail" in Rules.unlocked_areas(session.snapshot().player),"unlock survives loss")
	check(same_data(session.snapshot().player.districtEmblems,emblem),"emblem survives loss")
	check(service.settle().status=="wrong_step","settlement cannot duplicate")
	point=goto_stage(4)
	check(service.start(point).status=="wrong_step","must beat four again before reclaim")
	for i in 4:
		point=goto_stage(i)
		check(service.start(point).status=="ok","requalify start "+str(i))
		terminal("won");check(service.settle().status=="ok","requalify settle "+str(i))
	point=goto_stage(4)
	check(service.start(point).status=="ok","reclaim allowed")
	check(session.snapshot().player.encounter.state.q.name=="Zeca","new holder replaces champion in combat")
	terminal("won");check(service.settle().status=="ok","reclaim settles")
	check(Rules.status(session.snapshot().player,"morro")=="won","title recovered")
	check(session.snapshot().player.inventory["rabiola-raio"]==1 and same_data(session.snapshot().player.districtEmblems,emblem),"reclaim does not duplicate first rewards")
	point=goto_stage(1)
	check(service.offer_defense(point).status=="ok" and service.start_defense(point).status=="ok","Bia defense")
	terminal("fled");check(service.settle().status=="ok","explicit fleeing settles defense")
	check(Rules.entry(session.snapshot().player,"morro").champion=="bia","explicit defense forfeit loses title")
	check(session.resume_slot("slot-1").status=="ok" and Rules.status(session.snapshot().player,"morro")=="requalifying","lost title survives reload")
	point=goto_stage(0)
	check(service.start(point).status=="ok","stale session fixture starts")
	terminal("won")
	var other:=Session.new();other._store=Store.new(session._store.directory)
	check(other.resume_slot("slot-1").status=="ok","second session reads same revision")
	check(service.settle().status=="ok","first writer settles")
	var balance:int=session.snapshot().player.coins
	check(Morro.new(other).settle().status=="stale","second writer is rejected")
	check(session.resume_slot("slot-1").status=="ok" and session.snapshot().player.coins==balance,"stale writer cannot duplicate reward")
	other.free()
	session.free()
func _initialize()->void:
	pure_model();transactions()
	print("DISTRICTS: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
