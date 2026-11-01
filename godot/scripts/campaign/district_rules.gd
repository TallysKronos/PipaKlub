extends RefCounted
## Historical completion is permanent. Current ownership/qualification is a separate cycle.
const VERSION:=1
static var _catalog:Dictionary={}
static func catalog() -> Array:
	if _catalog.is_empty():_catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/championship/districts.json"))
	return _catalog.districts.duplicate(true)
static func definition(id:String) -> Dictionary:
	if _catalog.is_empty():catalog()
	for d:Dictionary in _catalog.districts:
		if d.id==id:return d.duplicate(true)
	return {}
static func fresh(id:String) -> Dictionary:
	var d:=definition(id)
	return {} if d.is_empty() else {"completed":false,"champion":d.champion.id,"qualification":[],"wonDuels":[],"rewardClaimed":false,"pendingDefense":{},"epoch":0,"defensesWon":0,"defensesLost":0}
static func entry(player:Dictionary,id:String) -> Dictionary:
	var d:=definition(id)
	if d.is_empty():return {}
	var result:Dictionary=player.get("championship",{}).get("districts",{}).get(id,fresh(id)).duplicate(true)
	# Lazy, additive migration. Never replay historical stars into a requalification cycle.
	if id=="morro" and not result.completed:
		var stars:Dictionary=player.get("morro",{}).get("stars",{})
		for stage:Dictionary in d.stages:
			if not stars.has(stage.id):continue
			if stage.id not in result.wonDuels:result.wonDuels.append(stage.id)
			if stage.role=="lieutenant" and stage.id not in result.qualification:result.qualification.append(stage.id)
		if stars.has("morro-5"):
			result.completed=true;result.rewardClaimed=true;result.champion="player"
			for stage:Dictionary in d.stages:
				if stage.id not in result.wonDuels:result.wonDuels.append(stage.id)
	return result
static func store(player:Dictionary,id:String,value:Dictionary) -> void:
	if not player.has("championship"):player.championship={"version":VERSION,"districts":{}}
	player.championship.districts[id]=value.duplicate(true)
static func completed(player:Dictionary,id:String) -> bool:
	return bool(entry(player,id).get("completed",false))
static func completed_count(player:Dictionary) -> int:
	var count:=0
	for d:Dictionary in catalog():
		if completed(player,d.id):count+=1
	return count
static func unlocked_areas(player:Dictionary) -> Array:
	var result:Array=[]
	for d:Dictionary in catalog():
		if not completed(player,d.id):continue
		for area in d.unlocks:
			if area not in result:result.append(area)
	return result
static func city_final_unlocked(player:Dictionary) -> bool:
	return completed_count(player)==12
static func opponent_name(player:Dictionary,id:String) -> String:
	var d:=definition(id);var value:=entry(player,id)
	if d.is_empty():return ""
	var npc:String=value.pendingDefense.get("challenger",value.champion)
	if npc=="player":return player.get("name","Kael")
	if npc==d.champion.id:return d.champion.name
	for stage:Dictionary in d.stages:
		if stage.npcId==npc:return stage.get("npcName",stage.name)
	return ""
static func objective(player:Dictionary,id:String) -> String:
	var value:=entry(player,id)
	match status(player,id):
		"defense_pending":return "Defesa pendente · converse com "+opponent_name(player,id)+". O desafio fica salvo."
		"requalifying":return "Reconquista · %d/4 desafios vencidos. Depois, enfrente %s."%[value.qualification.size(),opponent_name(player,id)]
		"reclaim":return "Reconquista · enfrente "+opponent_name(player,id)+" para recuperar o título."
		"won":return "Você é o campeão do bairro. Os caminhos continuam abertos."
	return ""
static func award_emblem(player:Dictionary,id:String) -> bool:
	var d:=definition(id)
	if d.is_empty() or not completed(player,id):return false
	var identity=preload("res://scripts/campaign/pipeiro_identity.gd")
	if not identity.issued(player):
		if not identity.eligible(player):return false
		identity.issue_into(player);player.flags.pipeiroDocumentsSeen=true
	var name:String="Insígnia do Morro do Sol" if id=="morro" else d.emblem.name
	var awarded:bool=identity.award_district(player,int(d.emblem.slot),d.champion.id,name,{"districtName":d.name,"bossName":d.champion.name})
	if awarded and id=="morro":player.inventory["insignia-morro-do-sol"]=1
	return awarded
static func unlocked(player:Dictionary,id:String) -> bool:
	var d:=definition(id)
	if d.is_empty():return false
	return completed(player,id) or (player.get("journey",{}).get("phase")=="complete" if d.number==1 else completed(player,catalog()[int(d.number)-2].id))
static func qualified(value:Dictionary,d:Dictionary) -> bool:
	return d.stages.slice(0,4).all(func(s):return s.id in value.qualification)
static func status(player:Dictionary,id:String) -> String:
	var d:=definition(id);var value:=entry(player,id)
	if not unlocked(player,id):return "locked"
	if value.champion=="player":return "defense_pending" if not value.pendingDefense.is_empty() else "won"
	if not qualified(value,d):return "requalifying" if value.completed else "lieutenants"
	if not d.prerequisiteFlag.is_empty() and not player.get("flags",{}).get(d.prerequisiteFlag,false):return "prerequisite"
	return "reclaim" if value.completed else "champion"
