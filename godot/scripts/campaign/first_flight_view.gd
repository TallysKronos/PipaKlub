extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal continue_lesson
signal leave
const Flight = preload("res://scripts/campaign/first_flight_model.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
var model: RefCounted
var content: Dictionary
var texture_p: Texture2D
var texture_q: Texture2D
var background: Texture2D
var clock := 0.0
var next_button: Button
var hint: Label
var mouse_target := Vector2(-1, -1)
var paused := false
var resume_button: Button
var line_held := false
var footer: VBoxContainer
var lesson_label: Label
var bottom_panel: PanelContainer

func configure(data: Dictionary, lesson: int) -> void:
	content = data
	model = Flight.new(lesson)
	texture_p = load("res://assets/campaign/" + content.practice.rabbito.image)
	texture_q = load("res://assets/campaign/" + content.practice.nozinho.image)
	background = load("res://assets/campaign/rooftop-arena-v1.png")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bottom := VBoxContainer.new()
	footer = bottom
	var panel := PanelContainer.new()
	bottom_panel = panel
	panel.anchor_top = .73
	panel.anchor_right = 1
	panel.anchor_bottom = 1
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_bottom = -12
	panel.theme_type_variation = "PanelContainer"
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bottom)
	lesson_label = Label.new()
	lesson_label.add_theme_font_size_override("font_size", 20)
	bottom.add_child(lesson_label)
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 18)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(hint)
	resume_button = Button.new()
	resume_button.text = "Retomar treino"
	resume_button.visible = false
	resume_button.pressed.connect(func(): paused = false; resume_button.release_focus(); resume_button.hide())
	bottom.add_child(resume_button)
	next_button = Button.new()
	next_button.text = "Continuar"
	next_button.disabled = true
	next_button.custom_minimum_size.y = 50
	next_button.pressed.connect(func(): continue_lesson.emit())
	var row := HBoxContainer.new()
	bottom.add_child(row)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(next_button)
	var exit := Button.new()
	exit.text = "Salvar e voltar ao menu"
	exit.pressed.connect(func(): leave.emit())
	exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(exit)
	Hud.fit_footer(panel, bottom, 208)

func _field_scale() -> float:
	return minf(size.x / 1000, maxf(200, bottom_panel.position.y - 8) / 640) if is_instance_valid(bottom_panel) else minf(size.x / 1000, size.y * .7 / 640)

func _field_offset() -> Vector2:
	return Vector2((size.x - 1000 * _field_scale()) / 2, 0)

func _process(delta: float) -> void:
	if model == null:
		return
	clock += delta
	var direction := Controls.direction()
	if direction.length() < .1 and mouse_target.x >= 0:
		direction = (mouse_target - Vector2(model.p.x, model.p.y)).limit_length()
	var line_now := Controls.held("line")
	if not paused:
		model.tick(delta, {"x": direction.x, "y": direction.y,
		"cut": Controls.held("cut") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
		"skill": Controls.held("skill"), "dodge": Controls.held("dodge"),
		"line": line_now and not line_held, "guard": Controls.held("guard")})
	line_held = line_now
	var lesson: Dictionary = content.lessons[model.lesson]
	lesson_label.text = "Primeiro voo · %d / 5 · %s" % [model.lesson + 1, lesson.title]
	hint.text = lesson.success if model.complete else lesson.hint
	if model.lesson == 3 and not model.complete:
		hint.text += "\n" + {"skill": "%s · Habilidade: acerte Nozinho" % Controls.prompt("skill"), "dodge": "%s · Esquiva" % Controls.prompt("dodge"), "line": "%s · Rebicada" % Controls.prompt("line"), "guard": "%s · Guarda: proteja-se no impacto" % Controls.prompt("guard")}.get(model.exercise, "")
	hint.text = hint.text.replace("WASD / setas", "analógico" if Controls.gamepad else "setas").replace("Espaço", Controls.prompt("cut")).replace("com R", "com " + Controls.prompt("line"))
	next_button.disabled = not model.complete
	next_button.text = "Concluir treino" if model.lesson == 4 else "Próxima lição"
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(resume_button):
		paused = true
		resume_button.show()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var point: Vector2 = (event.position - _field_offset()) / _field_scale()
		if point.y >= 70 and point.y <= 480:
			mouse_target = point

func _draw() -> void:
	if model == null:
		return
	draw_set_transform(_field_offset(), 0, Vector2.ONE * _field_scale())
	draw_texture_rect(background, Rect2(0, 0, 1000, 640), false)
	draw_rect(Rect2(0, 0, 1000, 640), Tokens.alpha(Tokens.TINTA, .12))
	var p: Dictionary = model.p
	var q: Dictionary = model.q
	var crossed: Dictionary = model.contact(p, q)
	draw_line(Vector2(p.anchor, 585), Vector2(p.x, p.y), Tokens.CEU, 3)
	draw_dashed_line(Vector2(q.anchor, 585), Vector2(q.x, q.y), Tokens.RABIOLA, 3, 8)
	if not crossed.is_empty():
		draw_circle(crossed.point, 12, Tokens.FOLHA if crossed.valid else Tokens.PAPEL_2, false, 3)
	if model.lesson == 0:
		draw_circle(Vector2(700, 180), 45, Tokens.CEU, false, 4)
	if q.signatureWindup > 0:
		draw_circle(q.signatureAim, 78, Tokens.alpha(Tokens.RABIOLA, .2))
		draw_arc(q.signatureAim, 78, -PI / 2, -PI / 2 + TAU * (1 - q.signatureWindup / 1.65), 48, Tokens.RABIOLA, 5)
	for index in 2:
		var id := "rabbito" if index == 0 else "nozinho"
		var actor: Dictionary = p if index == 0 else q
		var frames: Array = content.practice[id].frames
		var frame: Dictionary = frames[int(clock * 12) % frames.size()]
		var texture := texture_p if index == 0 else texture_q
		draw_texture_rect_region(texture, Rect2(actor.x - 64, actor.y - 64, 128, 128), Rect2(frame.x, frame.y, frame.w, frame.h))
		if actor.guardTime > 0:
			draw_circle(Vector2(actor.x, actor.y), 56, Tokens.CEU, false, 5)
		var x := 30 if index == 0 else 660
		Hud.stat_card(self, Rect2(x, 20, 310, 92), "Rabbito" if index == 0 else "Nozinho", actor, "dark" if index == 0 else "danger", true)

	draw_set_transform(Vector2.ZERO)

