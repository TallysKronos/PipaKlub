extends Node2D
## Reusable art showcase: open plains, three materials, no campaign or saves.
@export var show_masks := false
@export var show_props := true
@export_range(0.4,1.6) var path_width := 0.9
@export_range(0.0,0.6) var edge_variation := 0.32
@export_range(0.03,0.25) var blend_width := 0.12
const BASE := "res://assets/overworld/kits/planicie-v1/"
const SHADER = preload("res://shaders/overworld/plains_ground.gdshader")
var ground_material: ShaderMaterial
var props: Node2D

static func iso(x: float,y: float) -> Vector2:
 return Vector2((x-y)*32.0,(x+y)*16.0)

func _ready() -> void:
 var footprint := PackedVector2Array()
 # Irregular, gently clipped perimeter; this is all one level, no fake cliff.
 for cell in [Vector2(-.5,1),Vector2(.2,-.4),Vector2(3.5,-.5),Vector2(6.3,-.25),Vector2(10.7,-.5),Vector2(13.8,.1),Vector2(14.5,2),Vector2(14.2,4.7),Vector2(14.5,8.6),Vector2(13.6,11.5),Vector2(10.5,11.8),Vector2(7.4,11.5),Vector2(3.3,11.8),Vector2(.1,11.3),Vector2(-.5,9),Vector2(-.2,5.5)]:
  footprint.append(iso(cell.x,cell.y))
 var ground := Polygon2D.new()
 ground.name = "GramaTerraPedra"
 ground.polygon = footprint
 ground_material = ShaderMaterial.new()
 ground_material.shader = SHADER
 ground_material.set_shader_parameter("grass_texture",load(BASE+"surfaces/grama.png"))
 ground_material.set_shader_parameter("earth_texture",load(BASE+"surfaces/terra.png"))
 ground_material.set_shader_parameter("stone_texture",load("res://assets/overworld/kits/cavernas-v3/surfaces/rocha-cinza.png"))
 ground_material.set_shader_parameter("show_masks",show_masks)
 ground_material.set_shader_parameter("path_width",path_width)
 ground_material.set_shader_parameter("edge_variation",edge_variation)
 ground_material.set_shader_parameter("blend_width",blend_width)
 ground.material = ground_material
 add_child(ground)
 props = Node2D.new()
 props.name = "ObjetosPorProfundidade"
 props.y_sort_enabled = true
 props.visible = show_props
 add_child(props)
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"library.json"))
 var tree: Dictionary = manifest.props.arvore
 for at in [Vector2(1.8,5.5),Vector2(3.1,9),Vector2(11.6,1.9)]:
  prop(BASE+tree.file,Vector2(tree.pivot[0],tree.pivot[1]),iso(at.x,at.y),1.0,true)
 for at in [Vector2(2.8,2.3),Vector2(12.1,8.5)]:
  var rock: Node2D = load("res://scenes/overworld/caves-v3/props/rocha-solta.tscn").instantiate()
  rock.position = iso(at.x,at.y)
  rock.scale = Vector2(0.7,0.7)
  props.add_child(rock)
 # The new ground painting supplies folded grass blades. Legacy granular grass
 # decals clash with the flat palette and would duplicate those details.
 for at in [Vector2(3.7,6.3),Vector2(10.7,3.4),Vector2(11.5,10),Vector2(2.4,8.4)]:
  prop("res://assets/overworld/kits/comum/pecas/flores-amarela.png",Vector2(31.5,79),iso(at.x,at.y),0.32)

func prop(path: String,pivot: Vector2,at: Vector2,scale_value: float,shadow: bool=false) -> void:
 var support := Node2D.new()
 support.position = at
 support.scale = Vector2.ONE*scale_value
 props.add_child(support)
 if shadow:
  var contact := Polygon2D.new()
  contact.color = Color(0.18,0.26,0.12,0.24)
  var points := PackedVector2Array()
  for i in range(24):points.append(Vector2(cos(float(i)*TAU/24.0)*29,sin(float(i)*TAU/24.0)*8))
  contact.polygon = points
  support.add_child(contact)
 var sprite := Sprite2D.new()
 sprite.texture = load(path)
 sprite.centered = false
 sprite.position = -pivot
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 support.add_child(sprite)