static func prepare(player:Dictionary,id:String,duel:String,defense_id:String="") -> Dictionary:
	var d:=definition(id);var value:=entry(player,id)
	if d.is_empty() or not unlocked(player,id):return {"status":"wrong_step"}
	var index:int=d.stages.map(func(s):return s.id).find(duel)
	if index<0:return {"status":"wrong_step"}
	var mode:="progress"
	if not defense_id.is_empty():
		if value.pendingDefense.get("id","")!=defense_id or value.champion!="player" or index!=4:return {"status":"wrong_step"}
		mode="defense"
	else:
		if not value.pendingDefense.is_empty():return {"status":"defense_pending"}
		if value.champion=="player":return {"status":"already_applied"}
		if index<4:
			if duel in value.qualification:return {"status":"already_applied"}
			if index>0 and d.stages[index-1].id not in value.qualification:return {"status":"wrong_step"}
			mode="requalify" if value.completed else "progress"
		elif status(player,id) not in ["champion","reclaim"]:return {"status":"wrong_step"}
		else:mode="reclaim" if value.completed else "progress"
	var opponent:String=value.pendingDefense.challenger if mode=="defense" else value.champion if index==4 else d.stages[index].npcId
	return {"status":"ok","context":{"version":VERSION,"district":id,"duel":duel,"mode":mode,"opponent":opponent,"defenseId":defense_id,"epoch":value.epoch}}
static func offer(player:Dictionary,id:String,challenger:String,challenge_id:String,scene:String) -> Dictionary:
	var d:=definition(id);var value:=entry(player,id)
	if d.is_empty() or challenge_id.is_empty() or challenger not in d.stages.slice(0,4).map(func(s):return s.npcId) or value.champion!="player":return {"status":"wrong_step"}
	if not value.pendingDefense.is_empty():return {"status":"already_applied"}
	var next:=player.duplicate(true)
	value.epoch+=1
	value.pendingDefense={"id":challenge_id,"challenger":challenger,"scene":scene}
	store(next,id,value)
	return {"status":"ok","player":next}
static func settle(player:Dictionary,context:Dictionary,outcome:String) -> Dictionary:
	if outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
	var planned:=prepare(player,str(context.get("district","")),str(context.get("duel","")),str(context.get("defenseId","")))
	if planned.status!="ok":return planned
	if not same_context(planned.context,context):return {"status":"stale"}
	var d:=definition(context.district);var value:=entry(player,d.id)
	var next:=player.duplicate(true)
	var first:bool=outcome=="won" and context.duel not in value.wonDuels
	var first_district:=false
	if context.mode=="defense":
		if outcome=="won":value.defensesWon+=1
		else:
			value.defensesLost+=1;value.champion=context.opponent;value.qualification=[]
		value.pendingDefense={}
	elif outcome=="won":
		if context.duel not in value.wonDuels:value.wonDuels.append(context.duel)
		if context.duel==d.stages[4].id:
			first_district=not value.rewardClaimed
			value.completed=true;value.rewardClaimed=true;value.champion="player"
		else:value.qualification.append(context.duel)
	value.epoch+=1
	store(next,d.id,value)
	return {"status":"ok","player":next,"firstClear":first,"firstDistrict":first_district,"mode":context.mode,"unlocked":([d.next]+d.unlocks) if first_district else []}
static func valid(value:Variant) -> bool:
	if not value is Dictionary or value.get("version")!=VERSION or not value.get("districts") is Dictionary or value.districts.size()>12:return false
	for id in value.districts:
		var d:=definition(id);var e:Variant=value.districts[id]
		if d.is_empty() or not e is Dictionary:return false
		for field in ["completed","rewardClaimed"]:
			if not e.get(field) is bool:return false
		for field in ["epoch","defensesWon","defensesLost"]:
			var n:Variant=e.get(field)
			if not (n is float or n is int) or not is_finite(n) or n<0 or n>9007199254740991 or floorf(n)!=n:return false
		if e.get("champion") not in ["player",d.champion.id]+d.stages.slice(0,4).map(func(s):return s.npcId):return false
		for field in ["qualification","wonDuels"]:
			if not e.get(field) is Array:return false
			var seen:={}
			var allowed:Array=d.stages.slice(0,4 if field=="qualification" else 5).map(func(s):return s.id)
			for duel in e[field]:
				if duel not in allowed or seen.has(duel):return false
				seen[duel]=true
		if e.completed!=e.rewardClaimed or (e.champion=="player" and not e.completed):return false
		if not e.get("pendingDefense") is Dictionary:return false
		if not e.pendingDefense.is_empty():
			var pending:Dictionary=e.pendingDefense
			if e.champion!="player" or not pending.get("id") is String or pending.id.is_empty() or pending.id.length()>64 or pending.get("challenger") not in d.stages.slice(0,4).map(func(s):return s.npcId) or not pending.get("scene") is String:return false
	return true
static func valid_context(value:Variant) -> bool:
	if not value is Dictionary or value.get("version")!=VERSION:return false
	var d:=definition(str(value.get("district","")))
	if d.is_empty() or value.get("duel") not in d.stages.map(func(s):return s.id):return false
	if value.get("mode") not in ["progress","requalify","reclaim","defense"] or value.get("opponent") not in [d.champion.id]+d.stages.slice(0,4).map(func(s):return s.npcId):return false
	var epoch:Variant=value.get("epoch")
	if not (epoch is float or epoch is int) or not is_finite(epoch) or epoch<0 or epoch>9007199254740991 or floorf(epoch)!=epoch:return false
	return value.get("defenseId") is String and (not value.defenseId.is_empty() if value.mode=="defense" else value.defenseId.is_empty())
static func same_context(a:Dictionary,b:Dictionary) -> bool:
	if not valid_context(a) or not valid_context(b):return false
	for field in ["district","duel","mode","opponent","defenseId"]:
		if a[field]!=b[field]:return false
	# Godot JSON loads integers as floats; Dictionary equality distinguishes those variants.
	return int(a.epoch)==int(b.epoch) and int(a.version)==int(b.version)
