extends SceneTree
const Model = preload("res://scripts/campaign/encounter_model.gd")
const MorroModel = preload("res://scripts/campaign/morro_model.gd")
const Effects = preload("res://scripts/campaign/hud_impacts.gd")
const Rewards = preload("res://scripts/campaign/hud_rewards.gd")
const Card = preload("res://scripts/campaign/hud_reward_card.gd")
const Preferences = preload("res://scripts/campaign/preferences.gd")
const State = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var partner := {"id": "effects-test", "modelId": "rabbito", "personalName": "Brisa", "xp": 0}
	var player := {"partners": [partner], "inventory": {}, "coins": 0}
	var model := Model.new(partner)
	var effects := Effects.new()
	model.damage_applied.connect(effects.add)
	model.q.hp = 3
	model._apply_hit({"target": model.q, "body": false, "damage": 20.0})
	check(effects.bursts.size() == 1 and effects.bursts[0].amount == 3, "impact reports actual clamped damage, not requested overkill")
	model._apply_hit({"target": model.q, "body": false, "damage": 20.0})
	check(effects.bursts.size() == 1, "no repeated visual damage on an already empty line")
	var snapshot := model.snapshot()
	effects.step(1)
	check(effects.bursts.is_empty(), "impact always returns to rest")
	check(model.snapshot() == snapshot and Engine.time_scale == 1, "visual step cannot change combat or global time")
	for index in 30: effects.add({"amount": 1, "point": Vector2(300, 300), "player": false, "body": false})
	check(effects.bursts.size() == 10, "simultaneous damage has a bounded visual budget")
	model.outcome = "won"
	var before := player.duplicate(true)
	var summary := Rewards.preview(player, {"kind": "lacertubo"}, model)
	check(summary.xp == 120 and summary.items == ["Rabiola de Lacertubo"], "boss preview shows native reward")
	check(player == before, "preview cannot award XP, mutate inventory or save")
	partner.xp = 25965
	summary = Rewards.preview(player, {"kind": "lacertubo"}, model)
	check(summary.xp == 5 and summary.after == 25970, "preview respects level cap credit")
	partner.xp = 0
	model.outcome = "fled"
	check(Rewards.preview(player, {"kind": "lacertubo"}, model).xp == 0, "flee never presents a reward")
	var trail := MorroModel.new(partner, "morro-1")
	trail.outcome = "lost"
	check(Rewards.preview(player, {"kind": "morro"}, trail).xp == 20, "Morro loss retains native consolation XP")
	model.outcome = "won"
	var card := Card.new()
	card.summary = Rewards.preview(player, {"kind": "lacertubo"}, model)
	root.add_child(card)
	card.advance(.4)
	check(card.shown > 0 and card.shown < 120, "reward counter progresses between endpoints")
	card.advance(1)
	check(card.shown == 120 and card.levels.text.contains("→ 3"), "counter ends at actual XP and crossed level")
	card.advance(10)
	check(card.shown == 120, "counter never loops or increases settlement")
	card.free()
	card = Card.new()
	card.summary = summary
	card.reduced_motion = true
	root.add_child(card)
	check(card.shown == summary.xp, "reduced motion presents reward immediately")
	card.free()
	var prefs := Preferences.new()
	prefs.reduced_motion = true
	var path := "user://hud-effects-" + State.new_id() + ".cfg"
	check(prefs.save_settings(path) == OK, "save isolated motion preference")
	var loaded := Preferences.new()
	loaded.load_settings(path)
	check(loaded.reduced_motion, "motion preference persists independently of saves")
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var transition = load("res://scripts/campaign/hud_ink_transition.gd").new()
	layer.add_child(transition)
	check(transition.mouse_filter == Control.MOUSE_FILTER_IGNORE, "ink reveal never swallows input")
	await create_timer(.55).timeout
	check(not is_instance_valid(layer), "ink reveal frees its whole layer after 450ms")
	print("HUD EFFECTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
