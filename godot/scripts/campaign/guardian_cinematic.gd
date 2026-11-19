extends Control
## Apresentação de guardião em página de mangá, dentro do jogo e determinística.
## A câmera do mapa se aproxima do guardião com tremor; uma página de três quadros
## (retrato, nome, onomatopeia) se abre sobre a cena e se rasga de volta para o mapa.
## Não salva, não dá recompensa e não inicia batalha: quem chama decide o que vem depois.
signal finished
signal cue(event_id: String)
const T = preload("res://scripts/campaign/ui_tokens.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Ink = preload("res://scripts/campaign/battle_ink.gd")

## Linha do tempo (segundos).
const PUSH_START := .35
const PUSH_END := 2.3
const PAGE_IN := 2.45
const PAGE_OUT := 6.35
const DURATION := 8.4

var park: Node2D
var focus := Vector2.ZERO
var title := "Guardião"
var subtitle := ""
var face: Texture2D
var face_region := Rect2()
var sound := "" ## onomatopeia desenhada no terceiro quadro
var accent := T.RABIOLA
var before_text := ""
var after_text := ""
var cry_event := ""
var silhouette := false ## o retrato aparece só em silhueta (trailer, revelações)
var flip_face := false
var reduced_motion := false
var zoom_to := 1.7

var elapsed := 0.0
var done := false
var called: Dictionary = {}
var caption: Label
var skip: Button
var initial_camera := Vector2.ZERO
var initial_zoom := Vector2.ONE
var initial_offset := Vector2.ZERO
var initial_smoothing := true
var initial_hud := true
var initial_map := true
var initial_paused := false

static func duration() -> float:
	return DURATION

## Guardiões com apresentação. Chave = ação do evento no mapa.
const PRESETS := {
	"mormacoStory": {"title": "Mormaço", "subtitle": "O Primeiro Vento", "face": "mormaco-v1/free.png", "sound": "FWOOSH", "accent": "#b978dd", "cry": "creature.mormaco",
		"before": "A água do poço começa a ferver. O vento parado volta de uma vez.", "after": "KAEL   Ele estava aqui o tempo todo… debaixo d'água."},
	"grutaBoss": {"title": "Estratonte", "subtitle": "Guardião da Gruta do Moinho", "face": "planicies-v1/estratonte.png", "sound": "KRRAK", "accent": "#9da9b5", "cry": "creature.estratonte",
		"before": "O lago da gruta treme. Alguma coisa se ergue da ilha.", "after": "KAEL   Ossos de papel… e ele está olhando pra gente."},
	"vulcaoBoss": {"title": "Tricórdio", "subtitle": "Guardião da Cratera", "face": "regioes-v1/tricordio.png", "sound": "FSSSHH", "accent": "#ff5a36", "cry": "creature.tricordio",
		"before": "A lava estala. Três sombras se mexem na borda da cratera.", "after": "KAEL   Três cabeças. Fica perto de mim, parceiro."},
	"abismoBoss": {"title": "Coromar", "subtitle": "Guardião das Quatro Marés", "face": "abismo-v1/coromar.png", "sound": "BLUUSH", "accent": "#34798a", "cry": "creature.coromar",
		"before": "A água em volta do trono começa a girar em quatro correntes.", "after": "KAEL   Ele comanda as correntes. Segura firme na Boia."},
	"geleiraBoss": {"title": "Borealvo", "subtitle": "Guardião da Coroa Glacial", "face": "geleira-v1/borealvo.png", "sound": "KRAAANG", "accent": "#75abb7", "cry": "creature.borealvo",
		"before": "O gelo range. Um martelo se ergue sobre o santuário.", "after": "KAEL   Ninguém passa sem provar a força. Então vamos provar."},
	"eremor": {"title": "Eremor", "subtitle": "O que dormia sob as ruínas", "face": "combat-eremor.png", "region": [0, 0, 350, 313], "sound": "GRRRAOOO", "accent": "#ffc23d", "cry": "creature.eremor",
		"before": "Os pilares cedem. O chão da câmara se abre.", "after": "KAEL   Se ele passar daqui, a região inteira corre perigo."},
}

static func create(id: String, park_view: Node2D, at: Vector2, motion_reduced: bool = false) -> Control:
	var preset: Dictionary = PRESETS.get(id, {})
	if preset.is_empty(): return null
	var shot = load("res://scripts/campaign/guardian_cinematic.gd").new()
	shot.park = park_view
	shot.focus = at
	shot.title = preset.title
	shot.subtitle = preset.subtitle
	shot.face = load("res://assets/campaign/" + str(preset.face))
	if preset.has("region"): shot.face_region = Rect2(preset.region[0], preset.region[1], preset.region[2], preset.region[3])
	shot.sound = preset.sound
	shot.accent = Color(preset.accent)
	shot.cry_event = preset.cry
	shot.before_text = preset.before
	shot.after_text = preset.after
	shot.reduced_motion = motion_reduced
	return shot

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if is_instance_valid(park):
		var camera: Camera2D = park.camera
		initial_camera = camera.position
		initial_zoom = camera.zoom
		initial_offset = camera.offset
		initial_smoothing = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = false
		initial_paused = park.get("paused") == true
		park.set("paused", true)
		if park.get("guardian_focus") != null: park.set("guardian_focus", true)
		if park.get("path") is Array: park.path.clear()
		var hud = park.get("exploration_hud")
		if is_instance_valid(hud):
			initial_hud = hud.visible
			hud.hide()
			if is_instance_valid(hud.get("map")):
				initial_map = hud.map.visible
				hud.map.hide()
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_color_override("font_color", T.PAPEL)
	caption.add_theme_font_override("font", Hud.font())
	add_child(caption)
	skip = Button.new()
	skip.text = "Pular · Esc"
	skip.custom_minimum_size = Vector2(146, 42)
	Hud.navigation_button(skip, true)
	add_child(skip)
	skip.pressed.connect(complete)
	resized.connect(_layout)
	_layout()
	advance(0)

func _layout() -> void:
	var k := minf(size.x / 1280.0, size.y / 720.0)
	caption.position = Vector2(size.x * .08, size.y * .80)
	caption.size = Vector2(size.x * .84, size.y * .12)
	caption.add_theme_font_size_override("font_size", maxi(17, int(23 * k)))
	skip.position = Vector2(size.x - skip.size.x - 24, 16)

func _process(delta: float) -> void:
	advance(delta)

## Avança a apresentação; os testes e a gravação chamam com passos fixos.
func advance(delta: float) -> void:
	if done: return
	elapsed = minf(DURATION, elapsed + delta)
	if is_instance_valid(park):
		var camera: Camera2D = park.camera
		var push := smoothstep(PUSH_START, PUSH_END, elapsed)
		var back := smoothstep(PAGE_OUT + .3, DURATION - .4, elapsed)
		camera.position = initial_camera.lerp(focus, push).lerp(initial_camera, back)
		camera.zoom = initial_zoom if reduced_motion else initial_zoom.lerp(Vector2.ONE * zoom_to, push).lerp(initial_zoom, back)
		var shaking := elapsed > PUSH_START + .4 and elapsed < PUSH_END + .1 and not reduced_motion
		camera.offset = initial_offset + (Vector2(sin(elapsed * 47) * 2.2, cos(elapsed * 39) * 1.4) if shaking else Vector2.ZERO)
	var page := elapsed >= PAGE_IN and elapsed < PAGE_OUT + .35
	caption.visible = not page
	caption.text = before_text if elapsed < PAGE_IN else after_text if elapsed > PAGE_OUT + .35 else ""
	if elapsed >= PUSH_START + .4: _cue("rumble", "world.interact")
	if elapsed >= PAGE_IN: _cue("page", "battle.signature")
	if elapsed >= PAGE_IN + .5 and not cry_event.is_empty(): _cue("cry", cry_event)
	queue_redraw()
	if elapsed >= DURATION: complete()

func _cue(id: String, event_id: String) -> void:
	if called.has(id): return
	called[id] = true
	cue.emit(event_id)

func complete() -> void:
	if done: return
	done = true
	_restore()
	finished.emit()

func _restore() -> void:
	if not is_instance_valid(park) or not is_instance_valid(park.camera): return
	var camera: Camera2D = park.camera
	camera.position = initial_camera
	camera.zoom = initial_zoom
	camera.offset = initial_offset
	camera.position_smoothing_enabled = initial_smoothing
	camera.reset_smoothing()
	park.set("paused", initial_paused)
	if park.get("guardian_focus") != null: park.set("guardian_focus", false)
	if park.get("encounter_grace") != null: park.set("encounter_grace", maxf(float(park.get("encounter_grace")), 6.0))
	var hud = park.get("exploration_hud")
	if is_instance_valid(hud):
		hud.visible = initial_hud
		if is_instance_valid(hud.get("map")): hud.map.visible = initial_map

func _exit_tree() -> void:
	if not done: _restore()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		complete()

## Quanto um quadro já entrou (0 → 1), com atraso próprio e saída comum.
func _panel(delay: float) -> float:
	if reduced_motion: return 1.0 if elapsed >= PAGE_IN and elapsed < PAGE_OUT + .3 else 0.0
	var enter := clampf((elapsed - PAGE_IN - delay) / .22, 0, 1)
	var leave := clampf((elapsed - PAGE_OUT - delay * .5) / .25, 0, 1)
	return ease(enter, .35) * (1.0 - ease(leave, 2.4))

func _draw() -> void:
	var bars := smoothstep(0, .45, elapsed) * (1 - smoothstep(DURATION - .5, DURATION, elapsed))
	var bar := size.y * .1 * bars
	if not caption.text.is_empty():
		draw_rect(Rect2(size.x * .06, size.y * .795, size.x * .88, size.y * .12), Color(T.NANQUIM, .86))
	if elapsed >= PAGE_IN - .12 and elapsed < PAGE_IN + .08 and not reduced_motion:
		draw_rect(Rect2(Vector2.ZERO, size), Color(T.PAPEL, 1 - absf(elapsed - PAGE_IN + .02) / .1))
	if elapsed >= PAGE_IN and elapsed < PAGE_OUT + .6: _draw_page()
	draw_rect(Rect2(0, 0, size.x, bar), T.NANQUIM)
	draw_rect(Rect2(0, size.y - bar, size.x, bar), T.NANQUIM)

func _draw_page() -> void:
	var w := size.x
	var h := size.y
	var k := minf(w / 1280.0, h / 720.0)
	var gutter := 14.0 * k
	var top := h * .1 + gutter
	var bottom := h * .9 - gutter
	var a := _panel(0)
	var b := _panel(.16)
	var c := _panel(.32)
	var page := maxf(a, maxf(b, c))
	# Sarjeta de papel por trás dos quadros.
	draw_rect(Rect2(0, top - gutter, w, bottom - top + gutter * 2), Color(T.PAPEL, page))
	# Quadro A: retrato grande, recorte diagonal à esquerda.
	var split_top := w * .60
	var split_bottom := w * .50
	var poly_a := PackedVector2Array([Vector2(gutter, top), Vector2(split_top - gutter, top), Vector2(split_bottom - gutter, bottom), Vector2(gutter, bottom)])
	var slide_a := Vector2(-(1 - a) * w * .6, 0)
	_panel_fill(poly_a, slide_a, a, T.TINTA)
	if a > 0:
		_speed_lines(poly_a, slide_a, a)
		_halftone(poly_a, slide_a, a, Color(accent, .22))
		if face != null:
			var area := Rect2(Vector2(gutter, top) + slide_a, Vector2(split_top - gutter * 2, bottom - top))
			var grow := 1.0 + (0.0 if reduced_motion else (elapsed - PAGE_IN) * .025)
			var fit := _fit(face_region.size if face_region.has_area() else face.get_size(), area.grow(-18 * k))
			fit = Rect2(fit.get_center() - fit.size * grow / 2, fit.size * grow)
			var tint := Color(0.04, 0.05, 0.08, a) if silhouette else Color(1, 1, 1, a)
			if flip_face: fit = Rect2(fit.position + Vector2(fit.size.x, 0), Vector2(-fit.size.x, fit.size.y))
			if silhouette:
				# Borda de luz: a silhueta precisa se destacar do quadro escuro.
				var rim := Color(accent, .85 * a)
				for d in [Vector2(-5, 0), Vector2(5, 0), Vector2(0, -5), Vector2(0, 5), Vector2(-4, -4), Vector2(4, -4)]:
					var moved := Rect2(fit.position + d * k, fit.size)
					if face_region.has_area(): draw_texture_rect_region(face, moved, face_region, rim)
					else: draw_texture_rect(face, moved, false, rim)
			if face_region.has_area(): draw_texture_rect_region(face, fit, face_region, tint)
			else: draw_texture_rect(face, fit, false, tint)
		_outline(poly_a, slide_a, a)
	# Quadro B: nome e subtítulo, alto à direita.
	var mid := top + (bottom - top) * .56
	var poly_b := PackedVector2Array([Vector2(split_top + gutter, top), Vector2(w - gutter, top), Vector2(w - gutter, mid - gutter / 2), Vector2(split_top - (split_top - split_bottom) * .56 + gutter, mid - gutter / 2)])
	var slide_b := Vector2((1 - b) * w * .5, 0)
	_panel_fill(poly_b, slide_b, b, T.NANQUIM)
	if b > 0:
		_halftone(poly_b, slide_b, b, Color(T.PAPEL, .07))
		var x := split_top + gutter * 3 + slide_b.x
		var font := Hud.lettering()
		var name := "???" if silhouette and title.is_empty() else title.to_upper()
		var size_name := int(clampf(78 * k * 9.0 / maxf(9.0, name.length()), 34 * k, 78 * k))
		var at := Vector2(x, top + (mid - top) * .5)
		draw_string_outline(font, at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, size_name, int(12 * k), Color(T.NANQUIM, b))
		draw_string(font, at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, size_name, Color(T.PAPEL, b))
		if not subtitle.is_empty():
			var plate := Rect2(Vector2(x, at.y + 18 * k), Vector2(w - gutter * 2 - x + slide_b.x, 44 * k))
			Ink.plate(self, plate, Color(T.TINTA, b), Color(accent, b), 10 * k)
			draw_string(Hud.font(true), plate.position + Vector2(18 * k, plate.size.y * .68), subtitle.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, plate.size.x - 30 * k, int(21 * k), Color(T.PAPEL, b))
		_outline(poly_b, slide_b, b)
	# Quadro C: onomatopeia, baixo à direita.
	var poly_c := PackedVector2Array([Vector2(split_top - (split_top - split_bottom) * .56 + gutter, mid + gutter / 2), Vector2(w - gutter, mid + gutter / 2), Vector2(w - gutter, bottom), Vector2(split_bottom + gutter, bottom)])
	var slide_c := Vector2(0, (1 - c) * h * .5)
	_panel_fill(poly_c, slide_c, c, accent.darkened(.35))
	if c > 0:
		_burst(poly_c, slide_c, c)
		var word := sound if not sound.is_empty() else "!!"
		var font := Hud.lettering()
		var center := _center(poly_c) + slide_c
		var shake := Vector2.ZERO if reduced_motion else Vector2(sin(elapsed * 61), cos(elapsed * 53)) * 3 * k
		var word_size := int(clampf(96 * k * 6.0 / maxf(6.0, word.length()), 40 * k, 96 * k))
		var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size).x
		draw_set_transform(center + shake, -.12, Vector2.ONE)
		draw_string_outline(font, Vector2(-width / 2, word_size * .35), word, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size, int(16 * k), Color(T.NANQUIM, c))
		draw_string(font, Vector2(-width / 2, word_size * .35), word, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size, Color(T.SOL, c))
		draw_set_transform(Vector2.ZERO)
		_outline(poly_c, slide_c, c)

