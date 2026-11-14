extends RefCounted
## Read-only preview. The settlement transaction remains the only reward writer.
const Encounters = preload("res://scripts/campaign/encounters.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const Rules = preload("res://scripts/campaign/morro_rules.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
## Story duels pay Progression.story_xp (the same amount their settlement credits).
const STORY_KINDS := ["canal-gate","endgame-step","feira-story","mormaco-story","retalho-rescue","retalho-story","ruinas-elo","tufanocorte-story","tyler-lab","warehouse-story"]
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
	if encounter.get("kind","")=="district":
		var reward:Dictionary=preload("res://scripts/campaign/district_campaign.gd").reward(player,encounter.districtContext,model.outcome)
		summary.coins=reward.coins;amount=reward.xp
		if won and model.stage_id=="bambuzal-5" and not preload("res://scripts/campaign/district_rules.gd").completed(player,"bambuzal"):summary.unlock="Insígnia do Bambuzal · Clareira do Papel liberada"
		if won and model.stage_id=="beira-canal-5" and not preload("res://scripts/campaign/district_rules.gd").completed(player,"beira-canal"):summary.unlock="Insígnia de Beira-Canal · Feira do Largo é o próximo destino"
		if won and model.stage_id=="feira-5" and not preload("res://scripts/campaign/district_rules.gd").completed(player,"feira"):summary.unlock="Insígnia da Feira do Largo · caminho do Mural reconhecido"
	elif encounter.get("kind", "") == "morro" and model.outcome != "fled":
		var reward := Rules.settle(player.get("morro", Rules.defaults()), model.stage_id, won, model.rounds_lost())
		summary.coins = reward.coins
		summary.stars = reward.stars
		var next_index:=Rules.IDS.find(model.stage_id)+1
		if won and reward.firstClear and next_index<Rules.IDS.size():
			summary.unlock="Passagem liberada · "+str(Rules.stage(Rules.IDS[next_index]).get("name","próximo desafio"))
		amount = Morro.reward_amount(won, reward.firstClear)
		if reward.get("drop") != null: summary.items.append("Rabiola de Raio de sol")
	elif encounter.get("kind","")=="warehouse-story":
		if won:
			if encounter.get("warehouseOpponent")=="gollia":summary.unlock="Porta do galpão liberada · parte B"
			else:
				summary.unlock="Pipa-Dragão livre · duelo com Bruno Solda liberado"
				summary.items.append("Agulha de desatar")
	elif encounter.get("kind","")=="feira-story":
		if won:
			summary.unlock="Lalau confessou · procure Grampo no beco do mercado" if encounter.feiraOpponent=="lalau" else "Recebido · Apito de vento verdadeiro"
			if encounter.feiraOpponent=="lalau":summary.coins=20
	elif encounter.get("kind","")=="canal-gate":
		if won:summary.unlock="Grampo recuou · a comporta pode ser destrancada"
	if won and encounter.get("kind","") in STORY_KINDS:
		amount = Progression.story_xp(player, model.snapshot())
	elif won and encounter.get("kind","") not in ["district","morro"]:
		var boss: bool = encounter.get("kind", "") == "lacertubo"
		amount = Encounters.reward_for(encounter,model.snapshot())
		if boss: summary.items.append("Rabiola de Lacertubo")
		elif encounter.get("kind","")!="trainer":
			var drop: Dictionary = player.get("wildDrop", {"intro": false, "misses": 0})
			if not drop.intro or drop.misses >= 7 or encounter.get("dropRoll", 1) < .25:
				var name: String = {"basica": "Carcará", "mata": "Mata verde", "raio": "Raio de sol","rascunho-bicho-pau":"Bicho-pau de Vareta","rascunho-joaninha":"Joaninha-pião"}.get(model.enemy_model_id, model.enemy_model_id)
				summary.items.append("Rabiola de " + name)
	summary.xp = Progression.credit_for(partner, amount)
	summary.new_items=[]
	for item in summary.items:
		var item_id:String={"Rabiola de Bicho-pau de Vareta":"rabiola-rascunho-bicho-pau","Rabiola de Joaninha-pião":"rabiola-rascunho-joaninha","Rabiola de Mata verde":"rabiola-mata","Rabiola de Lacertubo":"rabiola-lacertubo","Rabiola de Carcará":"rabiola-basica","Rabiola de Raio de sol":"rabiola-raio"}.get(item,"")
		if not item_id.is_empty() and player.get("inventory",{}).get(item_id,0)==0:summary.new_items.append(item)
	if won and encounter.get("kind","")=="lacertubo" and not player.get("flags",{}).get("ninaTail",false):
		summary.notice="A rabiola de Nina ficou no chão. Procure-a no pátio, atrás do guardião."
	summary.after = summary.before + summary.xp
	var projected:Dictionary=player.duplicate(true)
	var projected_partner:Dictionary=partner.duplicate(true)
	Progression.award(projected,projected_partner,amount)
	var bonus:=Encounters.owner_bonus(encounter,model.snapshot())
	summary.coins+=bonus.coins
	projected.tamerXp=mini(31383,int(projected.get("tamerXp",0))+int(bonus.tamerXp))
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
