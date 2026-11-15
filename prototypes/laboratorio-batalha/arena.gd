extends Node2D

const Rope = preload("res://corda.gd")
const FORMATS := [Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(2,2),Vector2i(3,3)]
const ARENA := preload("res://arte/estadio-celestial.png")
const BLUE := Color("#61dcff")
const RED := Color("#ff8e83")
const GOLD := Color("#ffe08b")
const FIELD := Rect2(90,112,820,330)
const AERON := preload("res://arte/aeron.png")
const PYRON := preload("res://arte/pyron.png")
const AERON_PORTRAIT := preload("res://arte/aeron-retrato.png")
const PYRON_PORTRAIT := preload("res://arte/pyron-retrato.png")
const HUD_FRAME := preload("res://arte/hud/moldura.svg")
const WIND_FACE := preload("res://arte/hud/bussola.svg")
const WIND_NEEDLE := preload("res://arte/hud/agulha.svg")
const HUD_ICONS := [
	preload("res://arte/hud/giro.png"), preload("res://arte/hud/impulso.png"),
	preload("res://arte/hud/tempestade.png"), preload("res://arte/hud/escudo.png"),
]
const COMBAT_ART := {
	"giro": preload("res://arte/vfx/giro.png"),
	"impacto": preload("res://arte/vfx/impacto.png"),
	"tempestade": preload("res://arte/vfx/tempestade.png"),
	"escudo": preload("res://arte/vfx/escudo.png"),
	"impulso": preload("res://arte/hud/impulso.png"),
}
const LASSO_ROPE_POINT := 14
const LASSO_MIN_RADIUS := 42.0
const LASSO_MAX_RADIUS := 124.0
const VERTICAL_FLIGHT := {
	"raio": [preload("res://arte/voo/raio-subida.png"), preload("res://arte/voo/raio-mergulho.png")],
	"azulao": [preload("res://arte/voo/azulao-subida.png"), preload("res://arte/voo/azulao-mergulho.png")],
	"rabbito": [preload("res://arte/voo/aeron-subida.png"), preload("res://arte/voo/aeron-mergulho.png")],
	"mata": [preload("res://arte/voo/pyron-subida.png"), preload("res://arte/voo/pyron-mergulho.png")],
}
const ESCAPE_ARROW := preload("res://arte/hud/seta-fuga.svg")
const STORM_REACH := 230.0
const DASH_KNOT_WINDOW := 3.2
const DASH_KNOT_LIFE := 4.0
const DASH_ESCAPE_TRAVEL := 26.0
const DASH_RETURN_SPAN := 6
const DASH_ESCAPE_WINDUP := .45
const LASSO_COST := 32.0
const ROUND_TIME := 120.0
const HEAL_COOLDOWN := 30.0
const PROFILES := [
	["Aeron","Vento",10.2,188.0,preload("res://arte/rabbito.png")],
	["Pyron","Brasa",8.0,168.0,preload("res://arte/mata.png")],
	["Raio de Sol","Brasa",9.0,175.0,preload("res://arte/raio.png")],
	["Azulão","Água",7.5,168.0,preload("res://arte/azulao.png")],
]
var actors: Array[Dictionary] = []
var controlled := 0
var selected := 0
var mode := 0
var elapsed := 0.0
var presentation_time := 0.0
var heal_clock := 0.0
var heal_cast := 0.0
var heal_target := -1
var potions := 2
var result := ""
var notice := ""
var notice_clock := 0.0
var contact := {}
var orbit_angle := 0.0
var orbit_elapsed := 0.0
var orbit_grace := 0.0
var orbit_pointer := Vector2.ZERO
var practice := 0
var practice_button := Button.new()
var orbit_center := Vector2.ZERO
var cut_queue := 0.0
var dash_crossing := {}
var dash_knot := {}
var knot_release := {}
var knot_escape_notice := 0.0
var rival_windup := 0.0
var rival_recovery := 0.0
var rival_attacker := -1
var rival_target := -1
var orbit_previous := Vector2.ZERO
var lasso_window := 0.0
var orbit_match := Vector2i(-1,-1)
var test_mode := false
var special_flash := 0.0
var animations := {}
var bursts: Array[Dictionary] = []
var format_buttons: Array[Button] = []
var sounds := {}
var sound_player := AudioStreamPlayer.new()
const SPRITE_IDS := ["rabbito","mata","raio","azulao"]

func _ready() -> void:
	_bind_inputs()
	add_child(sound_player)
	sound_player.volume_db=-10.0
	_load_presentation()
	for i in FORMATS.size():
		var button:=Button.new()
		button.text="%d × %d" % [FORMATS[i].x,FORMATS[i].y]
		button.position=Vector2(282+59*i,535)
		button.size=Vector2(55,21)
		button.focus_mode=Control.FOCUS_NONE
		button.pressed.connect(_start.bind(i))
		add_child(button)
		format_buttons.append(button)
	practice_button.text="Treinar Laço"
	practice_button.position=Vector2(868,531)
	practice_button.size=Vector2(118,26)
	practice_button.focus_mode=Control.FOCUS_NONE
	practice_button.pressed.connect(_toggle_practice)
	add_child(practice_button)
	_start(0)
	if "--capture" in OS.get_cmdline_user_args():
		_start(4 if "--equipe" in OS.get_cmdline_user_args() else 0)
		_capture()
	if "--test" in OS.get_cmdline_user_args():
		test_mode=true
		set_physics_process(false)
		_run_checks()

func _bind_inputs() -> void:
	for data in [
		["left",KEY_A,JOY_AXIS_LEFT_X,-1],["right",KEY_D,JOY_AXIS_LEFT_X,1],
		["up",KEY_W,JOY_AXIS_LEFT_Y,-1],["down",KEY_S,JOY_AXIS_LEFT_Y,1],
		["reel",KEY_Z,JOY_AXIS_TRIGGER_RIGHT,1],["release",KEY_C,JOY_AXIS_TRIGGER_LEFT,1],
	]:
		InputMap.add_action(data[0],.18)
		var key:=InputEventKey.new()
		key.physical_keycode=data[1]
		InputMap.action_add_event(data[0],key)
		var axis:=InputEventJoypadMotion.new()
		axis.axis=data[2]
		axis.axis_value=data[3]
		InputMap.action_add_event(data[0],axis)
	for data in [
		["cut",KEY_SPACE,JOY_BUTTON_X],["dodge",KEY_SHIFT,JOY_BUTTON_B],
		["guard",KEY_G,JOY_BUTTON_LEFT_SHOULDER],["tech",KEY_Q,JOY_BUTTON_Y],
		["snap",KEY_R,JOY_BUTTON_RIGHT_SHOULDER],["heal",KEY_H,JOY_BUTTON_A],["special",KEY_E,JOY_BUTTON_DPAD_UP],
		["switch",KEY_TAB,JOY_BUTTON_LEFT_STICK],["target",KEY_F,JOY_BUTTON_RIGHT_STICK],
		["reset",KEY_ENTER,JOY_BUTTON_START],["mode",KEY_M,JOY_BUTTON_BACK],
	]:
		InputMap.add_action(data[0])
		var key:=InputEventKey.new()
		key.physical_keycode=data[1]
		InputMap.action_add_event(data[0],key)
		var pad:=InputEventJoypadButton.new()
		pad.button_index=data[2]
		InputMap.action_add_event(data[0],pad)
	for data in [["left",KEY_LEFT],["right",KEY_RIGHT],["up",KEY_UP],["down",KEY_DOWN]]:
		var key:=InputEventKey.new()
		key.physical_keycode=data[1]
		InputMap.action_add_event(data[0],key)

func _toggle_practice() -> void:
	var enter:=practice==0
	_start(0)
	if enter:_practice_stage(1)

func _practice_stage(stage:int) -> void:
	practice=stage
	result=""
	practice_button.text="Sair do treino"
	elapsed=0
	actors[controlled].pos=Vector2(405,318)
	actors[controlled].vel=Vector2.ZERO
	actors[controlled].rope.reset(actors[controlled].anchor,actors[controlled].pos)
	var rival:=actors[selected]
	rival.anchor=Vector2(540,525)
	rival.pos=Vector2(540,165)
	rival.rope.reset(rival.anchor,rival.pos)
	rival.line=100.0
	actors[controlled].energy=100.0
	actors[controlled].special=0.0
	orbit_match=Vector2i(-1,-1)
	lasso_window=0
	_reset_orbit()

