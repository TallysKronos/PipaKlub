extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal progress_changed(state: Dictionary)
signal finished(outcome: Dictionary)
signal leave_requested
signal pause_requested
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
var bamboo: Texture2D
var scissors: Texture2D
var staging_time:=.8
const PREPARATIONS:=["Preparando a armação","Separando a linha","Abrindo o papel","Soltando a pipa ao vento","Firmando o novo elo"]
var bottom_panel: PanelContainer
var pause_button: Button
var feedback_age:=2.0
var feedback_success:=false
const STAGES:=["ARMAÇÃO","NÓS","PAPEL","VOO","DESPERTAR"]
const INSTRUCTIONS:=["Encaixe as varetas nos apoios.","Solte cada nó na faixa verde.","Recorte seguindo o pontilhado.","Use as teclas de movimento para equilibrar.","Solte o elo antes do excesso de brilho."]

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
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background = load("res://assets/campaign/workshop-manga-v1/bancada.png")
	bamboo = load("res://assets/campaign/workshop-manga-v1/vareta.png")
	scissors = load("res://assets/campaign/workshop-manga-v1/tesoura.png")
	bottom_panel = PanelContainer.new()
	bottom_panel.anchor_top=1
	bottom_panel.anchor_bottom = 1
	bottom_panel.offset_left = 24
	bottom_panel.offset_right = 510
	bottom_panel.offset_top=-96
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
	_add_action(actions,resume_button)
	restock_button = Button.new()
	restock_button.text = "Buscar materiais"
	restock_button.visible = false
	restock_button.pressed.connect(_restock)
	_add_action(actions,restock_button)
	pause_button = Button.new()
	pause_button.tooltip_text="Pausar montagem"
	pause_button.icon=Controls.glyph("pause",true)
	pause_button.expand_icon=true
	pause_button.add_theme_constant_override("icon_max_width",32)
	pause_button.pressed.connect(func():_pause();pause_requested.emit())
	add_child(pause_button)
	pause_button.anchor_left=1;pause_button.anchor_right=1
	pause_button.offset_left=-80;pause_button.offset_right=-24
	pause_button.offset_top=20;pause_button.offset_bottom=74
	var back := Button.new()
	back.text = "Sair da bancada"
	back.pressed.connect(func(): _pause(); leave_requested.emit())
	back.hide()
	for button in [resume_button, restock_button, pause_button, back]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 56
	Hud.secondary_button(back)
	Hud.secondary_button(pause_button)
	Hud.pause_glyph(pause_button)
	back.queue_free()
	Hud.fit_footer(bottom_panel,bottom,110)
	bottom_panel.hide()

func _add_action(parent: HBoxContainer, button: Button) -> void:
	var space := Hud.focus_space(parent)
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.visible = button.visible
	space.add_child(button)
	# Hidden actions must not leave empty columns in paused/blocked states.
	button.visibility_changed.connect(func(): space.visible = button.visible)

func _scale() -> float:
	return minf(size.x/960,size.y/640)

func _offset() -> Vector2:
	return (size-Vector2(960,640)*_scale())/2

func _gui_input(event: InputEvent) -> void:
	if model == null or paused or staging_time>0 or not model.run.outcome.is_empty():
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
		feedback_age=0
		feedback_success=false

func _checkpoint_if_needed() -> void:
	if last_stage != model.run.stage:
		feedback_age=0
		feedback_success=true
		last_stage = model.run.stage
		staging_time=.65
		dragging_rod=false
		cutting=false
		help.text = ""
		progress_changed.emit(model.run.duplicate(true))
	if not model.run.outcome.is_empty() and not sent_outcome and not storage_blocked:
		sent_outcome = true
		finished.emit(model.run.outcome.duplicate(true))

