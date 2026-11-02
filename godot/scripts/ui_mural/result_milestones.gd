extends RefCounted
## Read only committed campaign data; never grant XP or create a reward receipt.
const Levels=preload("res://scripts/campaign/partner_levels.gd")
static func levels(player:Dictionary) -> Dictionary:
	var result:Dictionary={}
	for partner in player.get("partners",[]):result[partner.id]=Levels.level_for_xp(partner.get("xp",0))
	return result
static func changes(previous:Dictionary,player:Dictionary) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for partner in player.get("partners",[]):
		var after:=Levels.level_for_xp(partner.get("xp",0));var before:int=previous.get(partner.id,after)
		if after>before:result.append({"name":partner.get("personalName",partner.modelId),"model":partner.modelId,"before":before,"after":after})
	return result
