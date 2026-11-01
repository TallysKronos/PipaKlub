extends RefCounted
## Offline city quest. Reward and receipt are one atomic campaign snapshot.
const MODEL:="doberman-c"
const ITEM:="apito-de-elo"
const CLASP:="quest-fecho-guia"
const TITLE:="Um elo para a estrada"
const ZECA:=Vector2(22.8,18.5)
const LIA:=Vector2(25.8,-.6)
var session:Node
func _init(local_session:Node) -> void:session=local_session

static func owned(player:Dictionary) -> bool:
	return int(player.get("inventory",{}).get(ITEM,0))>0

static func capable(partner:Dictionary) -> bool:
	return partner.get("modelId","")==MODEL

static func healthy(partner:Dictionary) -> bool:
	var condition:Dictionary=partner.get("condition",{})
	var stats:Dictionary=preload("res://scripts/campaign/encounter_model.gd").stats(preload("res://scripts/campaign/partner_levels.gd").level_for_xp(partner.get("xp",0)),partner.get("craftBonus",0))
	return stats.line*float(condition.get("line",100))/100.0>=1.0 and stats.line*float(condition.get("structure",100))/100.0>=1.0

static func eligible(player:Dictionary) -> bool:
	if not owned(player):return false
	for partner in player.get("partners",[]):
		if capable(partner) and healthy(partner):return true
	return false

static func grant_partner(player:Dictionary) -> void:
	for partner in player.get("partners",[]):
		if partner.get("origin","")=="mount-quest-reward-v1":return
	player.partners.append({"id":preload("res://scripts/campaign/state.gd").new_id(),"modelId":MODEL,"personalName":"Dóber de papel","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100},"origin":"mount-quest-reward-v1","certification":"unverified"})
	preload("res://scripts/campaign/progression.gd").acquire(player,MODEL)

static func stage(player:Dictionary) -> int:
	if owned(player):return 3
	if player.get("flags",{}).get("mountClaspReady",false):return 2
	if player.get("flags",{}).get("mountQuestAccepted",false):return 1
	return 0

static func objective(player:Dictionary) -> String:
	match stage(player):
		0:return "Converse com Zeca na pracinha para conhecer a montaria."
		1:return "Peça a Lia, na rua alta, um fecho para a guia."
		2:return "Leve o fecho de volta a Zeca na pracinha."
	return "Apito de Elo recebido. Use B ou a mochila para chamar a montaria."

static func available(player:Dictionary) -> bool:
	return player.get("journey",{}).get("phase")=="complete"

func talk(npc:String) -> Dictionary:
	var saved:Dictionary=session.snapshot()
	var player:Dictionary=saved.player
	if not available(player):return {"status":"wrong_step"}
	var cp:Dictionary=saved.checkpoint
	if cp.get("kind")!="world" or cp.get("scene")!="quintal" or cp.get("space")!="bairro-inicial-v2":return {"status":"wrong_step"}
	if npc not in ["zeca","lia"]:return {"status":"wrong_step"}
	var p:=Vector2(cp.position[0],cp.position[1])
	if p.distance_to(ZECA if npc=="zeca" else LIA)>1.8:return {"status":"wrong_step"}
	var step:=stage(player)
	if step==3:
		if npc=="zeca" and player.flags.get("mountQuestCompleted",false):
			var count:int=player.partners.size()
			grant_partner(player)
			if player.partners.size()>count:return session.commit_operation("mount-partner-issued-v1",cp,player)
		return {"status":"already_applied"}
	var operation:=""
	if npc=="zeca" and step==0:
		player.flags.mountQuestAccepted=true;operation="mount-quest-accepted-v1"
	elif npc=="lia" and step==1:
		player.flags.mountClaspReady=true;player.inventory[CLASP]=1;operation="mount-quest-clasp-v1"
	elif npc=="zeca" and step==2 and int(player.inventory.get(CLASP,0))==1:
		grant_partner(player)
		player.inventory.erase(CLASP);player.inventory[ITEM]=1;player.flags.mountQuestCompleted=true;operation="mount-quest-reward-v1"
	else:return {"status":"wrong_step"}
	return session.commit_operation(operation,cp,player)
