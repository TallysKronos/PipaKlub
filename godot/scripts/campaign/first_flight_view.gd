extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal continue_lesson
signal leave
const SkySignals = preload("res://scripts/campaign/battle_signals.gd")
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
var reduced_motion := false
var require_action_release := false
var resume_button: Button
var line_held := false
var footer: VBoxContainer
var lesson_label: Label
var pointer_actions: Dictionary = {}
var move_cards: Array = []
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
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# This footer grows to its content; a non-scrolling clip cuts slanted edges.
	panel.add_child(bottom)
	var briefing:=HBoxContainer.new()
	briefing.add_theme_constant_override("separation",20)
	bottom.add_child(briefing)
	var instructions:=VBoxContainer.new()
	instructions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	briefing.add_child(instructions)
	lesson_label = Label.new()
	lesson_label.add_theme_font_size_override("font_size", 18)
	lesson_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	instructions.add_child(lesson_label)
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 16)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_child(hint)
	resume_button = Button.new()
	resume_button.text = "Retomar treino"
	resume_button.visible = false
	resume_button.pressed.connect(func(): paused = false; resume_button.release_focus(); resume_button.hide())
	var resume_space := Hud.focus_space(bottom)
	resume_space.visible = false
	resume_space.add_child(resume_button)
	resume_button.visibility_changed.connect(func(): resume_space.visible = resume_button.visible)
	next_button = Button.new()
	next_button.text = "Continuar"
	next_button.disabled = true
	next_button.custom_minimum_size.y = 50
	next_button.pressed.connect(func(): continue_lesson.emit())
	var row := HBoxContainer.new()
	bottom.add_child(row)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var next_space := Hud.focus_space(row)
	next_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_space.add_child(next_button)
	var exit := Button.new()
	exit.text = "Salvar e voltar ao menu"
	exit.pressed.connect(func(): leave.emit())
	exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var exit_space := Hud.focus_space(row)
	exit_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_space.add_child(exit)
	Hud.secondary_button(exit)
	var commands := HBoxContainer.new()
	commands.alignment = BoxContainer.ALIGNMENT_END
	briefing.add_child(commands)
	for entry in [["cut","Cortar","attack","attackCooldown",12],["skill","Habilidade","energy","skillCooldown",25],["dodge","Esquiva","dodge","dodgeCooldown",18],["line","Puxão","puxao","lineCooldown",28],["guard","Guarda","line","guardCooldown",0]]:
		var art = load("res://scripts/campaign/hud_action.gd").new()
		art.action_id=entry[0];art.title=entry[1];art.icon_id=entry[2];art.cost=entry[4]
		var id: String=entry[0]
		art.held_changed.connect(func(held:bool):
			if not paused:pointer_actions[id]=held)
		commands.add_child(art)
		move_cards.append({"tile":art,"cooldown":entry[3]})
	Hud.fit_footer(panel, bottom, 180)

func _field_scale() -> Vector2:
	return Vector2(size.x / 1000, maxf(200, bottom_panel.position.y - 8) / 640)

func _field_offset() -> Vector2:
	return Vector2.ZERO

func _project(point:Vector2) -> Vector2:
	return point*_field_scale()

func _process(delta: float) -> void:
	if model == null:
		return
	clock += delta
	if paused:
		pointer_actions.clear()
		require_action_release=true
	elif require_action_release:
		var held:bool=["cut","skill","dodge","line","guard"].any(func(action:String):return Controls.held(action) or bool(pointer_actions.get(action,false)))
		if not held:require_action_release=false
	var direction := Controls.direction()
	if direction.length() < .1 and mouse_target.x >= 0:
		direction = (mouse_target - Vector2(model.p.x, model.p.y)).limit_length()
	var line_now := _action_held("line")
	if not paused:
		model.tick(delta, {"x": direction.x, "y": direction.y,
		"cut": _action_held("cut"),"skill":_action_held("skill"),"dodge":_action_held("dodge"),
		"line": line_now and not line_held, "guard": _action_held("guard")})
	line_held = line_now
	for command in move_cards:
		command.tile.custom_minimum_size=Vector2(112,128)*size.y/1080.0
		command.tile.cooldown=model.p[command.cooldown]
		command.tile.key_text=Controls.prompt(command.tile.action_id)
		command.tile.enough_energy=model.p.energy>=command.tile.cost
		command.tile.lock_reason="pausa" if paused or model.complete else ""
		command.tile.reduced_motion=reduced_motion
		command.tile.charge=clampf(float(model.p.lineMove.get("elapsed",0))/1.05,0,1) if command.tile.action_id=="line" else 0.0
		command.tile.active=model.p.guardTime>0 if command.tile.action_id=="guard" else false
		command.tile.queue_redraw()
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
		suspend_actions()
		resume_button.show()

func suspend_actions() -> void:
	paused=true
	require_action_release=true
	pointer_actions.clear()

func _gui_input(event: InputEvent) -> void:
	if paused:return
	if event is InputEventMouseMotion:
		var point: Vector2 = (event.position - _field_offset()) / _field_scale()
		if point.y >= 70 and point.y <= 480:
			mouse_target = point

func _draw() -> void:
	if model == null:
		return
	var field:=Rect2(Vector2.ZERO,Vector2(1000,640)*_field_scale())
	var cover:=maxf(field.size.x/background.get_width(),field.size.y/background.get_height())
	var source_size:=field.size/cover
	draw_texture_rect_region(background,field,Rect2((background.get_size()-source_size)*.5,source_size))
	draw_rect(field, Tokens.alpha(Tokens.TINTA, .12))
	var p: Dictionary = model.p
	var q: Dictionary = model.q
	var crossed: Dictionary = model.contact(p, q)
	draw_line(_project(Vector2(p.anchor, 585)), _project(Vector2(p.x, p.y)), Tokens.CEU, 3)
	draw_dashed_line(_project(Vector2(q.anchor, 585)), _project(Vector2(q.x, q.y)), Tokens.RABIOLA, 3, 8)
	if model.lesson == 0:
		var target:=PackedVector2Array()
		for step in 49:
			target.append(_project(Vector2(700,180)+Vector2.from_angle(TAU*step/48.0)*45))
		draw_polyline(target, Tokens.CEU, 4,true)
	for index in 2:
		var id := "rabbito" if index == 0 else "nozinho"
		var actor: Dictionary = p if index == 0 else q
		var frames: Array = content.practice[id].frames
		var frame: Dictionary = frames[int(clock * 12) % frames.size()]
		var texture := texture_p if index == 0 else texture_q
		var extent:=Vector2.ONE*clampf(field.size.y*.22,80,150)
		draw_texture_rect_region(texture, Rect2(_project(Vector2(actor.x,actor.y))-extent*.5,extent), Rect2(frame.x, frame.y, frame.w, frame.h))
		var card_width:=minf(350,size.x*.32)
		var x := 20.0 if index == 0 else size.x-card_width-20
		Hud.stat_card(self, Rect2(x, 12, card_width, 92), "Rabbito" if index == 0 else "Nozinho", actor, "dark" if index == 0 else "danger", true)

	draw_set_transform(Vector2.ZERO)
	SkySignals.draw_on(self,model,func(point:Vector2)->Vector2:return _field_offset()+point*_field_scale(),clock,reduced_motion)

func _action_held(action:String) -> bool:
	return not paused and not require_action_release and (Controls.held(action) or bool(pointer_actions.get(action,false)))