func _start(index: int) -> void:
	practice=0
	practice_button.text="Treinar Laço"
	mode=index
	special_flash=0
	cut_queue=0
	dash_crossing.clear()
	dash_knot.clear()
	knot_release.clear()
	knot_escape_notice=0
	rival_windup=0
	rival_recovery=0
	rival_attacker=-1
	rival_target=-1
	actors.clear()
	bursts.clear()
	_update_format_buttons()
	for team in 2:
		var count:int=FORMATS[mode][team]
		for i in count:
			var profile_index: int = [[0,2,3],[1,3,2]][team][i]
			var profile: Array = PROFILES[profile_index]
			var anchor:=Vector2(145+i*67 if team==0 else 855-i*67,505)
			var pos:=Vector2(335+i*54 if team==0 else 665-i*54,173+i*67)
			var rope:=Rope.new()
			rope.reset(anchor,pos)
			actors.append({"team":team,"slot":i,"art":SPRITE_IDS[profile_index],"motion":0.0,"special":0.0,"profile":profile,"pos":pos,"vel":Vector2.ZERO,"anchor":anchor,"rope":rope,
				"line":100.0,"hull":100.0,"energy":100.0,"cut":0.0,"skill":0.0,"guard":0.0,
				"dodge":0.0,"defense":0.0,"boost":0.0,"slow":0.0,"shield":0.0,"flash":0.0,"guard_wave":0.0,"guard_side":Vector2.RIGHT,"exposed":0.0,"heading":Vector2.RIGHT if team==0 else Vector2.LEFT,"dash_crossed":false,"facing":-1.0 if team==1 else 1.0})
	controlled=0
	selected=FORMATS[mode].x
	heal_clock=0
	heal_cast=0
	heal_target=-1
	potions=2
	elapsed=0
	result=""
	contact={}
	orbit_match=Vector2i(-1,-1)
	lasso_window=0
	_reset_orbit()
	_say("Contorne o anel na linha rival para preparar o Laço.")

func _alive(a:Dictionary) -> bool:
	return a.line>0 and a.hull>0

func _next(current:int,team:int) -> int:
	for offset in range(1,actors.size()+1):
		var i:=posmod(current+offset,actors.size())
		if actors[i].team==team and _alive(actors[i]):return i
	return -1

func _say(message:String) -> void:
	notice=message
	notice_clock=2.3

func _physics_process(dt:float) -> void:
	presentation_time+=dt
	special_flash=maxf(0,special_flash-dt)
	if Input.is_action_just_pressed("mode"):
		_start((mode+1)%FORMATS.size())
	if Input.is_action_just_pressed("reset"):
		if practice>0:_practice_stage(1)
		else:_start(mode)
	if result.is_empty():
		_step(dt)
	for i in range(bursts.size()-1,-1,-1):
		bursts[i].life-=dt
		if bursts[i].life<=0:bursts.remove_at(i)
	queue_redraw()

func _step(dt:float) -> void:
	elapsed+=dt
	if not knot_release.is_empty() and elapsed>=float(knot_release.until):knot_release.clear()
	if not dash_crossing.is_empty() and elapsed>=float(dash_crossing.until):dash_crossing.clear()
	if not dash_knot.is_empty() and (elapsed>=float(dash_knot.until) or not _alive(actors[dash_knot.target]) or not _alive(actors[dash_knot.pilot])):_release_dash_knot(false)
	notice_clock=maxf(0,notice_clock-dt)
	heal_clock=maxf(0,heal_clock-dt)
	if Input.is_action_just_pressed("switch") or not _alive(actors[controlled]):
		var next:=_next(controlled,0)
		if next>=0:
			controlled=next
			cut_queue=0
	if Input.is_action_just_pressed("target") or not _alive(actors[selected]):
		var next:=_next(selected,1)
		if next>=0:
			selected=next
			cut_queue=0
	for i in actors.size():
		var a:=actors[i]
		if not _alive(a):continue
		for timer in ["cut","skill","guard","dodge","defense","boost","slow","shield","flash","motion","special","guard_wave","exposed"]:
			a[timer]=maxf(0,a[timer]-dt)
		a.energy=minf(100,a.energy+15*dt)
		if practice>0 and i==selected:
			if practice==2:
				a.pos=Vector2(540+sin(elapsed*1.25)*72,165)
				a.rope.solve(a.anchor,a.pos,0,dt)
		else:
			_fly(i,dt)
	contact=_crossing(actors[controlled],actors[selected]) if practice==0 else {}
	_track_lasso(dt)
	if not test_mode:
		_player_actions(dt)
		if practice==0:_rivals(dt)
	if heal_cast>0:
		heal_cast=maxf(0,heal_cast-dt)
		if heal_cast==0:
			if _alive(actors[heal_target]):
				var a:=actors[heal_target]
				a.line=minf(100,a.line+25)
				potions-=1
				_fx(a.pos,Color("#a8f0c8"),"LINHA RESTAURADA","cura")
				heal_clock=HEAL_COOLDOWN
				_say("Linha restaurada em até 25 pontos")
			heal_target=-1
	if practice>0:return
	var ally:=_next(controlled,0)
	var enemy:=_next(selected,1)
	if ally<0 or enemy<0 or elapsed>=ROUND_TIME:
		if ally>=0 and enemy>=0:
			var balance:=0.0
			for actor in actors:
				if _alive(actor):balance+=(actor.line+actor.hull)/FORMATS[mode][actor.team]*(1 if actor.team==0 else -1)
			result="Vitória" if balance>.01 else "Derrota" if balance<-.01 else "Empate"
		else:
			result="Vitória" if enemy<0 and ally>=0 else "Derrota"
		_play("victory" if result=="Vitória" else "defeat")

func _fly(i:int,dt:float) -> void:
	var a:=actors[i]
	var direction:=Vector2.ZERO
	var reel:=0.0
	if i==controlled and not test_mode:
		direction=Input.get_vector("left","right","up","down")
		reel=Input.get_action_strength("release")-Input.get_action_strength("reel")
	elif i!=controlled:
		var rival:=actors[selected if a.team==0 else controlled]
		var lane: int = a.slot
		var lateral:=130.0+lane*68.0
		var goal:=Vector2(rival.pos)+Vector2(lateral if a.team==1 else -lateral,sin(elapsed*1.7+i*2.1)*39+(lane-1)*78)
		if a.team==1 and i==(rival_attacker if rival_windup>0 else selected) and rival_recovery<=0:
			var defender:=actors[rival_target] if rival_target>=0 else rival
			var line:PackedVector2Array=defender.rope.points
			var point:=line[14]
			var normal:=line[12].direction_to(line[16]).orthogonal()
			if normal.dot(Vector2(a.anchor)-point)>0:normal=-normal
			goal=point+normal*105
		for teammate:Dictionary in actors:
			if is_same(a,teammate) or teammate.team!=a.team or not _alive(teammate):continue
			var spacing:=Vector2(a.pos)-Vector2(teammate.pos)
			if spacing.length()>1 and spacing.length()<128:
				goal+=spacing.normalized()*(128-spacing.length())*.95
		direction=((goal-Vector2(a.pos))/90.0).limit_length(.78)
		if a.rope.tension>.45:reel=.65
		elif a.team==1 and i==selected and sin(elapsed*1.2)>.7:reel=-.45
	if direction.length_squared()>.05 and (i==controlled or a.dodge<=0):
		a.heading=direction.normalized()
		if absf(direction.x)>.05:a.facing=signf(direction.x)
	var wind:=_wind()
	var response:=float(a.profile[2])*(1.30 if a.boost>0 else .60 if a.slow>0 else 1.0)
	var target:=direction*float(a.profile[3])+Vector2(wind,-3)
	if practice>0 and i==controlled:target=direction*float(a.profile[3])
	if a.guard>0:target*=.44
	if a.dodge<=0:
		if direction.length_squared()>.05 and Vector2(a.vel).dot(direction)<0:
			response*=2.8
		a.vel=Vector2(a.vel).lerp(target,1-exp(-response*dt))
	a.vel=Vector2(a.vel)+a.rope.advance(a.anchor,a.pos,reel,wind,dt)*dt
	var before:=Vector2(a.pos)
	var pos:=before+Vector2(a.vel)*dt
	var inset:=128.0 if mode==0 else FIELD.position.x
	a.pos=pos.clamp(Vector2(inset,FIELD.position.y),Vector2(1000-inset,FIELD.end.y))
	a.rope.solve(a.anchor,a.pos,wind,dt)
	_check_escape_travel(i)
	if practice==0 and i==controlled and a.dodge>0 and not a.dash_crossed:
		_track_dash_crossing(before,a.pos)

