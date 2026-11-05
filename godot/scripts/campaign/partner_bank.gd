extends RefCounted
## Local-profile ownership ledger, independent of campaign rollback/deletion.
## Immutable generations avoid rolling back ownership through an older .bak.
const State = preload("res://scripts/campaign/state.gd")
const Rewards = preload("res://scripts/campaign/partner_rewards.gd")
const CAMPAIGN_LIMIT := 30
const GLOBAL_LIMIT := 20
const MAX_BYTES := 16 * 1024 * 1024
const VERSION := 2
var store: RefCounted
func _init(value: RefCounted) -> void: store = value
func fresh() -> Dictionary: return {"version":VERSION,"revision":0,"entries":{},"operations":{},"pending":{}}
func _canonical(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)), "", true)
func load_ledger() -> Dictionary:
	var paths: Array[String] = []
	var revision := 0
	if DirAccess.dir_exists_absolute(store.bank_directory):
		for filename in DirAccess.get_files_at(store.bank_directory):
			if not filename.ends_with(".json") or filename.length() < 18 or filename.substr(12,1) != "-" or not filename.left(12).is_valid_int(): continue
			var number := int(filename.left(12))
			if number > revision: revision = number; paths.clear()
			if number == revision: paths.append(store.bank_directory.path_join(filename))
	if paths.is_empty(): return {"status":"ok","data":fresh()}
	if paths.size() != 1: return {"status":"bank_conflict"}
	var file := FileAccess.open(paths[0], FileAccess.READ)
	if file == null: return {"status":"io_error"}
	if file.get_length() > MAX_BYTES: return {"status":"bank_corrupt"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {"status":"bank_corrupt"}
	var envelope: Variant = parser.data
	if not envelope is Dictionary or not envelope.get("data") is Dictionary: return {"status":"bank_corrupt"}
	var data: Dictionary = envelope.data
	if envelope.get("hash") != _canonical(data).sha256_text() or data.get("revision") != revision: return {"status":"bank_corrupt"}
	if not State.whole(data.get("version")):return {"status":"bank_corrupt"}
	if data.version > VERSION: return {"status":"bank_future"}
	if not valid(data): return {"status":"bank_corrupt"}
	return {"status":"ok","data":data}
func valid(data: Dictionary) -> bool:
	if (data.get("version") != 1 and data.get("version") != VERSION) or not State.whole(data.get("revision")) or not data.get("entries") is Dictionary or not data.get("operations") is Dictionary or not data.get("pending") is Dictionary: return false
	var all: Array = []
	var global_count := 0
	for id: String in data.entries:
		var entry: Variant = data.entries[id]
		if not entry is Dictionary or not entry.get("owner") is String or entry.owner.is_empty() or entry.owner.length()>128 or not entry.get("partner") is Dictionary or entry.partner.get("id") != id: return false
		all.append(entry.partner)
		if entry.owner == "global": global_count += 1
	if global_count > GLOBAL_LIMIT: return false
	var sample := State.fresh("slot-1"); sample.player.partners = all
	if State.inspect(sample, "slot-1") != "ok": return false
	for operation: String in data.operations:
		var op: Variant = data.operations[operation]
		if not operation.begins_with("bank-transfer-") or operation.length()>128 or not op is Dictionary or not op.get("id") is String or not op.get("campaignId") is String or op.get("direction") not in ["deposit","withdraw","discard","award","claim"]: return false
	if data.has("awards"):
		if not data.awards is Dictionary:return false
		for ids in data.awards.values():
			if not ids is Array or ids.is_empty():return false
			for id in ids:
				if not id is String or not data.entries.has(id):return false
	for entry in data.entries.values():
		if entry.owner=="pending":
			if not entry.get("campaignId") is String or not entry.get("reward") is Dictionary:return false
			if not entry.reward.get("source") is String or not entry.reward.get("mandatory") is bool or not entry.reward.get("equip") is bool:return false
	if not data.pending.is_empty():
		var p: Dictionary = data.pending
		var expected: Variant = p.get("expected")
		if not (expected is int or expected is float) or not is_finite(float(expected)) or expected < -1 or not State.whole(expected+1): return false
		if not p.get("operation") is String or not data.operations.has(p.operation) or not State.valid_slot(str(p.get("target",""))) or not p.get("snapshot") is Dictionary: return false
		if State.inspect(p.snapshot, str(p.snapshot.get("slotId",""))) != "ok": return false
		if data.operations[p.operation].campaignId != State.campaign_key(p.snapshot) or not p.operation in p.snapshot.player.completedOperations: return false
	return true
func _commit(data: Dictionary, revision: int) -> Dictionary:
	var current := load_ledger()
	if current.status != "ok": return current
	if int(current.data.revision) != revision: return {"status":"stale"}
	var next := data.duplicate(true); next.revision = revision + 1;next.version=VERSION
	if not valid(next) or next.revision > 999999999999: return {"status":"bank_corrupt"}
	if DirAccess.make_dir_recursive_absolute(store.bank_directory) != OK: return {"status":"io_error"}
	var path: String = store.bank_directory.path_join("%012d-%s.json" % [next.revision, State.new_id()])
	var envelope := {"data":next,"hash":_canonical(next).sha256_text()}
	var error: Error = store._bank_write_json(path + ".tmp", envelope)
	if error != OK: return {"status":"io_error"}
	current = load_ledger()
	if current.status != "ok" or int(current.data.revision) != revision: return {"status":"stale"}
	if store._replace_file(path + ".tmp", path) != OK: return {"status":"io_error"}
	_prune()
	return {"status":"ok","data":next}
func _prune() -> void:
	# Each generation is a complete ledger, including every receipt. Keeping eight
	# limits disk use; a corrupt newest generation is still never rolled back.
	var committed: Array[String] = []
	for name in DirAccess.get_files_at(store.bank_directory):
		if name.ends_with(".json") and name.length()>=18 and name.substr(12,1)=="-" and name.left(12).is_valid_int(): committed.append(name)
	committed.sort()
	for index in maxi(0,committed.size()-8): store._remove_file(store.bank_directory.path_join(committed[index]))
func recover() -> String:
	var loaded := load_ledger()
	if loaded.status != "ok": return loaded.status
	if loaded.data.pending.is_empty(): return "ok"
	var ledger: Dictionary = loaded.data
	var p: Dictionary = ledger.pending
	var current: Dictionary = store.load_slot(p.target)
	if current.status == "ok" and State.campaign_key(current.data) == State.campaign_key(p.snapshot) and p.operation in current.data.player.completedOperations:
		pass
	else:
		var result: Dictionary = store.copy_to_slot(p.snapshot, p.target, int(p.expected))
		if result.status != "ok": return "bank_pending"
	ledger.pending = {}
	return "ok" if _commit(ledger, int(ledger.revision)).status == "ok" else "bank_pending"
func reconcile(snapshot: Dictionary, ledger: Dictionary) -> Dictionary:
	var next := snapshot.duplicate(true)
	var campaign := State.campaign_key(snapshot)
	if not next.has("campaignId"): next.campaignId = campaign
	var partners: Array = []
	var ids := {}
	for partner in next.player.partners:
		if ledger.entries.has(partner.id) and ledger.entries[partner.id].owner != campaign: continue
		partners.append(partner); ids[partner.id] = true
	for id: String in ledger.entries:
		if ledger.entries[id].owner == campaign and ledger.entries[id].get("inject",true) and not ids.has(id): partners.append(ledger.entries[id].partner.duplicate(true)); ids[id] = true
	next.player.partners = partners
	var queue: Array=[]
	for reward in next.player.get("pendingPartners",[]):
		if not ledger.entries.has(reward.id):queue.append(reward)
	for entry in ledger.entries.values():
		if entry.owner=="pending" and entry.get("campaignId")==campaign:queue.append(Rewards.item(entry))
	if not queue.is_empty() or next.player.has("pendingPartners"):next.player.pendingPartners=queue
	if not ids.has(next.player.get("equippedPartnerId","")):
		if partners.is_empty(): next.player.erase("equippedPartnerId")
		else: next.player.equippedPartnerId = partners[0].id
	for operation: String in ledger.operations:
		if ledger.operations[operation].campaignId == campaign and not operation in next.player.completedOperations: next.player.completedOperations.append(operation)
	return next
func global_partners(ledger: Dictionary) -> Array:
	var result: Array = []
	for entry in ledger.entries.values():
		if entry.owner == "global": result.append(entry.partner.duplicate(true))
	return result
func restriction(snapshot: Dictionary, id: String) -> String:
	if snapshot.get("checkpoint",{}).get("kind") != "world": return "bank_unsafe"
	var player: Dictionary = snapshot.player
	if id == player.get("equippedPartnerId",""): return "bank_active"
	if player.partners.size() <= 1: return "bank_last"
	for partner in player.partners:
		if partner.id != id: continue
		if story_bound(partner): return "bank_story"
		if player.partners.filter(func(candidate): return not story_bound(candidate)).size() <= 1: return "bank_last"
		if int(player.get("journey",{}).get("lesson",0)) < 5: return "bank_story"
		return "ok"
	return "bank_missing"
func story_bound(partner: Dictionary) -> bool:
	return partner.get("borrowed",false) or partner.get("loaned",false) or partner.get("temporary",false) or partner.get("storyBound",false) or str(partner.get("modelId","")).begins_with("retalho") or str(partner.get("modelId","")).begins_with("platyx") or partner.get("origin","") == "mount-quest-reward-v1"
func transfer(snapshot: Dictionary, id: String, direction: String, operation: String, target: String, revision: int) -> Dictionary:
	if direction not in ["deposit","withdraw","discard"] or not operation.begins_with("bank-transfer-") or operation.length()>128: return {"status":"invalid_operation"}
	if snapshot.get("checkpoint",{}).get("kind") != "world": return {"status":"bank_unsafe"}
	var loaded := load_ledger()
	if loaded.status != "ok": return loaded
	var ledger: Dictionary = loaded.data
	if not ledger.pending.is_empty(): return {"status":"bank_pending"}
	var campaign := State.campaign_key(snapshot)
	var request := {"id":id,"direction":direction,"campaignId":campaign}
	if ledger.operations.has(operation): return {"status":"already_applied" if ledger.operations[operation] == request else "invalid_operation"}
	var next := reconcile(snapshot, ledger)
	var partner: Dictionary = {}
	if direction == "deposit":
		var blocked := restriction(next, id)
		if blocked != "ok": return {"status":blocked}
		if global_partners(ledger).size() >= GLOBAL_LIMIT: return {"status":"bank_global_full"}
		for candidate in next.player.partners:
			if candidate.id == id: partner = candidate.duplicate(true)
	else:
		if direction == "withdraw" and next.player.partners.size() >= CAMPAIGN_LIMIT: return {"status":"bank_campaign_full"}
		if not ledger.entries.has(id) or ledger.entries[id].owner != "global": return {"status":"bank_missing"}
		partner = ledger.entries[id].partner.duplicate(true)
	# Register remaining partners too, so an older save cannot drop companions
	# acquired before this transaction when it rolls back the campaign snapshot.
	for candidate in next.player.partners:
		if not story_bound(candidate):
			var record: Dictionary=ledger.entries.get(candidate.id,{})
			record.owner=campaign;record.partner=candidate.duplicate(true);ledger.entries[candidate.id]=record
	if direction == "deposit":
		next.player.partners = next.player.partners.filter(func(candidate): return candidate.id != id)
	elif direction == "withdraw": next.player.partners.append(partner)
	var moved: Dictionary=ledger.entries.get(id,{})
	moved.owner="global" if direction == "deposit" else "released" if direction == "discard" else campaign
	moved.partner=partner;ledger.entries[id]=moved
	next.player.completedOperations.append(operation)
	ledger.operations[operation] = request
	ledger.pending = {"snapshot":next,"target":target,"expected":revision,"operation":operation}
	var committed := _commit(ledger, int(ledger.revision))
	if committed.status != "ok": return committed
	return {"status":"ok" if store._recover_archives() == "ok" else "bank_pending"}
