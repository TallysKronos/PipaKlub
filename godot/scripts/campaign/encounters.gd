extends RefCounted
const State = preload("res://scripts/campaign/state.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Park = preload("res://scripts/campaign/park_data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
const Training = preload("res://scripts/campaign/park_training.gd")
const Pacing = preload("res://scripts/campaign/park_pacing.gd")
var session: Node

static func reward_amount(boss: bool, _scene: String, enemy_id: String, level: int = 1) -> int:
	return Pacing.reward_xp("lacertubo" if boss else enemy_id,Pacing.BOSS_LEVEL if boss else level)

static func reward_for(battle: Dictionary, _state: Dictionary) -> int:
	# New encounters freeze their reward before the first input. Legacy suspended
	# fights retain the previous regional reward and their saved combat attributes.
	if battle.has("rewardXp"): return int(battle.rewardXp)
	return 160 if battle.get("kind","")=="lacertubo" else int({"park-trail":40,"park-clearing":60,"park-veredas":80}.get(battle.get("scene","park-veredas"),40))

func _init(local_session: Node) -> void:
	session = local_session

func start_wild(point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var scene: String = saved.checkpoint.get("scene", "")
	var grass := Park.in_grass(point) if scene == "park-veredas" else _route_grass(scene, point)
	if saved.checkpoint.get("space","")==Checkpoint.SPACE: grass = Checkpoint.encounter_weight(saved.checkpoint,point)>0
	if not grass or Time.get_unix_time_from_system() < saved.player.get("encounterGraceUntil", 0): return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var partner: Dictionary = {}
	for entry in player.partners:
		if entry.id == player.get("equippedPartnerId", ""): partner = entry
	if partner.is_empty() or partner.get("condition", {}).get("line", 100) <= 0 or partner.get("condition", {}).get("structure", 100) <= 0: return {"status": "repair_needed"}
	var bytes := Crypto.new().generate_random_bytes(12)
	var roll := bytes.decode_u32(0) / 4294967296.0
	var first: bool = not player.get("wildDrop", {}).get("intro", false)
	var species := ("basica" if roll < .5 else "mata") if first else ("basica" if roll < .5 else "mata" if roll < .85 else "raio")
	var level := 5 + bytes.decode_u32(4) % 5 if scene == "park-veredas" else 1 + bytes.decode_u32(4) % 3 + (1 if scene == "park-clearing" else 0)
	if saved.checkpoint.get("space","")==Checkpoint.SPACE: level=Pacing.wild_level(scene,bytes.decode_u32(4))
	var model := Model.new(partner, {"modelId": species, "level": level})
	Progression.discover(player, species)
	player.encounter = {"id": State.new_id(), "kind": "wild", "scene": scene, "dropRoll": bytes.decode_u32(8) / 4294967296.0, "returnPoint": [point.x, point.y], "state": model.snapshot()}
	player.encounter.rewardXp=reward_amount(false,scene,species,level)
	if saved.checkpoint.get("space","")==Checkpoint.SPACE: player.encounter.space=Checkpoint.SPACE
	return session.checkpoint({"kind": "encounter"}, player)

func _route_grass(scene: String, point: Vector2) -> bool:
	if scene not in ["park-trail", "park-clearing"]: return false
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
	for rect in maps[scene].walkable:
		if rect.properties.get("encounter_zone", "") != "" and Rect2(rect.x, rect.y, rect.w, rect.h).has_point(point): return true
	return false

func start_training(id: String, point: Vector2) -> Dictionary:
	var entry:=Training.duel(id)
	var saved: Dictionary=session.snapshot()
	if entry.is_empty() or saved.checkpoint.get("kind","")!="world" or saved.checkpoint.get("space","")!=Checkpoint.SPACE or saved.checkpoint.get("scene","")!=entry.scene: return {"status":"wrong_step"}
	if Training.completed(saved.player,id): return {"status":"already_applied"}
	var model_map=Checkpoint.model_for(entry.scene)
	var target:=Training.point(id,model_map)
	if not model_map.walkable(Vector2i(point.floor())) or point.distance_to(target)>1.8 or absf(model_map.height_at(point)-model_map.height_at(target))>=.25: return {"status":"wrong_step"}
	var partner:=Training.active(saved.player)
	if partner.is_empty() or Training.needs_rest(saved.player): return {"status":"repair_needed"}
	var model:=Model.new(partner,{"modelId":entry.species,"level":entry.level})
	model.intro=2.2
	model.q.name=entry.name
	model.q.trainingRank=Training.DUELS.find(entry)+1
	Progression.discover(saved.player,entry.species)
	saved.player.encounter={"id":State.new_id(),"kind":"trainer","trainerId":id,"trainerName":entry.name,"scene":entry.scene,"space":Checkpoint.SPACE,"rewardXp":entry.xp,"dropRoll":0.0,"returnPoint":[point.x,point.y],"state":model.snapshot()}
	return session.checkpoint({"kind":"encounter"},saved.player)

func start_boss(point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var nearby: bool = Checkpoint.near(saved.checkpoint,"boss",point) if saved.checkpoint.get("space","")==Checkpoint.SPACE else point.distance_to(Park.BOSS)<=85
	if saved.checkpoint.get("scene") != "park-veredas" or not nearby or not saved.player.flags.get("ninaAccepted", false) or saved.player.flags.get("guardianDefeated", false): return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var partner: Dictionary = {}
	for entry in player.partners:
		if entry.id == player.get("equippedPartnerId", ""): partner = entry
	if partner.is_empty() or partner.get("condition", {}).get("line", 100) <= 0 or partner.get("condition", {}).get("structure", 100) <= 0: return {"status": "repair_needed"}
	if partner.get("modelId") not in ["rabbito", "basica", "mata", "azulao", "raio", "lacertubo"]: return {"status": "wrong_step"}
	var model := Model.new(partner)
	Progression.discover(player, "lacertubo")
	player.encounter = {"id": State.new_id(), "kind": "lacertubo", "returnPoint": [point.x, point.y], "state": model.snapshot()}
	player.encounter.rewardXp=reward_amount(true,"park-veredas","lacertubo",model.enemy_level)
	if saved.checkpoint.get("space","")==Checkpoint.SPACE:
		player.encounter.space=Checkpoint.SPACE
		player.encounter.scene="park-veredas"
	return session.checkpoint({"kind": "encounter"}, player)

func save_battle(state: Dictionary) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.kind != "encounter": return {"status": "wrong_step"}
	saved.player.encounter.state = state.duplicate(true)
	return session.checkpoint(saved.checkpoint, saved.player)

func settle() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.kind != "encounter": return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var battle: Dictionary = player.encounter
	var state: Dictionary = battle.state
	if state.outcome not in ["won", "lost", "fled"]: return {"status": "wrong_step"}
	var boss: bool = battle.kind == "lacertubo"
	var training: bool=battle.kind=="trainer"
	var scene: String = battle.get("scene", "park-veredas")
	var reward := reward_for(battle,state)
	for partner in player.partners:
		if partner.id != state.partnerId: continue
		var condition: Dictionary = partner.get("condition", {"line": 100, "structure": 100})
		condition.line = minf(condition.line, clampf(state.p.hp / state.p.stats.line * 100, 0, 100))
		condition.structure = clampf(state.p.hull / state.p.stats.line * 100, 0, 100)
		partner.condition = condition
		if state.outcome == "won": reward = Progression.award(player, partner, reward)
	if state.outcome == "won" and boss:
		player.flags.guardianDefeated = true
		player.inventory["rabiola-lacertubo"] = player.inventory.get("rabiola-lacertubo", 0) + 1
	elif state.outcome == "won" and not training:
		var drop: Dictionary = player.get("wildDrop", {"intro": false, "misses": 0})
		if not drop.intro or drop.misses >= 7 or battle.dropRoll < .25:
			var item: String = "rabiola-" + state.enemyModelId
			player.inventory[item] = player.inventory.get(item, 0) + 1
			drop.intro = true
			drop.misses = 0
		else: drop.misses += 1
		player.wildDrop = drop
	player.lastEncounter = {"outcome": state.outcome, "partnerXp": reward if state.outcome == "won" else 0,"kind":battle.kind,"trainerName":battle.get("trainerName","")}
	player.encounterGraceUntil = Time.get_unix_time_from_system() + Pacing.walking_grace(player)
	var point: Array = battle.returnPoint if state.outcome != "lost" else ([Park.ENTRY.x, Park.ENTRY.y] if scene == "park-veredas" else [208, 816])
	var checkpoint := {"kind":"world","scene":scene,"position":point}
	if battle.get("space","")==Checkpoint.SPACE:
		var destination := Vector2(point[0],point[1]) if state.outcome!="lost" else Checkpoint.spawn(scene)
		checkpoint=Checkpoint.make(scene,destination,Checkpoint.SPACE)
	player.erase("encounter")
	return session.commit_operation(Training.receipt(battle.trainerId) if training and state.outcome=="won" else "encounter-"+battle.id, checkpoint, player)
