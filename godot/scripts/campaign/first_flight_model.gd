extends RefCounted
## Level-one Rabbito/Nozinho tutorial port. Not the general online combat engine.
var lesson := 0
var complete := false
var exercise := "skill"
var time := 0.0
var line_nonce := 0
var p: Dictionary
var q: Dictionary
var base_hits := 0
var base_score := 0
var base_skill := 0
var base_dodge := 0
var base_line := 0
var base_blocks := 0
var skill_activated := false

func _init(index: int = 0) -> void:
	p = _player(190, 320, 90)
	q = _player(300, 180, 910)
	prepare(index)

func _player(x: float, y: float, anchor: float) -> Dictionary:
	return {"x": x, "y": y, "anchor": anchor, "hp": 100.0, "hull": 100.0, "energy": 100.0,
		"vx": 0.0, "vy": 0.0, "attackCooldown": 0.0, "skillCooldown": 0.0, "skillTime": 0.0,
		"evade": 0.0, "dodgeCooldown": 0.0, "guardTime": 0.0, "guardCooldown": 0.0,
		"guardHeld": false, "counter": 0.0, "hits": 0, "score": 0, "skillCount": 0,
		"dodges": 0, "lineCount": 0, "blocks": 0, "lineCooldown": 0.0,
		"lineMove": {}, "signatureCooldown": 0.0, "signatureWindup": 0.0, "signatureAim": Vector2.ZERO}

func prepare(index: int) -> void:
	lesson = clampi(index, 0, 4)
	complete = false
	exercise = "skill"
	skill_activated = false
	base_hits = p.hits
	base_score = p.score
	base_skill = p.skillCount
	base_dodge = p.dodges
	base_line = p.lineCount
	base_blocks = p.blocks
	for player in [p, q]:
		player.hp = 100.0
		player.hull = 100.0
		player.energy = 100.0
		for field in ["skillCooldown", "skillTime", "evade", "dodgeCooldown", "guardTime", "guardCooldown", "lineCooldown", "signatureWindup", "signatureCooldown"]:
			player[field] = 0.0
		player.lineMove = {}
	if lesson == 2:
		p.energy = 25.0
	if lesson == 3:
		p.x = 700.0
		p.y = 180.0
	if lesson == 4:
		q.hp = 30.0
	q.x = 300.0
	q.y = 180.0

func contact(a: Dictionary, b: Dictionary) -> Dictionary:
	var start := Vector2(a.anchor, 585)
	var other := Vector2(b.anchor, 585)
	var r := Vector2(a.x, a.y) - start
	var v := Vector2(b.x, b.y) - other
	var den := r.cross(v)
	var angle := absf(den) / maxf(1, r.length() * v.length())
	if angle < .2:
		return {}
	var d := other - start
	var u := d.cross(v) / den
	var w := d.cross(r) / den
	if u <= .05 or u >= .98 or w <= .05 or w >= .98:
		return {}
	return {"point": start + r * u, "own": u, "enemy": w, "angle": angle,
		"valid": u >= .35 and u <= .95 and w >= .3 and w <= .85, "perfect": w >= .52 and w <= .68}

func _damage(a: Dictionary, c: Dictionary) -> float:
	var clean: bool = c.angle >= .85
	var moving := Vector2(a.vx, a.vy).length() >= 110
	var critical: bool = (c.perfect and clean and moving) or a.counter > 0
	var base := 24.0 if c.perfect else 18.0
	if critical:
		a.counter = 0.0
		return base * 1.75
	return base * (1 + (.2 if clean else 0) - (.2 if c.angle < .45 else 0) + (.15 if moving else 0))

