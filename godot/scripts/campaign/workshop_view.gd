extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal progress_changed(state: Dictionary)
signal finished(outcome: Dictionary)
signal leave_requested
const Hud = preload("res://scripts/campaign/hud.gd")
const Workshop = preload("res://scripts/campaign/workshop_model.gd")
const TITLES := ["Armação · arraste uma vareta até cada apoio", "Nós · segure um nó e solte na faixa verde", "Papel · recorte seguindo o pontilhado", "Voo · use A/D ou as setas para equilibrar", "Despertar · segure o elo e solte antes do excesso de brilho"]
var model: RefCounted
var dragging_rod := false
var cutting := false
var paused := false
var storage_blocked := false
var cursor := Vector2.ZERO
var pointer := Vector2.ZERO
var held_key := -1
var last_stage := -1
var sent_outcome := false
var help: Label
var resume_button: Button
var restock_button: Button
var background: Texture2D
var bottom_panel: PanelContainer
var pause_button: Button

func configure(kind: String, seed_value: int, state: Dictionary = {}) -> void:
	model = Workshop.new(kind, seed_value)
	if not state.is_empty():
		model.run = state.duplicate(true)
		if model.run.stage == 1:
			model.run.step.holding = -1
		if model.run.stage == 4:
			model.run.step.holding = false
	last_stage = model.run.stage

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background = load("res://assets/campaign/workshop-background.png")
	bottom_panel = PanelContainer.new()
	bottom_panel.anchor_right = 1
	bottom_panel.anchor_bottom = 1
	bottom_panel.offset_left = 24
	bottom_panel.offset_right = -24
	bottom_panel.offset_bottom = -16
	bottom_panel.theme_type_variation = "PanelContainer"
	add_child(bottom_panel)
	var bottom := VBoxContainer.new()
	bottom_panel.add_child(bottom)
	help = Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size.y = 55
	bottom.add_child(help)
	var actions := HBoxContainer.new()
	bottom.add_child(actions)
	resume_button = Button.new()
	resume_button.text = "Retomar a montagem"
	resume_button.visible = false
	resume_button.pressed.connect(func():
		if storage_blocked:
			progress_changed.emit(model.run.duplicate(true))
		if not storage_blocked:
			paused = false
			resume_button.hide())
	actions.add_child(resume_button)
	restock_button = Button.new()
	restock_button.text = "Buscar materiais"
	restock_button.visible = false
	restock_button.pressed.connect(_restock)
	actions.add_child(restock_button)
	pause_button = Button.new()
	pause_button.text = "Pausar"
	pause_button.pressed.connect(_pause)
	actions.add_child(pause_button)
	var back := Button.new()
	back.text = "Sair da bancada"
	back.pressed.connect(func(): _pause(); leave_requested.emit())
	actions.add_child(back)
	for button in [resume_button, restock_button, pause_button, back]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 56
	Hud.secondary_button(back)
	Hud.secondary_button(pause_button)
	Hud.fit_footer(bottom_panel, bottom, 110)

func _scale() -> float:
	return minf(size.x / 960, maxf(200, bottom_panel.position.y - 8) / 640) if is_instance_valid(bottom_panel) else minf(size.x / 960, size.y * .7 / 640)

func _offset() -> Vector2:
	return Vector2((size.x - 960 * _scale()) / 2, 0)

func _gui_input(event: InputEvent) -> void:
	if model == null or paused or not model.run.outcome.is_empty():
		return
	if event is InputEventMouse:
		cursor = (event.position - _offset()) / _scale()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var stage: int = model.run.stage
		if event.pressed:
			if cursor.y > 640:
				return
			match stage:
				0: dragging_rod = Rect2(760, 150, 180, 350).has_point(cursor)
				1:
					var points: Array = model.geometry().points
					for i in points.size():
						if cursor.distance_to(points[i]) <= 40:
							model.hold_knot(i)
							break
				2: cutting = true
				4:
					if cursor.distance_to(Workshop.CENTER) < 160:
						model.hold_soul()
		else:
			match stage:
				0:
					if dragging_rod:
						_feedback(model.place_rod(cursor))
				1: _feedback(model.release_knot())
				4: _feedback(model.release_soul())
			dragging_rod = false
			cutting = false
			_checkpoint_if_needed()

func _feedback(result: Dictionary) -> void:
	if result.has("message"):
		help.text = result.message

func _checkpoint_if_needed() -> void:
	if last_stage != model.run.stage:
		last_stage = model.run.stage
		help.text = ""
		progress_changed.emit(model.run.duplicate(true))
	if not model.run.outcome.is_empty() and not sent_outcome and not storage_blocked:
		sent_outcome = true
		finished.emit(model.run.outcome.duplicate(true))

func _process(delta: float) -> void:
	if model == null:
		return
	if not paused:
		var axis := Controls.direction().x
		_feedback(model.tick(delta, axis))
		if cutting and model.run.stage == 2:
			_feedback(model.cut_at(cursor, minf(delta, .05)))
		_checkpoint_if_needed()
	restock_button.visible = not str(model.run.blocked).is_empty()
	pause_button.visible = not paused
	help.visible = not help.text.is_empty()
	queue_redraw()

