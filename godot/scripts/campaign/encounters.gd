extends RefCounted
const State = preload("res://scripts/campaign/state.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Park = preload("res://scripts/campaign/park_data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
var session: Node

static func reward_amount(boss: bool, scene: String, enemy_id: String) -> int:
	return 120 if boss else 30 if scene == "park-clearing" or enemy_id == "raio" else 20

func _init(local_session: Node) -> void:
	session = local_session

func start_wild(point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var scene: String = saved.checkpoint.get("scene", "")
	var grass := Park.in_grass(point) if scene == "park-veredas" else _route_grass(scene, point)
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
	var model := Model.new(partner, {"modelId": species, "level": level})
	Progression.discover(player, species)
	player.encounter = {"id": State.new_id(), "kind": "wild", "scene": scene, "dropRoll": bytes.decode_u32(8) / 4294967296.0, "returnPoint": [point.x, point.y], "state": model.snapshot()}
	return session.checkpoint({"kind": "encounter"}, player)

func _route_grass(scene: String, point: Vector2) -> bool:
	if scene not in ["park-trail", "park-clearing"]: return false
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
	for rect in maps[scene].walkable:
		if rect.properties.get("encounter_zone", "") != "" and Rect2(rect.x, rect.y, rect.w, rect.h).has_point(point): return true
	return false

func start_boss(point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "park-veredas" or point.distance_to(Park.BOSS) > 85 or not saved.player.flags.get("ninaAccepted", false) or saved.player.flags.get("guardianDefeated", false): return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var partner: Dictionary = {}
	for entry in player.partners:
		if entry.id == player.get("equippedPartnerId", ""): partner = entry
	if partner.is_empty() or partner.get("condition", {}).get("line", 100) <= 0 or partner.get("condition", {}).get("structure", 100) <= 0: return {"status": "repair_needed"}
	if partner.get("modelId") not in ["rabbito", "basica", "mata", "azulao", "raio", "lacertubo"]: return {"status": "wrong_step"}
	var model := Model.new(partner)
	Progression.discover(player, "lacertubo")
	player.encounter = {"id": State.new_id(), "kind": "lacertubo", "returnPoint": [point.x, point.y], "state": model.snapshot()}
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
	var scene: String = battle.get("scene", "park-veredas")
	var reward := reward_amount(boss, scene, state.enemyModelId)
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
	elif state.outcome == "won":
		var drop: Dictionary = player.get("wildDrop", {"intro": false, "misses": 0})
		if not drop.intro or drop.misses >= 7 or battle.dropRoll < .25:
			var item: String = "rabiola-" + state.enemyModelId
			player.inventory[item] = player.inventory.get(item, 0) + 1
			drop.intro = true
			drop.misses = 0
		else: drop.misses += 1
		player.wildDrop = drop
	player.encounterGraceUntil = Time.get_unix_time_from_system() + 20
	player.lastEncounter = {"outcome": state.outcome, "partnerXp": reward if state.outcome == "won" else 0}
	var point: Array = battle.returnPoint if state.outcome != "lost" else ([Park.ENTRY.x, Park.ENTRY.y] if scene == "park-veredas" else [208, 816])
	player.erase("encounter")
	return session.commit_operation("encounter-" + battle.id, {"kind": "world", "scene": scene, "position": point}, player)
