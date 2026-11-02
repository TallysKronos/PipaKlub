extends RefCounted
const Levels=preload("res://scripts/campaign/partner_levels.gd")
static func player() -> Dictionary:
	var result:Dictionary=preload("res://scripts/campaign/state.gd").fresh("slot-1").player
	for pair in [["rabbito","Rabbito"],["basica","Carcará"],["doberman-c","Um parceiro com um nome bastante comprido"]]:
		result.partners.append({"id":pair[0],"modelId":pair[0],"personalName":pair[1],"xp":Levels.xp_for_level(8)+30,"condition":{"line":84,"structure":96}})
	result.equippedPartnerId="rabbito";result.sightings=["lacertubo"];result.coins=3560
	result.journey={"lesson":5,"phase":"complete"}
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(result)
	preload("res://scripts/campaign/pipeiro_identity.gd").award_district(result,0,"mikka","Insígnia do Morro do Sol",{"districtName":"Morro do Sol","bossName":"Mikka","description":"Vitória contra a campeã do Morro do Sol."})
	return result