func _crossing(a:Dictionary,b:Dictionary) -> Dictionary:
	if not _alive(a) or not _alive(b): return {}
	return Rope.crossing(a.rope.points,b.rope.points,b.exposed>0)

func _player_actions(dt:float) -> void:
	var a:=actors[controlled]
	var b:=actors[selected]
	if not _alive(a):return
	if a.defense>0 and (Input.is_action_just_pressed("guard") or Input.is_action_just_pressed("dodge")):
		_say("Guarda e impulso compartilham a recarga")
	if Input.is_action_just_pressed("guard") and a.defense<=0:
		a.guard=.42
		a.defense=2.2
	if Input.is_action_just_pressed("dodge") and a.defense<=0 and a.energy>=18:
		var direction:=Input.get_vector("left","right","up","down")
		_dash(controlled,direction if direction.length()>.15 else Vector2(a.heading))
	if Input.is_action_just_pressed("snap") and a.energy>=12 and a.cut<=0 and a.dodge<=0 and a.guard<=0:
		a.energy-=12
		a.cut=.30
		a.rope.length=maxf(155,a.rope.length-22)
		a.vel=Vector2(a.vel)+Vector2(a.pos).direction_to(a.anchor)*lerpf(40,155,a.rope.tension)
		_say("Rebicada")
		_fx(a.pos,BLUE,"","rebicar")
	if Input.is_action_just_pressed("cut"):
		cut_queue=.18
	if cut_queue>0:
		if contact.get("valid",false) and a.cut<=0 and a.energy>=12 and a.guard<=0 and a.dodge<=0:
			_cut(a,b,contact)
			cut_queue=0
		else:
			cut_queue=maxf(0,cut_queue-dt)
			if cut_queue==0:_say("Corte · cruze o trecho destacado da linha rival")
	if Input.is_action_just_pressed("tech"):_tech(a,b)
	if Input.is_action_just_pressed("heal"):_start_heal()
	if Input.is_action_just_pressed("special"):
		if lasso_window>0:
			_cast_lasso(a,b)
		elif practice==0:
			_special(a,b)

func _dash(index:int,direction:Vector2) -> void:
	var actor:=actors[index]
	actor.heading=direction.normalized()
	if absf(direction.x)>.05:actor.facing=signf(direction.x)
	actor.vel=Vector2(actor.heading)*440
	actor.dodge=.20
	actor.defense=1.8
	actor.energy-=18
	actor.dash_crossed=false
	if not dash_knot.is_empty() and index==dash_knot.target:
		knot_escape_notice=0
		var escape:=Vector2(dash_knot.direction)
		if Vector2(actor.heading).dot(escape)>.65:
			dash_knot.escape_origin=actor.pos
		else:
			dash_knot.erase("escape_origin")
	_fx(actor.pos,BLUE if actor.team==0 else RED,"","","impulso",Vector2(actor.heading).angle()+PI*.25)

func _track_dash_crossing(before:Vector2,after:Vector2) -> void:
	var rival:=actors[selected]
	if not _alive(rival) or before.distance_squared_to(after)<.001:return
	var rope:PackedVector2Array=rival.rope.points
	var movement:=before.direction_to(after)
	var contact_index:=-1
	var side:=0.0
	var nearest:=INF
	for segment in range(2,rope.size()-3):
		var tangent:=rope[segment].direction_to(rope[segment+1])
		var signed_angle:=tangent.cross(movement)
		if absf(signed_angle)<.45:continue
		var point:Variant=Geometry2D.segment_intersects_segment(before,after,rope[segment],rope[segment+1])
		if point==null:continue
		var distance:=before.distance_squared_to(point)
		if distance<nearest:
			nearest=distance
			contact_index=segment
			side=signf(signed_angle)
	if contact_index<0:return
	var pilot:=actors[controlled]
	pilot.dash_crossed=true
	if not dash_knot.is_empty() and dash_knot.target==selected:return
	var same_pair:bool=not dash_crossing.is_empty() and dash_crossing.pilot==controlled and dash_crossing.target==selected
	var is_return:bool=same_pair and dash_crossing.side!=side and absi(int(dash_crossing.segment)-contact_index)<=DASH_RETURN_SPAN
	if same_pair and not is_return:
		pilot.defense=minf(.65,pilot.defense)
		_say("Volte no sentido oposto pela faixa azul")
		return
	var mark:={"pilot":controlled,"target":selected,"segment":contact_index,"side":side,"until":elapsed+DASH_KNOT_WINDOW}
	if is_return:
		mark.until=elapsed+DASH_KNOT_LIFE
		mark.direction=-movement
		mark.escape_at=elapsed+1.10
		mark.tied_at=elapsed
		knot_escape_notice=0
		dash_knot=mark
		dash_crossing={}
		_fx(_knot_point(mark),GOLD,"","rebicar")
		_say("Nó armado · próximo golpe crítico")
	else:
		dash_crossing=mark
		pilot.defense=minf(.65,pilot.defense)
		_say("Atravesse a faixa azul de volta com Shift")

func _check_escape_travel(index:int) -> void:
	if dash_knot.is_empty() or index!=dash_knot.target or not dash_knot.has("escape_origin"):return
	var actor:=actors[index]
	if actor.dodge<=0:
		dash_knot.erase("escape_origin")
		return
	var displacement:=Vector2(actor.pos)-Vector2(dash_knot.escape_origin)
	if displacement.dot(Vector2(dash_knot.direction))>=DASH_ESCAPE_TRAVEL:
		_release_dash_knot(true)

func _release_dash_knot(escaped:bool) -> void:
	if dash_knot.is_empty():return
	knot_release={"point":_knot_point(dash_knot),"direction":dash_knot.direction,"target":dash_knot.target,"segment":dash_knot.segment,"until":elapsed+.32}
	if escaped:_fx(knot_release.point,BLUE,"NÓ DESFEITO","dodge")
	dash_knot.clear()
	knot_escape_notice=0

func _knot_point(mark:Dictionary) -> Vector2:
	var points:PackedVector2Array=actors[mark.target].rope.points
	return points[mark.segment].lerp(points[mark.segment+1],.5)

func _reset_orbit() -> void:
	orbit_previous=Vector2.ZERO
	orbit_angle=0.0
	orbit_elapsed=0.0
	orbit_grace=0.0
	orbit_pointer=Vector2.ZERO

func _lasso_center(target:Dictionary) -> Vector2:
	return target.rope.points[LASSO_ROPE_POINT]

func _track_lasso(dt:float) -> void:
	var pair:=Vector2i(controlled,selected)
	if pair!=orbit_match:
		orbit_match=pair
		orbit_center=_lasso_center(actors[selected])
		lasso_window=0
		_reset_orbit()
	lasso_window=maxf(0,lasso_window-dt)
	var pilot:=actors[controlled]
	var rival:=actors[selected]
	if lasso_window>0 or pilot.special>0 or not _alive(pilot) or not _alive(rival):
		return
	orbit_center=orbit_center.lerp(_lasso_center(rival),1-exp(-dt*14))
	var offset:=Vector2(pilot.pos)-orbit_center
	var radius:=offset.length()
	if orbit_elapsed>6.0:
		_reset_orbit()
	if radius<LASSO_MIN_RADIUS or radius>LASSO_MAX_RADIUS:
		if orbit_elapsed>0:
			orbit_elapsed+=dt
			orbit_grace+=dt
			if orbit_grace>.36:_reset_orbit()
		orbit_previous=Vector2.ZERO
		return
	orbit_grace=0
	if orbit_previous!=Vector2.ZERO:
		var sweep:=orbit_previous.angle_to(offset)
		if absf(sweep)>.22:
			_reset_orbit()
		else:
			orbit_angle+=sweep
	orbit_previous=offset
	orbit_pointer=offset
	orbit_elapsed+=dt
	if absf(orbit_angle)>=TAU-.12:
		lasso_window=3.0
		_reset_orbit()


