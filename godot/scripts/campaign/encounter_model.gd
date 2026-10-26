extends "res://scripts/campaign/first_flight_model.gd"
## Single-round local Lacertubo encounter. Contact/costs/armor follow src/engine.js.
## Does not implement online rooms, specialization classes or the six line loadouts.
var outcome := ""
var intro := 6.6
var duration := 120.0
var partner_id := ""
var model_id := "rabbito"
var enemy_model_id := "lacertubo"
var enemy_level := 15
signal damage_applied(event: Dictionary)

func _apply_hit(hit: Dictionary) -> void:
	var target: Dictionary = hit.target
	var field: String = "hull" if hit.body else "hp"
	var previous: float = target[field]
	target[field] = maxf(0, previous - hit.damage)
	var amount: float = previous - target[field]
	if amount > 0:
		damage_applied.emit({"amount": amount, "body": hit.body, "point": Vector2(target.x, target.y), "player": is_same(target, p)})

static func level_for_xp(xp: float) -> int:
	var level := 1
	while level < 50 and xp >= 40 * level + 10 * level * level: level += 1
	return level

static func stats(level: int, bonus: float = 0) -> Dictionary:
	var f := (clampi(level, 1, 50) - 1) / 49.0
	var result := {"line": roundf(100 + 20 * f), "energy": roundf(100 + 15 * f), "attack": 1 + .12 * f, "defense": 1 + .1 * f, "speed": 165 * (1 + .08 * f), "regen": 18 * (1 + .1 * f)}
	for key in result: result[key] = snappedf(result[key] * (1 + clampf(bonus, 0, 12) / 100), .000001)
	return result

func _init(partner: Dictionary = {}, enemy: Dictionary = {}) -> void:
	super(0)
	partner_id = partner.get("id", "")
	model_id = partner.get("modelId", "rabbito")
	p = _fighter(172, 90, stats(level_for_xp(partner.get("xp", 0)), partner.get("craftBonus", 0)))
	q = _fighter(828, 910, {"line": 250.0, "energy": 125.0, "attack": 1.18, "defense": 1.05, "speed": 157.0, "regen": 19.0})
	p.color = {"rabbito": 0, "basica": 0, "mata": 2, "azulao": 3, "raio": 1, "lacertubo": 2}.get(model_id, 0)
	q.color = 2
	q.boss = true
	if not enemy.is_empty():
		enemy_model_id = enemy.modelId
		enemy_level = enemy.level
		q = _fighter(828, 910, stats(enemy_level))
		q.color = {"basica": 0, "mata": 2, "raio": 1}.get(enemy_model_id, 0)
		intro = 3.0
		duration = 60.0
	p.hp *= partner.get("condition", {}).get("line", 100) / 100.0
	p.hull *= partner.get("condition", {}).get("structure", 100) / 100.0

func _fighter(x: float, anchor: float, attributes: Dictionary) -> Dictionary:
	var actor := _player(x, 290, anchor)
	actor.merge({"stats": attributes, "hp": attributes.line, "hull": attributes.line, "energy": attributes.energy, "boss": false,
		"phase": 1, "recovery": 0.0, "charge": 0.0, "telegraph": 0.0, "botFocus": -.4,
		"signatureCooldown": 6.0, "strike": false, "maneuver": false, "lineHeld": false, "signatureHeld": false}, true)
	return actor

func contact(a: Dictionary, b: Dictionary) -> Dictionary:
	var crossing := super.contact(a, b)
	if not crossing.is_empty() and a.color == 3 and a.skillTime > 0:
		crossing.valid = crossing.own >= .35 and crossing.own <= .95 and crossing.enemy >= .15 and crossing.enemy <= .92
	return crossing

