extends RefCounted
## Offline city quest. Reward and receipt are one atomic campaign snapshot.
const ITEM:="apito-de-elo"
const CLASP:="quest-fecho-guia"
const TITLE:="Um elo para a estrada"
const ZECA:=Vector2(22.8,18.5)
const LIA:=Vector2(25.8,-.6)
var session:Node
func _init(local_session:Node) -> void:session=local_session

static func owned(player:Dictionary) -> bool:
	return int(player.get("inventory",{}).get(ITEM,0))>0

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
	if step==3:return {"status":"already_applied"}
	var operation:=""
	if npc=="zeca" and step==0:
		player.flags.mountQuestAccepted=true;operation="mount-quest-accepted-v1"
	elif npc=="lia" and step==1:
		player.flags.mountClaspReady=true;player.inventory[CLASP]=1;operation="mount-quest-clasp-v1"
	elif npc=="zeca" and step==2 and int(player.inventory.get(CLASP,0))==1:
		player.inventory.erase(CLASP);player.inventory[ITEM]=1;player.flags.mountQuestCompleted=true;operation="mount-quest-reward-v1"
	else:return {"status":"wrong_step"}
	return session.commit_operation(operation,cp,player)
