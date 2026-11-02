extends Control
## A separate camera stage: the painted mural stays 2D on a wall in perspective.
var reduced_motion:=false
var camera:Camera3D
var viewport:SubViewport
var progress:=0.0
var motion:Tween
func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=70
	add_to_group("mural_cinematic")
	var container:=SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(container)
	viewport=SubViewport.new();viewport.own_world_3d=true
	viewport.size=Vector2i(get_viewport_rect().size)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("16131c");viewport.add_child(environment)
	var wall_texture:Texture2D=load("res://assets/overworld/kits/cavernas-v3/surfaces/parede-calcario.png")
	box(Vector3(15,6,.4),Vector3(0,3,-.25),Color("716479"),wall_texture)
	box(Vector3(15,.2,14),Vector3(0,-.1,5),Color("655c50"))
	box(Vector3(.4,6,14),Vector3(-7.4,3,5),Color("3d3546"),wall_texture)
	box(Vector3(.4,6,14),Vector3(7.4,3,5),Color("3d3546"),wall_texture)
	# Stone frame has actual thickness, so the opening angle reads as a camera turn.
	box(Vector3(11.2,3.85,.25),Vector3(0,3.15,.06),Color("483d39"))
	var panel:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(10.8,3.6)
	panel.mesh=quad;panel.position=Vector3(0,3.15,.2)
	panel.material_override=material(Color.WHITE,load("res://assets/overworld/kits/mural-v1/primeiro-laco.png"));viewport.add_child(panel)
	camera=Camera3D.new();camera.fov=55;camera.near=.1;camera.far=40;viewport.add_child(camera);camera.make_current()
	pose(1.0 if reduced_motion else 0.0)
	if not reduced_motion:
		motion=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		motion.tween_method(pose,0.0,1.0,1.15)
func material(color:Color,texture:Texture2D=null)->StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=color;mat.albedo_texture=texture
	return mat
func box(dimensions:Vector3,at:Vector3,color:Color,texture:Texture2D=null)->void:
	var piece:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=dimensions
	piece.mesh=mesh;piece.position=at;piece.material_override=material(color,texture);viewport.add_child(piece)
func pose(value:float)->void:
	progress=value
	camera.position=Vector3(4.8,4.3,10.5).lerp(Vector3(0,2.4,8.7),value)
	camera.look_at(Vector3(0,1.95,0))
