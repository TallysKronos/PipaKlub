extends RefCounted

const Rules = preload("res://scripts/campaign/district_rules.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const State = preload("res://scripts/campaign/state.gd")
const Flower := "flor-de-cerejeira"

static func begin_lab(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "professor-home" or not Rules.completed(saved.player, "centro") or saved.player.flags.get("tylerCreatedKnown", false):
		return {"status":"wrong_step"}
	var active: Dictionary = preload("res://scripts/campaign/park_training.gd").active(saved.player)
	if active.is_empty() or active.get("condition", {}).get("line", 100) <= 0 or active.get("condition", {}).get("structure", 100) <= 0:
		return {"status":"repair_needed"}
	var model := Model.new(active, {"modelId":"lacertubo", "level":33})
	model.q.name = "Sentinela do laboratório"
	saved.player.encounter = {"id":State.new_id(), "kind":"tyler-lab", "scene":"professor-home", "returnPoint":saved.checkpoint.position, "rewardXp":0, "state":model.snapshot()}
	return session.checkpoint({"kind":"encounter"}, saved.player)

static func settle_lab(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var battle: Dictionary = saved.player.get("encounter", {})
	if saved.checkpoint.kind != "encounter" or battle.get("kind") != "tyler-lab" or not State.valid_encounter(battle):
		return {"status":"wrong_step"}
	var result: Dictionary = battle.state
	if result.outcome not in ["won", "lost", "fled"]:
		return {"status":"wrong_step"}
	for partner: Dictionary in saved.player.partners:
		if partner.id == result.partnerId:
			partner.condition = {"line":clampf(result.p.hp / result.p.stats.line * 100, 0, 100), "structure":clampf(result.p.hull / result.p.stats.line * 100, 0, 100)}
	if result.outcome == "won":
		saved.player.flags.tylerCreatedKnown = true
	saved.player.erase("encounter")
	return session.commit_operation("encounter-"+battle.id, {"kind":"world", "scene":"professor-home", "position":battle.returnPoint}, saved.player)

static func finish_ghost(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "kronasta-centro-c" or not Rules.completed(saved.player, "centro") or saved.player.flags.get("pipeiroFantasmaResolvido", false):
		return {"status":"wrong_step"}
	saved.player.flags.pipeiroFantasmaResolvido = true
	saved.player.inventory[Flower] = 1
	return session.commit_operation("pipeiro-fantasma-v1", saved.checkpoint, saved.player)

static func finale_ready(player: Dictionary) -> bool:
	return Rules.city_final_unlocked(player) and player.flags.get("tylerCreatedKnown", false) and int(player.inventory.get(Flower, 0)) > 0 and not player.flags.get("tylerFlowerGiven", false)

static func finish_finale(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "professor-home" or not finale_ready(saved.player):
		return {"status":"wrong_step"}
	saved.player.inventory.erase(Flower)
	saved.player.flags.tylerFlowerGiven = true
	return session.commit_operation("tyler-flor-de-cerejeira-v1", saved.checkpoint, saved.player)

static func presentation_pending(player: Dictionary) -> bool:
	return player.flags.get("tylerFlowerGiven",false) and not player.flags.get("tylerFlowerSceneSeen",false)

static func finish_presentation(session: Node, point: Vector2) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	if saved.checkpoint.get("scene")!="professor-home" or not presentation_pending(saved.player):return {"status":"wrong_step"}
	if not point.is_finite():return {"status":"wrong_step"}
	saved.player.flags.tylerFlowerSceneSeen=true
	var checkpoint: Dictionary=saved.checkpoint.duplicate(true)
	checkpoint.position=[point.x,point.y]
	return session.commit_operation("tyler-flor-cena-v1",checkpoint,saved.player)