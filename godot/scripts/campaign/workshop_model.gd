extends RefCounted
## Native port of tools/oficina-v3/model.mjs. All time comes from the caller.
const CENTER := Vector2(480, 286)
const FLIGHT_TIME := 9.0
const ZONE := 12.0
const FALL := 46.0
const GUST := 1.4
const CLASSES := {
	"comum": {"rods": 4, "snap": 48, "wobble": 0, "ringSpeed": .5, "ringWidth": .16, "cutTol": 18, "cutTarget": 14, "tear": .022, "gusts": 4, "power": [.8, 1.05], "tell": 1, "soulSpeed": .3},
	"incomum": {"rods": 5, "snap": 42, "wobble": 10, "ringSpeed": .62, "ringWidth": .12, "cutTol": 15, "cutTarget": 12, "tear": .028, "gusts": 5, "power": [.95, 1.25], "tell": .8, "soulSpeed": .36},
	"raro": {"rods": 6, "snap": 36, "wobble": 18, "ringSpeed": .75, "ringWidth": .09, "cutTol": 12, "cutTarget": 10, "tear": .034, "gusts": 6, "power": [1.1, 1.45], "tell": .62, "soulSpeed": .42}}
var run: Dictionary

class Sequence:
	var value: int
	func _init(seed_value: int) -> void:
		value = seed_value & 0xffffffff
		if value == 0:
			value = 1
	func next_value() -> float:
		value = (value + 0x6d2b79f5) & 0xffffffff
		var t := ((value ^ (value >> 15)) * (value | 1)) & 0xffffffff
		t = (t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & 0xffffffff)) & 0xffffffff)) & 0xffffffff
		return float((t ^ (t >> 14)) & 0xffffffff) / 4294967296.0

func _init(kind: String = "comum", seed_value: int = 7) -> void:
	run = {"kind": kind if CLASSES.has(kind) else "comum", "seed": seed_value & 0xffffffff,
		"stage": 0, "materials": {"linha": 3, "folha": 2}, "grades": [], "log": [],
		"blocked": "", "outcome": {}, "knotSequence": 0, "elapsed": [0.0, 0.0, 0.0, 0.0, 0.0],
		"active": [false, false, false, false, false], "errors": [0, 0, 0, 0, 0], "clock": 0.0, "artesao": false}
	# Production protocol v3 disables variant rolls; keep the same policy here.
	run.variantRoll = 1.0
	_start_stage()

func geometry() -> Dictionary:
	var points: Array[Vector2] = []
	var rods: Array[Vector2] = []
	var path: Array[Vector2] = []
	var samples: Array[Vector2] = []
	var count: int = CLASSES[run.kind].rods
	for i in count:
		var angle := -PI / 2 + i * TAU / count
		var radius := 128.0 if run.kind == "raro" and i % 2 else 176.0
		var p := CENTER + Vector2.from_angle(angle) * radius
		points.append(p)
		rods.append((p + CENTER) / 2)
		path.append(p + (p - CENTER).normalized() * 16)
	for i in count:
		var p := path[i]
		var q := path[(i + 1) % count]
		var steps := ceili(p.distance_to(q) / 8)
		for j in steps:
			samples.append(p.lerp(q, float(j) / steps))
	return {"points": points, "rods": rods, "path": path, "samples": samples}

func _window() -> Array:
	run.knotSequence += 1
	var random := Sequence.new((int(run.seed) ^ ((int(run.knotSequence) * 0x45d9f3b) & 0xffffffff)) & 0xffffffff)
	var width: float = CLASSES[run.kind].ringWidth
	var start := .22 + random.next_value() * (.86 - width - .22)
	return [start, start + width]

func _wind_schedule() -> Array:
	var config: Dictionary = CLASSES[run.kind]
	var random := Sequence.new((int(run.seed) + run.log.size()) * 31 + str(run.kind).length())
	var gusts: Array = []
	var time := 1.1
	for i in int(config.gusts):
		var direction := -1 if random.next_value() < .5 else 1
		var power: float = config.power[0] + random.next_value() * (config.power[1] - config.power[0])
		if time < FLIGHT_TIME - .6:
			gusts.append({"t": time, "dir": direction, "power": power})
		time += (FLIGHT_TIME - 1.6) / config.gusts * (.75 + random.next_value() * .4)
	return gusts

