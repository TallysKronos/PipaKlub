extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal continue_lesson
signal leave
const SkySignals = preload("res://scripts/campaign/battle_signals.gd")
const Flight = preload("res://scripts/campaign/first_flight_model.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Field=preload("res://scripts/campaign/battle_field.gd")
const Coach=preload("res://scripts/campaign/hud_lesson_coach.gd")
const CornerHud=preload("res://scripts/campaign/battle_corner_hud.gd")
const Ink = preload("res://scripts/campaign/battle_ink.gd")
var model: RefCounted
var content: Dictionary
var texture_p: Texture2D
var texture_q: Texture2D
var background: Texture2D
var coach
var command_row:HBoxContainer
var save_button:Button
var pause_button:Button
var activity_age:=10.0
var highlight_age:=0.0
var highlight_key:=""
var was_complete:=false
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
var settling_from:Array[Vector2]=[]
var settling_age:=1.0
const SETTLING_TIME:=.65
var cinematic:=false
var cinematic_paused:=false
var reel_progress:=0.0
var reel_origins:Array[Vector2]=[]

func configure(data: Dictionary, lesson: int) -> void:
	content = data
	model = Flight.new(lesson)
	texture_p = load("res://assets/campaign/" + content.practice.rabbito.image)
	texture_q = load("res://assets/campaign/" + content.practice.nozinho.image)
	background = load("res://assets/campaign/rooftop-arena-wide-v2.png")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coach=Coach.new()
	bottom_panel=coach
	add_child(coach)
	coach.minimum_size_changed.connect(_layout_lesson.call_deferred)
	lesson_label=coach.title
	hint=coach.body
	next_button=Button.new()
	Hud.navigation_button(next_button)
	next_button.add_theme_font_size_override("font_size",20)
	next_button.expand_icon=true
	next_button.add_theme_constant_override("icon_max_width",22)
	next_button.disabled=true
	next_button.pressed.connect(func():
		if model.complete and settling_age>=SETTLING_TIME:continue_lesson.emit())
	coach.add_advance(next_button)
	resume_button=Button.new()
	resume_button.text="Retomar treino"
	Hud.navigation_button(resume_button,false,"back")
	resume_button.hide()
	resume_button.pressed.connect(func():paused=false;resume_button.release_focus();resume_button.hide())
	add_child(resume_button)
	save_button=Button.new()
	save_button.text="Salvar e voltar ao menu"
	Hud.navigation_button(save_button,true,"save")
	save_button.pressed.connect(func():leave.emit())
	save_button.hide()
	add_child(save_button)
	pause_button=Button.new()
	pause_button.text="Pausar"
	Hud.navigation_button(pause_button,true)
	pause_button.pressed.connect(func():suspend_actions();Hud.focus_later(resume_button))
	add_child(pause_button)
	command_row=HBoxContainer.new()
	command_row.alignment=BoxContainer.ALIGNMENT_END
	command_row.add_theme_constant_override("separation",8)
	add_child(command_row)
	for entry in [["cut","Cortar","attack","attackCooldown",12],["skill","Habilidade","energy","skillCooldown",25],["dodge","Esquiva","dodge","dodgeCooldown",18],["line","Puxão","puxao","lineCooldown",28],["guard","Guarda","line","guardCooldown",0]]:
		var art=load("res://scripts/campaign/hud_action.gd").new()
		art.action_id=entry[0];art.title=entry[1];art.icon_id=entry[2];art.cost=entry[4]
		var id:String=entry[0]
		art.held_changed.connect(func(held:bool):
			if not paused:pointer_actions[id]=held)
		command_row.add_child(art)
		move_cards.append({"tile":art,"cooldown":entry[3]})
	resized.connect(_layout_lesson)
	_layout_lesson.call_deferred()

func _layout_lesson() -> void:
	if not is_instance_valid(coach):return
	coach.set_compact(activity_age<2 and not paused and not model.complete)
	coach.visible=not paused
	next_button.visible=not paused
	command_row.visible=not paused
	var width:=minf(400,size.x*.36)
	coach.size=Vector2(width,0)
	next_button.custom_minimum_size.y=48
	coach.position=Vector2(20,size.y-28-coach.get_combined_minimum_size().y)
	var action_height:=preload("res://scripts/campaign/hud_action.gd").SIZE.y*size.y/1080.0
	command_row.position=Vector2(440,size.y-action_height-8)
	command_row.size=Vector2(maxf(0,size.x-464),action_height)
	pause_button.position=Vector2(20,88)
	pause_button.size=Vector2(150,40)
	pause_button.visible=not paused
	resume_button.visible=paused
	save_button.visible=paused
	resume_button.position=Vector2(size.x/2-160,size.y/2-40)
	resume_button.size=Vector2(320,48)
	save_button.position=Vector2(size.x/2-160,size.y/2+22)
	save_button.size=Vector2(320,48)
	if cinematic:
		for control:Control in [coach,next_button,command_row,pause_button,resume_button,save_button]:control.hide()

func _field_scale() -> Vector2:
	return Field.scale_for(size)
func _field_offset() -> Vector2:
	return Field.origin(size)
func _project(point:Vector2) -> Vector2:
	return _field_offset()+point*_field_scale()

func prepare_lesson(index:int)->void:
	settling_from.assign([Vector2(model.p.x,model.p.y),Vector2(model.q.x,model.q.y)])
	# Keep the arena and sprites; reset the exercise exactly like loading a new lesson.
	model=Flight.new(index)
	settling_age=SETTLING_TIME if reduced_motion else 0.0
	paused=false
	require_action_release=true
	pointer_actions.clear()
	line_held=false
	mouse_target=Vector2(-1,-1)
	was_complete=false
	activity_age=10
	highlight_age=0
	next_button.release_focus()
	queue_redraw()

func _actor_point(index:int)->Vector2:
	var actor:Dictionary=model.p if index==0 else model.q
	var target:=Vector2(actor.x,actor.y)
	if cinematic and reel_origins.size()==2:
		return reel_origins[index].lerp(Vector2(actor.anchor,585),smoothstep(0,1,reel_progress))
	if settling_from.size()!=2 or settling_age>=SETTLING_TIME:return target
	return settling_from[index].lerp(target,smoothstep(0,SETTLING_TIME,settling_age))

func reel_in()->void:
	reel_origins.assign([_actor_point(0),_actor_point(1)])
	cinematic=true
	paused=true
	var tree:=get_tree()
	while is_inside_tree() and reel_progress<1:
		await tree.process_frame
		if not is_instance_valid(self) or not is_inside_tree():return
		if cinematic_paused or not get_window().has_focus():continue
		reel_progress=minf(1,reel_progress+minf(get_process_delta_time(),.05)/(.15 if reduced_motion else .8))
		queue_redraw()

func _process(delta: float) -> void:
	if model == null:
		return
	clock += delta
	highlight_age+=delta
	activity_age+=delta
	if not paused:settling_age+=minf(delta,.05)
	if paused:
		pointer_actions.clear()
		require_action_release=true
	elif require_action_release:
		var held:bool=["cut","skill","dodge","line","guard"].any(func(action:String):return Controls.held(action) or bool(pointer_actions.get(action,false)))
		if not held:require_action_release=false
	var direction := Controls.direction()
	if direction.length() < .1 and mouse_target.x >= 0:
		direction = (mouse_target - Vector2(model.p.x, model.p.y)).limit_length()
	if direction.length()>.1 or ["cut","skill","dodge","line","guard"].any(func(action:String):return _action_held(action)):activity_age=0
	var line_now := _action_held("line")
	if not paused and settling_age>=SETTLING_TIME:
		model.tick(delta, {"x": direction.x, "y": direction.y,
		"cut": _action_held("cut"),"skill":_action_held("skill"),"dodge":_action_held("dodge"),
		"line": line_now and not line_held, "guard": _action_held("guard")})
	line_held = line_now
	for command in move_cards:
		command.tile.custom_minimum_size=command.tile.SIZE*size.y/1080.0
		command.tile.cooldown=model.p[command.cooldown]
		command.tile.key_text=Controls.prompt(command.tile.action_id)
		command.tile.enough_energy=model.p.energy>=command.tile.cost
		command.tile.lock_reason="pausa" if paused or model.complete else ""
		command.tile.reduced_motion=reduced_motion
		command.tile.charge=clampf(float(model.p.lineMove.get("elapsed",0))/1.05,0,1) if command.tile.action_id=="line" else 0.0
		command.tile.active=model.p.guardTime>0 if command.tile.action_id=="guard" else false
		command.tile.queue_redraw()
	var lesson: Dictionary = content.lessons[model.lesson]
	coach.full_title = "Sr. Assis · %d / 5 · %s" % [model.lesson + 1, lesson.title]
	coach.short_title="Sr. Assis · %d / 5"%[model.lesson+1]
	hint.text = lesson.success if model.complete else lesson.hint
	if model.lesson == 3 and not model.complete:
		hint.text += "\n" + {"skill": "%s · Habilidade: acerte Nozinho" % Controls.prompt("skill"), "dodge": "%s · Esquiva" % Controls.prompt("dodge"), "line": "%s · Rebicada" % Controls.prompt("line"), "guard": "%s · Guarda: proteja-se no impacto" % Controls.prompt("guard")}.get(model.exercise, "")
	hint.text = hint.text.replace("WASD / setas", "analógico" if Controls.gamepad else "setas").replace("Espaço", Controls.prompt("cut")).replace("com R", "com " + Controls.prompt("line"))
	next_button.disabled = not model.complete
	if model.complete and not was_complete:Hud.focus_later(next_button)
	was_complete=model.complete
	next_button.text = ("Recolher a pipa" if model.lesson == 4 else "Avançar") if model.complete else "Pratique no campo"
	next_button.icon=Hud.icon("cadeado") if not model.complete else Hud.icon("back")
	coach.short.text={0:"Leve seu parceiro até o alvo.",1:"Cruze as linhas e corte.",2:"Leia a sua energia.",3:"Experimente a ferramenta indicada.",4:"Vença o duelo com Nozinho."}.get(model.lesson,"")
	if model.lesson==3:coach.short.text=hint.text.split("\n")[-1]
	var key:="%d-%s"%[model.lesson,model.exercise]
	if key!=highlight_key:highlight_key=key;highlight_age=0
	_layout_lesson()
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
	var field:=Rect2(Vector2.ZERO,size)
	var cover:=maxf(field.size.x/background.get_width(),field.size.y/background.get_height())
	var source_size:=field.size/cover
	draw_texture_rect_region(background,field,Rect2((background.get_size()-source_size)*.5,source_size))
	draw_rect(field, Tokens.alpha(Tokens.TINTA, .12))
	var p: Dictionary = model.p
	var q: Dictionary = model.q
	var crossed: Dictionary = model.contact(p, q)
	draw_line(_project(Vector2(p.anchor, 585)), _project(_actor_point(0)), Tokens.CEU, 3)
	draw_dashed_line(_project(Vector2(q.anchor, 585)), _project(_actor_point(1)), Tokens.RABIOLA, 3, 8)
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
		if cinematic:extent*=1.0-.65*reel_progress
		var sprite_rect:=Rect2(_project(_actor_point(index))-extent*.5,extent)
		var target:Dictionary=q if index==0 else p
		if Ink.facing_flip(id,actor.x,target.x):
			sprite_rect.size.x=-sprite_rect.size.x
		draw_texture_rect_region(texture, sprite_rect, Rect2(frame.x, frame.y, frame.w, frame.h))
	var actors:Array=[p.duplicate(false),q.duplicate(false)]
	for actor in actors:actor.stats={"line":100.0,"energy":100.0}
	actors[1].name="Sr. Assis"
	var faces:Array=[]
	for index in 2:
		var art:=AtlasTexture.new()
		art.atlas=texture_p if index==0 else texture_q
		var frame:Dictionary=content.practice["rabbito" if index==0 else "nozinho"].frames[0]
		art.region=Rect2(frame.x,frame.y,frame.w,frame.h)
		faces.append(art)
	var action_cost:=0
	for command in move_cards:
		if _action_held(command.tile.action_id):action_cost=command.tile.cost
	CornerHud.draw_on(self,actors,faces,["Rabbito · Nv. 1","Nozinho · Nv. 1"],{},0,1,1,0,action_cost,model.lesson)

	draw_set_transform(Vector2.ZERO)
	SkySignals.draw_on(self,model,_project,clock,reduced_motion)
	_draw_lesson_highlight()
	if paused and not cinematic:draw_rect(Rect2(Vector2.ZERO,size),Tokens.alpha(Tokens.NANQUIM,.55))

func _action_held(action:String) -> bool:
	return not paused and settling_age>=SETTLING_TIME and not require_action_release and (Controls.held(action) or bool(pointer_actions.get(action,false)))


func _draw_lesson_highlight() -> void:
	var duration:=.08 if reduced_motion else 1.2
	if highlight_age>=duration or paused:return
	var target:=_project(Vector2(500,260))
	if model.lesson==0:target=_project(Vector2(700,180))
	elif model.lesson==2:target=Vector2(300,size.y-42)
	elif model.lesson==3:
		for command in move_cards:
			if command.tile.action_id==model.exercise:target=command.tile.get_global_rect().get_center()
	var tint:=Tokens.alpha(Tokens.SOL,(1-highlight_age/duration)*.7)
	draw_texture_rect(Ink.brush(1),Rect2(target-Vector2(52,28),Vector2(104,56)),false,tint)
	var head:=target-Vector2(3,24)
	draw_line(head-Vector2(42,42),head,tint,4,true)
	draw_colored_polygon(PackedVector2Array([head,head-Vector2(18,5),head-Vector2(5,18)]),tint)
