extends RefCounted
## Rewards from 021_tamers_and_classes.sql, committed with the calling operation.
static func discover(player: Dictionary, model_id: String) -> void:
	var seen: Array = player.get("sightings", [])
	if model_id not in seen:
		seen.append(model_id)
		player.sightings = seen
		player.tamerXp = mini(31383, int(player.get("tamerXp", 0)) + 5)

static func acquire(player: Dictionary, model_id: String) -> void:
	var acquired: Array = player.get("acquiredModels", [])
	if model_id not in acquired:
		acquired.append(model_id)
		player.acquiredModels = acquired
		player.tamerXp = mini(31383, int(player.get("tamerXp", 0)) + 20)

static func award(player: Dictionary, partner: Dictionary, amount: int) -> int:
	var previous := int(partner.get("xp", 0))
	var credited := credit_for(partner, amount)
	partner.xp = previous + credited
	player.tamerXp = mini(31383, int(player.get("tamerXp", 0)) + int(floor(credited / 5.0)))
	return credited

static func credit_for(partner: Dictionary, amount: int) -> int:
	return maxi(0, mini(amount, 25970 - int(partner.get("xp", 0))))