func tick(delta: float, input: Dictionary) -> void:
	if not outcome.is_empty(): return
	var dt := clampf(delta, 0, .05)
	time += dt
	if intro > 0:
		intro = maxf(0, intro - dt)
		return
	duration = maxf(0, duration - dt)
	var wind := sin(time / 9) * 12
	_move_fighter(p, input, dt, wind)
	_move_fighter(q, _boss_input(dt) if q.boss else _wild_input(dt), dt, wind)
	var hits: Array = []
	if q.boss: _signature_hit(q, p, dt, true, hits)
	_signature_hit(p, q, dt, input.get("signature", false) and model_id == "rabbito", hits)
	_strike(p, q, hits)
	_strike(q, p, hits)
	for hit in hits:
		_apply_hit(hit)
	if p.hp <= 0 or p.hull <= 0: outcome = "lost"
	elif q.hp <= 0 or q.hull <= 0: outcome = "won"
	elif duration <= 0:
		if not q.boss and q.hp == p.hp:
			# The original starts another round on a tied timeout, preserving hull wear.
			duration = 60.0
			intro = 3.0
			for actor in [p, q]:
				actor.hp = actor.stats.line
				actor.energy = actor.stats.energy
				actor.x = 172.0 if actor == p else 828.0
				actor.y = 290.0
				actor.lineMove = {}
				actor.signatureWindup = 0.0
				actor.skillTime = 0.0
				actor.skillCooldown = 0.0
				actor.attackCooldown = 0.0
				actor.lineCooldown = 0.0
		else: outcome = "lost" if q.boss or q.hp > p.hp else "won"
	complete = not outcome.is_empty()

func _move_fighter(actor: Dictionary, raw: Dictionary, dt: float, wind: float) -> void:
	actor.strike = false
	actor.maneuver = false
	for key in ["attackCooldown", "skillCooldown", "skillTime", "guardTime", "guardCooldown", "evade", "dodgeCooldown", "counter", "lineCooldown"]:
		actor[key] = maxf(0, actor[key] - dt)
	var direction := Vector2(raw.get("x", 0), raw.get("y", 0))
	var cut: bool = raw.get("cut", false)
	var guard: bool = raw.get("guard", false)
	var muted: bool = actor.signatureWindup > 0
	if muted:
		direction *= .2
		cut = false
		guard = false
	if guard and not actor.guardHeld and actor.lineMove.is_empty() and actor.evade <= 0 and actor.guardCooldown <= 0:
		actor.guardTime = .5
		actor.guardCooldown = 20.0
	actor.guardHeld = guard
	if raw.get("dodge", false) and not muted and actor.guardTime <= 0 and actor.lineMove.is_empty() and actor.dodgeCooldown <= 0 and actor.energy >= 18:
		actor.energy -= 18
		actor.evade = .28
		actor.dodgeCooldown = 2.2
		actor.dodgeDir = direction.normalized() if direction.length() > .1 else Vector2.UP
	if raw.get("skill", false) and not muted and actor.guardTime <= 0 and actor.lineMove.is_empty() and actor.skillCooldown <= 0 and actor.energy >= 25:
		actor.energy -= 25
		actor.skillCooldown = 7.0
		actor.skillTime = [2.0, .22, 1.5, 2.5][actor.color]
		if actor.color == 1: actor.x = clampf(actor.x + (-96 if direction.x < 0 else 96), 55, 945)
	var norm := maxf(1, direction.length())
	if actor.guardTime > 0:
		direction *= .4
		cut = false
	var before := Vector2(actor.x, actor.y)
	if actor.evade > 0:
		actor.x = clampf(actor.x + (actor.dodgeDir.x * 165 * 3.2 + wind) * dt, 55, 945)
		actor.y = clampf(actor.y + actor.dodgeDir.y * 165 * 3.2 * dt, 70, 480)
	elif actor.lineMove.is_empty():
		actor.x = clampf(actor.x + (direction.x / norm * actor.stats.speed + wind) * dt, 55, 945)
		actor.y = clampf(actor.y + direction.y / norm * actor.stats.speed * dt, 70, 480)
	var line: bool = raw.get("line", false)
	if line and not actor.lineHeld and not muted and actor.guardTime <= 0 and actor.evade <= 0 and actor.lineMove.is_empty() and actor.lineCooldown <= 0 and actor.energy >= 28:
		actor.energy -= 28
		actor.lineCooldown = 4.0
		actor.lineMove = {"elapsed": 0.0, "origin": Vector2(actor.x, actor.y), "hit": false}
	actor.lineHeld = line
	if not actor.lineMove.is_empty():
		actor.lineMove.elapsed += dt
		var t: float = clampf(actor.lineMove.elapsed / 1.05, 0, 1)
		var offset := 110 * sin(t / .42 * PI / 2) if t < .42 else 110 * cos((t - .42) / .58 * PI / 2)
		actor.x = clampf(actor.lineMove.origin.x, 55, 945)
		actor.y = clampf(actor.lineMove.origin.y + offset, 70, 480)
		actor.maneuver = t >= .45 and t < .9 and not actor.lineMove.hit
		if t >= 1:
			actor.lineMove = {}
			actor.attackCooldown = maxf(actor.attackCooldown, .25)
	if dt > 0:
		actor.vx = (actor.x - before.x) / dt
		actor.vy = (actor.y - before.y) / dt
	if cut and actor.energy >= 12 and actor.evade <= 0 and actor.lineMove.is_empty() and actor.attackCooldown <= 0:
		actor.energy -= 12
		actor.attackCooldown = .65
		actor.strike = true
	actor.energy = clampf(actor.energy + (6 if cut else actor.stats.regen) * dt, 0, actor.stats.energy)