func _restock() -> void:
	# Same restock operation as the v3 protocol, only when resources are blocked.
	if str(model.run.blocked).is_empty():
		return
	model.run.materials.linha = maxi(model.run.materials.linha, 2)
	model.run.materials.folha = maxi(model.run.materials.folha, 1)
	model.run.blocked = ""
	model._start_stage()
	progress_changed.emit(model.run.duplicate(true))

func _pause() -> void:
	paused = true
	dragging_rod = false
	cutting = false
	if model.run.stage == 1:
		model.run.step.holding = -1
	if model.run.stage == 4:
		model.run.step.holding = false
	resume_button.show()
	pause_button.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(resume_button):
		_pause()

func _draw() -> void:
	if model == null or background == null:
		return
	draw_set_transform(_offset(), 0, Vector2.ONE * _scale())
	draw_texture_rect(background, Rect2(0, 0, 960, 640), false)
	draw_style_box(Hud.panel(), Rect2(30, 20, 900, 62))
	var index: int = mini(model.run.stage, 4)
	draw_string(Hud.font(), Vector2(46, 48), TITLES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Hud.PAPER)
	draw_string(Hud.font(), Vector2(46, 72), "Linha: %d · Papel: %d" % [model.run.materials.linha, model.run.materials.folha], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Hud.PAPER)
	var g: Dictionary = model.geometry()
	var points := PackedVector2Array(g.points)
	if model.run.stage >= 2:
		draw_colored_polygon(points, Color("f4db9c"))
	for i in points.size():
		var point := points[i]
		var installed: bool = model.run.stage > 0 or i in model.run.step.get("placed", [])
		if installed:
			draw_line(Workshop.CENTER, point, Color("8b572b"), 8)
			draw_line(Workshop.CENTER, point, Color("e7b86b"), 3)
		else:
			draw_dashed_line(Workshop.CENTER, point, Tokens.PAPEL_2, 3, 8)
	if model.run.stage == 0:
		draw_rect(Rect2(760, 150, 180, 350), Color("604628"))
		for i in int(Workshop.CLASSES[model.run.kind].rods):
			draw_line(Vector2(790 + i * 24, 190), Vector2(800 + i * 24, 450), Color("e7b86b"), 8)
		if dragging_rod:
			draw_line(cursor - Vector2(0, 80), cursor + Vector2(0, 80), Color("f8d58e"), 8)
	elif model.run.stage == 1:
		for i in points.size():
			draw_circle(points[i], 22, Tokens.FOLHA if i in model.run.step.tied else Tokens.PAPEL_2, false, 5)
		if model.run.step.holding >= 0:
			var band: Array = model.run.step.windows[model.run.step.holding]
			_meter(model.run.step.fill, band[0], band[1])
	elif model.run.stage == 2:
		for i in g.samples.size():
			draw_circle(g.samples[i], 3, Tokens.FOLHA if i in model.run.step.covered else Tokens.TINTA_3)
		_meter(model.run.step.tear, 0, .8)
	elif model.run.stage == 3:
		var tilt: float = model.run.step.theta
		draw_line(Vector2(480, 460), Vector2(480, 460) + Vector2(sin(deg_to_rad(tilt)), -cos(deg_to_rad(tilt))) * 230, Tokens.CEU, 6)
		_meter(absf(tilt) / Workshop.FALL, 0, Workshop.ZONE / Workshop.FALL)
		draw_style_box(Hud.panel(), Rect2(360, 527, 290, 52))
		draw_string(Hud.font(), Vector2(390, 560), "%.1f / 9 s" % model.run.step.t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Hud.PAPER)
		for gust in model.run.step.gusts:
			if gust.t > model.run.step.t and gust.t - model.run.step.t <= Workshop.CLASSES[model.run.kind].tell:
				draw_style_box(Hud.panel("paper"), Rect2(355, 73, 300, 58))
				draw_string(Hud.font(), Vector2(390, 110), "Rajada →" if gust.dir > 0 else "← Rajada", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Hud.INK)
				break
	elif model.run.stage == 4:
		draw_circle(Workshop.CENTER, 84, Tokens.TINTA_2)
		draw_string(Hud.font(), Workshop.CENTER + Vector2(-75, 8), "Segure o elo", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Tokens.PAPEL)
		_meter(model.run.step.fill, .4, .92)
	draw_set_transform(Vector2.ZERO)

func _meter(fill: float, start: float, end: float) -> void:
	draw_rect(Rect2(270, 585, 420, 24), Hud.TRACK)
	draw_rect(Rect2(270 + 420 * start, 585, 420 * (end - start), 24), Hud.LINE)
	draw_line(Vector2(270 + 420 * fill, 579), Vector2(270 + 420 * fill, 615), Hud.PAPER, 5)
