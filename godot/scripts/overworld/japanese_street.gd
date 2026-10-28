extends Node2D
## Street art showcase: road=0, sidewalk=10, dry drainage bed=-3 px.
@export var show_geometry := false
const BASE := "res://assets/overworld/kits/rua-japonesa-v1/"
var props: Node2D
var details: Node2D
var surfaces: Array[ShaderMaterial] = []

static func iso(cell: Vector2,height: float=0.0) -> Vector2:
 return Vector2((cell.x-cell.y)*32.0,(cell.x+cell.y)*16.0-height)

static func rect(u0: float,v0: float,u1: float,v1: float) -> PackedVector2Array:
 return PackedVector2Array([Vector2(u0,v0),Vector2(u1,v0),Vector2(u1,v1),Vector2(u0,v1)])

static func height_at(cell: Vector2) -> float:
 if cell.y>=7.5 and cell.y<=9.5:
  if cell.x>=3.0 and cell.x<=4.0:return 10.0*(4.0-cell.x)
  if cell.x>=9.5 and cell.x<=10.5:return 10.0*(cell.x-9.5)
 if cell.x<=4.0 or cell.x>=9.5:return 10.0
 return 0.0

func surface(cells: PackedVector2Array,heights: PackedFloat32Array,kind: int) -> void:
 var vertices := PackedVector2Array()
 for i in range(4):vertices.append(iso(cells[i],heights[i]))
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_TEX_UV] = cells
 arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var node := MeshInstance2D.new()
 node.name = "Superficie_"+str(kind)
 node.mesh = mesh
 var material := ShaderMaterial.new()
 material.shader = load("res://shaders/overworld/street_surface.gdshader")
 material.set_shader_parameter("asphalt_texture",load(BASE+"surfaces/asfalto.png"))
 material.set_shader_parameter("surface_kind",kind)
 material.set_shader_parameter("show_geometry",show_geometry)
 node.material = material
 add_child(node)
 surfaces.append(material)

func flat(cells: PackedVector2Array,height: float,kind: int) -> void:
 surface(cells,PackedFloat32Array([height,height,height,height]),kind)

func polygon(parent: Node2D,points: PackedVector2Array,color: Color) -> void:
 var node := Polygon2D.new()
 node.polygon = points
 node.color = color
 parent.add_child(node)

func wall(a: Vector2,b: Vector2,top: float,bottom: float) -> void:
 polygon(self,PackedVector2Array([iso(a,top),iso(b,top),iso(b,bottom),iso(a,bottom)]),Color("667C81") if show_geometry else Color("92968E"))

func detail_quad(cells: PackedVector2Array,height: float,color: Color) -> void:
 var points := PackedVector2Array()
 for cell in cells:points.append(iso(cell,height))
 polygon(details,points,color)

