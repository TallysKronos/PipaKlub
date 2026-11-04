extends RefCounted
const Rules = preload("res://scripts/campaign/morro_rules.gd")
const Model = preload("res://scripts/campaign/morro_model.gd")
const State = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const District=preload("res://scripts/campaign/district_rules.gd")
var session: Node
static func reward_amount(won: bool, first_clear: bool) -> int:
	return (120 if first_clear else 80) if won else 20
func _init(active_session: Node) -> void:
	session = active_session

static var _maps: Dictionary = {}

static func maps() -> Dictionary:
	if _maps.is_empty(): _maps = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/morro/maps.json"))
	return _maps

func start(point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.kind != "world" or not maps().has(saved.checkpoint.scene): return {"status": "wrong_step"}
	var data: Dictionary = maps()[saved.checkpoint.scene]
	var place: Dictionary = data.places.filter(func(p: Dictionary): return p.has("stage"))[0]
	if not point.is_finite() or point.distance_to(Vector2(place.point[0], place.point[1])) > 90: return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var progress: Dictionary = player.get("morro", Rules.defaults())
	if not Rules.unlocked(progress, data.stage): return {"status": "wrong_step"}
	var planned:=District.prepare(player,"morro",data.stage)
	if planned.status!="ok":return planned
	return _begin(saved,point,data.stage,planned.context)

func _begin(saved:Dictionary,point:Vector2,stage:String,context:Dictionary) -> Dictionary:
	var player:Dictionary=saved.player
	var progress:Dictionary=player.get("morro",Rules.defaults())
	var partner: Dictionary = {}
	for entry in player.partners:
		if entry.id == player.get("equippedPartnerId", ""): partner = entry
	if partner.is_empty() or partner.get("condition", {}).get("line", 100) <= 0 or partner.get("condition", {}).get("structure", 100) <= 0: return {"status": "repair_needed"}
	var model := Model.new(partner, stage, progress)
	if context.mode in ["defense","reclaim"]:
		for source:Dictionary in District.definition("morro").stages:
			if source.npcId!=context.opponent:continue
			model.q.name=source.get("npcName",source.name);model.q.color=source.foes[0].color
			model.q.style=Rules.content().stories[source.id].styles[0]
	player.encounter = {"id": State.new_id(), "kind": "morro", "scene": saved.checkpoint.scene, "returnPoint": [point.x, point.y], "state": model.snapshot(),"districtContext":context.duplicate(true)}
	return session.checkpoint({"kind": "encounter"}, player)

func offer_defense(point:Vector2) -> Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="world" or not maps().has(saved.checkpoint.scene) or not point.is_finite():return {"status":"wrong_step"}
	var data:Dictionary=maps()[saved.checkpoint.scene]
	var place:Dictionary=data.places.filter(func(p):return p.has("stage"))[0]
	if point.distance_to(Vector2(place.point[0],place.point[1]))>90:return {"status":"wrong_step"}
	var source:Dictionary=District.definition("morro").stages.filter(func(s):return s.id==data.stage)[0]
	var id:=State.new_id()
	var result:=District.offer(saved.player,"morro",source.npcId,id,saved.checkpoint.scene)
	if result.status!="ok":return result
	return session.commit_operation("district-challenge-"+id,saved.checkpoint,result.player)

func start_defense(point:Vector2) -> Dictionary:
	var saved:Dictionary=session.snapshot()
	var pending:Dictionary=District.entry(saved.get("player",{}),"morro").pendingDefense
	if saved.checkpoint.kind!="world" or pending.is_empty() or pending.scene!=saved.checkpoint.scene or not point.is_finite():return {"status":"wrong_step"}
	var place:Dictionary=maps()[pending.scene].places.filter(func(p):return p.has("stage"))[0]
	if point.distance_to(Vector2(place.point[0],place.point[1]))>90:return {"status":"wrong_step"}
	var planned:=District.prepare(saved.player,"morro","morro-5",pending.id)
	if planned.status!="ok":return planned
	return _begin(saved,point,"morro-5",planned.context)

func settle() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.kind != "encounter" or saved.player.encounter.kind != "morro": return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var encounter: Dictionary = player.encounter
	var model := Model.new()
	model.restore(encounter.state)
	if model.outcome not in ["won", "lost", "fled"]: return {"status": "wrong_step"}
	var context:Dictionary=encounter.get("districtContext",{})
	# Suspended pre-update fights keep their existing combat state and receipt.
	if context.is_empty():
		var planned:=District.prepare(player,"morro",model.stage_id)
		if planned.status=="ok":context=planned.context
	var title_result:Dictionary={}
	if not context.is_empty():
		title_result=District.settle(player,context,model.outcome)
		if title_result.status!="ok":return title_result
		player=title_result.player
	var reward := {"coins": 0, "stars": 0, "firstClear": false, "drop": null}
	if model.outcome != "fled":
		reward = Rules.settle(player.get("morro", Rules.defaults()), model.stage_id, model.outcome == "won", model.rounds_lost())
		player.morro = reward.progress
		player.coins += reward.coins
		if reward.drop != null:
			# Source item alias maps to the campaign's existing Raio de sol recipe.
			player.inventory["rabiola-raio"] = player.inventory.get("rabiola-raio", 0) + 1
	var earned := 0
	for partner in player.partners:
		if partner.id != model.partner_id: continue
		partner.condition = {"line": clampf(model.p.hp / model.p.stats.line * 100, 0, 100), "structure": clampf(model.p.hull / model.p.stats.line * 100, 0, 100)}
		if model.outcome != "fled": earned = Progression.award(player, partner, reward_amount(model.outcome == "won", reward.firstClear))
	player.lastMorro = {"stage": model.stage_id, "outcome": model.outcome, "coins": reward.coins, "stars": reward.stars, "partnerXp": earned, "drop": reward.drop}
	if not context.is_empty():player.lastMorro.merge({"districtMode":context.mode,"opponent":context.opponent,"unlocked":title_result.unlocked})
	if model.outcome=="won" and model.stage_id=="morro-5":
		player.lastMorro.insignia=District.award_emblem(player,"morro")
	player.erase("encounter")
	return session.commit_operation("encounter-" + encounter.id, {"kind": "world", "scene": encounter.scene, "position": encounter.returnPoint}, player)
