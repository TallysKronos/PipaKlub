extends SceneTree

const Store = preload("res://scripts/campaign/save_store.gd")
const Session = preload("res://scripts/campaign/session.gd")
const State = preload("res://scripts/campaign/state.gd")
const Opening = preload("res://scripts/campaign/opening.gd")
const Workshop = preload("res://scripts/campaign/workshop_model.gd")
const Encounter = preload("res://scripts/campaign/encounter_model.gd")
const Encounters = preload("res://scripts/campaign/encounters.gd")
const Exploration = preload("res://scripts/campaign/exploration.gd")
const Park = preload("res://scripts/campaign/park_data.gd")
const Ground = preload("res://scripts/illustrated_ground.gd")
const Journey = preload("res://scripts/campaign/journey.gd")
const Preferences = preload("res://scripts/campaign/preferences.gd")
const Flight = preload("res://scripts/campaign/first_flight_model.gd")
var failures := 0
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func _initialize() -> void:
	var directory := "user://campaign-checks-" + State.new_id()
	print("ISOLATED DIRECTORY: ", ProjectSettings.globalize_path(directory))
	var store := Store.new(directory)
	var session := Session.new()
	session._store = store
	var created := session.start("slot-1")
	check(created.status == "ok", "create isolated slot")
	if session.snapshot().is_empty():
		session.free()
		quit(1)
		return
	check(store.create_slot("slot-1").status == "occupied", "never replace occupied slot")
	var original := session.snapshot()
	var player: Dictionary = original.player.duplicate(true)
	player.coins = 9
	check(session.checkpoint(original.checkpoint, player).status == "ok", "save checkpoint")
	check(store.load_slot("slot-1").data.player.coins == 9, "resume saved coins")
	check(store.save_slot(original).status == "stale", "reject stale writer")
	var copy := session.snapshot()
	copy.player.coins = 999
	check(session.snapshot().player.coins == 9, "snapshot is independent")
	player.coins = 19
	check(session.commit_operation("reward-one", original.checkpoint, player).status == "ok", "commit reward and receipt")
	player.coins = 29
	check(session.commit_operation("reward-one", original.checkpoint, player).status == "already_applied", "reject repeated reward")
	check(store.load_slot("slot-1").data.player.coins == 19, "duplicate grants no coins")
	var path := directory.path_join("slot-1.json")
	var damaged := FileAccess.open(path, FileAccess.WRITE)
	damaged.store_string("interrupted-invalid-json")
	damaged.close()
	var recovered := store.load_slot("slot-1")
	check(recovered.status == "ok" and recovered.recovered, "recover good backup")
	check(recovered.data.player.coins == 9, "backup contains previous committed state")
	check(store.save_slot(recovered.data).status == "ok", "save after recovery")
	check(store.load_slot("slot-1").data.player.coins == 9, "recovered state survives reload")
	var future: Dictionary = store.load_slot("slot-1").data
	future.schemaVersion = 99
	write_json(path, future)
	var before := FileAccess.get_sha256(path)
	check(store.load_slot("slot-1").status == "future", "future schema blocks old backup")
	check(store.save_slot(original).status == "future", "future schema blocks write")
	check(FileAccess.get_sha256(path) == before, "future save bytes preserved")
	check(store.load_slot("../slot-1").status == "invalid_slot", "reject path traversal")
	check(session.start("slot-2").status == "ok", "create narrative fixture")
	var opening := Opening.new(session)
	for step in range(10):
		var transition := opening.advance(step)
		if transition.status != "ok": print("TRANSITION: ", step, " ", transition)
		check(transition.status == "ok", "opening transition %d" % step)
	check(opening.name_partner("x".repeat(25)).status == "invalid_name", "reject overlong partner name")
	check(opening.name_partner("Brisa").status == "ok", "birth commits partner")
	var born := session.snapshot()
	check(born.player.partners.size() == 1, "one birth partner")
	check(opening.name_partner("Duplicado").status == "wrong_step", "birth cannot repeat")
	check(session.resume_slot("slot-2").status == "ok", "resume narrative")
	check(session.snapshot().player.partners[0].id == born.player.partners[0].id and session.snapshot().player.partners[0].personalName == "Brisa", "partner UUID persists")
	for step in range(11, 14):
		check(opening.advance(step).status == "ok", "final opening transition %d" % step)
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/workshop.json"))
	var rare_workshop: Dictionary = {}
	for fixture in fixtures:
		var model := Workshop.new(fixture.kind, int(fixture.seed))
		var last_stage := -1
		for event in fixture.events:
			match event[0]:
				"rod": model.place_rod(Vector2(event[1], event[2]))
				"knot": model.hold_knot(int(event[1]))
				"knot-up": model.release_knot()
				"cut": model.cut_at(Vector2(event[1], event[2]), event[3])
				"t": model.tick(event[1], event[2])
				"soul": model.hold_soul()
				"soul-up": model.release_soul()
			if model.run.stage != last_stage:
				last_stage = model.run.stage
				var serialized: Dictionary = JSON.parse_string(JSON.stringify(model.run))
				check(State.valid_workshop(serialized), "%s workshop stage %d remains valid after JSON roundtrip" % [fixture.kind, last_stage])
		check(model.run.stage == fixture.expected.stage, fixture.kind + " workshop final stage matches JavaScript")
		for field in ["precision", "speed", "quality"]:
			check(absf(model.quality()[field] - fixture.quality[field]) < .000001, fixture.kind + " JavaScript quality: " + field)
		check(model.run.outcome.get("type") == fixture.expected.outcome.get("type"), fixture.kind + " birth outcome matches JavaScript")
		if fixture.kind == "raro": rare_workshop = model.run.duplicate(true)
	var combat: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/combat.json"))
	for fixture in combat:
		var model := Encounter.new({"id": "fixture", "modelId": "rabbito", "craftBonus": fixture.bonus})
		model.p.color = int(fixture.color)
		for event in fixture.events:
			var input: Dictionary = event.input.duplicate()
			input.line = input.has("lineNonce")
			model._move_fighter(model.p, input, 1.0 / 60, event.wind)
		for key in fixture.expected:
			if absf(model.p[key] - fixture.expected[key]) >= .00001: print("DIFFERENCE ", fixture.color, " ", key, " native=", model.p[key], " JS=", fixture.expected[key])
			check(absf(model.p[key] - fixture.expected[key]) < .00001, "combat color %d JavaScript %s" % [fixture.color, key])
	var domain := Exploration.new(session)
	var tutorial: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/tutorial.json"))
	for fixture in tutorial:
		var flight := Flight.new(int(fixture.lesson))
		var seen_nonce := 0
		for event in fixture.events:
			var input: Dictionary = event.input.duplicate()
			var nonce: int = input.get("lineNonce", 0)
			input.line = nonce > seen_nonce
			seen_nonce = maxi(seen_nonce, nonce)
			flight.tick(event.dt, input)
		check(flight.complete, "tutorial completes original trace lesson %d" % fixture.lesson)
		for key in fixture.expected.p:
			if absf(flight.p[key] - fixture.expected.p[key]) > .0001: print("TUTORIAL DIFFERENCE ", fixture.lesson, " ", key, " native=", flight.p[key], " JS=", fixture.expected.p[key])
			check(absf(flight.p[key] - fixture.expected.p[key]) < .0001, "tutorial lesson %d matches JS %s" % [fixture.lesson, key])
	for initial_hp in [250, 130]:
		var boss_trace: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/boss-%d.json" % initial_hp))
		var boss_model := Encounter.new()
		boss_model.intro = 0
		boss_model.q.hp = initial_hp
		var trace_equal := true
		for index in boss_trace.size():
			var frame: Dictionary = boss_trace[index]
			boss_model.tick(frame.dt, frame.input)
			for side in ["p", "q"]:
				var actor: Dictionary = boss_model.p if side == "p" else boss_model.q
				for key in frame[side]:
					var native_key: String = {"bossCharge": "charge", "bossRecovery": "recovery"}.get(key, key)
					if absf(actor[native_key] - frame[side][key]) > .0001:
						if trace_equal: print("BOSS FIRST DIFFERENCE frame=", index, " ", side, ".", key, " native=", actor[native_key], " JS=", frame[side][key])
						trace_equal = false
		check(trace_equal, "12-second boss trace matches original JavaScript")
	var encounters := Encounters.new(session)
	var saved := session.snapshot()
	saved.player.journey = {"lesson": 5, "phase": "complete"}
	saved.player.equippedPartnerId = saved.player.partners[0].id
	check(session.checkpoint({"kind": "world", "scene": "park-veredas", "position": [816, 480]}, saved.player).status == "ok", "isolated park checkpoint")
	check(domain.accept_nina(Park.ENTRY).status == "wrong_step", "Nina requires proximity")
	check(domain.accept_nina(Park.NINA).status == "ok", "accept mission")
	check(domain.chest("woodland", Park.CHESTS.woodland.point).status == "ok", "collect chest")
	check(domain.chest("woodland", Park.CHESTS.woodland.point).status == "already_applied", "chest cannot repeat")
	check(session.snapshot().player.coins == 25, "chest grants original reward once")
	check(domain.chest("courtyard", Park.CHESTS.courtyard.point).status == "guardian", "guardian gates courtyard chest")
	check(domain.collect_tail(Park.TAIL).status == "wrong_step", "quest tail requires victory")
	check(encounters.start_boss(Park.BOSS).status == "ok", "persist encounter before fighting")
	var battle_state: Dictionary = session.snapshot().player.encounter.state
	var native := Encounter.new()
	native.restore(battle_state)
	native.intro = 0
	for i in 30: native.tick(1.0 / 60, {"x": 1})
	check(encounters.save_battle(native.snapshot()).status == "ok", "save actual battle state")
	check(session.resume_slot("slot-2").status == "ok", "reload encounter")
	var resumed := Encounter.new()
	resumed.restore(session.snapshot().player.encounter.state)
	check(absf(resumed.p.x - native.p.x) < .000001, "battle resumes at saved position")
	# Transaction fixture: synthetic outcome verifies grants, not player skill/playthrough.
	native.outcome = "won"
	check(encounters.save_battle(native.snapshot()).status == "ok", "persist outcome fixture")
	check(encounters.settle().status == "ok", "settle reward and guardian flag atomically")
	check(encounters.settle().status == "wrong_step", "cannot settle twice")
	check(session.snapshot().player.inventory["rabiola-lacertubo"] == 1, "boss drops own tail once")
	check(domain.collect_tail(Park.TAIL).status == "ok", "collect Nina tail separately")
	check(domain.return_tail(Park.NINA).status == "ok", "return mission item")
	check(not session.snapshot().player.inventory.has("quest-nina-tail"), "returned quest item consumed")
	check(session.snapshot().player.flags.ninaReturned, "mission complete persists")
	var ground := Ground.new(JSON.parse_string(FileAccess.get_file_as_string("res://assets/illustrated/routes-v2.json")))
	for id in Park.CHESTS:
		check(ground.walkable(Park.CHESTS[id].point), "chest on supported ground: " + id)
	check(ground.walkable(Park.BOSS) and ground.walkable(Park.TAIL), "boss and tail on supported ground")
	check(encounters.start_wild(Park.ENTRY).status == "wrong_step", "no wild encounters on safe path")
	var wild_saved := session.snapshot()
	wild_saved.player.encounterGraceUntil = 0
	check(session.checkpoint(wild_saved.checkpoint, wild_saved.player).status == "ok", "isolated encounter cooldown fixture")
	check(encounters.start_wild(Vector2(185, 418)).status == "ok", "wild encounter only inside grass")
	var wild := Encounter.new()
	wild.restore(session.snapshot().player.encounter.state)
	check(not wild.q.boss and wild.enemy_level >= 5 and wild.enemy_level <= 9, "wild stats independent from guardian")
	check(wild.enemy_model_id in ["basica", "mata"], "first encounter uses original introductory species")
	wild.outcome = "won"
	check(encounters.save_battle(wild.snapshot()).status == "ok", "persist wild outcome fixture")
	check(encounters.settle().status == "ok", "settle wild outcome once")
	check(session.snapshot().player.inventory.get("rabiola-" + wild.enemy_model_id, 0) >= 1, "first wild victory guarantees species tail")
	check(encounters.start_wild(Vector2(185, 418)).status == "wrong_step", "grace prevents immediate encounter")
	var journey := Journey.new(session)
	check(journey.enter_world("professor-home", Vector2(1440, 672)).status == "ok", "return to professor")
	check(domain.repair().status == "ok", "repair partners without payment")
	check(session.snapshot().player.partners[0].condition.line == 100, "repair restores line")
	check(journey.start_summon("lacertubo").status == "ok", "reserve boss tail for workshop")
	check(session.snapshot().player.inventory.get("rabiola-lacertubo", 0) == 0, "reserved tail cannot be spent twice")
	check(journey.cancel_workshop().status == "ok", "cancel inventory workshop")
	check(session.snapshot().player.inventory["rabiola-lacertubo"] == 1, "cancel refunds exactly one tail")
	check(journey.cancel_workshop().status == "wrong_step", "repeated cancellation cannot refund again")
	check(journey.start_summon("lacertubo").status == "ok", "restart workshop")
	var crafted := session.snapshot()
	crafted.player.workshop.seed = 7
	crafted.player.workshop.state = rare_workshop
	check(session.checkpoint(crafted.checkpoint, crafted.player).status == "ok", "completed workshop transaction fixture")
	check(journey.finish_workshop().status == "ok", "inventory tail creates partner")
	check(session.snapshot().player.partners.size() == 2 and session.snapshot().player.partners[1].modelId == "lacertubo", "created guardian enters collection")
	check(journey.finish_workshop().status == "wrong_step", "workshop birth cannot repeat")
	var prefs := Preferences.new()
	check(prefs.crt, "CRT defaults enabled")
	prefs.crt = false
	check(prefs.save_settings(directory.path_join("settings.cfg")) == OK, "save isolated preferences")
	var read_prefs := Preferences.new()
	read_prefs.load_settings(directory.path_join("settings.cfg"))
	check(not read_prefs.crt, "CRT choice survives reload")
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
	for scene in ["park-trail", "park-clearing"]:
		var route_saved := session.snapshot()
		route_saved.player.encounterGraceUntil = 0
		var patch: Dictionary = {}
		for area in maps[scene].walkable:
			if area.properties.get("encounter_zone", "") != "":
				patch = area
				break
		check(not patch.is_empty(), scene + " has authored encounter grass")
		var point := Vector2(patch.x + patch.w / 2, patch.y + patch.h / 2)
		check(session.checkpoint({"kind": "world", "scene": scene, "position": [point.x, point.y]}, route_saved.player).status == "ok", scene + " persists checkpoint")
		check(encounters.start_wild(point).status == "ok", scene + " starts wild battle")
		var state: Dictionary = session.snapshot().player.encounter.state
		check(state.enemyLevel >= (2 if scene == "park-clearing" else 1) and state.enemyLevel <= (4 if scene == "park-clearing" else 3), scene + " preserves original encounter levels")
		state.outcome = "fled"
		check(encounters.save_battle(state).status == "ok" and encounters.settle().status == "ok", scene + " flee settles")
		check(session.snapshot().checkpoint.scene == scene, scene + " returns to its own area")
	print("CAMPAIGN CHECKS: %d checks, %d failures" % [checks, failures])
	session.free()
	quit(1 if failures else 0)