func _ready() -> void:
 # Road is actually cut around the lower drainage beds.
 for span in [Vector2(-.5,7.5),Vector2(9.5,13.5)]:
  flat(rect(4.35,span.x,9.15,span.y),0,0)
  for bounds in [Vector2(4.0,4.35),Vector2(9.15,9.5)]:
   flat(rect(bounds.x,span.x,bounds.y,span.y),-3,2)
   wall(Vector2(bounds.x,span.x),Vector2(bounds.y,span.x),0,-3)
   wall(Vector2(bounds.x,span.y),Vector2(bounds.y,span.y),0,-3)
  wall(Vector2(4.35,span.x),Vector2(4.35,span.y),0,-3)
  wall(Vector2(9.15,span.x),Vector2(9.15,span.y),0,-3)
  wall(Vector2(4,span.x),Vector2(4,span.y),10,-3)
  wall(Vector2(9.5,span.x),Vector2(9.5,span.y),10,-3)
 flat(rect(4,7.5,9.5,9.5),0,0)
 # Only exterior boundaries and exposed curb intervals receive a face.
 for u in [-.5,13.5]:wall(Vector2(u,-.5),Vector2(u,13.5),10,0)
 for v in [-.5,13.5]:
  wall(Vector2(-.5,v),Vector2(4,v),10,0)
  wall(Vector2(9.5,v),Vector2(13.5,v),10,0)
 flat(rect(-.5,-.5,3,13.5),10,1)
 flat(rect(10.5,-.5,13.5,13.5),10,1)
 for span in [Vector2(-.5,7.5),Vector2(9.5,13.5)]:
  flat(rect(3,span.x,4,span.y),10,1)
  flat(rect(9.5,span.x,10.5,span.y),10,1)
 # Ramps meet road at 0 and upper paving at 10. Sides taper to zero.
 for v in [7.5,9.5]:
  polygon(self,PackedVector2Array([iso(Vector2(3,v),10),iso(Vector2(4,v),10),iso(Vector2(4,v),0)]),Color("92968E"))
  polygon(self,PackedVector2Array([iso(Vector2(9.5,v),10),iso(Vector2(10.5,v),10),iso(Vector2(9.5,v),0)]),Color("92968E"))
 surface(rect(3,7.5,4,9.5),PackedFloat32Array([10,0,0,10]),1)
 surface(rect(9.5,7.5,10.5,9.5),PackedFloat32Array([0,10,10,0]),1)
 details = Node2D.new()
 details.name = "TampasGrelhasESinalizacao"
 details.visible = not show_geometry
 add_child(details)
 # Crosswalk is painted on the road and reaches neither elevated curb.
 for i in range(8):detail_quad(rect(4.45+float(i)*.58,7.65,4.79+float(i)*.58,9.35),0.1,Color("D9D6C2"))
 manhole(Vector2(6.75,4.2))
 for at in [Vector2(4.0,3.4),Vector2(9.15,11.1)]:grate(at)
 for u in [2.55,10.65]:
  detail_quad(rect(u,7.6,u+.45,9.4),10.15,Color("C7A65A"))
  for y in range(7):
   for x in range(2):detail_quad(rect(u+.08+float(x)*.2,7.72+float(y)*.23,u+.15+float(x)*.2,7.80+float(y)*.23),10.55,Color("E5C77F"))
 props = Node2D.new()
 props.name = "FachadasPorProfundidade"
 props.y_sort_enabled = true
 props.visible = not show_geometry
 add_child(props)
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"library.json"))
 for placement in [["loja",Vector2(3.5,5.2)],["casa",Vector2(13,5.4)],["maquina",Vector2(11.3,10.7)],["vaso",Vector2(3.3,6.2)],["vaso",Vector2(12.5,6.4)],["banco",Vector2(1.0,8.6)],["poste",Vector2(2.8,12.1)],["poste",Vector2(10.6,-.2)]]:
  var id: String = placement[0]
  var cell: Vector2 = placement[1]
  var info: Dictionary = manifest.props[id]
  var support := Node2D.new()
  support.position = iso(cell,height_at(cell))
  props.add_child(support)
  if id=="loja" or id=="casa":
   var building := Node2D.new()
   building.set_script(load("res://scripts/overworld/street_building.gd"))
   building.house = id=="casa"
   support.add_child(building)
   continue
  var sprite := Sprite2D.new()
  sprite.texture = load(BASE+info.file)
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  sprite.centered = false
  sprite.position = -Vector2(info.pivot[0],info.pivot[1])
  support.add_child(sprite)
  support.scale = Vector2.ONE*float(info.get("scale",1.0))

func manhole(at: Vector2) -> void:
 for layer in [[.64,0.0,Color("252F3D")],[.58,-.4,Color("8F9B9B")],[.51,-.8,Color("52616B")]]:
  var points := PackedVector2Array()
  for i in range(48):
   var angle := float(i)*TAU/48.0
   points.append(iso(at+Vector2(cos(angle),sin(angle))*float(layer[0]),float(layer[1])))
  polygon(details,points,layer[2])
 for i in range(-2,3):
  var v := float(i)*.16
  var reach := sqrt(.47*.47-v*v)
  var line := Line2D.new()
  line.width = 1.0
  line.default_color = Color("34414F")
  line.points = PackedVector2Array([iso(at+Vector2(-reach,v),-.7),iso(at+Vector2(reach,v),-.7)])
  details.add_child(line)
 # Small kite-shaped central stamp, on the metal rather than floating UI.
 polygon(details,PackedVector2Array([iso(at+Vector2(0,-.16),-.6),iso(at+Vector2(.12,0),-.6),iso(at+Vector2(0,.16),-.6),iso(at+Vector2(-.12,0),-.6)]),Color("B2B5A1"))

func grate(at: Vector2) -> void:
 # Open metal frame: the actual recessed channel remains visible between bars.
 for edge in [rect(at.x,at.y,at.x+.04,at.y+1.2),rect(at.x+.31,at.y,at.x+.35,at.y+1.2),rect(at.x,at.y,at.x+.35,at.y+.04),rect(at.x,at.y+1.16,at.x+.35,at.y+1.2)]:
  detail_quad(edge,-.5,Color("829095"))
 for i in range(7):detail_quad(rect(at.x+.04,at.y+.08+float(i)*.16,at.x+.31,at.y+.13+float(i)*.16),-.45,Color("66747B"))