func _boss_input(dt: float) -> Dictionary:
	var phase := 2 if minf(q.hp, q.hull) <= 250 * .55 else 1
	if phase != q.phase:
		q.phase = phase
		q.charge = 0.0
		q.recovery = 1.8
	if q.signatureWindup > 0: return {}
	var k := pow(((7 if phase == 2 else 6) - 1) / 9.0, .75)
	var speed := minf(1, .6 + .4 * k) * .95
	var fraction := .6 + .16 * (1 - k) * sin(time * 1000 / 650 + 1.7)
	var crossing := Vector2(p.anchor, 585).lerp(Vector2(p.x, p.y), fraction)
	var target := Vector2(clampf(q.anchor + (crossing.x - q.anchor) / .7, 55, 945), clampf(585 + (crossing.y - 585) / .7, 70, 480))
	var input := {"x": clampf((target.x - q.x) / 80, -speed, speed), "y": clampf((target.y - q.y) / 80, -speed, speed), "cut": false}
	var own_crossing := contact(q, p)
	var threat := contact(p, q)
	var dodge := clampf(((7 if phase == 2 else 6) - 2) / 8.0, 0, 1)
	if threat.get("valid", false) and not own_crossing.get("valid", false):
		var away: Vector2 = (Vector2(q.x, q.y) - threat.point).normalized()
		target = Vector2(q.x, q.y) + away * 120 * dodge + (target - Vector2(q.x, q.y)) * (1 - dodge)
		input.x = clampf((target.x - q.x) / 80, -speed, speed)
		input.y = clampf((target.y - q.y) / 80, -speed, speed)
	if phase == 2 and own_crossing.get("valid", false):
		var along := (Vector2(q.x, q.y) - Vector2(q.anchor, 585)).normalized() * .8 * (1 if sin(time * 1000 / 260 + 1) > 0 else -1)
		input.x = along.x
		input.y = along.y
	if q.recovery > 0:
		q.recovery = maxf(0, q.recovery - dt)
		q.telegraph = 0.0
		input.x *= .25
		input.y *= .25
		return input
	var duration_value := .8 if phase == 2 else 1.15
	if q.charge > 0 or contact(q, p).get("valid", false):
		q.charge += dt
		q.telegraph = minf(1, q.charge / duration_value)
		if q.telegraph > .6:
			input.x = 0.0
			input.y = 0.0
		if q.charge >= duration_value:
			input.cut = true
			q.charge = 0.0
			q.telegraph = 0.0
			q.recovery = 1.15 if phase == 2 else 1.5
	else: q.telegraph = 0.0
	return input

func _wild_input(dt: float) -> Dictionary:
	# Original wild opponents use ai.level=1, independently of their Pipamon level.
	var fraction := .6 + .16 * sin(time * 1000 / 650 + 1.7)
	var crossing := Vector2(p.anchor, 585).lerp(Vector2(p.x, p.y), fraction)
	var target := Vector2(clampf(q.anchor + (crossing.x - q.anchor) / .7, 55, 945), clampf(585 + (crossing.y - 585) / .7, 70, 480))
	var contact_now := contact(q, p)
	q.botFocus = q.botFocus + dt if contact_now.get("valid", false) else minf(0, q.botFocus) + dt
	var pull: bool = contact_now.get("valid", false) and q.botFocus >= .95 and q.energy >= 12
	if pull and q.attackCooldown <= 0: q.botFocus = -1.15
	return {"x": clampf((target.x - q.x) / 80, -.6, .6), "y": clampf((target.y - q.y) / 80, -.6, .6), "cut": pull, "skill": pull and q.energy >= 40}

