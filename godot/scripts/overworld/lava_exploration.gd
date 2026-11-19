extends Node2D

const Actor = preload("res://scripts/overworld/lava_actor.gd")
const KaelModel = preload("res://assets/overworld/lava-atores/kael.glb")
const KirinModel = preload("res://assets/overworld/lava-atores/kirin.glb")
const BRIDGE_Y := 4.0
const ROCKS := [Vector2(2.8,2.2), Vector2(3.8,8.4), Vector2(12.1,5.4)]
var kael: Actor
var kirin: Actor
var map
var patrol_direction := 1.0
var proud := false
var help: Label
var camera := Camera2D.new()

func _ready() -> void:
	map = get_parent()
	var backdrop := CanvasLayer.new()
	backdrop.layer = -8
	add_child(backdrop)
	var haze := ColorRect.new()
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(haze)
	haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var atmosphere := ShaderMaterial.new()
	atmosphere.shader = preload("res://shaders/overworld/lava_caldera.gdshader")
	haze.material = atmosphere
	for i in map.props.get_child_count():
		var rock: Node2D = map.props.get_child(i)
		rock.get_node("Visual").hide()
		basalt(rock,i)
	var bridge := Node2D.new()
	map.add_child(bridge)
	map.move_child(bridge,map.props.get_index())
	# Closely fitted basalt slabs cross the actual upper banks.
	var center := 7.7+sin(BRIDGE_Y*0.55)*1.15
	for i in 10:
		var x := center-2.65+0.53*i
		var lip := .64+.055*sin(i*1.7)
		var corners := PackedVector2Array([map.iso(x,BRIDGE_Y-lip+.09),map.iso(x+.09,BRIDGE_Y-lip),map.iso(x+.49,BRIDGE_Y-lip),map.iso(x+.53,BRIDGE_Y-lip+.12),map.iso(x+.53,BRIDGE_Y+lip-.09),map.iso(x+.45,BRIDGE_Y+lip),map.iso(x+.08,BRIDGE_Y+lip),map.iso(x,BRIDGE_Y+lip-.12)])
		for j in [3,4,5,6]:
			var a := corners[j]
			var b := corners[(j+1)%8]
			facet(bridge,PackedVector2Array([a,b,b+Vector2.DOWN*8,a+Vector2.DOWN*8]),Color("513a42") if j<5 else Color("352e39"))
		var tone := Color("74636a").lerp(Color("978384"),.5+.45*sin(i*3.4))
		facet(bridge,corners,tone)
		var crack := Line2D.new()
		var middle := corners[0].lerp(corners[4],.48+.15*sin(i))
		crack.points = PackedVector2Array([corners[1],middle+Vector2(-4,1),middle+Vector2(2,2)])
		crack.width = .85
		crack.default_color = tone.darkened(.24)
		bridge.add_child(crack)
		var bevel := PackedVector2Array([corners[0],corners[1],corners[2],corners[2]+Vector2.DOWN*1.5,corners[1]+Vector2.DOWN*2,corners[0]+Vector2.DOWN*1.5])
		facet(bridge,bevel,Color("b4998c"))
	kael = Actor.new()
	map.props.add_child(kael)
	kael.setup(KaelModel,0.9,40,Vector2i(124,116),Vector2(12,5),0)
	kael.position = map.iso(3,4)
	kael.play("Espera")
	kirin = Actor.new()
	map.props.add_child(kirin)
	kirin.setup(KirinModel,2.9,19,Vector2i(232,200),Vector2(31,12),PI/2)
	kirin.position = map.iso(11.7,3.4)
	kirin.play("Idle")
	kirin.face(Vector2.LEFT,1)
	camera.position = map.iso(6.5,5.4) - Vector2(0,22)
	camera.zoom = Vector2.ONE*1.64
	add_child(camera)
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,16)
	hud.add_child(panel)
	help = Label.new()
	help.text = "  Rio de Brasa   ·   WASD / Setas: mover   ·   Shift: correr  "
	panel.add_child(help)

