extends Control
signal finished
const LENGTH := 10.5
const TERRACE := preload("res://assets/campaign/evolucoes-v1/ritual-terraco.png")
const RASTRO_IDLE := preload("res://assets/campaign/evolucoes-v1/rastro-dos-ventos-idle.png")
const STAGE_SIZE := Vector2(960, 540)
const ALTAR := Vector2(480, 386)
const GOLD := Color("#ffd53e")
const PINK := Color("#fa51b4")
const BLUE := Color("#69e8ff")
var before: Texture2D
var after: Texture2D
var target_form := ""
var reveal_frames: Array[AtlasTexture] = []
var sound: Node
var elapsed := 0.0
var phase := -1
var done := false
var creature := TextureRect.new()
var silhouette := ShaderMaterial.new()

func _ready() -> void:
	custom_minimum_size = Vector2(320, 260)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	creature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	creature.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	creature.mouse_filter = Control.MOUSE_FILTER_IGNORE
	silhouette.shader = preload("res://shaders/evolution_silhouette.gdshader")
	silhouette.set_shader_parameter("ink", Color("#f5fbff"))
	creature.material = silhouette
	add_child(creature)
	if target_form == "rastro-dos-ventos":
		var frame_width := RASTRO_IDLE.get_width() / 4.0
		for frame_index in 4:
			var frame := AtlasTexture.new()
			frame.atlas = RASTRO_IDLE
			frame.region = Rect2(frame_index * frame_width, 94, frame_width, 500)
			frame.filter_clip = true
			reveal_frames.append(frame)

func skip() -> void:
	if done: return
	done = true
	set_process(false)
	finished.emit()

func _process(delta: float) -> void:
	elapsed += delta
	var stage := 0 if elapsed < 2.0 else 1 if elapsed < 5.0 else 2 if elapsed < 7.8 else 3
	if phase != stage:
		phase = stage
		if is_instance_valid(sound):
			sound.play_event(["workshop.soul_charge", "workshop.knot_pull", "workshop.gust", "workshop.birth"][stage])
	var fit := minf(size.x / STAGE_SIZE.x, size.y / STAGE_SIZE.y)
	var reveal := smoothstep(7.2, 8.05, elapsed)
	var charge := smoothstep(2.0, 5.4, elapsed)
	creature.texture = after if elapsed >= 7.2 else before
	if elapsed >= 7.2 and not reveal_frames.is_empty():
		var frame_index := int((elapsed - 7.2) * 6.0) % reveal_frames.size()
		creature.texture = reveal_frames[frame_index]
	var extent := lerpf(185.0, 230.0, reveal)
	creature.size = Vector2.ONE * extent * fit
	var center := Vector2(480 + sin(elapsed * 33) * charge * (1.0 - reveal) * 4, ALTAR.y - extent * .43 + sin(elapsed * 3) * 5)
	creature.position = (size - STAGE_SIZE * fit) * .5 + center * fit - creature.size * .5
	silhouette.set_shader_parameter("strength", charge * (1.0 - reveal))
	queue_redraw()
	if elapsed >= LENGTH: skip()

func _shape(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _draw() -> void:
	var fit := minf(size.x / STAGE_SIZE.x, size.y / STAGE_SIZE.y)
	draw_set_transform((size - STAGE_SIZE * fit) * .5, 0, Vector2.ONE * fit)
	draw_texture_rect(TERRACE, Rect2(Vector2.ZERO, STAGE_SIZE), false)
	var core := ALTAR
	draw_set_transform((size - STAGE_SIZE * fit) * .5 + core * fit, 0, Vector2(fit, fit * .26))
	for i in 3:
		draw_arc(Vector2.ZERO, 96 + 54 * i, 0, TAU, 64, Color(GOLD if i == 2 else PINK, smoothstep(1.0, 5.5, elapsed) * .7), 4, true)
	draw_set_transform((size - STAGE_SIZE * fit) * .5, 0, Vector2.ONE * fit)
	var buildup := clampf((elapsed - 1.0) / 5.0, 0.0, 1.0)
	var center := core - Vector2(0, 80 + sin(elapsed * 3) * 5)
	var ribbon := PackedVector2Array()
	for i in 52:
		var t := float(i) / 51.0
		var angle := t * TAU * 1.4 + elapsed * 3.0
		ribbon.append(center + Vector2(cos(angle) * (72 + t * 89), sin(angle) * 31 + 105 - 183 * t))
	draw_polyline(ribbon, Color(PINK, buildup * .76), 5, true)
	var line := PackedVector2Array()
	for i in 48:
		var t := float(i) / 47.0
		line.append(Vector2(480 + sin(t * 18 + elapsed * 8) * (6 + buildup * 35) * sin(t * PI), lerpf(127, core.y, t)))
	draw_polyline(line, Color(BLUE, .45 + buildup * .5), 3, true)
	for i in 26:
		var angle := i * TAU / 26 + elapsed * (1.6 + buildup)
		var orbit := Vector2(cos(angle) * (126 + i % 5 * 13), sin(angle) * (42 + i % 7 * 11))
		var point := center + orbit + Vector2(0, sin(elapsed * 2 + i) * 29)
		var color := Color([BLUE, GOLD, PINK][i % 3], .3 + buildup * .65)
		if i % 5 == 0: draw_line(point, point + Vector2.from_angle(angle) * 34, color, 4, true)
		else: _shape([point, point + Vector2(10, -5), point + Vector2(4, 11)], color)
	var flare := maxf(0, 1 - absf(elapsed - 7.15) / .56)
	if flare > 0:
		for i in 12:
			var ray := Vector2.from_angle(i * TAU / 12.0)
			_shape([center, center + ray.rotated(-.035) * 370, center + ray.rotated(.035) * 370], Color(BLUE, flare * .55))

