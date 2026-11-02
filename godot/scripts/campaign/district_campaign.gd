extends RefCounted
## Native district adapter. Every result and reward shares the encounter receipt.
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
const Progression=preload("res://scripts/campaign/progression.gd")
var session:Node
func _init(active:Node)->void:session=active
static func stage(id:String)->Dictionary:
	for district:Dictionary in Rules.catalog():
		for entry:Dictionary in district.stages:
			if entry.id==id and entry.get("authored",false):
				entry.district=district.id;return entry
	return {}
static func objective(player:Dictionary,district:String="bambuzal")->String:
	var title:=Rules.objective(player,district)
	if not title.is_empty():return title
	var value:=Rules.entry(player,district)
	for entry:Dictionary in Rules.definition(district).stages:
		if entry.role=="lieutenant" and entry.id not in value.qualification:return "Converse com %s · %d/4 desafios vencidos."%[entry.name,value.qualification.size()]
	if district=="feira" and Rules.status(player,district)=="prerequisite":return preload("res://scripts/campaign/feira_story.gd").objective(player)
	if district=="industrial" and Rules.status(player,district)=="prerequisite":return "Resolva o confronto no galpão e vença a Pipa-Dragão desatada antes do duelo com Bruno Solda."
	return "Destranque a comporta nas Veredas antes do duelo com Kleie." if Rules.status(player,district)=="prerequisite" else "Siga até a arena do bairro."
static func reward(player:Dictionary,context:Dictionary,outcome:String)->Dictionary:
	var entry:=stage(context.duel)
	var first:bool=context.duel not in Rules.entry(player,context.district).wonDuels
	var amount:int=int(entry.reward.xp)
	if context.mode in ["defense","reclaim"]:
		for source:Dictionary in Rules.definition(context.district).stages:
			if source.npcId==context.opponent:
				var species:String=["basica","raio","mata","azulao"][int(source.foes[0].color)]
				amount=preload("res://scripts/campaign/opponent_rewards.gd").xp(species,int(entry.level))
	return {"coins":int(entry.reward.coins)*(2 if first else 1) if outcome=="won" else 0,"xp":amount if outcome=="won" else 20 if outcome=="lost" else 0}
func _near(saved:Dictionary,id:String,point:Vector2)->bool:
	var cp:Dictionary=saved.checkpoint
	if cp.kind!="world" or cp.get("space","")!=Checkpoint.SPACE or Checkpoint.region_of(cp.get("scene",""))!=stage(id).get("district","") or not point.is_finite():return false
	var map=Checkpoint.model_for(cp.scene)
	if not map.point_walkable(point):return false
	for event:Dictionary in map.data.events:
		if event.props.get("duel","")!=id:continue
		var at:=Vector2(event.u+.5,event.v+.5)
		return point.distance_to(at)<=1.8 and absf(map.height_at(point)-map.height_at(at))<.25
	return false
func start(id:String,point:Vector2,defense:bool=false)->Dictionary:
	var saved:Dictionary=session.snapshot()
	var district:String=stage(id).get("district","")
	if not _near(saved,id,point):return {"status":"wrong_step"}
	var pending:Dictionary=Rules.entry(saved.player,district).pendingDefense
	if defense and (pending.is_empty() or pending.scene!=saved.checkpoint.scene or stage(id).npcId!=pending.challenger):return {"status":"wrong_step"}
	var duel:String=district+"-5" if defense else id
	var planned:=Rules.prepare(saved.player,district,duel,str(pending.get("id","")) if defense else "")
	if planned.status!="ok":return planned
	var active:Dictionary={}
	for partner:Dictionary in saved.player.partners:
		if partner.id==saved.player.get("equippedPartnerId",""):active=partner
	if active.is_empty() or active.get("condition",{}).get("line",100)<=0 or active.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
	var model:=Model.new(active,duel)
	if planned.context.mode in ["defense","reclaim"]:
		for source:Dictionary in Rules.definition(district).stages:
			if source.npcId!=planned.context.opponent:continue
			model.q.name=source.name;model.q.color=source.foes[0].color;model.q.style=source.styles[0]
			model.enemy_model_id=["basica","raio","mata","azulao"][int(model.q.color)]
	Progression.discover(saved.player,model.enemy_model_id)
	saved.player.encounter={"id":State.new_id(),"kind":"district","scene":saved.checkpoint.scene,"space":Checkpoint.SPACE,"returnPoint":[point.x,point.y],"districtContext":planned.context,"state":model.snapshot()}
	return session.checkpoint({"kind":"encounter"},saved.player)