func _cast_lasso(pilot:Dictionary,rival:Dictionary) -> void:
	if pilot.special>0 or pilot.guard>0 or pilot.dodge>0 or not _alive(rival):
		return
	if practice>0:
		if practice==1:
			_practice_stage(2)
		else:
			result="Treino concluído"
		return
	if pilot.energy<LASSO_COST:
		_say("Laço · energia insuficiente")
		return
	pilot.energy-=LASSO_COST
	pilot.special=10.0
	pilot.motion=.36
	lasso_window=0
	_hit(pilot,rival,"line",28.0,_lasso_center(rival))
	if rival.dodge<=0:
		rival.slow=2.0
		_fx(_lasso_center(rival),BLUE,"LAÇO DE VENTO","attack","giro")

func _rivals(dt:float) -> void:
	if not dash_knot.is_empty() and elapsed>=float(dash_knot.escape_at):
		var victim:=actors[dash_knot.target]
		var can_dash:bool=victim.guard<=0 and victim.defense<=0 and victim.energy>=18
		if knot_escape_notice>0:
			knot_escape_notice=maxf(0,knot_escape_notice-dt)
			if knot_escape_notice==0 and can_dash:
				var direction:=Vector2(dash_knot.direction)
				var room:=(Vector2(victim.pos)+direction*55).clamp(FIELD.position,FIELD.end)-Vector2(victim.pos)
				if room.dot(direction)>=DASH_ESCAPE_TRAVEL:
					_dash(dash_knot.target,direction)
				dash_knot.escape_at=elapsed+.6
		elif can_dash:
			knot_escape_notice=DASH_ESCAPE_WINDUP
	# Each side gets one designated attacker. Others maneuver and may take over.
	var active_attack:=rival_windup>0 and rival_attacker>=0 and _alive(actors[rival_attacker])
	var attacker_index:=rival_attacker if active_attack else selected
	var enemy:=actors[attacker_index]
	var a:=actors[controlled]
	if attacker_index!=rival_attacker or rival_target<0 or not _alive(actors[rival_target]):
		rival_attacker=attacker_index
		rival_target=controlled
		rival_windup=0
		rival_recovery=.35
	if rival_windup==0 and rival_recovery<=0 and FORMATS[mode].x>1:
		var nearest:=INF
		for i in actors.size():
			var defender:=actors[i]
			if defender.team!=0 or not _alive(defender):continue
			var distance:=Vector2(enemy.pos).distance_to(defender.rope.points[14])
			if distance<nearest:
				nearest=distance
				rival_target=i
	a=actors[rival_target]
	rival_recovery=maxf(0,rival_recovery-dt)
	if rival_windup>0:
		rival_windup=maxf(0,rival_windup-dt)
		if rival_windup==0:
			var crossing:=_crossing(enemy,a)
			if crossing.get("valid",false):_cut(enemy,a,crossing)
			rival_recovery=1.45
	elif rival_recovery==0 and _alive(enemy) and enemy.cut<=0:
		var crossing:=_crossing(enemy,a)
		if crossing.get("valid",false) or Vector2(enemy.pos).distance_to(a.rope.points[14])<145:
			rival_windup=.55
	if FORMATS[mode].x>1:
		var i:=_next(controlled,0)
		if i>=0 and i!=controlled and sin(elapsed*1.85)<-.7:
			var ally:=actors[i]
			var crossing:=_crossing(ally,enemy)
			if crossing.get("valid",false):_cut(ally,enemy,crossing)

func _cut(a:Dictionary,b:Dictionary,c:Dictionary) -> void:
	if a.cut>0 or a.energy<12 or a.dodge>0 or a.guard>0 or not _alive(b):return
	a.cut=.68
	a.motion=.36
	a.energy-=12
	if not c.get("valid",false):
		if a.team==0:_say("Corte fora do cruzamento")
		return
	var tension:=float(a.rope.tension)
	var leverage:=1.0-absf(tension-.65)/.65
	var damage:=13.0+5.0*float(c.angle)+6.0*leverage
	if b.exposed>0:damage+=5.0
	if b.dodge<=0:_fx(c.get("point",b.pos),GOLD,"","attack")
	_hit(a,b,"line",damage,c.get("point",b.pos))

func _hit(a:Dictionary,b:Dictionary,field:String,damage:float,contact_point:Vector2=Vector2.INF) -> void:
	if b.dodge>0:
		_say("Esquiva")
		_fx(b.pos,BLUE,"ESQUIVA","dodge")
		return
	var critical:bool=not dash_knot.is_empty() and is_same(a,actors[dash_knot.pilot]) and is_same(b,actors[dash_knot.target])
	if critical:
		damage*=1.65
		_release_dash_knot(false)
	if b.guard>0:
		damage*=.35
		b.guard=0
		b.guard_wave=.36
		var source:=Vector2(a.pos) if contact_point==Vector2.INF else contact_point
		b.guard_side=Vector2(b.pos).direction_to(source)
		_say("Guarda · dano reduzido")
		_fx(b.pos,BLUE,"GUARDA","")
		_play("block")
	else:
		_say(("Corte" if field=="line" else "Impacto")+(" no rival" if a.team==0 else " sofrido"))
	if b.shield>0:
		damage*=.6
		b.shield=0
		b.guard_wave=.36
		var source:=Vector2(a.pos) if contact_point==Vector2.INF else contact_point
		b.guard_side=Vector2(b.pos).direction_to(source)
	b[field]=maxf(0,b[field]-damage)
	if field=="hull":b.flash=.19
	var damage_at:=Vector2(b.pos) if contact_point==Vector2.INF else contact_point
	_fx(damage_at,GOLD if critical else RED,("CRÍTICO  −%d" if critical else "−%d") % roundi(damage),"critical" if critical or field=="hull" else "")
	if field=="line" and heal_target>=0 and is_same(b,actors[heal_target]):
		heal_cast=0
		heal_target=-1
		heal_clock=3
		_say("Cura interrompida · item preservado")

func _tech(a:Dictionary,b:Dictionary) -> void:
	if a.skill>0 or a.energy<24 or a.guard>0 or a.dodge>0:return
	a.skill=6
	a.motion=.36
	a.energy-=24
	match a.profile[1]:
		"Vento":
			a.boost=3
			_fx(a.pos,BLUE,"","rebicar","giro")
			_say("Embalado · curvas mais rápidas")
		"Flora":
			a.shield=5
			_say("Protegido · reduz o próximo impacto")
		"Água":
			a.slow=0
			a.line=minf(100,a.line+9)
			_say("Fluxo calmo · linha aliviada")
		"Brasa":
			if Vector2(a.pos).distance_to(b.pos)<=155:
				var damage:=20.0*(1.15 if b.profile[1]=="Flora" else 1.0)
				_hit(a,b,"hull",damage)
				if b.dodge<=0:b.slow=2.2
			else:_say("Brasa · alvo fora do alcance")

func _start_heal() -> void:
	if potions<=0 or heal_clock>0 or heal_cast>0:return
	if actors[controlled].line>=100:
		_say("Linha já está cheia")
		return
	heal_target=controlled
	heal_cast=.65
	_say("Preparando cura")

