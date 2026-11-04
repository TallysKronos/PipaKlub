extends Node2D
## Entire camera is submerged. No water rectangle is laid over a dry scene.
@export var reduced_motion := false
@export var effects_enabled := true
const BASE := "res://assets/overworld/kits/submerso-v1/"
const TERRAIN = preload("res://scripts/overworld/underwater_terrain.gd")
@export var show_geometry := false
var preview_time := -1.0
var elapsed := 0.0
var ground_material: ShaderMaterial
var props: Node2D
var plant_materials: Array[ShaderMaterial] = []
var rays: Array[Polygon2D] = []
var effect_clock := 0.0
var particles: Node2D
var terrain_materials: Array[ShaderMaterial] = []

static func iso(u: float,v: float) -> Vector2:
 return Vector2((u-v)*32.0,(u+v)*16.0)

func _ready() -> void:
 ground_material = ShaderMaterial.new()
 ground_material.shader = load("res://shaders/overworld/underwater_ground.gdshader")
 ground_material.set_shader_parameter("sand_texture",load("res://assets/overworld/kits/areia-v1/surfaces/areia.png"))
 ground_material.set_shader_parameter("rock_texture",load("res://assets/overworld/kits/cavernas-v3/surfaces/rocha-cinza.png"))
 terrain_materials = TERRAIN.build(self,ground_material,show_geometry)
 props = Node2D.new()
 props.name = "RecifePorProfundidade"
 props.y_sort_enabled = true
 add_child(props)
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"library.json"))
 var kelp: Dictionary = manifest.props.algas
 for at in [Vector2(1.6,4.7),Vector2(3.3,8),Vector2(6.8,10),Vector2(11.8,1.6),Vector2(12.2,3.2),Vector2(11.7,9.2)]:
  var support := support_at(at,14)
  plant(support,load(BASE+kelp.file),Vector2(kelp.pivot[0],kelp.pivot[1]),float(plant_materials.size())*1.1)
 var coral: Dictionary = manifest.props.coral
 for at in [Vector2(2.8,3.2),Vector2(11.0,7.0),Vector2(3.2,10.3)]:
  var support := support_at(at,22)
  var sprite := Sprite2D.new()
  sprite.texture = load(BASE+coral.file)
  sprite.centered = false
  sprite.position = -Vector2(coral.pivot[0],coral.pivot[1])
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  sprite.modulate = Color(0.82,0.94,1.0)
  support.add_child(sprite)
 for at in [Vector2(1.5,1.5),Vector2(10.7,9.0)]:
  var rock: Node2D = load("res://scenes/overworld/caves-v3/props/rocha-solta.tscn").instantiate()
  rock.position = iso(at.x,at.y)-Vector2(0,TERRAIN.height_at(at))
  rock.scale = Vector2(0.9,0.9)
  var visual := rock.get_node("Visual") as Sprite2D
  visual.material = visual.material.duplicate()
  visual.material.set_shader_parameter("body_tint",Color(0.30,0.57,0.61))
  props.add_child(rock)
 # Low-opacity shafts live in the water column, not in terrain textures.
 for i in range(3):
  var ray := Polygon2D.new()
  var x := -210.0+float(i)*210.0
  ray.polygon = PackedVector2Array([Vector2(x,-140),Vector2(x+25,-140),Vector2(x+200,330),Vector2(x+75,330)])
  ray.vertex_colors = PackedColorArray([Color(0.6,0.87,0.88,0.07),Color(0.6,0.87,0.88,0.07),Color(0.6,0.87,0.88,0.0),Color(0.6,0.87,0.88,0.0)])
  add_child(ray)
  rays.append(ray)
 particles = Node2D.new()
 particles.name = "BolhasNaColunaDeAgua"
 particles.draw.connect(_draw_particles)
 add_child(particles)
 _apply(0.0)

func support_at(cell: Vector2,radius: float) -> Node2D:
 var support := Node2D.new()
 support.position = iso(cell.x,cell.y)-Vector2(0,TERRAIN.height_at(cell))
 props.add_child(support)
 var shadow := Polygon2D.new()
 shadow.color = Color(0.06,0.18,0.22,0.30)
 var shape := PackedVector2Array()
 for i in range(24):shape.append(Vector2(cos(float(i)*TAU/24.0)*radius,sin(float(i)*TAU/24.0)*radius*0.22))
 shadow.polygon = shape
 support.add_child(shadow)
 return support

func plant(parent: Node2D,texture: Texture2D,pivot: Vector2,phase: float) -> void:
 var size := texture.get_size()
 var rows: Array[float] = [0.0,pivot.y,size.y]
 for i in range(1,16):rows.append(size.y*float(i)/16.0)
 rows.sort()
 var vertices := PackedVector2Array()
 var uv := PackedVector2Array()
 var indices := PackedInt32Array()
 for y: float in rows:
  vertices.append(Vector2(0,y)-pivot)
  vertices.append(Vector2(size.x,y)-pivot)
  uv.append(Vector2(0,y/size.y))
  uv.append(Vector2(1,y/size.y))
 for i in range(rows.size()-1):
  var a := i*2
  indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_TEX_UV] = uv
 arrays[Mesh.ARRAY_INDEX] = indices
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var visual := MeshInstance2D.new()
 visual.mesh = mesh
 visual.texture = texture
 visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var material := ShaderMaterial.new()
 material.shader = load("res://shaders/overworld/underwater_foliage.gdshader")
 material.set_shader_parameter("height_px",pivot.y)
 material.set_shader_parameter("phase",phase)
 visual.material = material
 parent.add_child(visual)
 plant_materials.append(material)

func _process(delta: float) -> void:
 elapsed += delta
 _apply(elapsed if preview_time<0.0 else preview_time)

func _apply(time: float) -> void:
 effect_clock = 0.0 if reduced_motion else fposmod(time,8.0)
 if ground_material:
  for material in terrain_materials:
   material.set_shader_parameter("animation_time",effect_clock)
   material.set_shader_parameter("effects_enabled",effects_enabled)
   material.set_shader_parameter("show_masks",ground_material.get_shader_parameter("show_masks"))
 for material in plant_materials:
  material.set_shader_parameter("animation_time",effect_clock)
  material.set_shader_parameter("sway_strength",0.0 if reduced_motion else 4.0)
 for i in range(rays.size()):
  rays[i].visible = effects_enabled
  rays[i].modulate.a = 0.7+sin(effect_clock*TAU/8.0+float(i))*0.15
 if is_instance_valid(particles):particles.queue_redraw()

func _draw_particles() -> void:
 if not effects_enabled or reduced_motion:return
 for i in range(9):
  var p := fposmod(effect_clock/8.0+float(i)*0.137,1.0)
  var point := Vector2(-290.0+float(i)*75.0+sin(p*TAU+float(i))*3.0,230.0-p*240.0)
  particles.draw_arc(point,1.3+float(i%3)*0.5,0.0,TAU,12,Color(0.64,0.89,0.89,sin(p*PI)*0.32),0.8,true)

func set_animation_time(time: float) -> void:
 preview_time = time
 _apply(elapsed if time<0.0 else time)
