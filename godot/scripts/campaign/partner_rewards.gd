extends RefCounted
## Earned creatures have durable identity even while awaiting a destination.
const State = preload("res://scripts/campaign/state.gd")
var bank: RefCounted
func _init(value: RefCounted) -> void: bank = value
static func item(entry: Dictionary) -> Dictionary:
	return {"id":entry.partner.id,"partner":entry.partner.duplicate(true),"source":entry.reward.source,"mandatory":entry.reward.mandatory,"equip":entry.reward.equip}
func _active(next: Dictionary, previous: String = "") -> void:
	var ids: Array = next.player.partners.map(func(p):return p.id)
	if ids.has(next.player.get("equippedPartnerId","")): return
	if ids.has(previous): next.player.equippedPartnerId=previous
	elif not ids.is_empty(): next.player.equippedPartnerId=ids[0]
	else: next.player.erase("equippedPartnerId")
func _stage(ledger: Dictionary, next: Dictionary, source: String, id: String, direction: String, target: String, revision: int) -> Dictionary:
	var stamp := "bank-transfer-reward-"+State.new_id()
	next.player.completedOperations.append(stamp)
	ledger.operations[stamp]={"id":id,"direction":direction,"campaignId":State.campaign_key(next),"source":source}
	ledger.pending={"snapshot":next,"target":target,"expected":revision,"operation":stamp}
	var result: Dictionary=bank._commit(ledger,int(ledger.revision))
	if result.status!="ok":return result
	return {"status":"ok" if bank.store._recover_archives()=="ok" else "bank_pending"}
func grant(snapshot: Dictionary, additions: Array, source: String, target: String, revision: int, previous_active: String) -> Dictionary:
	var loaded: Dictionary=bank.load_ledger()
	if loaded.status!="ok":return loaded
	var ledger: Dictionary=loaded.data
	if not ledger.pending.is_empty():return {"status":"bank_pending"}
	var campaign:=State.campaign_key(snapshot)
	var key:=campaign+"|"+source
	var awards: Dictionary=ledger.get("awards",{})
	var known: Array=awards.get(key,[])
	var next: Dictionary=bank.reconcile(snapshot,ledger)
	var proposed: Array=additions.map(func(p):return p.id)
	next.player.partners=next.player.partners.filter(func(p):return not p.id in proposed)
	var earned: Array=[]
	if known.is_empty():
		for partner in additions:
			var mandatory: bool=bank.story_bound(partner) or partner.get("origin","") in ["story-kael-birthday-v1","first-flight-starter-v1"]
			ledger.entries[partner.id]={"owner":"pending","campaignId":campaign,"partner":partner.duplicate(true),"inject":not bank.story_bound(partner),"reward":{"source":source,"mandatory":mandatory,"equip":snapshot.player.get("equippedPartnerId","")==partner.id}}
			earned.append(partner.id)
		awards[key]=earned;ledger.awards=awards
	else: earned=known.duplicate()
	var queue: Array=next.player.get("pendingPartners",[])
	for id: String in earned:
		if not ledger.entries.has(id):return {"status":"bank_corrupt"}
		var entry: Dictionary=ledger.entries[id]
		if entry.owner not in ["pending",campaign]:continue
		if next.player.partners.any(func(p):return p.id==id):continue
		if next.player.partners.size()<bank.CAMPAIGN_LIMIT:
			next.player.partners.append(entry.partner.duplicate(true));entry.owner=campaign
			queue=queue.filter(func(p):return p.id!=id)
			if entry.reward.equip:next.player.equippedPartnerId=id
		else:
			entry.owner="pending"
			if not queue.any(func(p):return p.id==id):queue.append(item(entry))
	if not queue.is_empty():next.player.pendingPartners=queue
	elif next.player.has("pendingPartners"):next.player.pendingPartners=[]
	for partner in next.player.partners:
		if not bank.story_bound(partner):
			var record: Dictionary=ledger.entries.get(partner.id,{})
			record.owner=campaign;record.partner=partner.duplicate(true);ledger.entries[partner.id]=record
	_active(next,previous_active)
	return _stage(ledger,next,source,str(earned[0]),"award",target,revision)
func resolve(snapshot: Dictionary, id: String, destination: String, victim: String, operation: String, target: String, revision: int) -> Dictionary:
	if destination not in ["campaign","global","replace","decline"] or not operation.begins_with("bank-transfer-") or operation.length()>128:return {"status":"invalid_operation"}
	if snapshot.checkpoint.get("kind") in ["encounter","workshop"]:return {"status":"bank_unsafe"}
	var loaded: Dictionary=bank.load_ledger()
	if loaded.status!="ok":return loaded
	var ledger: Dictionary=loaded.data
	if not ledger.pending.is_empty():return {"status":"bank_pending"}
	var campaign:=State.campaign_key(snapshot)
	var request: Dictionary={"id":id,"direction":"claim","campaignId":campaign,"destination":destination,"victim":victim}
	if ledger.operations.has(operation):return {"status":"already_applied" if ledger.operations[operation]==request else "invalid_operation"}
	if not ledger.entries.has(id) or ledger.entries[id].owner!="pending" or ledger.entries[id].get("campaignId")!=campaign:return {"status":"reward_missing"}
	var entry: Dictionary=ledger.entries[id]
	if entry.reward.mandatory and destination in ["global","decline"]:return {"status":"reward_essential"}
	var next: Dictionary=bank.reconcile(snapshot,ledger)
	if destination in ["campaign","replace"]:
		if destination=="replace":
			if next.player.partners.size()<bank.CAMPAIGN_LIMIT:return {"status":"reward_space_available"}
			if victim==next.player.get("equippedPartnerId",""):return {"status":"bank_active"}
			var found: Array=next.player.partners.filter(func(p):return p.id==victim)
			if found.is_empty():return {"status":"bank_missing"}
			if bank.story_bound(found[0]):return {"status":"bank_story"}
			ledger.entries[victim]={"owner":"released","partner":found[0].duplicate(true)}
			next.player.partners=next.player.partners.filter(func(p):return p.id!=victim)
		if next.player.partners.size()>=bank.CAMPAIGN_LIMIT:return {"status":"bank_campaign_full"}
		next.player.partners.append(entry.partner.duplicate(true));entry.owner=campaign
		if entry.reward.equip:next.player.equippedPartnerId=id
	elif destination=="global":
		if bank.global_partners(ledger).size()>=bank.GLOBAL_LIMIT:return {"status":"bank_global_full"}
		entry.owner="global"
	else:entry.owner="released"
	next.player.pendingPartners=next.player.get("pendingPartners",[]).filter(func(p):return p.id!=id)
	next.player.completedOperations.append(operation)
	ledger.operations[operation]=request
	ledger.pending={"snapshot":next,"target":target,"expected":revision,"operation":operation}
	var result: Dictionary=bank._commit(ledger,int(ledger.revision))
	if result.status!="ok":return result
	return {"status":"ok" if bank.store._recover_archives()=="ok" else "bank_pending"}
