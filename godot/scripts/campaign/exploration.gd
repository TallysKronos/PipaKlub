extends RefCounted
## Offline grants mirror 029_veredas_exploration.sql; no online certification.
const Data = preload("res://scripts/campaign/park_data.gd")
var session: Node

func _init(local_session: Node) -> void:
	session = local_session

func _near(point: Vector2, target: Vector2, radius: float = 85) -> bool:
	var saved: Dictionary = session.snapshot()
	return saved.get("checkpoint", {}).get("scene") == "park-veredas" and point.distance_to(target) <= radius

func accept_nina(point: Vector2) -> Dictionary:
	if not _near(point, Data.NINA): return {"status": "wrong_step"}
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	player.flags.ninaAccepted = true
	return session.commit_operation("nina-accepted-v1", saved.checkpoint, player)

func chest(id: String, point: Vector2) -> Dictionary:
	if not Data.CHESTS.has(id) or not _near(point, Data.CHESTS[id].point): return {"status": "wrong_step"}
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	if player.get("journey", {}).get("phase") != "complete": return {"status": "wrong_step"}
	if id == "courtyard" and not player.flags.get("guardianDefeated", false): return {"status": "guardian"}
	if id in player.openedChests: return {"status": "already_applied"}
	var reward: Dictionary = Data.CHESTS[id]
	if reward.item == "coins": player.coins += reward.amount
	else: player.inventory[reward.item] = player.inventory.get(reward.item, 0) + reward.amount
	player.openedChests.append(id)
	return session.commit_operation("veredas-chest-" + id, saved.checkpoint, player)

func collect_tail(point: Vector2) -> Dictionary:
	if not _near(point, Data.TAIL): return {"status": "wrong_step"}
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	if not player.flags.get("guardianDefeated", false) or not player.flags.get("ninaAccepted", false): return {"status": "wrong_step"}
	player.flags.ninaTail = true
	player.inventory["quest-nina-tail"] = 1
	return session.commit_operation("nina-tail-v1", saved.checkpoint, player)

func return_tail(point: Vector2) -> Dictionary:
	if not _near(point, Data.NINA): return {"status": "wrong_step"}
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	if not player.flags.get("ninaTail", false): return {"status": "wrong_step"}
	player.flags.ninaReturned = true
	player.inventory.erase("quest-nina-tail")
	return session.commit_operation("nina-returned-v1", saved.checkpoint, player)

func equip(id: String) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.get("checkpoint", {}).get("kind") != "world": return {"status": "wrong_step"}
	if not saved.player.partners.any(func(partner: Dictionary): return partner.id == id): return {"status": "wrong_step"}
	saved.player.equippedPartnerId = id
	return session.checkpoint(saved.checkpoint, saved.player)

func repair() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "professor-home": return {"status": "wrong_step"}
	for partner in saved.player.partners: partner.condition = {"line": 100, "structure": 100}
	return session.checkpoint(saved.checkpoint, saved.player)
