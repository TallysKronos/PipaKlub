extends SceneTree
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const Model = preload("res://scripts/campaign/morro_model.gd")
var checks := 0
var failures := 0
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", text)
func _initialize() -> void:
	var directory := "user://morro-transactions-" + State.new_id()
	var session := Session.new()
	session._store = Store.new(directory)
	check(session.start("slot-1").status == "ok", "create isolated slot")
	var player: Dictionary = session.snapshot().player
	player.partners = [{"id": "test", "modelId": "basica", "craftBonus": 0, "xp": 0}]
	player.equippedPartnerId = "test"
	player.journey = {"phase": "complete", "lesson": 5}
	var place: Dictionary = Morro.maps().morro.places.filter(func(p): return p.has("stage"))[0]
	var point := Vector2(place.point[0], place.point[1])
	check(session.checkpoint({"kind": "world", "scene": "morro", "position": place.point}, player).status == "ok", "post-professor fixture")
	var service := Morro.new(session)
	check(service.start(point + Vector2(500, 0)).status == "wrong_step", "requires nearby NPC")
	for outcome in ["fled", "lost", "won", "won"]:
		# Synthetic terminal states exercise storage/reward transactions separately from the input playthrough.
		player = session.snapshot().player
		player.partners[0].condition = {"line": 100, "structure": 100}
		check(session.checkpoint(session.snapshot().checkpoint, player).status == "ok", "isolated recovery fixture")
		var before: Dictionary = session.snapshot().player
		check(service.start(point).status == "ok", "start challenge " + outcome)
		var model := Model.new()
		model.restore(session.snapshot().player.encounter.state)
		model.outcome = outcome
		if outcome == "won": model.p.rounds = model.rounds_to_win
		if outcome == "lost": model.q.rounds = model.rounds_to_win
		var saved: Dictionary = session.snapshot()
		saved.player.encounter.state = model.snapshot()
		check(session.checkpoint(saved.checkpoint, saved.player).status == "ok", "persist terminal state")
		var preview: Dictionary = load("res://scripts/campaign/hud_rewards.gd").preview(saved.player, saved.player.encounter, model)
		check(service.settle().status == "ok", "settle " + outcome)
		var after: Dictionary = session.snapshot().player
		check(preview.xp == after.lastMorro.partnerXp and preview.coins == after.lastMorro.coins and preview.stars == after.lastMorro.stars, "preview matches committed outcome " + outcome)
		var coins: int = after.coins
		check(service.settle().status == "wrong_step" and session.snapshot().player.coins == coins, "repeated click cannot duplicate rewards")
		if outcome == "fled": check(after.coins == before.coins and not after.has("morro") and after.partners[0].xp == 0, "flee gives no rewards or losses")
		if outcome == "lost": check(after.morro.losses == 1 and after.morro.fails["morro-1"] == 1 and after.coins == 0 and after.partners[0].xp == 20, "defeat keeps challenge retryable and grants original XP")
		if outcome == "won": check(after.coins - before.coins == (15 if before.get("morro", Morro.Rules.defaults()).stars.has("morro-1") else 25), "first clear bonus paid once")
		check(session.resume_slot("slot-1").status == "ok", "result reloads")
	player = session.snapshot().player
	for id in ["morro-1", "morro-2", "morro-3", "morro-4"]: player.morro.stars[id] = 3
	var final_place: Dictionary = Morro.maps()["morro-area-5"].places.filter(func(p): return p.has("stage"))[0]
	check(session.checkpoint({"kind": "world", "scene": "morro-area-5", "position": final_place.point}, player).status == "ok", "leader transaction fixture")
	for attempt in 2:
		check(service.start(Vector2(final_place.point[0], final_place.point[1])).status == "ok", "leader rematch available")
		var leader := Model.new()
		leader.restore(session.snapshot().player.encounter.state)
		leader.outcome = "won"
		leader.p.rounds = leader.rounds_to_win
		var end: Dictionary = session.snapshot()
		end.player.encounter.state = leader.snapshot()
		check(session.checkpoint(end.checkpoint, end.player).status == "ok", "leader terminal fixture")
		check(service.settle().status == "ok", "leader reward transaction")
		check(session.snapshot().player.inventory.get("rabiola-raio", 0) == 1, "leader rematch never duplicates unique tail")
	var malformed := session.snapshot()
	malformed.player.morro.mastery = 9
	check(State.inspect(malformed, "slot-1") == "invalid", "invalid mastery rejected")
	var three := Model.new(player.partners[0], "morro-3")
	var battle := {"id": "check", "kind": "morro", "scene": "morro-area-3", "returnPoint": [656, 496], "state": three.snapshot()}
	check(State.valid_encounter(battle), "three fighters accepted")
	battle.state.actors.pop_back()
	check(not State.valid_encounter(battle), "missing simultaneous fighter rejected")
	# All rivals attack each other rather than sharing a team against the player.
	three = Model.new(player.partners[0], "morro-3")
	three.intro = 0
	three.p.out = true
	three.p.hp = 0
	for tick in 5000:
		three.tick(1.0 / 60, {})
		if three.q.hp < three.q.stats.line or three.actors[2].hp < three.actors[2].stats.line: break
	check(three.q.hp < three.q.stats.line or three.actors[2].hp < three.actors[2].stats.line, "Juninho and Lia damage each other")
	var start := Model.new(player.partners[0], "morro-1")
	start.intro = 0
	start.q.hp = 1
	start.p.strike = true
	var survivors: Array = [start.p]
	start._finish_round(survivors)
	check(start.p.rounds == 1 and start.outcome.is_empty(), "one round is not whole match")
	var restored := Model.new()
	restored.restore(JSON.parse_string(JSON.stringify(start.snapshot())))
	check(restored.intermission == start.intermission and restored.p.rounds == 1, "intermission and score resume")
	for tick in 400: restored.tick(1.0 / 60, {})
	check(restored.round_number == 2 and restored.p.hp == restored.p.stats.line, "next round restores line")
	session.free()
	print("Morro transactions: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
