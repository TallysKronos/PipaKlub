extends RefCounted
## Offline grants mirror 029_veredas_exploration.sql; no online certification.
const Data = preload("res://scripts/campaign/park_data.gd")
var session: Node

func _init(local_session: Node) -> void:
	session = local_session

func _near(point: Vector2, target: Vector2, radius: float = 85, key: String = "") -> bool:
	var saved: Dictionary = session.snapshot()
	if saved.get("checkpoint",{}).get("space","")=="parque-overworld-v1":
		return preload("res://scripts/campaign/park_checkpoint.gd").near(saved.checkpoint,key,point)
	return saved.get("checkpoint", {}).get("scene") == "park-veredas" and point.distance_to(target) <= radius

func accept_nina(point: Vector2) -> Dictionary:
	if not _near(point, Data.NINA,85,"nina"): return {"status": "wrong_step"}
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	player.flags.ninaAccepted = true
	return session.commit_operation("nina-accepted-v1", saved.checkpoint, player)

func introduce_guardian(point: Vector2) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	var checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
	if saved.checkpoint.get("space","")!=checkpoint.SPACE or saved.checkpoint.get("scene","")!="park-veredas": return {"status":"wrong_step"}
	if not saved.player.flags.get("ninaAccepted",false) or saved.player.flags.get("guardianDefeated",false): return {"status":"wrong_step"}
	if not checkpoint.valid_position("park-veredas",point) or point.distance_to(checkpoint.target("park-veredas","boss"))>=8.0: return {"status":"wrong_step"}
	saved.player.flags.lacertuboIntroduced=true
	return session.commit_operation("lacertubo-introduced-v1",saved.checkpoint,saved.player)

func chest(id: String, point: Vector2) -> Dictionary:
	if not Data.CHESTS.has(id) or not _near(point, Data.CHESTS[id].point,85,"chest:"+id): return {"status": "wrong_step"}
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
	if not _near(point, Data.TAIL,85,"tail"): return {"status": "wrong_step"}
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	if not player.flags.get("guardianDefeated", false) or not player.flags.get("ninaAccepted", false): return {"status": "wrong_step"}
	player.flags.ninaTail = true
	player.inventory["quest-nina-tail"] = 1
	return session.commit_operation("nina-tail-v1", saved.checkpoint, player)

func return_tail(point: Vector2) -> Dictionary:
	if not _near(point, Data.NINA,85,"nina"): return {"status": "wrong_step"}
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

func park_loot(id: String, point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if preload("res://scripts/campaign/park_checkpoint.gd").is_bosque(saved.checkpoint.get("scene","")):
		return preload("res://scripts/campaign/bosque_campaign.gd").new(session).collect(id,point)
	var Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
	var checkpoint: Dictionary = saved.get("checkpoint",{})
	if checkpoint.get("space","")!=Checkpoint.SPACE or not Checkpoint.MAPS.has(checkpoint.get("scene","")): return {"status":"wrong_step"}
	if saved.player.get("journey",{}).get("phase","")!="complete": return {"status":"wrong_step"}
	var map: Dictionary = Checkpoint.data(checkpoint.scene)
	var entry: Dictionary = {}
	var item := ""
	var amount := 0
	var chest := ""
	if id.begins_with("piece-"):
		for piece in map.pieces:
			if str(int(piece.id))!=id.trim_prefix("piece-") or piece.asset!="bau" or piece.props.has("bau"): continue
			if checkpoint.scene!="park-trail" or int(piece.id) not in [45,46]: return {"status":"wrong_step"}
			entry=piece
			item="coins" if int(piece.id)==45 else "linha"
			amount=10 if item=="coins" else 2
			chest="parque:"+map.id+":"+str(int(piece.id))
	else:
		for event in map.events:
			if str(int(event.id))==id and event.type=="item": entry=event; break
		if not entry.is_empty():
			item=str(entry.props.get("item",""))
			amount=int(entry.props.get("quantidade",0))
	if entry.is_empty() or item not in ["coins","linha","folha"] or amount<1 or amount>10: return {"status":"wrong_step"}
	if not Checkpoint.valid_position(checkpoint.scene,point) or not Checkpoint.model_for(checkpoint.scene).walkable(Vector2i(point.floor())) or point.distance_to(Vector2(entry.u+.5,entry.v+.5))>1.8: return {"status":"wrong_step"}
	if absf(Checkpoint.model_for(checkpoint.scene).height_at(point)-Checkpoint.model_for(checkpoint.scene).height_at(Vector2(entry.u+.5,entry.v+.5)))>=.25: return {"status":"wrong_step"}
	var operation: String = "park-item-"+map.id+"-"+id
	if operation in saved.player.completedOperations: return {"status":"already_applied"}
	if item=="coins": saved.player.coins+=amount
	else: saved.player.inventory[item]=saved.player.inventory.get(item,0)+amount
	if not chest.is_empty(): saved.player.openedChests.append(chest)
	var result: Dictionary = session.commit_operation(operation,checkpoint,saved.player)
	if result.status=="ok": result.reward="%d %s"%[amount,{"coins":"moedas","linha":"linha(s)","folha":"folha(s)"}[item]]
	return result

func rest(point: Vector2) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	var Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
	if saved.checkpoint.get("kind","")!="world" or saved.checkpoint.get("space","")!=Checkpoint.SPACE or not Checkpoint.MAPS.has(saved.checkpoint.get("scene","")): return {"status":"wrong_step"}
	var model=Checkpoint.model_for(saved.checkpoint.scene)
	if not point.is_finite() or not model.point_walkable(point): return {"status":"wrong_step"}
	var nearby:=false
	for event in model.data.events+preload("res://scripts/campaign/bosque_campaign.gd").rest_events(model.data.id,model):
		var target:=Vector2(event.u+.5,event.v+.5)
		if event.props.get("acao","")=="wildRest" and point.distance_to(target)<=1.8 and absf(model.height_at(point)-model.height_at(target))<.25: nearby=true;break
	if not nearby: return {"status":"wrong_step"}
	for partner in saved.player.partners: partner.condition={"line":100,"structure":100}
	saved.player.encounterGraceUntil=Time.get_unix_time_from_system()+6.0
	return session.checkpoint(saved.checkpoint,saved.player)
