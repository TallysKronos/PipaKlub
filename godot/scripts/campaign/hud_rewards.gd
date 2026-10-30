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
		var next_index:=Rules.IDS.find(model.stage_id)+1
		if won and reward.firstClear and next_index<Rules.IDS.size():
			summary.unlock="Passagem liberada · "+str(Rules.stage(Rules.IDS[next_index]).get("name","próximo desafio"))
		amount = Morro.reward_amount(won, reward.firstClear)
		if reward.get("drop") != null: summary.items.append("Rabiola de Raio de sol")
	elif won:
		var boss: bool = encounter.get("kind", "") == "lacertubo"
		amount = Encounters.reward_for(encounter,model.snapshot())
		if boss: summary.items.append("Rabiola de Lacertubo")
		elif encounter.get("kind","")!="trainer":
			var drop: Dictionary = player.get("wildDrop", {"intro": false, "misses": 0})
			if not drop.intro or drop.misses >= 7 or encounter.get("dropRoll", 1) < .25:
				var name: String = {"basica": "Carcará", "mata": "Mata verde", "raio": "Raio de sol"}.get(model.enemy_model_id, model.enemy_model_id)
				summary.items.append("Rabiola de " + name)
	summary.xp = Progression.credit_for(partner, amount)
	summary.new_items=[]
	for item in summary.items:
		var item_id:String={"Rabiola de Mata verde":"rabiola-mata","Rabiola de Lacertubo":"rabiola-lacertubo","Rabiola de Carcará":"rabiola-basica","Rabiola de Raio de sol":"rabiola-raio"}.get(item,"")
		if not item_id.is_empty() and player.get("inventory",{}).get(item_id,0)==0:summary.new_items.append(item)
	if won and encounter.get("kind","")=="lacertubo" and not player.get("flags",{}).get("ninaTail",false):
		summary.notice="A rabiola de Nina ficou no chão. Procure-a no pátio, atrás do guardião."
	summary.after = summary.before + summary.xp
	var projected:Dictionary=player.duplicate(true)
	var projected_partner:Dictionary=partner.duplicate(true)
	Progression.award(projected,projected_partner,amount)
	summary.tamer={"name":player.get("name","Kael"),"before":int(player.get("tamerXp",0)),"after":int(projected.get("tamerXp",0)),"xp":int(projected.get("tamerXp",0))-int(player.get("tamerXp",0))}
	summary.team=[]
	var equipped:Dictionary=partner.duplicate(true)
	equipped["earnedXp"]=summary.xp
	summary.team.append(equipped)
	for entry in player.get("partners",[]):
		if entry.id!=partner.id and summary.team.size()<3:
			var reserve:Dictionary=entry.duplicate(true)
			reserve["earnedXp"]=0
			summary.team.append(reserve)
	return summary
