extends RefCounted
## Authored story duel and valve, separate from the already-defeated Lacertubo.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const AT=Vector2(31.5,16.5)
var session:Node
func _init(active:Node)->void:session=active
static func available(player:Dictionary)->bool:
	return player.get("flags",{}).get("leagueGreen",false) and Rules.qualified(Rules.entry(player,"beira-canal"),Rules.definition("beira-canal"))
static func events(player:Dictionary)->Array:
	if not available(player):return []
	return [{"id":10900,"type":"npc","name":"Grampo","u":31,"v":16,"props":{"acao":"canalGate","ocultar_apos":"grampoVeredasVencido","storySpritePath":"res://assets/campaign/beira-canal-v1/grampo.png"}}, {"id":10901,"type":"interacao","name":"Destrancar a comporta","u":31,"v":16,"props":{"acao":"canalGate","requer":"grampoVeredasVencido","ocultar_apos":"comportaVeredasAberta"}}]
func nearby(point:Vector2)->bool:
	var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
	if cp.kind!="world" or cp.get("scene")!="park-veredas" or cp.get("space")!=CP.SPACE or not available(saved.player) or not point.is_finite():return false
	var model=CP.model_for("park-veredas")
	return model.point_walkable(point) and point.distance_to(AT)<=1.8 and absf(model.height_at(point)-model.height_at(AT))<.25
func begin(point:Vector2)->Dictionary:
	if not nearby(point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if saved.player.flags.get("grampoVeredasVencido",false):return {"status":"already_applied"}
	var active:Dictionary=preload("res://scripts/campaign/park_training.gd").active(saved.player)
	if active.is_empty() or active.get("condition",{}).get("line",100)<=0 or active.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
	var model:=Model.new(active,{"modelId":"platyx-draft","level":14});model.q.name="Platyx · Grampo";model.intro=3
	saved.player.encounter={"id":State.new_id(),"kind":"canal-gate","scene":"park-veredas","space":CP.SPACE,"returnPoint":[point.x,point.y],"state":model.snapshot()}
	return session.checkpoint({"kind":"encounter"},saved.player)
func settle()->Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="encounter" or saved.player.encounter.kind!="canal-gate":return {"status":"wrong_step"}
	var e:Dictionary=saved.player.encounter;var state:Dictionary=e.state
	if state.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
	for partner:Dictionary in saved.player.partners:
		if partner.id!=state.partnerId:continue
		partner.condition={"line":clampf(state.p.hp/state.p.stats.line*100,0,100),"structure":clampf(state.p.hull/state.p.stats.line*100,0,100)}
	if state.outcome=="won":preload("res://scripts/campaign/progression.gd").story_win(saved.player,state)
	if state.outcome=="won":saved.player.flags.grampoVeredasVencido=true
	# Story unlock only: no repeatable loot, rabiola or second guardian reward.
	saved.player.erase("encounter")
	return session.commit_operation("encounter-"+e.id,CP.make(e.scene,CP.spawn(e.scene) if state.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1]),CP.SPACE),saved.player)
func open(point:Vector2)->Dictionary:
	if not nearby(point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if not saved.player.flags.get("grampoVeredasVencido",false):return {"status":"wrong_step"}
	if saved.player.flags.get("comportaVeredasAberta",false):return {"status":"already_applied"}
	saved.player.flags.comportaVeredasAberta=true
	return session.commit_operation("canal-comporta-v1",CP.make("park-veredas",point,CP.SPACE),saved.player)
func rest(point:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
	if cp.kind!="world" or cp.get("scene")!="kronasta-beira-canal-b" or cp.get("space")!=CP.SPACE or not point.is_finite():return {"status":"wrong_step"}
	var model=CP.model_for(cp.scene);var target:=Vector2(22.5,30.5)
	if not model.point_walkable(point) or point.distance_to(target)>1.8 or absf(model.height_at(point)-model.height_at(target))>=.25:return {"status":"wrong_step"}
	if saved.player.partners.all(func(p):return p.get("condition",{}).get("line",100)>=100 and p.get("condition",{}).get("structure",100)>=100):return {"status":"already_applied"}
	if saved.player.coins<12:return {"status":"not_enough_coins"}
	saved.player.coins-=12
	for p:Dictionary in saved.player.partners:p.condition={"line":100,"structure":100}
	return session.checkpoint(cp,saved.player)
