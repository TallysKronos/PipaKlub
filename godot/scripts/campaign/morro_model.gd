extends "res://scripts/campaign/encounter_model.gd"
const Rules = preload("res://scripts/campaign/morro_rules.gd")
var stage_id := "morro-1"
var actors: Array = []
var round_number := 1
var rounds_to_win := 2
var intermission := 0.0
var round_message := ""
var ai_level := 1

func _init(partner: Dictionary = {}, id: String = "morro-1", progress: Dictionary = {}) -> void:
	super(partner, {"modelId": "basica", "level": 1})
	stage_id = id
	var entry := Rules.stage(id)
	if entry.is_empty(): return
	ai_level = Rules.ai_level(entry, Rules.defaults() if progress.is_empty() else progress)
	rounds_to_win = int(entry.rounds)
	p.merge({"name": "Seu parceiro", "rounds": 0, "out": false, "target": -1, "slot": 0, "style": "", "threatTime": 0.0})
	actors = [p]
	var styles: Array = Rules.content().stories[id].styles
	for index in entry.foes.size():
		var anchor: float = [910, 325][index]
		var rival := _fighter(500 + (anchor - 500) * .8, anchor, stats(1))
		rival.color = entry.foes[index].color
		rival.merge({"name": entry.foes[index].name, "rounds": 0, "out": false, "target": -1, "slot": index + 1, "style": styles[index], "threatTime": 0.0})
		actors.append(rival)
	q = actors[1]
	intro = 3.0
	duration = 60.0

func alive(actor: Dictionary) -> bool:
	return not actor.out and actor.hp > 0 and actor.hull > 0

func rounds_lost() -> int:
	var total := 0
	for rival in actors.slice(1): total += int(rival.rounds)
	return total

func tick(delta: float, input: Dictionary) -> void:
	if not outcome.is_empty(): return
	var dt := clampf(delta, 0, .05)
	time += dt
	if intermission > 0:
		intermission = maxf(0, intermission - dt)
		if intermission == 0: _new_round()
		return
	if intro > 0:
		intro = maxf(0, intro - dt)
		return
	duration = maxf(0, duration - dt)
	var inputs: Array = [input]
	for rival in actors.slice(1): inputs.append(_rival_input(rival, dt) if alive(rival) else {})
	for index in actors.size():
		if alive(actors[index]): _move_fighter(actors[index], inputs[index], dt, sin(time / 9) * 12)
	var hits: Array = []
	if alive(p):
		var closest: Dictionary = {}
		var distance := INF
		for rival in actors.slice(1):
			if alive(rival):
				var d := Vector2(p.x, p.y).distance_to(Vector2(rival.x, rival.y))
				if d < distance:
					distance = d
					closest = rival
		if not closest.is_empty(): _signature_hit(p, closest, dt, input.get("signature", false) and model_id == "rabbito", hits)
	for actor in actors:
		if not alive(actor): continue
		for target in actors:
			if actor.slot != target.slot and alive(target): _strike(actor, target, hits)
	# Collect first, apply second: every rival can hit every other rival on the same tick.
	for hit in hits:
		_apply_hit(hit)
	for actor in actors:
		if actor.hp <= 0 or actor.hull <= 0: actor.out = true
	var survivors := actors.filter(alive)
	if survivors.size() <= 1 or duration <= 0: _finish_round(survivors)

func _finish_round(survivors: Array) -> void:
	survivors.sort_custom(func(a: Dictionary, b: Dictionary): return a.hp > b.hp)
	var winner: Dictionary = survivors[0] if survivors.size() == 1 or (survivors.size() > 1 and survivors[0].hp > survivors[1].hp) else {}
	var broken := actors.any(func(actor: Dictionary): return actor.hull <= 0)
	if not winner.is_empty():
		if broken: winner.rounds = maxi(int(winner.rounds), rounds_to_win - 1)
		winner.rounds += 1
		round_message = "%s venceu a rodada %d" % [winner.name, round_number]
		if winner.rounds >= rounds_to_win: outcome = "won" if winner.slot == 0 else "lost"
	else:
		round_message = "Rodada %d empatada" % round_number
		if survivors.is_empty() and broken: outcome = "lost"
	for actor in actors:
		actor.strike = false
		actor.lineMove = {}
	intermission = 3.2

func _new_round() -> void:
	round_number += 1
	intro = 3.0
	duration = 60.0
	for index in actors.size():
		var old: Dictionary = actors[index]
		var actor := _fighter(500 + (old.anchor - 500) * .8, old.anchor, old.stats)
		for key in ["name", "rounds", "slot", "style", "color", "hull"]: actor[key] = old[key]
		actor.merge({"out": actor.hull <= 0, "target": -1, "threatTime": 0.0})
		actors[index] = actor
	p = actors[0]
	q = actors[1]

func _brain(style: String) -> Dictionary:
	var k := pow((clampi(ai_level, 1, 10) - 1) / 9.0, .75)
	var b := {"focus": .95 - .8 * k, "rest": 1.15 - .95 * k, "speed": .6 + .4 * k, "jitter": .16 * (1 - k), "dodge": clampf((ai_level - 2) / 8.0, 0, 1), "reserve": 24 if ai_level >= 5 else 0, "smart": ai_level >= 3, "weakest": ai_level >= 6, "evade": .04 + .025 * (ai_level - 4) if ai_level >= 4 else 0.0, "sweep": ai_level >= 7, "tip": .88 if ai_level >= 8 else .7}
	match style:
		"patient":
			b.focus *= 1.15
			b.rest *= 1.1
			b.speed *= .95
		"mobile":
			b.speed = minf(1, b.speed + .1)
			b.jitter = minf(.22, b.jitter + .04)
			b.focus *= 1.15
		"guard":
			b.reserve = maxi(b.reserve, 10)
			b.dodge = maxf(b.dodge, .25)
			b.focus *= 1.1
		"reader":
			b.reserve = maxi(b.reserve, 18)
			b.dodge = minf(.9, b.dodge + .1)
			b.focus *= 1.1
	return b