func tick(delta: float, input: Dictionary) -> void:
	if complete:
		return
	var dt := clampf(delta, 0, .05)
	time += dt
	p.hp = 100.0
	if lesson < 4:
		q.hp = 100.0
	q.x = 300.0
	q.y = 180.0
	var old_hits: int = p.hits
	var old_skill: int = p.skillCount
	var had_skill: bool = p.skillTime > 0
	var previous_signature: float = q.signatureCooldown
	var was_guard := exercise == "guard"
	for player in [p, q]:
		for field in ["attackCooldown", "skillCooldown", "skillTime", "guardTime", "guardCooldown", "evade", "dodgeCooldown", "counter", "lineCooldown", "signatureCooldown"]:
			player[field] = maxf(0, player[field] - dt)
	var direction := Vector2(input.get("x", 0), input.get("y", 0)).limit_length()
	var cut: bool = input.get("cut", false)
	var guard: bool = input.get("guard", false)
	if guard and not p.guardHeld and p.lineMove.is_empty() and p.evade <= 0 and p.guardCooldown <= 0:
		p.guardTime = .5
		p.guardCooldown = 20.0
	p.guardHeld = guard
	if input.get("dodge", false) and p.lineMove.is_empty() and p.dodgeCooldown <= 0 and p.energy >= 18:
		p.energy -= 18
		p.evade = .28
		p.dodgeCooldown = 2.2
		p.dodgeDir = direction if direction.length() > 0 else Vector2.UP
		p.dodges += 1
	if input.get("skill", false) and p.guardTime <= 0 and p.lineMove.is_empty() and p.skillCooldown <= 0 and p.energy >= 25:
		p.energy -= 25
		p.skillCooldown = 7.0
		p.skillTime = 2.0
		p.skillCount += 1
	var before := Vector2(p.x, p.y)
	var wind := sin(time / 9) * 12
	q.x += wind * dt
	if p.guardTime > 0:
		direction *= .4
		cut = false
	if p.evade > 0:
		p.x = clampf(p.x + (p.dodgeDir.x * 165 * 3.2 + wind) * dt, 55, 945)
		p.y = clampf(p.y + p.dodgeDir.y * 165 * 3.2 * dt, 70, 480)
	elif p.lineMove.is_empty():
		p.x = clampf(p.x + (direction.x * 165 + wind) * dt, 55, 945)
		p.y = clampf(p.y + direction.y * 165 * dt, 70, 480)
	var maneuver := false
	if input.get("line", false) and p.lineMove.is_empty() and p.lineCooldown <= 0 and p.evade <= 0 and p.guardTime <= 0 and p.energy >= 28:
		p.energy -= 28
		p.lineCooldown = 4.0
		p.lineCount += 1
		p.lineMove = {"elapsed": 0.0, "origin": Vector2(p.x, p.y), "hit": false}
	if not p.lineMove.is_empty():
		p.lineMove.elapsed += dt
		var t: float = clampf(p.lineMove.elapsed / 1.05, 0, 1)
		var offset := 110 * sin(t / .42 * PI / 2) if t < .42 else 110 * cos((t - .42) / .58 * PI / 2)
		p.x = clampf(p.lineMove.origin.x, 55, 945)
		p.y = clampf(p.lineMove.origin.y + offset, 70, 480)
		maneuver = t >= .45 and t < .9 and not p.lineMove.hit
		if t == 1:
			p.lineMove = {}
			p.attackCooldown = maxf(p.attackCooldown, .25)
	if dt > 0:
		p.vx = (p.x - before.x) / dt
		p.vy = (p.y - before.y) / dt
	var strike: bool = cut and p.energy >= 12 and p.evade <= 0 and p.lineMove.is_empty() and p.attackCooldown <= 0
	if strike:
		p.energy -= 12
		p.attackCooldown = .65
	p.energy = clampf(p.energy + (6 if input.get("cut", false) else 18) * dt, 0, 100)
	if strike or maneuver:
		var body: bool = strike and Vector2(p.x, p.y).distance_to(Vector2(q.x, q.y)) <= 48
		var crossed := contact(p, q)
		if body or crossed.get("valid", false):
			var damage := _damage(p, {"angle": 1.0, "perfect": false}) if body else 32.0 if maneuver else _damage(p, crossed)
			if p.skillTime > 0 and not maneuver:
				damage += 8
				p.skillTime = 0.0
			if body:
				q.hull = maxf(0, q.hull - damage)
			else:
				q.hp = maxf(0, q.hp - damage)
			if maneuver and not p.lineMove.is_empty():
				p.lineMove.hit = true
			p.hits += 1
			if q.hp <= 0 or q.hull <= 0:
				p.score += 100
	if lesson == 3:
		skill_activated = skill_activated or p.skillCount > base_skill
		if exercise == "skill" and skill_activated and (had_skill or p.skillTime > 0 or p.skillCount > old_skill) and p.hits > old_hits:
			exercise = "dodge"
			p.energy = 100.0
		if exercise == "dodge" and p.dodges > base_dodge:
			exercise = "line"
			p.energy = 100.0
		if exercise == "line" and p.lineCount > base_line and p.lineMove.is_empty():
			exercise = "guard"
			p.energy = 100.0
			p.x = 620.0
			p.y = 240.0
			q.signatureCooldown = 1.0
			p.guardCooldown = 0.0
			base_blocks = p.blocks
		if exercise == "guard" and was_guard:
			_signature(dt, previous_signature)
		complete = exercise == "guard" and p.blocks > base_blocks
	elif lesson == 0:
		complete = Vector2(p.x, p.y).distance_to(Vector2(700, 180)) < 45
	elif lesson == 1:
		complete = p.hits > base_hits
	elif lesson == 2:
		complete = not input.get("cut", false) and p.energy >= 90
	else:
		complete = p.score > base_score

func _signature(dt: float, previous_cooldown: float) -> void:
	p.hp = 100.0
	p.hull = 100.0
	q.hull = 100.0
	if q.signatureWindup > 0:
		q.signatureWindup = maxf(0, q.signatureWindup - dt)
		if q.signatureWindup <= 0 and Vector2(p.x, p.y).distance_to(q.signatureAim) <= 78:
			if p.guardTime > 0:
				p.blocks += 1
			elif p.evade > 0:
				p.counter = 2.0
			else:
				p.hull = maxf(0, p.hull - 32)
	elif previous_cooldown <= 0:
		q.signatureWindup = 1.65
		q.signatureCooldown = 22.0
		q.signatureAim = Vector2(p.x, p.y)
	elif previous_cooldown > 1.5:
		q.signatureCooldown = maxf(0, 1.5 - dt)
		p.guardCooldown = 0.0
