extends RefCounted
const Controls = preload("res://scripts/campaign/controls.gd")
## Reads presentation transitions; never writes a combat/workshop model.
var audio: Node
var watched: Dictionary = {}
var property_cache: Dictionary = {}

func _init(director: Node) -> void:
	audio = director

func clear() -> void:
	watched.clear()

func has_paused_scene() -> bool:
	for record: Dictionary in watched.values():
		if record.kind == "world": continue
		var view: Node = record.ref.get_ref()
		if not is_instance_valid(view) or view.is_queued_for_deletion() or not view.is_inside_tree(): continue
		if _has(view, "paused") and view.paused: return true
		if _has(view, "blocked") and view.blocked: return true
		if _has(view, "storage_blocked") and view.storage_blocked: return true
	return false

func _has(node: Object, key: String) -> bool:
	var script: Script = node.get_script()
	var path: String = script.resource_path if script != null else node.get_class()
	if not property_cache.has(path):
		var names: Dictionary = {}
		for property: Dictionary in node.get_property_list(): names[str(property.name)] = true
		property_cache[path] = names
	return property_cache[path].has(key)

func bind(node: Node) -> void:
	var script: Script = node.get_script()
	if script == null: return
	var file := script.resource_path.get_file()
	var kind := ""
	if file in ["encounter_view.gd", "morro_battle_view.gd", "first_flight_view.gd"]: kind = "battle"
	elif file == "workshop_view.gd": kind = "workshop"
	elif file in ["room_view.gd", "park_view.gd", "park_route_view.gd", "morro_view.gd", "neighborhood_view.gd"]: kind = "world"
	elif file == "hud_dialogue.gd":
		audio.play_event("dialogue.open")
		return
	elif file == "fruit_tree.gd":
		if not node.has_meta("soul_fruit_audio"):
			node.set_meta("soul_fruit_audio", true)
			node.fruit_landed.connect(func(_species: String, _point: Vector2): audio.play_event("world.fruit_land"))
		return
	if kind.is_empty() or watched.has(node.get_instance_id()): return
	var record := {"ref": weakref(node), "kind": kind, "old": {}, "distance": 0.0, "mother_distance": 0.0, "file": file}
	watched[node.get_instance_id()] = record
	if kind == "world":
		if file != "room_view.gd": audio.start_ambience("ambience.leaves" if file in ["park_view.gd", "park_route_view.gd"] else "ambience.wind")
		return
	var model: RefCounted = node.model
	if model == null: return
	if kind == "battle":
		if model.has_signal("damage_applied"):
			model.damage_applied.connect(_damage)
			model.combat_feedback.connect(func(event: Dictionary): audio.play_event("battle.block" if event.kind == "block" else "battle.evade"))
		if _has(model, "intro") and model.intro > 0:
			audio.play_event("battle.boss_intro" if model.q.get("boss", false) else "battle.encounter")
		_capture_battle(node, record, true)
	else: record.old = _workshop_state(model.run)

func _damage(event: Dictionary) -> void:
	audio.play_event("battle.hull_hit" if event.get("body", false) else "battle.line_hit")
	if event.get("critical", false): audio.play_event("battle.critical")
	if event.get("cut_line", false): audio.play_event("battle.line_snap")
	if event.get("broke_hull", false): audio.play_event("battle.hull_break")

func step(_delta: float) -> void:
	for id: int in watched.keys():
		var record: Dictionary = watched[id]
		var view: Node = record.ref.get_ref()
		if not is_instance_valid(view) or not view.is_inside_tree() or view.is_queued_for_deletion(): watched.erase(id); continue
		if _has(view, "paused") and view.paused: continue
		if _has(view, "storage_blocked") and view.storage_blocked: continue
		if _has(view, "blocked") and view.blocked: continue
		match str(record.kind):
			"battle": _capture_battle(view, record)
			"workshop": _workshop(view, record)
			"world": _world(view, record)