func _signature_hit(actor: Dictionary, target: Dictionary, dt: float, wants: bool, hits: Array) -> void:
	actor.signatureCooldown = maxf(0, actor.signatureCooldown - dt)
	var radius := 95 if actor.boss else 85
	if actor.signatureWindup > 0:
		actor.signatureWindup = maxf(0, actor.signatureWindup - dt)
		if actor.signatureWindup > 0: return
		actor.attackCooldown = maxf(.65, actor.attackCooldown)
		if actor.boss: actor.recovery = 2.2
		if Vector2(target.x, target.y).distance_to(actor.signatureAim) > radius: return
		if target.guardTime > 0:
			target.blocks += 1
			return
		if target.evade > 0:
			target.counter = 2.0
			return
		hits.append({"target": target, "body": true, "damage": (44 if actor.boss else 38) * actor.stats.attack / target.stats.defense})
		return
	var edge: bool = wants and (actor.boss or not actor.signatureHeld)
	actor.signatureHeld = wants
	var cost := 0 if actor.boss else 40
	if not edge or actor.signatureCooldown > 0 or actor.energy < cost or actor.guardTime > 0 or actor.evade > 0 or not actor.lineMove.is_empty(): return
	if Vector2(actor.x, actor.y).distance_to(Vector2(target.x, target.y)) > 440: return
	actor.energy -= cost
	actor.signatureCooldown = 20.0 if actor.boss else 24.0
	actor.signatureWindup = 1.5 if actor.boss else 1.4
	actor.signatureAim = Vector2(target.x, target.y)
	actor.strike = false
	actor.maneuver = false
	if actor.boss:
		actor.charge = 0.0
		actor.telegraph = 0.0
		actor.recovery = 0.0

func _strike(actor: Dictionary, target: Dictionary, hits: Array) -> void:
	if not actor.strike and not actor.maneuver: return
	var body: bool = actor.strike and Vector2(actor.x, actor.y).distance_to(Vector2(target.x, target.y)) <= (42 if actor.boss else 24) + (42 if target.boss else 24)
	var crossing := contact(actor, target)
	if not body and not crossing.get("valid", false): return
	var maneuver: bool = not body and actor.maneuver
	if maneuver and not actor.lineMove.is_empty(): actor.lineMove.hit = true
	if body and target.guardTime > 0:
		target.blocks += 1
		return
	if target.evade > 0:
		target.energy = minf(target.stats.energy, target.energy + 18)
		target.counter = 2.0
		return
	var damage := 32.0 if maneuver else _damage(actor, {"angle": 1.0, "perfect": false} if body else crossing)
	if maneuver: actor.counter = 0.0
	if not maneuver and actor.color == 0 and actor.skillTime > 0:
		damage += 8
		actor.skillTime = 0.0
	if target.color == 2 and target.skillTime > 0: damage *= .4
	damage *= actor.stats.attack / target.stats.defense
	if actor.boss and actor.phase == 2: damage *= 1.12
	if target.boss: damage *= 1.2 if target.recovery > 0 else .18
	hits.append({"target": target, "body": body, "damage": damage})

func snapshot() -> Dictionary:
	return _encode({"p": p, "q": q, "time": time, "intro": intro, "duration": duration, "outcome": outcome, "partnerId": partner_id, "modelId": model_id, "enemyModelId": enemy_model_id, "enemyLevel": enemy_level})

func restore(saved: Dictionary) -> void:
	var decoded: Dictionary = _decode(saved)
	p = decoded.p
	q = decoded.q
	time = decoded.time
	intro = decoded.intro
	duration = decoded.duration
	outcome = decoded.outcome
	partner_id = decoded.partnerId
	model_id = decoded.modelId
	enemy_model_id = decoded.get("enemyModelId", "lacertubo")
	enemy_level = decoded.get("enemyLevel", 15)

static func _encode(value: Variant) -> Variant:
	if value is Vector2: return {"vector": [value.x, value.y]}
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = _encode(value[key])
		return result
	if value is Array: return value.map(_encode)
	return value

static func _decode(value: Variant) -> Variant:
	if value is Dictionary:
		if value.size() == 1 and value.has("vector"): return Vector2(value.vector[0], value.vector[1])
		var result := {}
		for key in value: result[key] = _decode(value[key])
		return result
	if value is Array: return value.map(_decode)
	return value
