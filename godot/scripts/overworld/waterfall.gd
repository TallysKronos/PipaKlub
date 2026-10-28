@tool
extends Node2D
## A falling water plane, fixed endpoints and independent foam. Pixel units.
const BASE := "res://assets/overworld/kits/aguas-v1/"
@export_enum("cortina-suave","cortina-forte") var curtain_id := "cortina-suave"
@export_enum("u","v") var axis := "v"
@export_range(1,8,1) var width_cells := 4
@export_range(1,4,1) var drop_levels := 1
## Optional measured drop, including a receiving pool below the floor plane.
@export_range(0.0,512.0,1.0) var drop_pixels_override := 0.0
@export var preview_time := -1.0
@export_tool_button("Atualizar cachoeira") var refresh_action: Callable = rebuild
var materials: Array[ShaderMaterial] = []
var visuals: Node2D

func _ready() -> void:rebuild()

func foam(id: String,at: Vector2,dimensions: Vector2,rotation_value: float=0.0) -> void:
	var sprite := Sprite2D.new()
	sprite.name = id
	sprite.texture = load(BASE+"effects/"+id+".png")
	sprite.position = at
	sprite.scale = dimensions/Vector2(sprite.texture.get_size())
	sprite.rotation = rotation_value
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/overworld/water_foam.gdshader")
	mat.set_shader_parameter("preview_time",preview_time)
	sprite.material = mat
	materials.append(mat)
	visuals.add_child(sprite)

func rebuild() -> void:
	if is_instance_valid(visuals):
		remove_child(visuals)
		visuals.queue_free()
	materials.clear()
	visuals = Node2D.new()
	add_child(visuals)
	var a := Vector2.ZERO
	var b := Vector2(width_cells*32,width_cells*16) if axis=="v" else Vector2(-width_cells*32,width_cells*16)
	var down := Vector2(0,drop_pixels_override if drop_pixels_override>0.0 else drop_levels*64.0)
	var plane := Polygon2D.new()
	plane.polygon = PackedVector2Array([a,b,b+down,a+down])
	plane.uv = PackedVector2Array([Vector2(0,0),Vector2(512,0),Vector2(512,512),Vector2(0,512)])
	plane.texture = load(BASE+"surfaces/"+curtain_id+".png")
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/overworld/water_fall.gdshader")
	mat.set_shader_parameter("surface_texture",plane.texture)
	mat.set_shader_parameter("flow_speed",2.0 if curtain_id=="cortina-forte" else 1.0)
	mat.set_shader_parameter("preview_time",preview_time)
	plane.material = mat
	materials.append(mat)
	visuals.add_child(plane)
	# Both emitters are centred exactly on the endpoints, never below a grass cap.
	var foam_angle := atan(0.5) if axis=="v" else -atan(0.5)
	foam("espuma-labio",b*.5,Vector2(b.length()+10,24),foam_angle)
	foam("respingo-base",b*.5+down+Vector2(0,3),Vector2(b.length()+36,54),foam_angle)

func set_animation_time(value: float) -> void:
	preview_time = value
	for mat in materials:mat.set_shader_parameter("preview_time",value)
