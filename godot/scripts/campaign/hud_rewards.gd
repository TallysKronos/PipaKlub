extends RefCounted
## Read-only preview. The settlement transaction remains the only reward writer.
const Encounters = preload("res://scripts/campaign/encounters.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const Rules = preload("res://scripts/campaign/morro_rules.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
static func preview(player: Dictionary, encounter: Dictionary, model: RefCounted) -> Dictionary:
	var summary := {"xp": 0, "coins": 0, "stars": 0, "items": [], "before": 0, "after": 0, "name": "Seu parceiro"}
	var partner: Dictionary = {}
	for entry in player.get("partners", []):
		if entry.id == model.partner_id: partner = entry
	if partner.is_empty(): return summary
	summary.name = partner.get("personalName", "Seu parceiro")
	summary.before = int(partner.get("xp", 0))
	summary.after = summary.before
	if model.outcome not in ["won", "lost", "fled"]: return summary
	var amount := 0
	var won: bool = model.outcome == "won"
	if encounter.get("kind", "") == "morro" and model.outcome != "fled":
		var reward := Rules.settle(player.get("morro", Rules.defaults()), model.stage_id, won, model.rounds_lost())
		summary.coins = reward.coins
		summary.stars = reward.stars
		amount = Morro.reward_amount(won, reward.firstClear)
		if reward.get("drop") != null: summary.items.append("Rabiola de Raio de sol")
	elif won:
		var boss: bool = encounter.get("kind", "") == "lacertubo"
		amount = Encounters.reward_amount(boss, encounter.get("scene", "park-veredas"), model.enemy_model_id)
		if boss: summary.items.append("Rabiola de Lacertubo")
		else:
			var drop: Dictionary = player.get("wildDrop", {"intro": false, "misses": 0})
			if not drop.intro or drop.misses >= 7 or encounter.get("dropRoll", 1) < .25:
				var name: String = {"basica": "Carcará", "mata": "Mata verde", "raio": "Raio de sol"}.get(model.enemy_model_id, model.enemy_model_id)
				summary.items.append("Rabiola de " + name)
	summary.xp = Progression.credit_for(partner, amount)
	summary.after = summary.before + summary.xp
	return summary
