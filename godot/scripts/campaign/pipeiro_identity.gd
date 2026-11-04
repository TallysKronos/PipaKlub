extends RefCounted
## Documents are issued with the training receipt; district emblems are separate from wild guardians.
const SLOT_COUNT := 12

static func eligible(player: Dictionary) -> bool:
	return int(player.get("journey", {}).get("lesson", 0)) >= 5

static func issued(player: Dictionary) -> bool:
	return player.has("pipeiroIdentity")

static func issue_into(player: Dictionary) -> void:
	if issued(player): return
	player.pipeiroIdentity = {"id":Crypto.new().generate_random_bytes(5).hex_encode().to_upper(), "issuedAt":int(Time.get_unix_time_from_system())}
	player.inventory["carteira-pipeiro"] = 1
	player.inventory["porta-emblemas"] = 1

static func ensure_legacy(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.is_empty() or not eligible(saved.player) or issued(saved.player): return {"status":"already_applied"}
	if saved.checkpoint.get("kind","") not in ["starter","workshop","world","encounter"]: return {"status":"already_applied"}
	issue_into(saved.player)
	# Existing journeys keep their current scene, including suspended battles.
	# The handoff presentation belongs to newly completed training only.
	saved.player.flags.pipeiroDocumentsSeen = true
	return session.commit_operation("pipeiro-documents-v1", saved.checkpoint, saved.player)

static func pending(saved: Dictionary) -> bool:
	return not saved.is_empty() and issued(saved.player) and not saved.player.flags.get("pipeiroDocumentsSeen", false)

static func acknowledge(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.is_empty() or not issued(saved.player): return {"status":"wrong_step"}
	saved.player.flags.pipeiroDocumentsSeen = true
	return session.commit_operation("pipeiro-documents-seen-v1", saved.checkpoint, saved.player)

static func tamer_level(xp: int) -> int:
	var level := 1
	while level < 100 and xp >= 20 * level + 3 * level * level: level += 1
	return level

static func slot_id(index: int) -> String:
	return "bairro-%02d" % (index + 1)

static func valid_identity(value: Variant) -> bool:
	if not value is Dictionary or not value.get("id") is String or value.id.length() != 10: return false
	for character in value.id:
		if character not in "0123456789ABCDEF": return false
	return valid_date(value.get("issuedAt"))

static func valid_date(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= 0 and value <= 9007199254740991

static func valid_emblems(value: Variant) -> bool:
	if not value is Dictionary or value.size() > SLOT_COUNT: return false
	var bosses := {}
	for key in value:
		var allowed := false
		for index in SLOT_COUNT:
			if key == slot_id(index): allowed = true
		if not allowed or not value[key] is Dictionary: return false
		var entry: Dictionary = value[key]
		if not entry.get("bossId") is String or entry.bossId.is_empty() or entry.bossId.length() > 64: return false
		if bosses.has(entry.bossId): return false
		bosses[entry.bossId] = true
		if not entry.get("name") is String or entry.name.is_empty() or entry.name.length() > 64: return false
		if not valid_date(entry.get("earnedAt")): return false
		for field in ["bossName","districtName","description"]:
			if entry.has(field) and (not entry[field] is String or entry[field].length()>(320 if field=="description" else 64)):return false
	return true

static func award_district(player: Dictionary, slot: int, boss_id: String, emblem_name: String, details:Dictionary={}) -> bool:
	# Called by a district boss settlement inside its existing atomic victory commit.
	# Mikka is the first district champion. Training and Lacertubo do not call this.
	if not issued(player) or slot < 0 or slot >= SLOT_COUNT: return false
	var emblems: Dictionary = player.get("districtEmblems", {}).duplicate(true)
	var key := slot_id(slot)
	if emblems.has(key): return false
	for entry in emblems.values():
		if entry.bossId == boss_id: return false
	emblems[key] = {"bossId":boss_id, "name":emblem_name, "earnedAt":int(Time.get_unix_time_from_system())}
	for field in ["bossName","districtName","description"]:
		if details.has(field):emblems[key][field]=details[field]
	if not valid_emblems(emblems): return false
	player.districtEmblems = emblems
	return true
