@tool
extends Node2D
## A recessed corner basin. One measured contour drives the cutout and its banks.
## Floor=0; water=-depth_px in height, projected down in screen coordinates.
const BASE := "res://assets/overworld/kits/cavernas-v3/"
const FALL = preload("res://scripts/overworld/cave_waterfall.gd")
const GROUND = preload("res://scripts/overworld/cave_ground.gd")
## This corner footprint has projection clearance for up to 24 px of depression.
@export_range(16.0,24.0,1.0) var depth_px := 24.0
@export var preview_time := -1.0
@export var show_geometry := false
@export_tool_button("Reconstruir poço") var refresh_action: Callable = rebuild
var visuals: Node2D
var water_material: ShaderMaterial
var fall: Node2D
var floor_piece_count := 0
var path_piece_count := 0

static func iso(x: float,y: float) -> Vector2:return Vector2((x-y)*32.0,(x+y)*16.0)

static func top_contour() -> PackedVector2Array:
 # The straight rear edge meets the cave wall. The exposed shore is irregular/rounded.
 var uv := PackedVector2Array([Vector2(5.75,-.5),Vector2(8.5,-.5),Vector2(8.75,.25),Vector2(8.75,1.75),Vector2(8.5,3),Vector2(7.75,3.75),Vector2(6.75,4),Vector2(5.75,3.75),Vector2(5.5,3),Vector2(5.25,2),Vector2(5.5,.75)])
 var result := PackedVector2Array([iso(uv[0].x,uv[0].y),iso(uv[1].x,uv[1].y)])
 for i in range(2,uv.size()):
  var a := uv[i-1].lerp(uv[i],.75)
  var b := uv[i].lerp(uv[(i+1)%uv.size()],.25)
  result.append(iso(a.x,a.y))
  result.append(iso(b.x,b.y))
 return result

func _ready() -> void:rebuild()

func polygon(points: PackedVector2Array,material_value: Material=null,color_value: Color=Color.WHITE) -> Polygon2D:
 var node := Polygon2D.new()
 node.polygon = points
 node.material = material_value
 node.color = color_value
 visuals.add_child(node)
 return node

func line(points: PackedVector2Array,width_value: float,color_value: Color,closed_value: bool=true) -> void:
 var node := Line2D.new()
 node.points = points
 node.closed = closed_value
 node.width = width_value
 node.default_color = color_value
 visuals.add_child(node)

func land(subject: PackedVector2Array,hole: PackedVector2Array,id: String) -> int:
 var pieces := Geometry2D.clip_polygons(subject,hole)
 # This basin shares the rear edge of the room, so its subtraction has no inner ring.
 for piece in pieces:
  var node := polygon(piece,load(BASE+"materials/"+id+".tres"))
  node.texture = load(BASE+"surfaces/"+id+".png")
 return pieces.size()

func rebuild() -> void:
 if is_instance_valid(visuals):
  remove_child(visuals)
  visuals.queue_free()
 visuals = Node2D.new()
 visuals.name = "MeasuredBasinVisuals"
 add_child(visuals)
 var top := top_contour()
 var down := Vector2(0,depth_px)
 var bottom := PackedVector2Array()
 for point in top:bottom.append(point+down)
 water_material = ShaderMaterial.new()
 water_material.shader = load("res://shaders/overworld/cave_basin_water.gdshader")
 water_material.set_shader_parameter("surface_texture",load(BASE+"surfaces/agua-linhas.png"))
 water_material.set_shader_parameter("preview_time",preview_time)
 var water_plane := polygon(bottom,null if show_geometry else water_material,Color("24536B") if show_geometry else Color.WHITE)
 water_plane.name = "LowerWaterSurface"
 var perimeter := 0.0
 for i in range(top.size()):
  var a := top[i]
  var b := top[(i+1)%top.size()]
  var length_value := a.distance_to(b)
  var face := polygon(PackedVector2Array([a,b,b+down,a+down]))
  face.texture = load(BASE+"surfaces/parede-umida.png") if not show_geometry else null
  face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
  face.uv = PackedVector2Array([Vector2(perimeter,0),Vector2(perimeter+length_value*2,0),Vector2(perimeter+length_value*2,depth_px*3),Vector2(perimeter,depth_px*3)])
  face.color = Color("BD935C") if show_geometry else Color(.65,.69,.74)
  perimeter += length_value*2
 line(bottom,3.0,Color("122937"))
 var room := PackedVector2Array([iso(-.5,-.5),iso(9.5,-.5),iso(9.5,9.5),iso(-.5,9.5)])
 floor_piece_count = land(room,top,"rocha-umida")
 # Blend both materials on the same clipped upper floor, never over the water.
 path_piece_count = floor_piece_count
 for node in visuals.get_children():
  if node is Polygon2D and node.material and node.material!=water_material:
   node.material = GROUND.material(true)
 if show_geometry:
  for node in visuals.get_children():
   if node is Polygon2D and node.material and node.material!=water_material:
    node.material = null
    node.texture = null
    node.color = Color("56726A")
 line(top,2.0,Color("1D2735"))
 # Rear wall-floor contact is cut at the mouth, so no black stripe crosses the pool.
 line(PackedVector2Array([iso(-.5,9.5),iso(-.5,-.5),top[0]]),4.0,Color("171A29"),false)
 line(PackedVector2Array([top[1],iso(9.5,-.5)]),4.0,Color("171A29"),false)
 fall = Node2D.new()
 fall.set_script(FALL)
 fall.name = "BasinWaterfall"
 fall.width_cells = 2
 fall.drop_levels = 2
 fall.drop_pixels_override = 128.0+depth_px
 fall.surface_override = load(BASE+"surfaces/queda-fitas.png")
 fall.position = Vector2(200,84-128)
 fall.preview_time = preview_time
 visuals.add_child(fall)
 # Impact belongs to the water plane: banks and upper ground must occlude its overspray.
 var impact: Node2D = fall.visuals.get_node_or_null("respingo-base")
 if impact:impact.reparent(water_plane,true)

func set_animation_time(value: float) -> void:
 preview_time = value
 if water_material:water_material.set_shader_parameter("preview_time",value)
 if is_instance_valid(fall):fall.set_animation_time(value)