func _draw() -> void:
	if actors.is_empty():return
	draw_texture_rect(ARENA,Rect2(0,0,1000,562),false,Color("#9caec7"))
	draw_rect(Rect2(0,0,1000,562),Color("#121e414a"),true)
	var haze:=PackedColorArray([Color("#16274300"),Color("#16274388"),Color("#162743aa"),Color("#16274300")])
	for band in 3:
		var top:=94.0+band*113
		draw_polygon(PackedVector2Array([Vector2(0,top),Vector2(1000,top),Vector2(1000,top+113),Vector2(0,top+113)]),
			PackedColorArray([haze[band],haze[band],haze[band+1],haze[band+1]]))

	for i in actors.size():
		var a:=actors[i]
		if not _alive(a):continue
		var color:=BLUE if a.team==0 else Color("#ffad73")
		var rope:PackedVector2Array=a.rope.points
		if not knot_release.is_empty() and i==knot_release.target:
			rope=rope.duplicate()
			var tick:=1.0-(float(knot_release.until)-elapsed)/.32
			var center:=int(knot_release.segment)
			var jerk:=Vector2(knot_release.direction)*sin(tick*TAU*1.35)*(1.0-tick)*15
			for sample in range(maxi(1,center-3),mini(rope.size()-1,center+4)):
				rope[sample]+=jerk*(1.0-absf(sample-center)/4.0)
		var focus:=1.0 if i==controlled or i==selected else .35
		draw_polyline(rope,Color("#0b1325cc",.8*focus),6,true)
		draw_polyline(rope,Color(color,.18*focus),9,true)
		draw_polyline(rope,Color(color,.55*focus),4,true)
		draw_polyline(rope,Color("#fffaf1",focus),1.25,true)
		if i==selected and result.is_empty():
			var exposed:bool=a.exposed>0
			var valid_span:=rope.slice(5 if exposed else 8,23 if exposed else 21)
			draw_polyline(valid_span,Color("#dba2ff" if exposed else "#ffa778"),2.5,true)
		if i==rival_target and rival_windup>0:
			var strike:=rope.slice(8,21)
			var pulse:=.55+.42*sin(presentation_time*20)
			draw_polyline(strike,Color(RED,.3),8,true)
			draw_polyline(strike,Color(RED,pulse),3,true)
		if a.rope.tension>.1:
			var at:=int(fposmod(elapsed*1.7,1.0)*(rope.size()-1))
			draw_line(rope[at],rope[at+1],Color(1,1,.95,a.rope.tension),2,true)
		draw_circle(a.anchor,4,color)
	for i in actors.size():
		var a:=actors[i]
		if not _alive(a):continue
		var main:bool=a.art in ["rabbito","mata"]
		var color:=BLUE if a.team==0 else RED
		var y_bob:=sin(presentation_time*4+i)*4.0
		var pos:=Vector2(a.pos)+Vector2(0,y_bob)
		var heading:=Vector2(a.heading)
		var faces_left:bool=a.facing<0
		var native_left:bool=a.art=="mata"
		var flip:=faces_left!=native_left
		var angle:=heading.y*.48*(-1 if native_left else 1)
		var extent:=Vector2(278,170) if main and FORMATS[mode]==Vector2i(1,1) else Vector2(146,93) if main else Vector2(86,86)
		if FORMATS[mode]==Vector2i(1,1):
			var separation:=Vector2(actors[0].pos).distance_to(actors[1].pos)
			extent*=lerpf(.70,1.0,smoothstep(75.0,240.0,separation))
		var sprite:=_frame(a)
		var vertical:=absf(heading.y)>.79
		if vertical:
			sprite=VERTICAL_FLIGHT[a.art][0 if heading.y<0 else 1]
			flip=faces_left!=(a.art=="mata" or (a.art=="azulao" and heading.y<0))
			var art_size:=sprite.get_size()
			extent=art_size*minf(extent.x*(.74 if main else .96)/art_size.x,extent.y*1.15/art_size.y)
			angle=0
		var shell:bool=a.guard>0 or a.shield>0 or a.guard_wave>0
		var radius:=extent.length()*.5+5
		var strength:=maxf(.45,maxf(a.guard/.42,minf(1,a.shield)))
		if shell:_draw_guard_shell(pos,radius,color,strength,false)
		draw_set_transform(pos,angle)
		if main:
			if vertical:draw_set_transform(pos,heading.angle()+(PI if faces_left else 0))
			for ray in 3:
				var dir:float=1 if faces_left else -1
				var y:=float(ray-1)*15
				var streak := PackedVector2Array([Vector2(dir*39,y),Vector2(dir*extent.x*.36,y-ray*3),Vector2(dir*(extent.x*.53+ray*9),y+9)])
				draw_polyline(streak,Color(color,.24+absf(a.vel.x)*.001),3,true)
		draw_set_transform(pos,angle*(-1 if flip else 1),Vector2(-1 if flip else 1,1))
		for offset in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			draw_texture_rect(sprite,Rect2(-extent*.5+offset*1.5,extent),false,Color("#10182dbb"))
		draw_texture_rect(sprite,Rect2(-extent*.5,extent),false,Color(1,.69,.59) if a.flash>0 else Color.WHITE)
		draw_set_transform(Vector2.ZERO)
		if shell:
			_draw_guard_shell(pos,radius,color,strength,true)
			if a.guard_wave>0:
				var progress:=1.0-float(a.guard_wave)/.36
				var side:=Vector2(a.guard_side).angle()
				draw_arc(pos,radius+12*progress,side-.13-progress,side+.13+progress,32,Color("#dcffff",1-progress),3,true)
		if (i==controlled or i==selected) and FORMATS[mode]!=Vector2i(1,1):
			_centered_text(pos+Vector2(0,-extent.y*.5-3),"VOCÊ" if i==controlled else "ALVO",11,color)
		if FORMATS[mode]!=Vector2i(1,1):
			var chip:=pos+Vector2(-33,extent.y*.5+2)
			if a.team==0:
				draw_circle(chip,4,BLUE)
			else:
				draw_colored_polygon(PackedVector2Array([chip+Vector2.UP*5,chip+Vector2.RIGHT*5,chip+Vector2.DOWN*5,chip+Vector2.LEFT*5]),RED)
		if FORMATS[mode]!=Vector2i(1,1):
			draw_rect(Rect2(pos+Vector2(-24,extent.y*.5),Vector2(48*a.line/100,3)),color)
	_draw_bursts()
	_draw_lasso_guide()
	_draw_dash_knot()
	if not contact.is_empty():
		var point:Vector2=contact.point
		var ready:bool=contact.valid and actors[controlled].cut<=0 and actors[controlled].energy>=12
		var r:=9.0 if ready else 4.0
		if ready:
			draw_circle(point,13,Color("#0c182bcc"))
			draw_arc(point,13,0,TAU,32,GOLD,2,true)

		draw_circle(point,r*1.8,Color(GOLD,.19))
		for i in 4:
			var dir:=Vector2.from_angle(i*PI*.25)
			draw_line(point-dir*r,point+dir*r,Color("#fff7ca"),1.6,true)
	var a:=actors[controlled]
	var b:=actors[selected]
	_duel_card(a,false)
	_duel_card(b,true)
	if b.exposed>0:_text(Vector2(674,133),"LINHA EXPOSTA",10,Color("#dba2ff"))
	_hex(Rect2(427,10,146,52),BLUE)
	if practice>0:
		_centered_text(Vector2(500,37),"TREINO",21,Color.WHITE)
		_centered_text(Vector2(500,54),"Laço  %d / 2" % practice,12,BLUE)
	else:
		var seconds:=ceili(maxf(0,ROUND_TIME-elapsed))
		_centered_text(Vector2(500,41),"%02d:%02d" % [seconds/60,seconds%60],33,Color.WHITE)
		_centered_text(Vector2(500,56),"Rodada 1/1",12,Color.WHITE)
	_wind_dial(Vector2(946,158))
	_draw_hotbar(a)
	if FORMATS[mode].x>1:_draw_team_strip()
	if practice>0 and result.is_empty():
		_panel(Rect2(20,270,274,43),Color("#172957"),BLUE)
		_text(Vector2(30,288),"TREINO %s / 2" % practice,13,BLUE)
		_text(Vector2(30,305),"Contorne a linha parada" if practice==1 else "Contorne a linha em movimento",12,Color.WHITE)
	elif notice_clock>0 and lasso_window<=0:
		_panel(Rect2(20,276,300,27),Color("#172957"),GOLD)
		_text(Vector2(31,295),notice,13,GOLD)
	if special_flash>0:
		var fade:=minf(1,special_flash*4)
		draw_colored_polygon(PackedVector2Array([Vector2(640,524),Vector2(731,437),Vector2(1000,395),Vector2(1000,490)]),Color(.26,.18,.59,.74*fade))
		draw_texture_rect(_portrait(a),Rect2(867,380,119,99),false,Color(1,1,1,fade))
		draw_line(Vector2(670,518),Vector2(996,450),Color(.71,.55,1,fade),3,true)
		_hex(Rect2(680,454,308,54),Color("#ab8bff"))
		_text(Vector2(693,489),"TEMPESTADE CELESTIAL!",21,Color.WHITE)
	if not result.is_empty():
		_hex(Rect2(347,223,306,100),GOLD)
		_centered_text(Vector2(500,268),result,34,GOLD)
		_centered_text(Vector2(500,300),"Enter / Start para repetir",16,Color.WHITE)