func _capture_battle(view: Node, record: Dictionary, quiet: bool = false) -> void:
	var model: RefCounted = view.model
	if model == null: return
	var actors: Array = model.actors if _has(model, "actors") else [model.p, model.q]
	var states: Array = []
	for actor: Dictionary in actors:
		var state: Dictionary = {}
		for key: String in ["attackCooldown", "guardCooldown", "dodgeCooldown", "lineCooldown", "skillCooldown", "signatureWindup", "hp", "hull", "energy", "blocks", "counter", "phase"]: state[key] = actor.get(key, 0)
		states.append(state)
	var outcome: String = str(model.outcome) if _has(model, "outcome") else "complete" if model.complete else ""
	var intro: float = float(model.intro) if _has(model, "intro") else 0.0
	var held := {"cut": Controls.held("cut"), "dodge": Controls.held("dodge"), "line": Controls.held("line"), "skill": Controls.held("skill")}
	var current := {"actors": states, "outcome": outcome, "intro": intro, "model": model.get_instance_id(), "held": held}
	var old: Dictionary = record.old
	record.old = current
	if quiet or old.is_empty() or old.get("model") != model.get_instance_id(): return
	if float(old.intro) > 0 and intro <= 0: audio.play_event("battle.round_start"); audio.play_event("battle.launch")
	if old.outcome != outcome and not outcome.is_empty():
		audio.play_event({"won":"battle.victory", "lost":"battle.defeat", "fled":"battle.flee", "complete":"progress.tutorial"}.get(outcome, "progress.tutorial"))
	for index in mini(states.size(), old.actors.size()):
		var a: Dictionary = old.actors[index]
		var b: Dictionary = states[index]
		for key: String in ["attackCooldown", "guardCooldown", "dodgeCooldown", "lineCooldown", "skillCooldown"]:
			if float(b[key]) > float(a[key]) + .08:
				audio.play_event({"attackCooldown":"battle.attack", "guardCooldown":"battle.guard", "dodgeCooldown":"battle.dodge", "lineCooldown":"battle.pull", "skillCooldown":"workshop.gust"}[key])
		if float(a.signatureWindup) <= 0 and float(b.signatureWindup) > 0: audio.play_event("battle.signature_charge"); audio.play_event("battle.signature_banner")
		if float(a.signatureWindup) > 0 and float(b.signatureWindup) <= 0:
			audio.play_event("battle.signature_lacertubo" if actors[index].get("boss", false) else "battle.signature_rabbito")
		if int(b.phase) > int(a.phase): audio.play_event("battle.boss_phase")
		if not model.has_signal("damage_applied"):
			if float(b.hp) < float(a.hp): audio.play_event("battle.line_hit")
			if float(b.hull) < float(a.hull): audio.play_event("battle.hull_hit")
			if int(b.blocks) > int(a.blocks): audio.play_event("battle.block")
		if float(a.counter) <= 0 and float(b.counter) > 0: audio.play_event("battle.counter")
		if index == 0:
			if intro <= 0 and outcome.is_empty():
				for attempt: Array in [["cut", 12, "attackCooldown"], ["dodge", 18, "dodgeCooldown"], ["line", 28, "lineCooldown"], ["skill", 25, "skillCooldown"]]:
					if bool(held[attempt[0]]) and not bool(old.held.get(attempt[0], false)) and float(a.energy) < float(attempt[1]) and float(b[attempt[2]]) <= float(a[attempt[2]]) + .08: audio.play_event("battle.no_energy")
			if float(a.energy) < 40 and float(b.energy) >= 40: audio.play_event("battle.energy_ready")
			if float(a.guardCooldown) > 0 and float(b.guardCooldown) <= 0: audio.play_event("battle.cooldown_ready")
			if float(b.hp) > 0 and float(b.hp) < 25 and outcome.is_empty(): audio.play_event("battle.low_line")

