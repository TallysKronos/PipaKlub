extends RefCounted
## Demo trail rules mirrored from src/trails.js. Not an online certification.
const IDS := ["morro-1", "morro-2", "morro-3", "morro-4", "morro-5"]
const DROP := "rabiola-raio-de-sol"

static var _content: Dictionary = {}

static func content() -> Dictionary:
	if _content.is_empty(): _content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/morro/trails.json"))
	return _content

static func stage(id: String) -> Dictionary:
	for entry in content().stages:
		if entry.id == id: return entry.duplicate(true)
	return {}

static func defaults() -> Dictionary:
	return {"coins": 0, "stars": {}, "mastery": 0, "wins": 0, "losses": 0, "fails": {}, "items": []}

static func unlocked(progress: Dictionary, id: String) -> bool:
	var index := IDS.find(id)
	return index >= 0 and (index == 0 or progress.stars.has(IDS[index - 1]))

static func ai_level(entry: Dictionary, progress: Dictionary) -> int:
	var bonus := mini(1 if entry.foes.size() > 1 else 8, int(progress.mastery / 2))
	var relief := 1 if progress.fails.get(entry.id, 0) >= 3 else 0
	return clampi(int(entry.level) + bonus - relief, 1, 10)

static func settle(progress: Dictionary, id: String, won: bool, rounds_lost: int = 0) -> Dictionary:
	var entry := stage(id)
	if entry.is_empty(): return {"progress": progress.duplicate(true), "coins": 0, "stars": 0, "firstClear": false}
	progress = progress.duplicate(true)
	for key in progress.fails: progress.fails[key] = mini(int(progress.fails[key]), 99)
	var next := progress.duplicate(true)
	var stars := clampi(3 - rounds_lost, 1, 3) if won else 0
	var first_clear: bool = won and not progress.stars.has(id)
	var coins := int(floor(float(entry.coins) * (1.0 + (stars - 1) * 0.25) + 0.5)) + (int(entry.coins) if first_clear else 0) if won else 0
	var drop: Variant = entry.get("drop") if won and not entry.get("drop", "") in progress.items else null
	if drop != null: next.items.append(drop)
	next.coins += coins
	if won:
		next.wins += 1
		next.stars[id] = maxi(int(progress.stars.get(id, 0)), stars)
		next.mastery = clampi(int(progress.mastery) + (2 if stars == 3 else 1), 0, 8)
		next.fails.erase(id)
	else:
		next.losses += 1
		next.fails[id] = int(progress.fails.get(id, 0)) + 1
		next.mastery = clampi(int(progress.mastery) - (2 if next.fails[id] >= 2 else 1), 0, 8)
	return {"progress": next, "coins": coins, "stars": stars, "firstClear": first_clear, "drop": drop, "fails": next.fails.get(id, 0), "levelBefore": ai_level(entry, progress), "levelAfter": ai_level(entry, next)}

