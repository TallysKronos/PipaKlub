extends RefCounted
const Levels = preload("res://scripts/campaign/partner_levels.gd")
## Campaign XP and tamer credits, committed with the calling operation.
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
	return maxi(0, mini(amount, Levels.xp_for_level(Levels.MAX_LEVEL) - int(partner.get("xp", 0))))

## XP of a won story duel (Ruínas, Quatro Ventos, Gollia, Tufanocorte...): until now these
## paid nothing while the result card promised the park's regional XP.
static func story_xp(player: Dictionary, state: Dictionary) -> int:
	var partner := _partner(player, str(state.get("partnerId", "")))
	if partner.is_empty(): return 0
	var foe := int(state.get("enemyLevel", state.get("q", {}).get("level", 1)))
	return credit_for(partner, Levels.win_xp(foe, Levels.level_for_xp(int(partner.get("xp", 0))), "story"))

static func story_win(player: Dictionary, state: Dictionary) -> int:
	var partner := _partner(player, str(state.get("partnerId", "")))
	if partner.is_empty(): return 0
	return award(player, partner, story_xp(player, state))

## Story duels have no rematch rule, so a casual player could hit the same boss many
## times in a row (Jamile: 25% for bot 4). Like districtLossStreak, each loss in a row
## to the same duel softens the boss (EncounterModel.assist, up to 2); a win resets it.
static func story_key(enemy_model_id: String, level: int) -> String:
	return "%s-%d" % [enemy_model_id, level]

static func story_assist(player: Dictionary, model) -> void:
	model.assist = mini(2, int(player.get("storyLossStreak", {}).get(story_key(model.enemy_model_id, model.enemy_level), 0)))

static func story_result(player: Dictionary, state: Dictionary) -> void:
	var key := story_key(str(state.get("enemyModelId", "")), int(state.get("enemyLevel", 0)))
	var streaks: Dictionary = player.get("storyLossStreak", {})
	if state.get("outcome") == "lost": streaks[key] = int(streaks.get(key, 0)) + 1
	elif state.get("outcome") == "won": streaks.erase(key)
	player.storyLossStreak = streaks

static func _partner(player: Dictionary, id: String) -> Dictionary:
	for partner in player.get("partners", []):
		if partner.get("id", "") == id: return partner
	return {}
