extends RefCounted
## Plain campaign data. Scene nodes and online credentials never enter a slot.
const SCHEMA_VERSION := 1
const CONTENT_VERSION := "demo-1"
const RULES_VERSION := "demo-1"

static func fresh(slot_id: String) -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION, "contentVersion": CONTENT_VERSION,
		"rulesVersion": RULES_VERSION, "slotId": slot_id, "revision": 0,
		"checkpoint": {"kind": "opening", "step": 0},
		"player": {"name": "Kael", "avatar": {}, "coins": 0,
			"inventory": {}, "partners": [], "flags": {}, "openedChests": [],
			"completedOperations": []}
	}

static func valid_slot(slot_id: String) -> bool:
	return slot_id in ["slot-1", "slot-2", "slot-3"]

static func new_id() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var raw := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [raw.substr(0, 8), raw.substr(8, 4), raw.substr(12, 4), raw.substr(16, 4), raw.substr(20)]

static func whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= 0 and value <= 9007199254740991

static func inspect(value: Variant, slot_id: String) -> String:
	if not value is Dictionary:
		return "invalid"
	if not whole(value.get("schemaVersion")):
		return "invalid"
	if value.schemaVersion > SCHEMA_VERSION:
		return "future"
	# No legacy campaign schema has shipped. Prototype saves are not campaign saves.
	if value.schemaVersion != SCHEMA_VERSION:
		return "unsupported"
	if value.get("contentVersion") != CONTENT_VERSION or value.get("rulesVersion") != RULES_VERSION:
		return "unsupported"
	if value.get("slotId") != slot_id or not valid_slot(slot_id) or not whole(value.get("revision")):
		return "invalid"
	if not value.get("checkpoint") is Dictionary or not value.get("player") is Dictionary:
		return "invalid"
	var checkpoint: Dictionary = value.checkpoint
	var kind: String = str(checkpoint.get("kind", ""))
	if kind not in ["opening", "world", "practice", "starter", "workshop", "encounter"]:
		return "invalid"
	if kind == "opening" and (not whole(checkpoint.get("step")) or checkpoint.step > 14):
		return "invalid"
	if kind == "practice" and (not whole(checkpoint.get("lesson")) or checkpoint.lesson > 4):
		return "invalid"
	if kind == "world":
		if checkpoint.get("scene") not in ["quintal", "professor-home", "park-trail", "park-clearing", "park-veredas", "morro", "morro-area-2", "morro-area-3", "morro-area-4", "morro-area-5"] or not checkpoint.get("position") is Array or checkpoint.position.size() != 2:
			return "invalid"
		for coordinate in checkpoint.position:
			if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)) or absf(coordinate) > 4096:
				return "invalid"
	var player: Dictionary = value.player
	if not player.get("name") is String or player.name.length() > 64 or not whole(player.get("coins")):
		return "invalid"
	for key in ["avatar", "inventory", "flags"]:
		if not player.get(key) is Dictionary:
			return "invalid"
	for key in ["partners", "openedChests", "completedOperations"]:
		if not player.get(key) is Array:
			return "invalid"
	for key in player.inventory:
		if not (key is String or key is StringName) or not whole(player.inventory[key]):
			return "invalid"
	for key in player.flags:
		if not (key is String or key is StringName) or not player.flags[key] is bool:
			return "invalid"
	for key in ["openedChests", "completedOperations"]:
		var seen := {}
		for entry in player[key]:
			if not entry is String or entry.is_empty() or seen.has(entry):
				return "invalid"
			seen[entry] = true
	# Structural validation protects offline readers; it is not certification.
	var partner_ids := {}
	for partner in player.partners:
		if not partner is Dictionary or not partner.get("id") is String or partner.id.is_empty() or partner_ids.has(partner.id) or not partner.get("modelId") is String:
			return "invalid"
		partner_ids[partner.id] = true
		if not whole(partner.get("xp", 0)) or not number(partner.get("craftBonus", 0)) or partner.get("craftBonus", 0) < 0 or partner.get("craftBonus", 0) > 12: return "invalid"
		if partner.has("condition"):
			if not partner.condition is Dictionary: return "invalid"
			for field in ["line", "structure"]:
				if not number(partner.condition.get(field)) or partner.condition[field] < 0 or partner.condition[field] > 100: return "invalid"
	if player.has("equippedPartnerId") and not partner_ids.has(player.equippedPartnerId): return "invalid"
	if not whole(player.get("tamerXp", 0)) or player.get("tamerXp", 0) > 31383: return "invalid"
	for field in ["sightings", "acquiredModels"]:
		if player.has(field):
			if not player[field] is Array: return "invalid"
			for entry in player[field]:
				if not entry is String: return "invalid"
	if player.has("morro") and not valid_morro(player.morro): return "invalid"
	if player.has("wildDrop"):
		if not player.wildDrop is Dictionary or not player.wildDrop.get("intro") is bool or not whole(player.wildDrop.get("misses")): return "invalid"
	if player.has("encounterGraceUntil"):
		if not (player.encounterGraceUntil is int or player.encounterGraceUntil is float) or not is_finite(player.encounterGraceUntil) or player.encounterGraceUntil < 0: return "invalid"
	if kind == "encounter" and not valid_encounter(player.get("encounter")):
		return "invalid"
	if kind in ["practice", "starter", "workshop"]:
		if not player.get("journey") is Dictionary or not whole(player.journey.get("lesson")) or player.journey.lesson > 5:
			return "invalid"
	if kind == "workshop":
		if not player.get("workshop") is Dictionary:
			return "invalid"
		var job: Dictionary = player.workshop
		if not job.get("id") is String or job.get("modelId") not in ["basica", "mata", "azulao", "raio", "lacertubo"] or not job.get("state") is Dictionary:
			return "invalid"
		var state: Dictionary = job.state
		if not whole(job.get("seed")) or job.seed != state.get("seed") or not job.get("variant") is bool or job.get("status") != "building": return "invalid"
		if not whole(state.get("stage")) or state.stage > 5 or state.get("kind") not in ["comum", "incomum", "raro"]:
			return "invalid"
		for field in ["step", "materials", "outcome"]:
			if not state.get(field) is Dictionary:
				return "invalid"
		for field in ["grades", "errors", "elapsed", "active", "log"]:
			if not state.get(field) is Array:
				return "invalid"
		if state.errors.size() != 5 or state.elapsed.size() != 5 or state.active.size() != 5:
			return "invalid"
		if not valid_workshop(state): return "invalid"
	return "ok"

