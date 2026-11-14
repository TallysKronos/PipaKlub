extends SceneTree

const Encounter = preload("res://scripts/campaign/encounter_model.gd")
const Rope = preload("res://scripts/campaign/soulflight_rope.gd")
var failures := 0

func check(condition: bool, label: String) -> void:
	if condition: return
	failures += 1
	push_error(label)

func _initialize() -> void:
	var rope := Rope.new()
	var anchor := Vector2(100, 585)
	var tip := Vector2(200, 300)
	rope.reset(anchor, tip)
	var step := 1.0 / 60
	for i in 120: rope.solve(anchor, tip, 12, step)
	check(rope.points.size() == 25 and rope.points[0] == anchor and rope.points[24] == tip, "fixed endpoints")
	check(absf((tip - anchor).cross(rope.points[12] - anchor)) / tip.distance_to(anchor) > 8, "visible slack")
	for i in 90: rope.advance(anchor, tip, -1, 0, step)
	check(rope.tension > .85, "reel generates tension")
	for i in 120: rope.advance(anchor, tip, 1, 0, step)
	check(rope.tension < .05, "release removes tension")
	var a := PackedVector2Array([Vector2.ZERO, Vector2(5, 10), Vector2(10, 10)])
	var b := PackedVector2Array([Vector2(0, 6), Vector2(5, 6), Vector2(8, 12)])
	check(Rope.crossing(a, b).valid, "simulated segment contact")
	var battle := Encounter.new({}, {"modelId": "mata", "level": 1})
	battle.soulflight = true
	battle.intro = 0
	for i in 12: battle.tick(step, {"x": 1})
	var x: float = battle.p.x
	battle.tick(step, {})
	check(battle.p.x > x and battle.p.vx > 0, "coasts after input")
	var enemy_start: float = battle.q.x
	for i in 120: battle.tick(step, {"x": -1 if i < 35 else 1, "reel": -.5})
	check(is_finite(battle.p.vx) and absf(battle.p.vx) < 600 and battle.q.x != enemy_start, "bounded reversal and enemy flight")
	check(battle.line_points(battle.p).size() == 25, "render uses simulated line")
	battle.player_rope.points = a
	battle.enemy_rope.points = b
	battle.p.strike = false
	var hits: Array = []
	battle._strike(battle.p, battle.q, hits)
	check(hits.is_empty(), "contact alone causes no damage")
	battle.p.strike = true
	battle.q.evade = .1
	battle._strike(battle.p, battle.q, hits)
	check(hits.is_empty(), "dodge prevents crossed-line damage")
	battle.q.evade = 0
	battle._strike(battle.p, battle.q, hits)
	check(hits.size() == 1 and not hits[0].body, "cut registers once on simulated crossing")
	battle.soulflight = false
	check(battle.line_points(battle.p).size() == 2, "legacy uses straight line")
	print("soulflight_checks: ", "OK" if failures == 0 else "FAIL")
	quit(int(failures > 0))