func _process(delta: float) -> void:
	if model == null:
		return
	feedback_age+=delta
	if not paused and staging_time>0:
		staging_time=maxf(0,staging_time-minf(delta,.05))
	elif not paused and not storage_blocked:
		var axis := Controls.direction().x
		_feedback(model.tick(delta, axis))
		if cutting and model.run.stage == 2:
			_feedback(model.cut_at(cursor, minf(delta, .05)))
		_checkpoint_if_needed()
	restock_button.visible = not str(model.run.blocked).is_empty()
	pause_button.visible = not paused
	help.visible = not help.text.is_empty()
	bottom_panel.visible=storage_blocked or restock_button.visible or resume_button.visible or (help.visible and feedback_age<2)
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
	draw_rect(Rect2(Vector2.ZERO,size),Color("101d29"))
	draw_set_transform(_offset(), 0, Vector2.ONE * _scale())
	draw_texture_rect(background,Rect2(0,0,960,640),false)
	var index: int = mini(model.run.stage, 4)
	var ink=preload("res://scripts/campaign/battle_ink.gd")
	ink.plate(self,Rect2(26,20,250,62),Hud.INK,Hud.CYAN,14)
	draw_string(Hud.display(),Vector2(44,51),"%d/5 · %s"%[index+1,STAGES[index]],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Hud.PAPER)
	draw_string(Hud.font(true),Vector2(44,72),"Linha %d · Papel %d"%[model.run.materials.linha,model.run.materials.folha],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Hud.MUTED)
	ink.plate(self,Rect2(300,20,550,62),Hud.PAPER,Hud.INK,12)
	draw_string(Hud.font(),Vector2(318,56),INSTRUCTIONS[index],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Hud.INK)
	for i in 5:
		var p:=Vector2(46+i*28,100)
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-7),p+Vector2(7,0),p+Vector2(0,7),p-Vector2(7,0)]),Hud.CYAN if i<=index else Hud.TRACK)
	var g: Dictionary = model.geometry()
	var points := PackedVector2Array(g.points)
	if model.run.stage >= 2:
		draw_colored_polygon(_shift(points,Vector2(3,5)),Color(0.02,0.08,0.1,.35))
		draw_colored_polygon(points, Color("f5e9cb"))
		for i in points.size():
			var p:Vector2=points[i]
			var q:Vector2=points[(i+1)%points.size()]
			draw_colored_polygon(PackedVector2Array([Workshop.CENTER,p,q]),Color("f5e9cb") if i%2 else Color("e6d3a6"))
			draw_line(p,q,Color("26394d"),2,true)
	for i in points.size():
		var point := points[i]
		var installed: bool = model.run.stage > 0 or i in model.run.step.get("placed", [])
		if installed:
			_rod(Workshop.CENTER,point,9)
		else:
			draw_dashed_line(Workshop.CENTER, point, Color("91b4ad"), 2, 7,true)
		draw_circle(point,11,Color("203b40"))
		draw_circle(point,7,Color("e8bc58") if installed else Color("9abbb3"))
		if installed:
			for wrap in 3:
				draw_line(point+Vector2(-6,-4+wrap*4),point+Vector2(6,-2+wrap*4),Color("f5e9cb"),2,true)
	draw_circle(Workshop.CENTER,7,Color("e8bc58"))
	if model.run.stage == 0:
		for i in int(Workshop.CLASSES[model.run.kind].rods):
			_rod(Vector2(795+i*18,170),Vector2(795+i*18,410),10)
		if dragging_rod:
			_rod(cursor-Vector2(0,80),cursor+Vector2(0,80),11)
		draw_string(Hud.font(true),Vector2(779,465),"VARETAS",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Hud.PAPER)
	elif model.run.stage == 1:
		for i in points.size():
			draw_circle(points[i], 22, Tokens.FOLHA if i in model.run.step.tied else Tokens.PAPEL_2, false, 5)
		if model.run.step.holding >= 0:
			draw_line(Vector2(810,510),points[model.run.step.holding],Color("f5e9cb"),2,true)
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
		draw_string(Hud.font(true), Vector2(390, 560), "%.1f / 9 s" % model.run.step.t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Hud.PAPER)
		for gust in model.run.step.gusts:
			if gust.t > model.run.step.t and gust.t - model.run.step.t <= Workshop.CLASSES[model.run.kind].tell:
				draw_style_box(Hud.panel("paper"), Rect2(355, 73, 300, 58))
				draw_string(Hud.font(), Vector2(385, 110), "Rajada", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Hud.INK)
				draw_texture_rect(Hud.icon("seta-direita" if gust.dir > 0 else "seta-esquerda"),Rect2(540,84,36,36),false)
				break
	elif model.run.stage == 4:
		var pulse:float=.5+.5*sin(model.run.clock*3)
		for r in 3:
			draw_arc(Workshop.CENTER,55+r*14,0,TAU,64,Color(.3,.85,.86,.18+pulse*.15),2,true)
		draw_circle(Workshop.CENTER,42,Color("26394d"))
		draw_texture_rect(Hud.icon("tail"),Rect2(Workshop.CENTER-Vector2(21,25),Vector2(42,50)),false)
		draw_string(Hud.font(true),Vector2(404,405),"Segure o elo",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Hud.INK)
		_meter(model.run.step.fill, .4, .92)
	if scissors != null:
		var tool_position:Vector2=cursor if cutting and model.run.stage==2 else Vector2(831,510)
		var tool_angle:float=(-.12 if int(model.run.clock*10)%2 else .12) if cutting else -.35
		_tool(scissors,tool_position,Vector2(49,77),tool_angle)
	if feedback_age<1.0:
		var color:Color=Hud.CYAN if feedback_success else Tokens.TINTA_3
		var art=ink.brush(0)
		draw_texture_rect(art,Rect2(660,460,220,120),false,color)
		draw_string(Hud.lettering(),Vector2(690,530),"FEITO!" if feedback_success else "AJUSTE!",HORIZONTAL_ALIGNMENT_LEFT,-1,36,Hud.PAPER)
	if not model.run.outcome.is_empty():
		ink.plate(self,Rect2(340,420,280,80),Hud.INK,Hud.GOLD,14)
		var stars:int=model.run.outcome.get("stars",1)
		draw_string(Hud.display(),Vector2(365,470),"RARA" if stars>=4 else "BOA" if stars>=3 else "COMUM",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Hud.PAPER)
	if staging_time>0 and model.run.stage<5:
		var opacity:=minf(1,staging_time/.18)
		ink.plate(self,Rect2(310,242,340,82),Color(Hud.INK,opacity),Color(Hud.GOLD,opacity),12)
		draw_string(Hud.font(true),Vector2(325,289),PREPARATIONS[index],HORIZONTAL_ALIGNMENT_CENTER,310,22,Color(Hud.PAPER,opacity))
	draw_set_transform(Vector2.ZERO)