func _hunters(slot: int, self_slot: int) -> int:
	return actors.filter(func(a: Dictionary): return a.slot != 0 and a.slot != self_slot and alive(a) and a.target == slot).size()

func _rival_input(actor: Dictionary, dt: float) -> Dictionary:
	var b := _brain(actor.style)
	var foes := actors.filter(func(a: Dictionary): return a.slot != actor.slot and alive(a))
	if foes.is_empty(): return {}
	foes.sort_custom(func(a: Dictionary, c: Dictionary):
		var ha := _hunters(int(a.slot), int(actor.slot))
		var hc := _hunters(int(c.slot), int(actor.slot))
		if ha != hc: return ha < hc
		var ca: bool = contact(actor, a).get("valid", false)
		var cc: bool = contact(actor, c).get("valid", false)
		if ca != cc: return ca
		if b.weakest and a.hp != c.hp: return a.hp < c.hp
		return Vector2(a.x - actor.x, a.y - actor.y).length_squared() < Vector2(c.x - actor.x, c.y - actor.y).length_squared())
	var target: Dictionary = foes[0]
	actor.target = target.slot
	var fraction: float = .6 + b.jitter * sin(time * 1000 / 650 + actor.slot * 1.7)
	var crossing := Vector2(target.anchor, 585).lerp(Vector2(target.x, target.y), fraction)
	var aim := Vector2(clampf(actor.anchor + (crossing.x - actor.anchor) / b.tip, 55, 945), clampf(585 + (crossing.y - 585) / b.tip, 70, 480))
	var c := contact(actor, target)
	var threat: Dictionary = {}
	for foe in foes:
		var test := contact(foe, actor)
		if test.get("valid", false):
			threat = test
			break
	if b.dodge > 0 and not threat.is_empty() and not c.get("valid", false):
		var escape: Vector2 = (Vector2(actor.x, actor.y) - threat.point).normalized()
		aim = Vector2(actor.x, actor.y) + escape * 120 * b.dodge + (aim - Vector2(actor.x, actor.y)) * (1 - b.dodge)
	actor.botFocus = actor.botFocus + dt if c.get("valid", false) else minf(0, actor.botFocus) + dt
	var pull: bool = c.get("valid", false) and actor.botFocus >= b.focus and (actor.energy >= 12 + b.reserve or target.hp <= 24)
	if pull and actor.attackCooldown <= 0 and actor.energy >= 12: actor.botFocus = -b.rest
	var skill := false
	if not b.smart: skill = pull and actor.energy >= 40
	elif actor.skillCooldown <= 0 and actor.energy >= 25 + b.reserve / 2.0:
		skill = (actor.color == 0 and pull) or (actor.color == 1 and absf(aim.x - actor.x) > 140) or (actor.color == 2 and not threat.is_empty()) or (actor.color == 3 and not c.is_empty() and not c.get("valid", false))
	var hunter: Dictionary = {}
	for foe in foes:
		if b.evade > 0 and foe.strike and foe.energy >= 12 and contact(foe, actor).get("valid", false): hunter = foe
	actor.threatTime = actor.threatTime + dt if not hunter.is_empty() else 0.0
	if not hunter.is_empty() and not c.get("valid", false) and actor.dodgeCooldown <= 0 and actor.energy >= 30 and actor.threatTime >= b.focus * .6 and hunter.attackCooldown <= b.evade:
		var escape: Vector2 = (Vector2(actor.x, actor.y) - contact(hunter, actor).point).normalized()
		return {"x": escape.x, "y": escape.y, "dodge": true}
	if b.sweep and c.get("valid", false):
		var direction := (Vector2(actor.x - actor.anchor, actor.y - 585)).normalized() * (.8 if sin(time * 1000 / 260 + actor.slot) > 0 else -.8)
		return {"x": direction.x, "y": direction.y, "cut": pull, "skill": skill}
	return {"x": clampf((aim.x - actor.x) / 80, -b.speed, b.speed), "y": clampf((aim.y - actor.y) / 80, -b.speed, b.speed), "cut": pull, "skill": skill}

func attack_notice(actor: Dictionary) -> Dictionary:
	var notice := super.attack_notice(actor)
	if is_same(actor,p):return notice
	var brain:=_brain(actor.style)
	var aiming:bool=alive(actor) and actor.target==p.slot and actor.attackCooldown<=0 and (actor.energy>=12+brain.reserve or p.hp<=24) and contact(actor,p).get("valid",false)
	var progress:=clampf(actor.botFocus/brain.focus,0,1)
	return {"active":aiming and progress>.6,"progress":progress}

func snapshot() -> Dictionary:
	var saved := super.snapshot()
	saved.merge({"trailStage": stage_id, "actors": _encode(actors), "roundNumber": round_number, "roundsToWin": rounds_to_win, "intermission": intermission, "roundMessage": round_message, "aiLevel": ai_level})
	return saved

func restore(saved: Dictionary) -> void:
	super.restore(saved)
	stage_id = saved.trailStage
	actors = _decode(saved.actors)
	p = actors[0]
	q = actors[1]
	round_number = int(saved.roundNumber)
	rounds_to_win = int(saved.roundsToWin)
	intermission = saved.intermission
	round_message = saved.roundMessage
	ai_level = int(saved.aiLevel)

