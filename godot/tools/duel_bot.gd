extends RefCounted
## A bot holding Kael's controls in a duel: it reads the lines the same way the rival
## AI does (aim for a crossing, wait for focus, pull, dodge a threat), at a skill from
## 1 to 10. Used by tools/campaign_walker.gd (--fight=N) and tools/duel_balance.gd.

## Plays the model to its end; returns the seconds it took. A duel that never ends
## within 15 minutes counts as lost.
static func play(m, skill: int, seed_value: int = 1) -> float:
	# A person is not exact: each pull waits a little more or less, and the aim drifts.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bot := {"focus": 0.0, "sig": false, "rng": rng, "wait": 0.0, "drift": rng.randf_range(0, TAU)}
	var t := 0.0
	var dt := 1.0 / 30.0
	while m.outcome.is_empty() and t < 900.0:
		m.tick(dt, input(m, dt, skill, bot))
		t += dt
	if m.outcome.is_empty(): m.outcome = "lost"
	return t

static func input(m, dt: float, fight_skill: int, bot: Dictionary) -> Dictionary:
	var p: Dictionary = m.p
	var foes: Array = []
	if m.get("actors") != null:
		for a in m.actors:
			if a.slot != p.slot and m.alive(a): foes.append(a)
	elif m.q.hp > 0 and m.q.hull > 0: foes.append(m.q)
	if foes.is_empty() or p.hp <= 0 or p.hull <= 0: return {}
	foes.sort_custom(func(a, c): return Vector2(a.x - p.x, a.y - p.y).length_squared() < Vector2(c.x - p.x, c.y - p.y).length_squared())
	var target: Dictionary = foes[0]
	var k := pow((clampi(fight_skill, 1, 10) - 1) / 9.0, .75)
	var focus := .95 - .8 * k
	var rest := 1.15 - .95 * k
	var speed := .6 + .4 * k
	var dodge := clampf((fight_skill - 2) / 8.0, 0, 1)
	var rng: RandomNumberGenerator = bot.rng
	var fraction := .6 + .16 * (1 - k) * sin(m.time * 1000 / 650 + bot.drift) + rng.randf_range(-.05, .05) * (1 - k)
	var crossing := Vector2(target.anchor, 585).lerp(Vector2(target.x, target.y), fraction)
	var tip := .88 if fight_skill >= 8 else .7
	var aim := Vector2(clampf(p.anchor + (crossing.x - p.anchor) / tip, 55, 945), clampf(585 + (crossing.y - 585) / tip, 70, 480))
	var c: Dictionary = m.contact(p, target)
	var threat: Dictionary = {}
	for foe in foes:
		var test: Dictionary = m.contact(foe, p)
		if test.get("valid", false): threat = test; break
	var input := {}
	if dodge > 0 and not threat.is_empty() and not c.get("valid", false):
		var away: Vector2 = (Vector2(p.x, p.y) - threat.point).normalized()
		aim = Vector2(p.x, p.y) + away * 120 * dodge + (aim - Vector2(p.x, p.y)) * (1 - dodge)
		if fight_skill >= 4 and p.dodgeCooldown <= 0 and p.energy >= 30 and float(target.get("attackCooldown", 1)) <= .1:
			input.dodge = true
	bot.focus = bot.focus + dt if c.get("valid", false) else minf(0, bot.focus) + dt
	var pull: bool = c.get("valid", false) and bot.focus >= focus + bot.wait and p.energy >= 12
	if pull and p.attackCooldown <= 0:
		bot.focus = -rest
		bot.wait = rng.randf_range(-.15, .35) * (1 - k * .7)
	# A player who has learnt the Mata verde's shield waits for it to drop (skill 6+).
	if fight_skill >= 6 and int(target.get("color", -1)) == 2 and float(target.get("skillTime", 0)) > 0:
		pull = false
		bot.focus = minf(bot.focus, focus * .8)
	input.x = clampf((aim.x - p.x) / 80, -speed, speed)
	input.y = clampf((aim.y - p.y) / 80, -speed, speed)
	input.cut = pull
	input.skill = pull and p.energy >= 40
	# The signature is a press: alternate so each attempt is a new edge.
	var near: bool = Vector2(p.x, p.y).distance_to(Vector2(target.x, target.y)) < 300
	bot.sig = not bot.sig and fight_skill >= 3 and near and p.energy >= 40 and p.signatureCooldown <= 0 and threat.is_empty()
	input.signature = bot.sig
	return input