func _start_stage() -> void:
	match int(run.stage):
		0: run.step = {"placed": [], "scores": []}
		1:
			var windows: Array = []
			for i in int(CLASSES[run.kind].rods):
				windows.append(_window())
			run.step = {"tied": [], "scores": [], "holding": -1, "fill": 0.0, "windows": windows}
		2: run.step = {"covered": [], "tear": 0.0, "sumD": 0.0, "nD": 0, "time": 0.0, "samples": geometry().samples.size()}
		3: run.step = {"t": 0.0, "theta": 0.0, "omega": 0.0, "inZone": 0.0, "gusts": _wind_schedule()}
		4: run.step = {"fill": 0.0, "holding": false}

func _average(values: Array) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / maxf(1, values.size())

func _finish(grade: float) -> void:
	run.grades.append(clampf(grade + (.06 if run.artesao else 0), 0, 1))
	run.stage += 1
	if run.stage < 5:
		_start_stage()

func _lose(material: String, message: String) -> Dictionary:
	run.errors[run.stage] += 1
	run.materials[material] -= 1
	run.log.append({"stage": run.stage, "lost": material})
	if run.materials[material] <= 0:
		run.blocked = material
	return {"ok": false, "message": message}

func place_rod(p: Vector2) -> Dictionary:
	if run.stage != 0 or not run.blocked.is_empty():
		return {"ok": false}
	run.active[0] = true
	var config: Dictionary = CLASSES[run.kind]
	var rods: Array = geometry().rods
	var best := -1
	var distance := INF
	for i in rods.size():
		if i not in run.step.placed and p.distance_to(rods[i]) < distance:
			best = i
			distance = p.distance_to(rods[i])
	var angle_error: float = config.wobble * sin(run.clock * 3.1)
	if best < 0 or distance > config.snap or absf(angle_error) > 14:
		run.errors[0] += 1
		return {"ok": false, "message": "Solte a vareta perto do apoio, quando estiver alinhada."}
	run.step.placed.append(best)
	run.step.scores.append(clampf(1 - distance / config.snap * .35 - absf(angle_error) / 14 * .45, 0, 1))
	if run.step.placed.size() == config.rods:
		_finish(_average(run.step.scores))
	return {"ok": true}

func hold_knot(index: int) -> void:
	if run.stage != 1 or not run.blocked.is_empty() or index in run.step.tied or index < 0 or index >= run.step.windows.size():
		return
	run.active[1] = true
	run.step.holding = index
	run.step.fill = 0.0

func release_knot() -> Dictionary:
	if run.stage != 1 or run.step.holding < 0:
		return {"ok": false}
	var index: int = run.step.holding
	var window: Array = run.step.windows[index]
	var fill: float = run.step.fill
	run.step.holding = -1
	run.step.fill = 0.0
	if fill < window[0]:
		run.errors[1] += 1
		run.step.windows[index] = _window()
		return {"ok": false, "message": "Frouxo. Tente acertar a nova faixa verde."}
	if fill > window[1]:
		run.step.windows[index] = _window()
		return _lose("linha", "Apertou demais e a linha arrebentou.")
	run.step.tied.append(index)
	run.step.scores.append(clampf(1 - absf(fill - (window[0] + window[1]) / 2) / ((window[1] - window[0]) / 2) * .5, 0, 1))
	if run.step.tied.size() == CLASSES[run.kind].rods:
		_finish(_average(run.step.scores))
	return {"ok": true}

func cut_at(p: Vector2, dt: float) -> Dictionary:
	if run.stage != 2 or not run.blocked.is_empty():
		return {}
	run.active[2] = true
	var config: Dictionary = CLASSES[run.kind]
	var g := geometry()
	var distance := INF
	for i in g.path.size():
		distance = minf(distance, p.distance_to(Geometry2D.get_closest_point_to_segment(p, g.path[i], g.path[(i + 1) % g.path.size()])))
	run.step.time += dt
	if distance <= config.cutTol:
		for i in g.samples.size():
			if p.distance_to(g.samples[i]) <= config.cutTol * 1.3 and i not in run.step.covered:
				run.step.covered.append(i)
		run.step.sumD += distance
		run.step.nD += 1
	elif Geometry2D.is_point_in_polygon(p, PackedVector2Array(g.path)):
		run.step.tear += config.tear * minf(3, distance / config.cutTol)
		if run.step.tear >= 1:
			_start_stage()
			return _lose("folha", "A vela rasgou. Pegue outra folha.")
		return {"message": "Cuidado: o corte entrou na vela."}
	if float(run.step.covered.size()) / g.samples.size() >= .95:
		var accuracy: float = 1 - run.step.sumD / run.step.nD / config.cutTol if run.step.nD else 0.0
		var speed: float = clampf(config.cutTarget / maxf(1, run.step.time), 0, 1)
		_finish(clampf(.65 * accuracy + .35 * speed - run.step.tear * .35, 0, 1))
	return {}