func _shift(points:PackedVector2Array,offset:Vector2)->PackedVector2Array:
	var moved:=PackedVector2Array()
	for point in points:moved.append(point+offset)
	return moved

func _rod(from:Vector2,to:Vector2,width:float)->void:
	if bamboo==null:return
	var normal:Vector2=(to-from).orthogonal().normalized()*width*.5
	draw_polygon(PackedVector2Array([from-normal,from+normal,to+normal,to-normal]),PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]),bamboo)

func _tool(texture:Texture2D,center:Vector2,extent:Vector2,angle:float)->void:
	var corners:=PackedVector2Array()
	for point in [Vector2(-.5,-.5),Vector2(.5,-.5),Vector2(.5,.5),Vector2(-.5,.5)]:
		corners.append(center+(point*extent).rotated(angle))
	draw_polygon(corners,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]),texture)

func _meter(fill: float, start: float, end: float) -> void:
	preload("res://scripts/campaign/battle_ink.gd").plate(self,Rect2(265,580,430,34),Hud.TRACK,Hud.INK,10)
	draw_rect(Rect2(270 + 420 * start, 585, 420 * (end - start), 24), Hud.LINE)
	draw_line(Vector2(270 + 420 * fill, 579), Vector2(270 + 420 * fill, 615), Hud.PAPER, 5)