func offer_defense(id:String,point:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot()
	var district:String=stage(id).get("district","")
	if not _near(saved,id,point):return {"status":"wrong_step"}
	var token:=State.new_id()
	var offered:=Rules.offer(saved.player,district,stage(id).npcId,token,saved.checkpoint.scene)
	if offered.status!="ok":return offered
	return session.commit_operation("district-challenge-"+token,saved.checkpoint,offered.player)
func settle()->Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="encounter" or saved.player.encounter.kind!="district":return {"status":"wrong_step"}
	var encounter:Dictionary=saved.player.encounter
	var district:String=encounter.districtContext.district
	var model:=Model.new();model.restore(encounter.state)
	var outcome:String=model.outcome
	var result:=Rules.settle(saved.player,encounter.districtContext,outcome)
	if result.status!="ok":return result
	var awarded:=reward(saved.player,encounter.districtContext,outcome)
	var player:Dictionary=result.player
	player.coins+=awarded.coins
	var xp:=0
	for partner:Dictionary in player.partners:
		if partner.id!=model.partner_id:continue
		partner.condition={"line":clampf(model.p.hp/model.p.stats.line*100,0,100),"structure":clampf(model.p.hull/model.p.stats.line*100,0,100)}
		xp=Progression.award(player,partner,awarded.xp)
	var emblem:bool=Rules.award_emblem(player,district) if outcome=="won" and model.stage_id==district+"-5" else false
	player.lastDistrict={"district":district,"duel":model.stage_id,"mode":encounter.districtContext.mode,"outcome":outcome,"coins":awarded.coins,"xp":xp,"emblem":emblem,"unlocked":result.unlocked}
	player.erase("encounter")
	return session.commit_operation("encounter-"+encounter.id,{"kind":"world","scene":encounter.scene,"space":Checkpoint.SPACE,"position":encounter.returnPoint},player)
func inspect_clue(id:String,point:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="world" or saved.checkpoint.get("space","")!=Checkpoint.SPACE or Checkpoint.region_of(saved.checkpoint.scene)!="bambuzal":return {"status":"wrong_step"}
	var map=Checkpoint.model_for(saved.checkpoint.scene)
	if not point.is_finite() or not map.point_walkable(point):return {"status":"wrong_step"}
	for event:Dictionary in map.data.events:
		if str(int(event.id))!=id or event.props.get("acao","")!="bambuzalClue":continue
		var at:=Vector2(event.u+.5,event.v+.5)
		if point.distance_to(at)>1.8 or absf(map.height_at(point)-map.height_at(at))>=.25:return {"status":"wrong_step"}
		saved.player.flags.bambuzalCorteDescoberto=true
		return session.commit_operation("bambuzal-corte-v1",saved.checkpoint,saved.player)
	return {"status":"wrong_step"}

## Rest is validated against the authored event, never an arbitrary caller position.
func rest(point:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
	if cp.kind!="world" or cp.get("space")!=Checkpoint.SPACE or Checkpoint.region_of(cp.get("scene",""))!="cais" or not point.is_finite():return {"status":"wrong_step"}
	var map=Checkpoint.model_for(cp.scene)
	if not map.point_walkable(point):return {"status":"wrong_step"}
	var near:=false
	for e:Dictionary in map.data.events:
		if e.props.get("acao","")!="districtRest" or e.props.get("district","")!="cais":continue
		var at:=Vector2(e.u+.5,e.v+.5)
		if point.distance_to(at)<=1.8 and absf(map.height_at(point)-map.height_at(at))<.25:near=true
	if not near:return {"status":"wrong_step"}
	if saved.player.partners.all(func(p):return p.get("condition",{}).get("line",100)>=100 and p.get("condition",{}).get("structure",100)>=100):return {"status":"already_applied"}
	if saved.player.coins<12:return {"status":"not_enough_coins"}
	saved.player.coins-=12
	for p:Dictionary in saved.player.partners:p.condition={"line":100,"structure":100}
	return session.checkpoint(cp,saved.player)