func hold_soul() -> void:
	if run.stage == 4 and run.outcome.is_empty():
		run.step.holding = true
		run.step.fill = 0.0

func release_soul() -> Dictionary:
	if run.stage != 4 or not run.step.holding:
		return {}
	run.step.holding = false
	var fill: float = run.step.fill
	run.step.fill = 0.0
	if fill < .4:
		return {"message": "O elo não pegou. Segure mais tempo."}
	_settle(fill)
	return {}

func tick(delta: float, control: float = 0) -> Dictionary:
	var dt := clampf(delta, 0, .05)
	run.clock += dt
	if run.stage >= 5 or not run.blocked.is_empty():
		return {}
	if run.stage < 4 and run.active[run.stage]:
		run.elapsed[run.stage] += dt
	var config: Dictionary = CLASSES[run.kind]
	var s: Dictionary = run.step
	if run.stage == 1 and s.holding >= 0:
		s.fill += config.ringSpeed * dt * (.55 + s.fill)
		if s.fill >= 1:
			s.windows[s.holding] = _window()
			s.holding = -1
			s.fill = 0.0
			return _lose("linha", "A linha arrebentou: soltou tarde.")
	elif run.stage == 3:
		run.active[3] = true
		var force := 0.0
		for gust in s.gusts:
			var k: float = s.t - gust.t
			if k >= 0 and k < GUST:
				force += gust.dir * gust.power * sin(PI * k / GUST)
		s.omega += (150 * force + 110 * clampf(control, -1, 1) - 3.2 * s.omega - 4.2 * s.theta) * dt
		s.theta += s.omega * dt
		s.t += dt
		if absf(s.theta) < ZONE:
			s.inZone += dt
		if absf(s.theta) > FALL:
			_start_stage()
			return _lose("linha", "A pipa caiu e a linha enroscou.")
		if s.t >= FLIGHT_TIME:
			_finish(clampf(s.inZone / FLIGHT_TIME * 1.08, 0, 1))
	elif run.stage == 4 and s.holding:
		s.fill = (s.fill + 1.0 / 3) * exp(config.soulSpeed * 1.5 * dt) - 1.0 / 3
		if s.fill >= 1:
			s.holding = false
			_settle(1)
	return {}

func quality() -> Dictionary:
	if run.grades.is_empty():
		return {"precision": 0.0, "speed": 0.0, "quality": 0.0, "errors": 0, "seconds": 0.0}
	var c: Dictionary = CLASSES[run.kind]
	var targets := [c.rods * 3, c.rods * 2.2, c.cutTarget, FLIGHT_TIME]
	var speed: Array = []
	var grades: Array = run.grades.slice(0, 4)
	var errors := 0
	var seconds := 0.0
	for i in 4:
		errors += run.errors[i]
		seconds += run.elapsed[i]
		if i < grades.size() and i != 3:
			speed.append(clampf(targets[i] / maxf(targets[i], run.elapsed[i]), 0, 1))
	var precision := _average(grades)
	var speed_score := _average(speed)
	return {"precision": precision, "speed": speed_score, "quality": clampf(precision * .75 + speed_score * .25 - minf(.4, errors * .025), 0, 1), "errors": errors, "seconds": seconds}

func _settle(fill: float) -> void:
	var detail := quality()
	var q: float = detail.quality
	var stars := 5 if q >= .9 else 4 if q >= .78 else 3 if q >= .62 else 2 if q >= .45 else 1
	if fill >= .92:
		run.outcome = {"type": "broken", "stars": stars, "message": "O elo partiu. A rabiola precisa ser restaurada."}
	else:
		var assembly := floorf(q * 80 + .5) / 10
		var elo := 4 if fill >= .86 else 0
		detail.merge({"assemblyPercent": assembly, "eloPercent": elo, "totalPercent": floor((assembly + elo) * 10 + .5) / 10, "multiplier": 1 + (assembly + elo) / 100})
		run.outcome = {"type": "born", "shine": fill >= .86, "variant": false, "stars": stars, "craftBonus": detail}
	run.stage = 5