func _draw_guard_shell(center:Vector2,radius:float,color:Color,strength:float,front:bool) -> void:
	if not front:
		draw_circle(center,radius,Color(color,.07*strength),true,-1.0,true)
		draw_arc(center,radius,PI,TAU,64,Color(color,.29*strength),1.5,true)
		draw_arc(center,radius-5,-2.9,-1.9,36,Color("#e1fbff",.64*strength),1.6,true)
		return
	draw_arc(center,radius,0,PI,64,Color(color,.22*strength),8,true)
	draw_arc(center,radius,0,PI,64,Color(color,.82*strength),2,true)
	draw_arc(center,radius-8,.1,1.5,32,Color("#e1fbff",.5*strength),1.5,true)

func _draw_lasso_guide() -> void:
	var pilot:=actors[controlled]
	var rival:=actors[selected]
	if not result.is_empty() or pilot.special>0 or not _alive(pilot) or not _alive(rival):return
	var center:=orbit_center if orbit_match==Vector2i(controlled,selected) else _lasso_center(rival)
	var armed:=lasso_window>0
	var color:=GOLD if armed else BLUE
	draw_circle(center,6,Color("#111a30"))
	draw_arc(center,6,0,TAU,24,color,1.5,true)

	var progress:=1.0 if armed else absf(orbit_angle)/TAU
	var radius:=(LASSO_MIN_RADIUS+LASSO_MAX_RADIUS)*.5
	var pointer:=orbit_pointer if orbit_pointer!=Vector2.ZERO else Vector2(pilot.pos)-center
	var start:=pointer.angle()-orbit_angle
	var sweep:=TAU if armed else orbit_angle
	draw_arc(center,radius,0,TAU,64,Color("#8bbff366" if orbit_grace==0 else "#ffa869"),1.5,true)
	if progress>.01:
		draw_arc(center,radius,minf(start,start+sweep),maxf(start,start+sweep),64,color,2.5,true)
	if orbit_grace>0:
		var resume:=center+pointer.normalized()*radius
		draw_circle(resume,5,Color("#ffbc76"))

func _draw_dash_knot() -> void:
	if result!="" or practice>0:return
	if not knot_release.is_empty():
		var progress:=1.0-(float(knot_release.until)-elapsed)/.32
		_draw_knot_braid(knot_release.point,Vector2(knot_release.direction).orthogonal().angle(),1.0,progress)
	if not dash_knot.is_empty():
		var points:PackedVector2Array=actors[dash_knot.target].rope.points
		var segment:=int(dash_knot.segment)
		var tangent:=points[segment].direction_to(points[segment+1])
		var point:=_knot_point(dash_knot)
		var draw_in:=smoothstep(0.0,.2,elapsed-float(dash_knot.tied_at))
		_draw_knot_braid(point,tangent.angle(),draw_in,0)
		var left:=clampf((float(dash_knot.until)-elapsed)/DASH_KNOT_LIFE,0,1)
		draw_arc(point,24,-PI*.5,-PI*.5+TAU*left,40,Color(GOLD,.67),1.5,true)
		if knot_escape_notice>0:
			var direction:=Vector2(dash_knot.direction)
			var anchor:=Vector2(actors[dash_knot.target].pos)+direction*64
			anchor=anchor.clamp(Vector2(58,106),Vector2(942,447))
			var opacity:=.58+.42*sin((DASH_ESCAPE_WINDUP-knot_escape_notice)*13)
			draw_set_transform(anchor,direction.angle())
			draw_texture_rect(ESCAPE_ARROW,Rect2(-38,-15,76,30),false,Color(1,1,1,opacity))
			draw_set_transform(Vector2.ZERO)
		return
	if dash_crossing.is_empty():return
	if dash_crossing.pilot!=controlled or dash_crossing.target!=selected:return
	var rope:PackedVector2Array=actors[selected].rope.points
	var segment:=int(dash_crossing.segment)
	var first:=maxi(2,segment-DASH_RETURN_SPAN)
	var last:=mini(rope.size()-2,segment+DASH_RETURN_SPAN+2)
	var span:=rope.slice(first,last)
	var pilot:=actors[controlled]
	var ready:bool=pilot.defense<=0 and pilot.energy>=18
	var pulse:=.74+.26*sin(presentation_time*11) if ready else .4
	draw_polyline(span,Color("#101e3c",.88),8,true)
	draw_polyline(span,Color(BLUE,pulse),4,true)
	draw_polyline(span,Color("#e3faff",pulse),1.25,true)
	for point in [span[0],span[-1]]:
		draw_circle(point,4,Color(BLUE,pulse),true,-1,true)
	var at:=_knot_point(dash_crossing)
	draw_arc(at,10,0,TAU,28,Color(BLUE,pulse),2,true)

func _draw_knot_braid(center:Vector2,angle:float,tight:float,opening:float) -> void:
	var loop:=PackedVector2Array()
	for i in 41:
		var phase:=float(i)/40*TAU
		var x:=sin(phase)*18.0*lerpf(.28,1.0,tight)+(float(i)/40.0-.5)*49.0*opening
		var y:=sin(phase*2)*9.0*tight*(1.0-opening)
		loop.append(center+Vector2(x,y).rotated(angle))
	var opacity:=1.0-opening
	var weave:=lerpf(1.5,3.5,tight)
	draw_polyline(loop,Color("#0a142c",opacity),weave+4.0,true)
	draw_polyline(loop,Color(BLUE,opacity),weave,true)
	draw_polyline(loop.slice(18,24),Color("#d0f7ff",opacity),1.6,true)
	draw_arc(center,6,0,TAU,25,Color(GOLD,opacity*tight),1.8,true)

func _draw_team_strip() -> void:
	var x:=22.0
	for i in actors.size():
		var ally:=actors[i]
		if ally.team!=0:continue
		var threatened:=i==rival_target and rival_windup>0
		var rect:=Rect2(x,121,41,34)
		draw_rect(rect,Color("#0b162c"))
		_draw_art(_portrait(ally),rect.get_center(),Vector2(34,28),Color.WHITE if _alive(ally) else Color(.4,.4,.4))
		draw_rect(rect,RED if threatened else BLUE if i==controlled else Color("#46637e"),false,2)
		if threatened:_text(rect.position+Vector2(28,13),"!",13,RED)
		draw_rect(Rect2(x+2,152,37*float(ally.line)/100,2),BLUE)
		x+=47

func _duel_card(actor:Dictionary,right:bool) -> void:
	var accent:=RED if right else BLUE
	var box:=Rect2(663,17,319,58) if right else Rect2(18,17,319,58)
	_hex(box,accent)
	var portrait:=_portrait(actor)
	var portrait_rect:=Rect2(883,7,99,88) if right else Rect2(18,7,99,88)
	_hex(portrait_rect,accent)
	draw_texture_rect(portrait,portrait_rect.grow(-5),false)
	var x:=674.0 if right else 122.0
	_text(Vector2(x,36),("P2   " if right else "P1   ")+str(actor.profile[0]),20,Color.WHITE)
	_text(Vector2(x+165,35),"Nv. 45",12,accent)
	_text(Vector2(x,54),"Integridade da Linha",11,Color.WHITE)
	draw_rect(Rect2(x,59,165,7),Color("#19233a"))
	draw_rect(Rect2(x,59,165*float(actor.line)/100,7),Color("#92ed59"))
	_text(Vector2(x+171,66),"%d / 100" % ceili(actor.line),10,Color.WHITE)
	for i in 3:
		var label: String = ["Tensão","Energia","Estabilidade"][i]
		var values := ["%d%%"%roundi(actor.rope.tension*100),str(roundi(actor.energy)),"%d%%"%roundi(actor.hull)]
		draw_rect(Rect2(x,76+16*i,135,15),Color("#122649bb"))
		_text(Vector2(x+4,88+16*i),label,11,Color.WHITE)
		_text(Vector2(x+99,88+16*i),values[i],11,accent)

func _portrait(actor:Dictionary) -> Texture2D:
	if actor.art=="rabbito":return AERON_PORTRAIT
	if actor.art=="mata":return PYRON_PORTRAIT
	return actor.profile[4]