static func valid_workshop(state: Dictionary) -> bool:
	if not whole(state.get("seed")) or state.seed > 4294967295 or not number(state.get("clock")) or state.clock < 0 or not state.get("artesao") is bool or not state.get("blocked") is String: return false
	for key in ["linha", "folha"]:
		if not whole(state.materials.get(key)): return false
	for value in state.grades:
		if not number(value) or value < 0 or value > 1: return false
	for i in 5:
		if not whole(state.errors[i]) or not number(state.elapsed[i]) or state.elapsed[i] < 0 or not state.active[i] is bool: return false
	var step: Dictionary = state.step
	var rods: int = {"comum": 4, "incomum": 5, "raro": 6}[state.kind]
	match int(state.stage):
		0, 1:
			var field := "placed" if state.stage == 0 else "tied"
			if not step.get(field) is Array or not step.get("scores") is Array or step[field].size() != step.scores.size(): return false
			for value in step[field]:
				if not whole(value) or value >= rods: return false
			for value in step.scores:
				if not number(value) or value < 0 or value > 1: return false
			if state.stage == 1:
				if not number(step.get("holding")) or step.holding < -1 or step.holding >= rods or floor(step.holding) != step.holding or not number(step.get("fill")) or not step.get("windows") is Array or step.windows.size() != rods: return false
				for window in step.windows:
					if not window is Array or window.size() != 2 or not number(window[0]) or not number(window[1]) or window[0] < 0 or window[0] >= window[1] or window[1] > 1: return false
		2:
			if not step.get("covered") is Array or not whole(step.get("samples")) or step.samples == 0: return false
			for value in step.covered:
				if not whole(value) or value >= step.samples: return false
			for key in ["tear", "sumD", "nD", "time"]:
				if not number(step.get(key)) or step[key] < 0: return false
		3:
			for key in ["t", "theta", "omega", "inZone"]:
				if not number(step.get(key)): return false
			if not step.get("gusts") is Array: return false
			for gust in step.gusts:
				if not gust is Dictionary or not number(gust.get("t")) or not number(gust.get("dir")) or absf(gust.dir) != 1 or not number(gust.get("power")): return false
		4, 5:
			if not number(step.get("fill")) or not step.get("holding") is bool: return false
	if state.stage == 5:
		if state.outcome.get("type") not in ["born", "broken"]: return false
		if state.outcome.type == "born":
			if not state.outcome.get("craftBonus") is Dictionary: return false
			var bonus: Dictionary = state.outcome.craftBonus
			if not number(bonus.get("totalPercent")) or bonus.totalPercent < 0 or bonus.totalPercent > 12: return false
	return true

