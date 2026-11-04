extends Node2D
## Reusable visual scene only. No campaign, navigation, collision or save changes.
@export var flooded := true
@export var reduced_motion := false
@export_range(0.0, 2.0) var wind_strength := 1.0
const PAPER = preload("res://shaders/overworld/cave_wind_paper.gdshader")
var preview_time := -1.0
var elapsed := 0.0
var cave: Node2D
var papers: Array[ShaderMaterial] = []
var strokes: Array[Line2D] = []
var route := Curve2D.new()
var root_anchors: Array[Vector2] = []

func _ready() -> void:
 cave = load("res://scenes/overworld/caves-v3/gruta-inundada.tscn" if flooded else "res://scenes/overworld/caves-v3/gruta-seca.tscn").instantiate()
 add_child(cave)
 _animate_flowers(cave)
 # Route follows the open walkway, from the rear chamber to the front exit.
 route.add_point(Vector2(80,104),Vector2.ZERO,Vector2(-40,20))
 route.add_point(Vector2(-32,160),Vector2(40,-20),Vector2(-40,20))
 route.add_point(Vector2(-144,216),Vector2(40,-20))
 for i in range(3):
  var stroke := Line2D.new()
  stroke.width = 1.2
  stroke.default_color = Color(0.62,0.85,0.79,0.0)
  stroke.begin_cap_mode = Line2D.LINE_CAP_ROUND
  stroke.end_cap_mode = Line2D.LINE_CAP_ROUND
  add_child(stroke)
  strokes.append(stroke)
 var texture_path := "res://assets/overworld/kits/cavernas-v3/ambient/rabiola-vento.png"
 if ResourceLoader.exists(texture_path):
  # The cord is pinned to the column's upper right ledge, never to empty space.
  var streamer := Node2D.new()
  streamer.name = "RabiolaPresaNaColuna"
  streamer.position = Vector2(-128,96) + Vector2(16,-74)
  add_child(streamer)
  _paper(streamer,load(texture_path),Vector2(20,8),true,1.3)
 _apply(0.0)

func _animate_flowers(node: Node) -> void:
 if node is Sprite2D and node.name == "Visual" and "cogumelos-gruta" in node.get_parent().name:
  var sprite := node as Sprite2D
  _paper(sprite.get_parent(),sprite.texture,-sprite.position,false,float(papers.size())*1.7)
  root_anchors.append(sprite.get_parent().position)
  sprite.visible = false
 for child in node.get_children():
  _animate_flowers(child)

func _paper(parent: Node2D, texture: Texture2D, pivot: Vector2, top: bool, phase_value: float) -> void:
 var size := texture.get_size()
 var rows: Array[float] = [0.0,pivot.y,size.y]
 for i in range(1,12): rows.append(size.y*float(i)/12.0)
 rows.sort()
 var vertices := PackedVector2Array()
 var uvs := PackedVector2Array()
 var indices := PackedInt32Array()
 for y: float in rows:
  vertices.append(Vector2(0,y)-pivot)
  vertices.append(Vector2(size.x,y)-pivot)
  uvs.append(Vector2(0,y/size.y))
  uvs.append(Vector2(1,y/size.y))
 for i in range(rows.size()-1):
  var a := i*2
  indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_TEX_UV] = uvs
 arrays[Mesh.ARRAY_INDEX] = indices
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var visual := MeshInstance2D.new()
 visual.name = "PapelArticulado"
 visual.mesh = mesh
 visual.texture = texture
 visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var material := ShaderMaterial.new()
 material.shader = PAPER
 material.set_shader_parameter("phase",phase_value)
 material.set_shader_parameter("anchored_top",top)
 material.set_shader_parameter("reach_px",size.y-pivot.y if top else pivot.y)
 visual.material = material
 parent.add_child(visual)
 papers.append(material)

func _process(delta: float) -> void:
 elapsed += delta
 _apply(elapsed if preview_time < 0.0 else preview_time)

func set_animation_time(value: float) -> void:
 preview_time = value
 _apply(elapsed if value < 0.0 else value)

func _apply(time: float) -> void:
 var gust := (0.45+0.55*pow(0.5+0.5*sin(TAU*time/8.0),2.0))*wind_strength
 for material in papers:
  material.set_shader_parameter("wind_time",time)
  material.set_shader_parameter("wind_strength",0.0 if reduced_motion else 4.5*gust)
 for i in range(strokes.size()):
  var line := strokes[i]
  line.visible = not reduced_motion and wind_strength > 0.0
  var progress := fposmod(time/4.0+float(i)/3.0,1.0)
  line.default_color.a = sin(PI*progress)*0.3*gust
  line.clear_points()
  for j in range(9):
   var distance := clampf(progress*route.get_baked_length()-float(j)*4.0,0.0,route.get_baked_length())
   var point := route.sample_baked(distance)
   point.y -= 10.0 + sin(time*TAU/2.0+float(j)*0.5+float(i))*1.5
   line.add_point(point)
 var basin := cave.get_node_or_null("RecessedBasin") if is_instance_valid(cave) else null
 if basin: basin.set_animation_time(time)