func _hex(rect:Rect2,accent:Color) -> void:
	var a:=rect.position
	var b:=rect.end
	var bevel:=minf(16,rect.size.x*.16)
	var points:=PackedVector2Array([a+Vector2(bevel,0),Vector2(b.x-bevel,a.y),Vector2(b.x,rect.get_center().y),b-Vector2(bevel,0),Vector2(a.x+bevel,b.y),Vector2(a.x,rect.get_center().y)])
	draw_texture_rect(HUD_FRAME,rect,false)
	var outline:=points.duplicate()
	outline.append(points[0])
	draw_polyline(outline,Color(accent,.24),6,true)
	draw_polyline(outline,accent,1.35,true)

func _wind() -> float:
	return sin(elapsed*1.9)*14.0+8.0

func _centered_text(center:Vector2,value:String,size:int,color:Color) -> void:
	var width:=ThemeDB.fallback_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	_text(center-Vector2(width*.5,0),value,size,color)

func _wind_dial(center:Vector2) -> void:
	var wind:=_wind()
	draw_texture_rect(WIND_FACE,Rect2(center-Vector2(41,41),Vector2(82,82)),false)
	draw_arc(center,32.5,-PI*.5,-PI*.5+maxf(.01,absf(wind)/22.0)*PI,32,BLUE,2,true)
	_text(center+Vector2(-30,4),"O",9,Color.WHITE)
	_text(center+Vector2(24,4),"L",9,Color.WHITE)
	var calm:=absf(wind)<.5
	if calm:
		draw_circle(center,3.0,BLUE)
	else:
		draw_set_transform(center,PI if wind<0 else 0.0)
		draw_texture_rect(WIND_NEEDLE,Rect2(-23,-11,46,22),false)
		draw_set_transform(Vector2.ZERO)
	_centered_text(center+Vector2(0,-16),"VENTO",9,Color.WHITE)
	_centered_text(center+Vector2(0,24),"Calmaria" if calm else "%.1f px/s"%absf(wind),10,BLUE)

func _draw_hotbar(actor:Dictionary) -> void:
	var actions:=[["Q","Giro Fantasma" if actor.art=="rabbito" else "Técnica","tech",actor.skill],["SHIFT","Impulso","dash",actor.defense],["E","Apertar Laço" if lasso_window>0 else "Laço de Vento" if practice>0 else "Tempestade","storm",actor.special],["G","Escudo de Vento","shield",actor.defense]]
	for i in actions.size():
		var card: Array = actions[i]
		var x:=327.0+88*i
		var accent:=GOLD if i==2 and lasso_window<=0 else BLUE
		var out_of_range:=i==2 and lasso_window<=0 and (practice>0 or not _storm_in_range(actor,actors[selected]))
		var ready:bool=float(card[3])<=0 and not out_of_range
		_hex(Rect2(x,460,83,68),accent if ready else Color("#64788c"))
		var tint:=Color.WHITE if ready else Color(.65,.68,.75,.48)
		_draw_art(HUD_ICONS[0] if i==2 and lasso_window>0 else HUD_ICONS[i],Vector2(x+41.5,481),Vector2(48,36),tint)
		_centered_text(Vector2(x+41.5,508),card[1],10,Color.WHITE)
		_centered_text(Vector2(x+41.5,522),"%ds"%ceili(card[3]) if card[3]>0 else ("Contorne" if practice>0 else "Sem alcance") if out_of_range else card[0],10,accent)
		if i==2 and lasso_window>0:
			draw_rect(Rect2(x+14,525,55*lasso_window/3.0,2),GOLD)
	if actor.defense>0:
		_centered_text(Vector2(588,454),"GUARDA / IMPULSO · RECARGA COMPARTILHADA",9,Color.WHITE)
	draw_rect(Rect2(12,454,182,95),Color("#122649d7"))
	_text(Vector2(22,472),"WASD · Pilotar",12,Color.WHITE)
	_text(Vector2(22,489),"Z / C · Recolher / soltar",12,Color.WHITE)
	_text(Vector2(22,506),"ESPAÇO · Cortar",12,Color.WHITE)
	_text(Vector2(22,523),"R · Rebicar   H · Curar",12,Color.WHITE)
	_text(Vector2(22,540),"Cura "+("%ds"%ceili(heal_clock) if heal_clock>0 else "pronta")+" · "+str(potions)+" itens",11,BLUE)

func _special(actor:Dictionary,target:Dictionary) -> void:
	if actor.special>0 or actor.energy<55 or actor.dodge>0 or actor.guard>0:return
	if not _storm_in_range(actor,target):
		_say("Tempestade · aproxime-se do alvo")
		return
	actor.energy-=55
	actor.special=18
	actor.boost=3
	actor.motion=.36
	special_flash=1.8
	_fx(actor.pos,GOLD,"","critical","tempestade")
	_hit(actor,target,"hull",26)
	if target.dodge<=0 and _alive(target):target.exposed=3.5

func _storm_in_range(actor:Dictionary,target:Dictionary) -> bool:
	return _alive(target) and Vector2(actor.pos).distance_to(target.pos)<=STORM_REACH

func _text(at:Vector2,value:String,size:int,color:Color) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _run_checks() -> void:
	var failures:=0
	for i in FORMATS.size():
		_start(i)
		for tick in 240:_step(1.0/60)
		var all_finite:=true
		for a in actors:
			all_finite=all_finite and Vector2(a.pos).is_finite() and a.rope.points.size()==25
		if actors.size()!=FORMATS[i].x+FORMATS[i].y or not all_finite:failures+=1
	_start(0)
	var a:=actors[0]
	var b:=actors[1]

	var original_length:float=a.rope.length
	test_mode=false
	Input.action_press("reel")
	for tick in 30:_fly(0,1.0/60)
	Input.action_release("reel")
	var short_length:float=a.rope.length
	if short_length>=original_length-30:failures+=1
	Input.action_press("release")
	for tick in 30:_fly(0,1.0/60)
	Input.action_release("release")
	test_mode=true
	if a.rope.length<=short_length+30:failures+=1
	_cut(a,b,{})
	if b.line!=100 or a.energy!=88:failures+=1
	a.cut=0
	b.dodge=.2
	_cut(a,b,{"valid":true,"angle":1.0})
	if b.line!=100:failures+=1
	a.cut=0
	b.dodge=0
	_cut(a,b,{"valid":true,"angle":1.0})
	if b.line>=100:failures+=1
	a.line=50
	_start_heal()
	_hit(b,a,"line",12)
	if potions!=2 or heal_cast!=0 or heal_clock!=3:failures+=1
	heal_clock=0
	_start_heal()
	for tick in 45:_step(1.0/60)
	if a.line!=63 or potions!=1 or heal_clock<29:failures+=1
	_tech(a,b)
	if a.boost<=0 or a.skill<=0 or bursts.back().art!="giro":failures+=1
	a.energy=100
	a.special=0
	a.pos=Vector2(400,180)
	b.pos=Vector2(660,180)
	_special(a,b)
	if a.energy!=100 or a.special!=0 or special_flash!=0:failures+=1
	b.pos=Vector2(480,180)
	_special(a,b)
	if a.energy!=45 or a.special!=18 or b.hull>=100 or special_flash<=0 or b.exposed<=0:failures+=1
	if bursts[-2].art!="tempestade" or bursts[-2].point!=a.pos or bursts.back().art!="impacto":failures+=1
	elapsed=0
	if absf(_wind()-8.0)>.001:failures+=1
	elapsed=PI*1.5/1.9
	if absf(_wind()+6.0)>.001:failures+=1
	var hull_after:float=b.hull
	_special(a,b)
	if b.hull!=hull_after:failures+=1
	elapsed=ROUND_TIME
	_step(1.0/60)
	if result.is_empty():failures+=1
	var own_line:=PackedVector2Array([Vector2(-40,25),Vector2(40,25)])
	var rival_line:=PackedVector2Array([Vector2(0,0),Vector2(0,100)])
	if Rope.crossing(own_line,rival_line).get("valid",false):failures+=1
	if not Rope.crossing(own_line,rival_line,true).get("valid",false):failures+=1
	failures+=_check_lasso()
	failures+=_check_dash_knot()
	print("Laboratório · cinco formatos, corda, corte, esquiva, cura, interrupção, técnica, especial, efeitos, vento, cronômetro, laço e nó de impulso · ",failures," falhas")
	get_tree().quit(int(failures>0))

