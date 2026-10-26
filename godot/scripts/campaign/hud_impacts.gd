extends RefCounted
## Presentation only. Events contain confirmed damage, never speculative input.
const Hud = preload("res://scripts/campaign/hud.gd")
var bursts: Array[Dictionary] = []
var lettering: Font = load("res://assets/campaign/ui-modern/fonts/Bangers-Regular.ttf")
var reduced_motion := false

func add(event: Dictionary) -> void:
	if event.get("amount", 0) <= 0: return
	var burst := event.duplicate()
	burst.age = 0.0
	bursts.append(burst)
	if bursts.size() > 10: bursts.pop_front()

func step(delta: float) -> void:
	if bursts.is_empty(): return
	for burst in bursts: burst.age += delta
	bursts = bursts.filter(func(burst: Dictionary): return burst.age < .65)

func draw_on(canvas: CanvasItem, projector: Callable = Callable()) -> void:
	for burst in bursts:
		var age: float = burst.age
		var alpha := clampf((.65 - age) / .18, 0, 1)
		var color := Color(Hud.CORAL if burst.player else Hud.CYAN, alpha)
		var point: Vector2 = burst.point
		if projector.is_valid(): point = projector.call(point)
		else:
			point.x = clampf(point.x, 75, 925)
			point.y = clampf(point.y, 148, 450)
		if not reduced_motion: point.y -= 22 * minf(1, age / .5)
		var number := "−%.1f" % burst.amount if burst.amount < 1 else "−%d" % roundi(burst.amount)
		var width := Hud.font(true).get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
		var baseline := point + Vector2(-width / 2, -28)
		canvas.draw_string_outline(Hud.font(true), baseline, number, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, 5, Color(Hud.BLACK, alpha))
		canvas.draw_string(Hud.font(true), baseline, number, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(Hud.PAPER, alpha))
		if burst.amount < 8 or age > .25: continue
		var word := "TOC!" if burst.body else "TCHAC!"
		var text_width := lettering.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 29).x
		var label_point := point + Vector2(-text_width / 2, 35)
		canvas.draw_string_outline(lettering, label_point, word, HORIZONTAL_ALIGNMENT_LEFT, -1, 29, 6, Color(Hud.BLACK, alpha))
		canvas.draw_string(lettering, label_point, word, HORIZONTAL_ALIGNMENT_LEFT, -1, 29, color)
		if not reduced_motion:
			for index in 6:
				var angle := TAU * index / 6.0 + .23
				var direction := Vector2(cos(angle), sin(angle))
				canvas.draw_line(point + direction * 45, point + direction * (58 + 35 * age), color, 2, true)