func _workshop_state(run: Dictionary) -> Dictionary:
	var step: Dictionary = run.get("step", {})
	return {"stage": run.stage, "placed": step.get("placed", []).size(), "tied": step.get("tied", []).size(), "covered": step.get("covered", []).size(), "holding": step.get("holding", false), "errors": run.errors.duplicate(), "materials": run.materials.duplicate(), "gusts":step.get("t", 0.0), "fill":step.get("fill", 0.0), "theta":step.get("theta", 0.0)}

func _workshop(view: Node, record: Dictionary) -> void:
	if view.model == null: return
	var current := _workshop_state(view.model.run)
	var old: Dictionary = record.old
	record.old = current
	if old.is_empty(): return
	if current.stage > old.stage: audio.play_event("workshop.stage_done"); return
	if current.placed > old.placed: audio.play_event("workshop.rod_place")
	if current.tied > old.tied: audio.play_event("workshop.knot_good")
	if current.covered > old.covered: audio.play_event("workshop.paper_cut")
	if current.stage == 1 and int(current.holding) >= 0 and int(old.holding) < 0: audio.play_event("workshop.knot_pull")
	if current.stage == 4 and bool(current.holding) and not bool(old.holding): audio.play_event("workshop.soul_charge")
	if current.stage == 3:
		for gust: Dictionary in view.model.run.step.get("gusts", []):
			if float(old.gusts) < float(gust.t) and float(current.gusts) >= float(gust.t): audio.play_event("workshop.gust")
		if absf(float(old.theta)) > 12 and absf(float(current.theta)) <= 12: audio.play_event("workshop.balance")
	for index in current.errors.size():
		if int(current.errors[index]) > int(old.errors[index]): audio.play_event("workshop.paper_tear" if index == 2 else "battle.line_snap" if index == 1 else "workshop.rod_fail")
	if int(current.materials.linha) > int(old.materials.linha) or int(current.materials.folha) > int(old.materials.folha): audio.play_event("workshop.restock")

func _world(view: Node, record: Dictionary) -> void:
	var room: bool = record.file == "room_view.gd"
	if room and view.story_paused: return
	if room and is_instance_valid(view.opening_tv) and view.opening_tv.visible: return
	var point: Vector2 = view.actor if room else view.player
	var old: Dictionary = record.old
	var mother: Vector2 = view.mother_point if room else Vector2.ZERO
	record.old = {"point": point, "mother": mother}
	if old.is_empty(): return
	var cells: bool = record.file == "neighborhood_view.gd"
	var moved: float = point.distance_to(old.point)
	if moved > (4.0 if cells else 140.0): record.distance = 0.0; return
	record.distance += moved
	var threshold := .8 if cells else 54.0
	var now := Time.get_ticks_msec()
	if moved <= .0001: record.distance = 0.0
	if record.distance >= threshold and now - int(record.get("last_step", -1000)) >= 280:
		record.last_step = now
		record.distance = fmod(record.distance, threshold)
		var material := "wood" if room else "stone" if cells else "soil"
		if cells and view.world.kind_at(point) == "grass": material = "grass"
		if view.has_method("in_grass") and view.in_grass(point): material = "grass"
		elif record.file == "park_view.gd" and preload("res://scripts/campaign/park_data.gd").in_grass(point): material = "grass"
		audio.play_event("world.step_" + material, -6)
		if material == "grass" and now - int(record.get("last_rustle", -2000)) >= 1200:
			record.last_rustle = now
			audio.play_event("world.grass_rustle", -18)
	if room and is_instance_valid(view.mother_sprite):
		var travel := mother.distance_to(old.mother)
		if travel < 140: record.mother_distance += travel
		if travel <= .0001: record.mother_distance = 0.0
		if record.mother_distance >= 54 and now - int(record.get("mother_step", -1000)) >= 300:
			record.mother_step = now
			record.mother_distance = 0.0
			audio.play_event("world.step_wood", -10)