func _check_lasso() -> int:
	_start(0)
	var pilot:=actors[controlled]
	var rival:=actors[selected]
	for sweep in [PI,0.0,TAU,-TAU]:
		lasso_window=0
		_reset_orbit()
		for i in 121:
			var angle:=float(sweep)*i/120.0
			rival.rope.points[LASSO_ROPE_POINT]+=Vector2(.3,.1)
			pilot.pos=_lasso_center(rival)+Vector2.from_angle(angle)*79
			_track_lasso(1.0/60)
		if (lasso_window>0)!=(absf(sweep)==TAU):return 1
	_cast_lasso(pilot,rival)
	if pilot.energy!=68 or pilot.special!=10 or rival.line!=72 or rival.slow!=2 or lasso_window!=0:
		return 1
	_start(2)
	lasso_window=3
	orbit_match=Vector2i(controlled,selected)
	selected+=1
	_track_lasso(1.0/60)
	return int(lasso_window>0)

func _check_dash_knot() -> int:
	_start(0)
	var pilot:=actors[controlled]
	var rival:=actors[selected]
	rival.rope.reset(Vector2(500,475),Vector2(500,150))
	var left:=Vector2(480,310)
	var right:=Vector2(550,310)
	_track_dash_crossing(left,right)
	if dash_crossing.is_empty() or not dash_knot.is_empty():return 1
	_track_dash_crossing(left,right)
	if dash_crossing.is_empty() or not dash_knot.is_empty():return 1
	_track_dash_crossing(right,left)
	if dash_knot.is_empty():return 1
	_hit(pilot,rival,"line",20)
	if rival.line!=67 or not dash_knot.is_empty():return 1
	_track_dash_crossing(left,right)
	_track_dash_crossing(right,left)
	_dash(selected,Vector2.LEFT)
	if dash_knot.is_empty():return 1
	_dash(selected,Vector2.RIGHT)
	_check_escape_travel(selected)
	if dash_knot.is_empty():return 1
	rival.pos=Vector2(rival.pos)+Vector2.RIGHT*30
	_check_escape_travel(selected)
	if not dash_knot.is_empty():return 1
	_track_dash_crossing(left,right)
	elapsed+=DASH_KNOT_WINDOW+.1
	_step(1.0/60)
	return int(not dash_crossing.is_empty())

func _capture() -> void:
	for frame in 30: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("SOULFLIGHT_CAPTURE")
	if "--especial" in OS.get_cmdline_user_args():
		actors[selected].pos=Vector2(actors[0].pos)+Vector2(205,5)
		_special(actors[0],actors[selected])
		for frame in 7: await get_tree().physics_frame
		queue_redraw()
		await RenderingServer.frame_post_draw
	if "--guarda" in OS.get_cmdline_user_args():
		actors[controlled].guard=.42
		queue_redraw()
		await RenderingServer.frame_post_draw
	if "--laco" in OS.get_cmdline_user_args():
		var pilot:=actors[controlled]
		for i in 121:
			pilot.pos=_lasso_center(actors[selected])+Vector2.from_angle(i*TAU/120.0)*79
			_track_lasso(1.0/60)
		pilot.rope.reset(pilot.anchor,pilot.pos)
		queue_redraw()
		await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	sound_player.stop()
	sound_player.stream=null
	await get_tree().process_frame
	get_tree().quit(error)
func _load_presentation() -> void:
	for id in SPRITE_IDS:
		var clips := {}
		for state in ["idle","attack","victory","defeat"]:
			var frames: Array[Texture2D] = []
			for i in 6:
				var file := "res://arte/animacoes/%s-%s-%d.png" % [id,state,i]
				if ResourceLoader.exists(file):frames.append(load(file))
			clips[state]=frames
		animations[id]=clips
	for clip in ["attack","block","dodge","victory","defeat","critical","cura","rebicar"]:
		sounds[clip]=load("res://audio/"+clip+".wav")

func _frame(actor:Dictionary) -> Texture2D:
	if actor.art=="rabbito":return AERON
	if actor.art=="mata":return PYRON
	var state:="attack" if actor.motion>0 else "idle"
	if not result.is_empty():
		state="victory" if (actor.team==0)==(result=="Vitória") else "defeat"
	var frames:Array=animations[actor.art][state]
	if frames.is_empty():return actor.profile[4]
	var tick:=int((.36-actor.motion)*16) if state=="attack" else int(presentation_time*10)
	return frames[clampi(tick,0,frames.size()-1) if state=="attack" else tick%frames.size()]

func _update_format_buttons() -> void:
	for i in format_buttons.size():
		var panel:=StyleBoxFlat.new()
		panel.bg_color=Color("#2d6f7e") if i==mode else Color("#213945")
		panel.border_color=BLUE if i==mode else Color("#43606a")
		panel.border_width_bottom=2
		panel.corner_radius_top_left=5
		panel.corner_radius_top_right=5
		format_buttons[i].add_theme_stylebox_override("normal",panel)
		format_buttons[i].add_theme_color_override("font_color",Color.WHITE)

func _play(id:String) -> void:
	if test_mode or not sounds.has(id):return
	sound_player.stream=sounds[id]
	sound_player.play()

func _draw_art(texture:Texture2D,center:Vector2,bounds:Vector2,tint:Color) -> void:
	var original:=texture.get_size()
	var size:=original*minf(bounds.x/original.x,bounds.y/original.y)
	draw_texture_rect(texture,Rect2(center-size*.5,size),false,tint)

func _fx(point:Vector2,color:Color,label:String,clip:String,art:String="",angle:float=0.0) -> void:
	if art.is_empty():
		match clip:
			"attack","critical": art="impacto"
			"block": art="escudo"
			"dodge","rebicar": art="giro"
	var duration:=.82 if art=="tempestade" else .46
	bursts.append({"point":point,"color":color,"label":label,"life":duration,"duration":duration,"art":art,"angle":angle})
	_play(clip)

func _draw_bursts() -> void:
	for burst in bursts:
		var life:=float(burst.life)
		var t:=1.0-life/float(burst.duration)
		var alpha:=minf(1.0,(1.0-t)*1.45)
		var point:=Vector2(burst.point)
		var art:=str(burst.art)
		if COMBAT_ART.has(art):
			var size:=220.0 if art=="tempestade" else 128.0 if art=="escudo" else 86.0
			var extent:=size*lerpf(.65,1.18,ease(t,.48))
			var angle:=float(burst.angle)+(t*.3 if art in ["giro","tempestade"] else 0.0)
			draw_set_transform(point,angle)
			_draw_art(COMBAT_ART[art],Vector2.ZERO,Vector2(extent,extent),Color(1,1,1,alpha*.87))
			draw_set_transform(Vector2.ZERO)
		if not str(burst.label).is_empty():
			var at:=point+Vector2(12,-19-t*24)
			_text(at+Vector2(1,2),burst.label,19,Color("#11172b",alpha))
			_text(at,burst.label,19,Color(burst.color,alpha))

func _panel(rect:Rect2,color:Color,accent:Color) -> void:
	var a:=rect.position
	var b:=rect.end
	draw_colored_polygon(PackedVector2Array([a+Vector2(9,0),Vector2(b.x,a.y),b-Vector2(9,0),Vector2(a.x,b.y)]),color)
	draw_line(a+Vector2(9,0),Vector2(b.x,a.y),accent,2,true)

func _draw_scorecard(actor:Dictionary,at:Vector2,accent:Color,team:String) -> void:
	_panel(Rect2(at,Vector2(267,79)),Color("#182934"),accent)
	draw_texture_rect(actor.profile[4],Rect2(at+Vector2(12,7),Vector2(54,54)),false)
	_text(at+Vector2(69,18),team+"  /  "+str(actor.profile[1]).to_upper(),11,accent)
	_text(at+Vector2(69,37),actor.profile[0],18,Color.WHITE)
	_meter(at+Vector2(69,45),"LIN",actor.line,accent)
	_meter(at+Vector2(69,56),"ARM",actor.hull,Color("#e2a87d"))
	_meter(at+Vector2(69,67),"ENE",actor.energy,GOLD)

func _meter(at:Vector2,label:String,value:float,tint:Color) -> void:
	_text(at+Vector2(0,7),label,9,Color("#cad8dc"))
	draw_rect(Rect2(at+Vector2(28,2),Vector2(135,5)),Color("#354954"))
	draw_rect(Rect2(at+Vector2(28,2),Vector2(135*clampf(value/100,0,1),5)),tint)
	_text(at+Vector2(170,7),str(ceili(value)),9,Color.WHITE)