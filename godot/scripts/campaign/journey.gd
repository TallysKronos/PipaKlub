extends RefCounted
## Local equivalents of 015, 026, 027 and 030. No authenticated account is faked.
const State = preload("res://scripts/campaign/state.gd")
const Workshop = preload("res://scripts/campaign/workshop_model.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const STARTERS := {"basica": "Carcará", "mata": "Mata verde", "azulao": "Azulão", "raio": "Raio de sol"}
const CATALOG := {"basica": "Carcará", "mata": "Mata verde", "azulao": "Azulão", "raio": "Raio de sol", "lacertubo": "Lacertubo"}
var session: Node

func _init(local_session: Node) -> void:
	session = local_session

func enter_world(scene: String, position: Vector2, space: String = "") -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.is_empty() or saved.player.partners.is_empty():
		return {"status": "wrong_step"}
	if scene=="quintal":
		var point: Dictionary=preload("res://scripts/campaign/neighborhood_checkpoint.gd").make(position,saved.player)
		return session.checkpoint(point,saved.player)
	if preload("res://scripts/campaign/park_checkpoint.gd").MAPS.has(scene):
		return session.checkpoint(preload("res://scripts/campaign/park_checkpoint.gd").make(scene,position,space),saved.player)
	return session.checkpoint({"kind": "world", "scene": scene, "position": [position.x, position.y]}, saved.player)

func practice() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "professor-home":
		return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	if not player.has("journey"):
		player.journey = {"lesson": 0, "phase": "practice"}
	if player.journey.lesson >= 5:
		return session.checkpoint({"kind": "starter"}, player)
	return session.checkpoint({"kind": "practice", "lesson": player.journey.lesson}, player)

func lesson_completed(index: int) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("kind") != "practice" or saved.checkpoint.lesson != index:
		return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	player.journey.lesson = index + 1
	var point := {"kind": "practice", "lesson": index + 1} if index < 4 else {"kind": "starter"}
	if index == 4:
		player.journey.phase = "choose"
	return session.commit_operation("first-flight-lesson-%d" % index, point, player)

func choose(model_id: String) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if not STARTERS.has(model_id) or saved.checkpoint.get("kind") != "starter" or saved.player.journey.lesson != 5:
		return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	if player.has("starter"):
		return {"status": "wrong_step"} if player.starter.modelId != model_id else start_workshop()
	player.starter = {"modelId": model_id, "tailId": State.new_id(), "status": "ready", "completed": false}
	var result: Dictionary = session.commit_operation("first-flight-starter-v1", {"kind": "starter"}, player)
	if result.status == "ok":
		return start_workshop()
	return result

func start_workshop() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	if not player.has("starter") or player.starter.completed or player.starter.status != "ready":
		return {"status": "wrong_step"}
	var bytes := Crypto.new().generate_random_bytes(8)
	var seed_value := bytes.decode_u32(0)
	var model := Workshop.new("comum", seed_value)
	player.workshop = {"id": State.new_id(), "modelId": player.starter.modelId, "seed": seed_value,
		"variant": bytes.decode_u32(4) % 459 == 0, "status": "building", "state": model.run}
	player.starter.status = "used"
	return session.checkpoint({"kind": "workshop"}, player)

func save_workshop(state: Dictionary) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.kind != "workshop" or not saved.player.has("workshop"):
		return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	player.workshop.state = state.duplicate(true)
	return session.checkpoint({"kind": "workshop"}, player)

func start_summon(model_id: String) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "professor-home" or not CATALOG.has(model_id) or saved.player.get("journey", {}).get("phase") != "complete": return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var item := "rabiola-" + model_id
	if player.inventory.get(item, 0) < 1: return {"status": "wrong_step"}
	var bytes := Crypto.new().generate_random_bytes(8)
	var seed_value := bytes.decode_u32(0)
	var model := Workshop.new("raro" if model_id == "lacertubo" else "comum", seed_value)
	player.inventory[item] -= 1
	if player.inventory[item] == 0: player.inventory.erase(item)
	player.workshop = {"id": State.new_id(), "modelId": model_id, "seed": seed_value, "source": "inventory", "variant": bytes.decode_u32(4) % 459 == 0, "status": "building", "state": model.run}
	return session.checkpoint({"kind": "workshop"}, player)

func restore_inventory_tail(model_id: String) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("scene") != "professor-home" or not CATALOG.has(model_id): return {"status": "wrong_step"}
	var item := "damaged-rabiola-" + model_id
	if saved.player.inventory.get(item, 0) < 1: return {"status": "wrong_step"}
	saved.player.inventory[item] -= 1
	if saved.player.inventory[item] == 0: saved.player.inventory.erase(item)
	var restored := "rabiola-" + model_id
	saved.player.inventory[restored] = saved.player.inventory.get(restored, 0) + 1
	return session.checkpoint(saved.checkpoint, saved.player)

func finish_workshop() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var player: Dictionary = saved.player
	if saved.checkpoint.kind != "workshop" or player.workshop.state.stage != 5:
		return {"status": "wrong_step"}
	var job: Dictionary = player.workshop
	var outcome: Dictionary = job.state.outcome
	var inventory_job: bool = job.get("source") == "inventory"
	if outcome.get("type") == "broken":
		if inventory_job:
			var item: String = "damaged-rabiola-" + job.modelId
			player.inventory[item] = player.inventory.get(item, 0) + 1
			job.status = "failed"
			return session.commit_operation("workshop-failed-" + job.id, {"kind": "world", "scene": "professor-home", "position": [1440, 672]}, player)
		player.starter.status = "damaged"
		job.status = "failed"
		return session.commit_operation("workshop-failed-" + job.id, {"kind": "starter"}, player)
	if outcome.get("type") != "born":
		return {"status": "wrong_step"}
	var id := State.new_id()
	player.partners.append({"id": id, "modelId": job.modelId, "personalName": CATALOG[job.modelId], "xp": 0,
		"craftBonus": outcome.craftBonus.totalPercent, "craftDetails": outcome.craftBonus,
		"condition": {"line": 100, "structure": 100}, "variant": job.variant,
		"origin": "workshop-" + job.id if inventory_job else "first-flight-starter-v1", "certification": "unverified"})
	player.equippedPartnerId = id
	Progression.acquire(player, job.modelId)
	if not inventory_job: player.starter.completed = true
	job.status = "completed"
	player.journey.phase = "complete"
	return session.commit_operation("workshop-birth-" + job.id, {"kind": "world", "scene": "professor-home", "position": [1440, 672]}, player)

func cancel_workshop() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.kind != "workshop" or saved.player.workshop.status != "building" or saved.player.workshop.state.stage >= 5:
		return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	if player.workshop.get("source") == "inventory":
		var job: Dictionary = player.workshop
		var item: String = "rabiola-" + job.modelId
		player.inventory[item] = player.inventory.get(item, 0) + 1
		job.status = "cancelled"
		job.state = {}
		return session.commit_operation("workshop-cancelled-" + job.id, {"kind": "world", "scene": "professor-home", "position": [1440, 672]}, player)
	player.workshop.status = "cancelled"
	player.workshop.state = {}
	player.starter.status = "ready"
	return session.checkpoint({"kind": "starter"}, player)

func restore_tail() -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.kind != "starter" or saved.player.get("starter", {}).get("status") != "damaged":
		return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	player.starter.status = "ready"
	return session.checkpoint({"kind": "starter"}, player)
