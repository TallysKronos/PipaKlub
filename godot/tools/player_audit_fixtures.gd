extends RefCounted
## Visual-state fixtures complement, never replace, the earned gameplay journey.
const State = preload("res://scripts/campaign/state.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const MorroModel = preload("res://scripts/campaign/morro_model.gd")
const Workshop = preload("res://scripts/campaign/workshop_model.gd")
static func scenarios() -> Array[String]:
	var result: Array[String] = ["menu", "settings", "controls"]
	for step in 15: result.append("opening-%d" % step)
	for lesson in 5:
		result.append("lesson-%d" % lesson)
		result.append("lesson-%d-complete" % lesson)
	for stage in 5: result.append("workshop-%d" % stage)
	result.append_array(["workshop-paused", "workshop-blocked", "starter", "street", "professor", "trail", "clearing", "park", "park-map", "pause", "bag-empty", "bag-full", "team-long", "boss-intro", "battle", "battle-paused", "battle-energy", "won", "lost", "fled", "save-error", "morro", "morro-area-2", "morro-area-3", "morro-area-4", "morro-area-5", "morro-dialog", "morro-battle", "morro-won", "morro-lost", "long-notice"])
	return result
static func show(front: Control, id: String) -> void:
	front.last_scene_key = ""
	if id == "menu":
		front._menu()
		return
	if id in ["settings", "controls"]:
		front.session.close_session()
		if id == "settings": front._show_settings()
		else: front._show_controls()
		return
	var saved := State.fresh("slot-1")
	saved.player.partners = [{"id": "audit-partner", "modelId": "rabbito", "personalName": "Rabbito", "xp": 0, "craftBonus": 0, "condition": {"line": 100, "structure": 100}}]
	saved.player.equippedPartnerId = "audit-partner"
	saved.player.journey = {"lesson": 5, "phase": "complete"}
	saved.player.flags = {"ninaAccepted": true}
	saved.checkpoint = {"kind": "world", "scene": "park-veredas", "position": [1160, 366]}
	if id.begins_with("opening-"): saved.checkpoint = {"kind": "opening", "step": id.trim_prefix("opening-").to_int()}
	elif id.begins_with("lesson-"): saved.checkpoint = {"kind": "practice", "lesson": id.split("-")[1].to_int()}
	elif id.begins_with("workshop-"):
		var model := Workshop.new("basica", 7)
		var stage := id.trim_prefix("workshop-").to_int() if id not in ["workshop-paused", "workshop-blocked"] else 1
		model.run.stage = stage
		model._start_stage()
		saved.player.workshop = {"id": "audit-job", "seed": 7, "modelId": "basica", "state": model.run}
		saved.checkpoint = {"kind": "workshop"}
	elif id in ["street", "professor"]:
		saved.checkpoint = {"kind": "world", "scene": "quintal" if id == "street" else "professor-home", "position": [1376, 688] if id == "street" else [1056, 1232]}
	elif id in ["trail", "clearing"]:
		saved.checkpoint = {"kind": "world", "scene": "park-trail" if id == "trail" else "park-clearing", "position": [336, 784]}
	elif id.begins_with("morro"):
		var scene: String = id if Morro.maps().has(id) else "morro-area-3"
		saved.checkpoint = {"kind": "world", "scene": scene, "position": Morro.maps()[scene].spawn}
		if id in ["morro-battle", "morro-won", "morro-lost"]:
			var model := MorroModel.new(saved.player.partners[0], "morro-3")
			model.intro = 0
			if id != "morro-battle": model.outcome = "won" if id == "morro-won" else "lost"
			saved.player.encounter = {"kind": "morro", "state": model.snapshot()}
			saved.checkpoint = {"kind": "encounter"}
	elif id in ["boss-intro", "battle", "battle-paused", "battle-energy", "battle-special", "battle-long-name", "battle-extremes", "won", "lost", "fled", "save-error"]:
		var model := Model.new(saved.player.partners[0], {} if id == "boss-intro" else {"modelId": "mata", "level": 3})
		if id != "boss-intro": model.intro = 0
		if id in ["won", "lost", "fled", "save-error"]:
			model.outcome = "won" if id in ["won", "save-error"] else id
			if model.outcome == "won": model.q.hp = 0
			if model.outcome == "lost": model.p.hp = 0
		if id == "battle-extremes":
			model.p.x = 55
			model.p.y = 70
			model.q.x = 945
			model.q.y = 480
		if id == "battle-energy": model.p.energy = 2
		if id == "battle-special":
			model.p.signatureWindup = 1.2
			model.p.signatureAim = Vector2(model.q.x, model.q.y)
		if id == "battle-long-name": saved.player.partners[0].personalName = "Um parceiro muito querido"
		saved.player.encounter = {"kind": "lacertubo" if id == "boss-intro" else "wild", "scene": "park-clearing", "dropRoll": 0.0, "state": model.snapshot()}
		saved.checkpoint = {"kind": "encounter"}
	elif id == "starter":
		saved.checkpoint = {"kind": "starter"}
		saved.player.journey = {"lesson": 5, "phase": "starter"}
	if id in ["bag-full", "team-long"]:
		saved.player.inventory = {"rabiola-basica": 2, "quest-nina-tail": 1, "rabiola-lacertubo": 1, "rabiola-azulao": 3, "rabiola-mata": 4, "rabiola-raio": 2}
	if id == "team-long":
		for index in 5:
			saved.player.partners.append({"id": "partner-%d" % index, "modelId": "basica", "personalName": "Um nome bem comprido aqui", "xp": 120 + index * 60, "condition": {"line": 20, "structure": 40}})
	front.session._snapshot = saved
	if id in ["bag-empty", "bag-full", "team-long", "starter"]:
		front._clear()
		front.last_scene_key = ""
		if id == "team-long": front._show_collection()
		elif id == "starter": front._show_starter()
		else: front._show_bag()
	else: front._show_saved()
	if id.begins_with("lesson-"):
		for child in front.get_children():
			if child.get_script() == front.FlightView:
				child.model.complete = id.ends_with("-complete")
				child._process(0)
				child.set_process(false)
	if id == "workshop-paused": front.workshop._pause()
	if id == "workshop-blocked":
		front.workshop.model.run.blocked = "linha"
		front.workshop.help.text = "A linha acabou. Busque materiais para continuar a montagem."
		front.workshop._process(0)
	if id == "battle-paused": front.battle.paused = true
	if id == "save-error": front.battle.blocked = true
	if is_instance_valid(front.battle):
		front.battle._physics_process(.016)
		front.battle.set_physics_process(false)
	if id == "pause": front._pause_game()
	if id == "park-map": front.park._unhandled_input(_map_key())
	if id == "morro-dialog":
		var story: Dictionary = Morro.Rules.content().stories["morro-3"]
		front._confirm_park("Juninho e Lia", "\n\n".join(story.before.map(func(line): return "%s: %s" % [line[0], line[1]])) + "\n\n" + story.tactic, "Vamos voar!", func(): pass)
	if id == "long-notice": front._notice("Sr. Assis: Reforcei a linha e a armação dos seus parceiros. Estão novos em folha.\n\nVolte sempre que precisar de reparos. Seus parceiros continuam com você mesmo depois de perder uma batalha.")
static func _map_key() -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_M
	key.pressed = true
	return key
