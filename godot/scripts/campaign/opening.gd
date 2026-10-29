extends RefCounted
## Port of player_opening's local narrative transitions (017_kael_opening.sql).
const BIRTH := "story-kael-birthday-v1"
const Progression = preload("res://scripts/campaign/progression.gd")
var session: Node

func _init(local_session: Node) -> void:
	session = local_session

func finish_broadcast(expected: int) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	if saved.is_empty() or saved.checkpoint.get("kind")!="opening" or int(saved.checkpoint.step)!=expected or expected not in [0,1]:
		return {"status":"wrong_step"}
	# Both broadcast lines have no rewards; persist the film-to-room handoff once.
	return session.commit_operation("opening-broadcast-%d" % expected,{"kind":"opening","step":2},saved.player)

func advance(expected: int) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.is_empty() or saved.checkpoint.get("kind") != "opening" or saved.checkpoint.step != expected or expected == 10 or expected >= 14:
		return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	if expected == 6:
		player.flags.ancientTailReceived = true
	if expected == 8:
		player.flags.ancientTailAttached = true
	return session.commit_operation("opening-step-%d" % expected, {"kind": "opening", "step": expected + 1}, player)

func name_partner(value: String) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.is_empty() or saved.checkpoint.get("kind") != "opening" or saved.checkpoint.step != 10 or not saved.player.flags.get("ancientTailAttached", false):
		return {"status": "wrong_step"}
	var personal_name := value.strip_edges()
	if personal_name.is_empty():
		personal_name = "Rabbito"
	if personal_name.length() > 24:
		return {"status": "invalid_name"}
	for index in personal_name.length():
		if personal_name.unicode_at(index) < 32 or personal_name.unicode_at(index) == 127:
			return {"status": "invalid_name"}
	var player: Dictionary = saved.player
	# One birth UUID is generated only when committing the named partner.
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var raw := bytes.hex_encode()
	var uuid := "%s-%s-%s-%s-%s" % [raw.substr(0, 8), raw.substr(8, 4), raw.substr(12, 4), raw.substr(16, 4), raw.substr(20)]
	player.partners.append({"id": uuid, "modelId": "rabbito", "personalName": personal_name,
		"xp": 0, "craftBonus": 0, "condition": {"line": 100, "structure": 100},
		"origin": BIRTH, "certification": "unverified"})
	player.equippedPartnerId = uuid
	Progression.acquire(player, "rabbito")
	return session.commit_operation(BIRTH, {"kind": "opening", "step": 11}, player)
