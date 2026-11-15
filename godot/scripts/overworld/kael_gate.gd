extends Node2D
## Independent hinged leaf. World-space rotation keeps the hinge fixed in 2:1 projection.
signal opened
signal closed
const Depth = preload("res://scripts/overworld/pier_depth.gd")
const HINGE := Vector2(3.58,18.2)
const WIDTH := 1.63
const DURATION := .65
var openness := 0.0
var target_open := false
var motion:Tween
var world:Node2D
var play:Node2D
var faces:Array[Dictionary]=[]
var dynamic_depth=Depth.new()
var obstacle:Dictionary={"id":"kael-moving-gate","bounds":[3.56,18.15,5.23,18.25]}
var last_step := -1
var automatic := true

func _ready() -> void:
	world=get_parent()
	play=world.get_parent()
	world.blockers.append(obstacle)
	z_index=2
	_rebuild()

func set_open(value:bool,instant:bool=false) -> void:
	if value==target_open and not instant:return
	target_open=value
	if motion:motion.kill()
	if instant:
		openness=1.0 if value else 0.0
		_rebuild()
		return
	motion=create_tween()
	motion.tween_property(self,"openness",1.0 if value else 0.0,DURATION*maxf(.05,absf(openness-(1.0 if value else 0.0)))).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(func():
		_rebuild()
		if target_open:opened.emit()
		else:closed.emit())

func _process(_delta:float) -> void:
	if not is_instance_valid(play):return
	if automatic:
		var center:=Vector2(4.4,18.2)
		var distance:float=minf(play.cell.distance_to(center),play.follower.distance_to(center))
		if distance<2.5:set_open(true)
		elif distance>3.3:set_open(false)
	# Quantized pose updates preserve crisp edges and avoid rebuilding stationary geometry.
	var step:=roundi(openness*24)
	if step!=last_step:_rebuild()

func _point(x:float,y:float,z:float) -> Vector3:
	var angle:float=-openness*PI*.5
	return Vector3(HINGE.x+cos(angle)*x-sin(angle)*y,HINGE.y+sin(angle)*x+cos(angle)*y,z)

func _face(points:Array,color:Color) -> void:
	var polygon:=PackedVector2Array()
	var depths:=PackedFloat32Array()
	for p:Vector3 in points:
		polygon.append(world.iso(Vector2(p.x,p.y),p.z))
		depths.append((p.x+p.y)*32+p.z)
	var plane:Vector3=world.depth_plane(polygon,depths)
	var node:=Polygon2D.new()
	node.polygon=polygon
	node.color=color
	node.antialiased=false
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://shaders/overworld/moving_gate.gdshader")
	mat.set_shader_parameter("depth_map",play.depth.texture)
	var bounds:Rect2=play.depth.bounds
	mat.set_shader_parameter("depth_bounds",Vector4(bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y))
	mat.set_shader_parameter("face_plane",plane)
	node.material=mat
	var box:=Rect2(polygon[0],Vector2.ZERO)
	for p in polygon:box=box.expand(p)
	var mean_depth:=0.0
	for value in depths:mean_depth+=value/float(depths.size())
	faces.append({"node":node,"polygon":polygon,"bounds":box,"plane":plane,"depth":mean_depth,"surface":"gate"})

func _bar(x0:float,x1:float,z0:float,z1:float) -> void:
	var a:=_point(x0,-.035,z1)
	var b:=_point(x1,-.035,z1)
	var c:=_point(x1,.035,z1)
	var d:=_point(x0,.035,z1)
	_face([d,c,_point(x1,.035,z0),_point(x0,.035,z0)],Color("445b86"))
	_face([b,c,_point(x1,.035,z0),_point(x1,-.035,z0)],Color("303b58"))
	_face([a,b,c,d],Color("9cacc2"))

func _rebuild() -> void:
	last_step=roundi(openness*24)
	for face in faces:face.node.free()
	faces.clear()
	# Full perimeter makes the leaf legible as a single rigid object.
	for z in [12.0,42.0]:_bar(0,WIDTH,z,z+3)
	for x in [0.0,WIDTH-.055]:_bar(x,x+.055,15,42)
	for i in range(1,9):
		var x:=float(i)*WIDTH/9.0
		_bar(x-.016,x+.016,15,42)
	_bar(WIDTH-.19,WIDTH-.07,28,30)
	faces.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.depth<b.depth)
	for face in faces:add_child(face.node)
	# A small local depth map supplies correct Kael/companion occlusion at every pose.
	dynamic_depth.bounds=Rect2()
	dynamic_depth.bake(faces)
	for material:ShaderMaterial in [play.player_material,play.partner_material]:
		material.set_shader_parameter("moving_depth_enabled",true)
		material.set_shader_parameter("moving_depth_map",dynamic_depth.texture)
		var bounds:Rect2=dynamic_depth.bounds
		material.set_shader_parameter("moving_depth_bounds",Vector4(bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y))
	# Hold the crossing until the leaf is clear; open-state footprint hugs the garden.
	obstacle.bounds=[3.56,18.15,5.23,18.25] if openness<.8 else [3.53,16.53,3.64,18.2]

func _exit_tree() -> void:
	if is_instance_valid(world):world.blockers.erase(obstacle)
	if is_instance_valid(play):
		for material:ShaderMaterial in [play.player_material,play.partner_material]:
			if material:material.set_shader_parameter("moving_depth_enabled",false)