func facet(parent: Node2D, points: PackedVector2Array, tint: Color) -> void:
	var face := Polygon2D.new()
	face.polygon = points
	face.color = tint
	parent.add_child(face)

func basalt(rock: Node2D, index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 373 + 27*index
	for k in 7:
		var center := Vector2((k%3-1)*15+rng.randf_range(-4,4),floorf(k/3.0)*5-7)
		var radius := rng.randf_range(9,15)
		var height := rng.randf_range(10,22)+(13 if k==1 else 0)
		var cap := PackedVector2Array()
		var base := PackedVector2Array()
		for j in 6:
			var angle := TAU*j/6+.23
			var edge := Vector2(cos(angle),.48*sin(angle))*radius*rng.randf_range(.91,1.09)
			base.append(center+edge)
			cap.append(center+edge*.83+Vector2(height*.14,-height+edge.x*.21))
		for j in 3:
			var n := (j+1)%6
			var tone := Color("604951").lerp(Color("413a48"),float(j)/2.)
			facet(rock,PackedVector2Array([cap[j],cap[n],base[n],base[j]]),tone)
		facet(rock,cap,Color("8c7376").darkened(rng.randf_range(0,.13)))
		facet(rock,PackedVector2Array([cap[0],cap[1],cap[2],cap[1]+Vector2.DOWN*1.8]),Color("a6827b"))

func on_solid(point: Vector2) -> bool:
	var cell := Vector2(point.x/64.0+point.y/32.0, point.y/32.0-point.x/64.0)
	if cell.x < -.28 or cell.x > 13.28 or cell.y < -.28 or cell.y > 11.28:
		return false
	if absf(cell.y-BRIDGE_Y) > .45:
		if Geometry2D.is_point_in_polygon(point,map.contour):
			return false
		for i in map.contour.size():
			if Geometry2D.get_closest_point_to_segment(point,map.contour[i],map.contour[(i+1)%map.contour.size()]).distance_to(point)<4.0:
				return false
	for at: Vector2 in ROCKS:
		if ((point-map.iso(at.x,at.y))/Vector2(27,9)).length()<1:
			return false
	return ((point-kirin.position)/Vector2(31,14)).length()>=1

func _physics_process(delta: float) -> void:
	var move := Vector2(
		int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"))-int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
		int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"))-int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")))
	move = Vector2(move.x, move.y*2).normalized() * Vector2(1,.5)
	var running := Input.is_physical_key_pressed(KEY_SHIFT)
	var step := move*(142.0 if running else 84.0)*delta
	var look := kael.position.lerp(kirin.position, 0.24) if kael.position.distance_to(kirin.position)<170 else kael.position
	camera.position = camera.position.lerp(look-Vector2(0,45),1.0-exp(-4.0*delta))
	var prev := kael.position
	if on_solid(prev+step):
		kael.position += step
	else:
		for slide in [Vector2(step.x,0), Vector2(0,step.y)]:
			if on_solid(kael.position+slide):
				kael.position += slide
	kael.face(move,delta)
	kael.play(("Correr" if running else "Andar") if kael.position.distance_squared_to(prev)>.001 else "Espera")
	var near := ((kael.position-kirin.position)*Vector2(1,2)).length()<102
	if proud:
		kirin.face(kael.position-kirin.position,delta)
		if not kirin.player.is_playing():
			proud = false
	elif near:
		kirin.face(kael.position-kirin.position,delta)
		kirin.play("Idle")
	else:
		var y := kirin.position.y/32.0-kirin.position.x/64.0
		if y>=3.7:patrol_direction=-1
		if y<=1.5:patrol_direction=1
		var travel := Vector2(-1,.5)*patrol_direction
		kirin.position+=travel*18.0*delta
		kirin.face(travel,delta)
		kirin.play("Walk")
	help.text = "  E · Observar Kirin  " if near else "  Rio de Brasa   ·   WASD / Setas: mover   ·   Shift: correr  "

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_E:
		if not proud and ((kael.position-kirin.position)*Vector2(1,2)).length()<102:
			proud = true
			kirin.play("Imponencia",false)