func _moved(poly: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly: out.append(p + by)
	return out

func _panel_fill(poly: PackedVector2Array, by: Vector2, amount: float, color: Color) -> void:
	if amount <= 0: return
	draw_colored_polygon(_moved(poly, by), Color(color, amount))

func _outline(poly: PackedVector2Array, by: Vector2, amount: float) -> void:
	var line := _moved(poly, by)
	line.append(line[0])
	draw_polyline(line, Color(T.NANQUIM, amount), 5 * minf(size.x / 1280.0, size.y / 720.0), true)

func _center(poly: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p in poly: sum += p
	return sum / poly.size()

func _bounds(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly: r = r.expand(p)
	return r

## Linhas de velocidade convergindo para o retrato.
func _speed_lines(poly: PackedVector2Array, by: Vector2, amount: float) -> void:
	var r := _bounds(poly)
	var center := r.get_center() + by
	var spin := 0.0 if reduced_motion else elapsed * .35
	for i in 46:
		var angle := TAU * i / 46.0 + spin + sin(i * 12.9898) * .05
		var dir := Vector2.from_angle(angle)
		var inner := r.size.length() * (.30 + .08 * fmod(i * .618, 1.0))
		var outer := r.size.length() * .75
		var start := center + dir * inner
		var end := center + dir * outer
		if Geometry2D.is_point_in_polygon(start - by, poly) or Geometry2D.is_point_in_polygon((start + end) / 2 - by, poly):
			var clip := Geometry2D.clip_polyline_with_polygon(PackedVector2Array([start - by, end - by]), poly)
			for part in clip:
				draw_line(part[0] + by, part[part.size() - 1] + by, Color(T.PAPEL, .16 * amount), 2 + (i % 3), true)

## Retícula de pontos (screentone).
func _halftone(poly: PackedVector2Array, by: Vector2, amount: float, color: Color) -> void:
	var r := _bounds(poly)
	var step := 16.0 * minf(size.x / 1280.0, size.y / 720.0)
	var y := r.position.y + step / 2
	var row := 0
	while y < r.end.y:
		var x := r.position.x + (step / 2 if row % 2 else 0.0)
		var fade := 1.0 - (y - r.position.y) / maxf(1, r.size.y)
		while x < r.end.x:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
				draw_circle(Vector2(x, y) + by, step * .22 * fade + .6, Color(color, color.a * amount))
			x += step
		y += step
		row += 1

## Explosão de raios atrás da onomatopeia.
func _burst(poly: PackedVector2Array, by: Vector2, amount: float) -> void:
	var center := _center(poly) + by
	var r := _bounds(poly).size.length() * .45
	var points := PackedVector2Array()
	for i in 28:
		var angle := TAU * i / 28.0 + (0.0 if reduced_motion else elapsed * .2)
		points.append(center + Vector2.from_angle(angle) * (r if i % 2 == 0 else r * .55))
	var clipped := Geometry2D.intersect_polygons(points, _moved(poly, by))
	for shape in clipped:
		draw_colored_polygon(shape, Color(accent, .9 * amount))

func _fit(source: Vector2, area: Rect2) -> Rect2:
	if source.x <= 0 or source.y <= 0: return area
	var s := minf(area.size.x / source.x, area.size.y / source.y)
	var dim := source * s
	return Rect2(area.position + (area.size - dim) / 2, dim)