static func valid_encounter(value: Variant) -> bool:
	if not value is Dictionary or not value.get("id") is String or value.get("kind") not in ["lacertubo", "wild", "morro"] or not value.get("state") is Dictionary: return false
	if not value.get("returnPoint") is Array or value.returnPoint.size() != 2: return false
	for point in value.returnPoint:
		if not number(point) or point < 0 or point > 1536: return false
	var state: Dictionary = value.state
	if value.kind == "wild":
		if not number(value.get("dropRoll")) or value.dropRoll < 0 or value.dropRoll >= 1 or state.get("enemyModelId") not in ["basica", "mata", "raio"] or not whole(state.get("enemyLevel")) or state.enemyLevel < 1 or state.enemyLevel > 9: return false
	if state.get("outcome") not in ["", "won", "lost", "fled"] or not state.get("partnerId") is String or not state.get("modelId") is String: return false
	for field in ["time", "intro", "duration"]:
		if not number(state.get(field)) or state[field] < 0: return false
	if value.kind == "morro":
		if not valid_morro_state(state) or value.get("scene") != {"morro-1": "morro", "morro-2": "morro-area-2", "morro-3": "morro-area-3", "morro-4": "morro-area-4", "morro-5": "morro-area-5"}.get(state.get("trailStage")): return false
	var actors: Array = state.actors if value.kind == "morro" else [state.get("p"), state.get("q")]
	for actor_value in actors:
		if not actor_value is Dictionary: return false
		var actor: Dictionary = actor_value
		for key in ["x", "y", "anchor", "hp", "hull", "energy", "vx", "vy", "attackCooldown", "skillCooldown", "skillTime", "evade", "dodgeCooldown", "guardTime", "guardCooldown", "counter", "hits", "score", "skillCount", "dodges", "lineCount", "blocks", "lineCooldown", "signatureCooldown", "signatureWindup", "phase", "recovery", "charge", "telegraph", "botFocus", "color"]:
			if not number(actor.get(key)): return false
		for key in ["guardHeld", "lineHeld", "signatureHeld", "boss", "strike", "maneuver"]:
			if not actor.get(key) is bool: return false
		if actor.color < 0 or actor.color > 3 or floor(actor.color) != actor.color: return false
		if not actor.get("stats") is Dictionary or not actor.get("lineMove") is Dictionary: return false
		for key in ["line", "energy", "attack", "defense", "speed", "regen"]:
			if not number(actor.stats.get(key)) or actor.stats[key] <= 0: return false
		if not vector_data(actor.get("signatureAim")): return false
		if actor.has("dodgeDir") and not vector_data(actor.dodgeDir): return false
		if actor.evade > 0 and not actor.has("dodgeDir"): return false
		if not actor.lineMove.is_empty():
			if not number(actor.lineMove.get("elapsed")) or not vector_data(actor.lineMove.get("origin")) or not actor.lineMove.get("hit") is bool: return false
	return true

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(value) < 1e9

static func vector_data(value: Variant) -> bool:
	return value is Dictionary and value.size() == 1 and value.get("vector") is Array and value.vector.size() == 2 and number(value.vector[0]) and number(value.vector[1])

static func valid_morro(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["coins", "mastery", "wins", "losses"]:
		if not whole(value.get(key)): return false
	if value.mastery > 8: return false
	for key in ["stars", "fails"]:
		if not value.get(key) is Dictionary: return false
		for id in value[key]:
			if id not in ["morro-1", "morro-2", "morro-3", "morro-4", "morro-5"] or not whole(value[key][id]) or value[key][id] < 1 or value[key][id] > (3 if key == "stars" else 100): return false
	if not value.get("items") is Array or value.items.size() > 1: return false
	return value.items.is_empty() or value.items == ["rabiola-raio-de-sol"]

static func valid_morro_state(state: Dictionary) -> bool:
	var id: String = str(state.get("trailStage", ""))
	if id not in ["morro-1", "morro-2", "morro-3", "morro-4", "morro-5"]: return false
	if not state.get("actors") is Array or state.actors.size() != (3 if id == "morro-3" else 2): return false
	for key in ["roundNumber", "roundsToWin", "aiLevel"]:
		if not whole(state.get(key)) or state[key] < 1: return false
	if state.roundsToWin != (3 if id == "morro-5" else 2) or state.aiLevel > 10: return false
	if not number(state.get("intermission")) or state.intermission < 0 or state.intermission > 3.2 or not state.get("roundMessage") is String: return false
	for index in state.actors.size():
		var actor: Variant = state.actors[index]
		if not actor is Dictionary or not actor.get("name") is String or not whole(actor.get("rounds")) or not actor.get("out") is bool or actor.get("slot") != index or not actor.get("style") is String or not number(actor.get("target")) or not number(actor.get("threatTime")): return false
	return state.get("p") == state.actors[0] and state.get("q") == state.actors[1]
