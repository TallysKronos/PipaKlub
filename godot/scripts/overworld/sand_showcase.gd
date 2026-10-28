extends Node2D
## Gentle continuous heightfield, three shared-mask materials, grounded sandstone.
@export var reduced_motion := false
@export var show_props := true
@export_range(0.0,24.0) var dune_height := 18.0
const BASE := "res://assets/overworld/kits/areia-v1/"
var preview_time := -1.0
var elapsed := 0.0
var ground_material: ShaderMaterial
var props: Node2D
var wind_strokes: Array[Line2D] = []
var measured_max_height := 0.0

static func iso(u: float,v: float) -> Vector2:
 return Vector2((u-v)*32.0,(u+v)*16.0)

func height_at(u: float,v: float) -> float:
 var edge := clampf(minf(minf(u+0.5,13.5-u),minf(v+0.5,11.5-v)),0.0,1.0)
 edge = edge*edge*(3.0-2.0*edge)
 var first := exp(-pow((u-3.3)/1.8,2.0)-pow((v-3.0)/2.8,2.0))
 var second := exp(-pow((u-11.0)/1.5,2.0)-pow((v-8.5)/2.5,2.0))
 return dune_height*maxf(first,second*0.8)*edge

func ground_point(u: float,v: float) -> Vector2:
 return iso(u,v)-Vector2(0,height_at(u,v))

func _ready() -> void:
 var vertices := PackedVector2Array()
 var uv := PackedVector2Array()
 var colors := PackedColorArray()
 var indices := PackedInt32Array()
 for y in range(49):
  for x in range(57):
   var u := -0.5+float(x)*0.25
   var v := -0.5+float(y)*0.25
   var h := height_at(u,v)
   measured_max_height = maxf(measured_max_height,h)
   var slope := (height_at(u+0.1,v)-height_at(u-0.1,v)+height_at(u,v+0.1)-height_at(u,v-0.1))*0.15+0.5
   vertices.append(ground_point(u,v))
   uv.append(Vector2(u,v))
   colors.append(Color(h/24.0,clampf(slope,0.0,1.0),0.0,1.0))
 for y in range(48):
  for x in range(56):
   var a := y*57+x
   indices.append_array(PackedInt32Array([a,a+1,a+57,a+1,a+58,a+57]))
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_TEX_UV] = uv
 arrays[Mesh.ARRAY_COLOR] = colors
 arrays[Mesh.ARRAY_INDEX] = indices
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var ground := MeshInstance2D.new()
 ground.name = "AreiaComRelevoContinuo"
 ground.mesh = mesh
 ground_material = ShaderMaterial.new()
 ground_material.shader = load("res://shaders/overworld/sand_ground.gdshader")
 ground_material.set_shader_parameter("sand_texture",load(BASE+"surfaces/areia.png"))
 ground_material.set_shader_parameter("earth_texture",load("res://assets/overworld/kits/planicie-v1/surfaces/terra.png"))
 ground_material.set_shader_parameter("stone_texture",load("res://assets/overworld/kits/cavernas-v3/surfaces/rocha-cinza.png"))
 ground.material = ground_material
 add_child(ground)
 props = Node2D.new()
 props.name = "ObjetosApoiadosNoRelevo"
 props.y_sort_enabled = true
 props.visible = show_props
 add_child(props)
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"library.json"))
 var stone: Dictionary = manifest.props.arenito
 for at in [Vector2(2.8,7.2),Vector2(11.4,3.0),Vector2(1.9,1.7)]:
  var support := Node2D.new()
  support.position = ground_point(at.x,at.y)
  props.add_child(support)
  var shadow := Polygon2D.new()
  shadow.color = Color(0.40,0.29,0.17,0.23)
  var points := PackedVector2Array()
  for i in range(24):points.append(Vector2(cos(float(i)*TAU/24.0)*27,sin(float(i)*TAU/24.0)*6))
  shadow.polygon = points
  support.add_child(shadow)
  var sprite := Sprite2D.new()
  sprite.texture = load(BASE+stone.file)
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  sprite.centered = false
  sprite.position = -Vector2(stone.pivot[0],stone.pivot[1])
  support.add_child(sprite)
 for i in range(3):
  var line := Line2D.new()
  line.width = 1.0
  line.default_color = Color(0.97,0.86,0.63,0.0)
  add_child(line)
  wind_strokes.append(line)
 _apply(0.0)

func _process(delta: float) -> void:
 elapsed += delta
 _apply(elapsed if preview_time<0.0 else preview_time)

func _apply(time: float) -> void:
 var cycle := fposmod(time,8.0)
 for i in range(wind_strokes.size()):
  var progress := fposmod(cycle/8.0+float(i)/3.0,1.0)
  var stroke := wind_strokes[i]
  stroke.visible = not reduced_motion
  stroke.default_color.a = sin(PI*progress)*0.20
  stroke.clear_points()
  for j in range(8):
   var u := 4.8+float(i)*1.7
   var v := 2.0+progress*7.0-float(j)*0.08
   stroke.add_point(ground_point(u,v)-Vector2(0,4.0))

func set_animation_time(time: float) -> void:
 preview_time = time
 _apply(elapsed if time<0.0 else time)
