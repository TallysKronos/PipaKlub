extends Node2D
## Painted wall elevations on exact 2:1 architectural planes.
## Origin is the near foundation corner; all three visible base corners have z=0.
@export var house := false
var width_cells := 3.3
var depth_cells := 3.0
const HEIGHT := 108.0
const RIDGE := 34.0
const OVERHANG := 0.20
const ATLAS := "res://assets/overworld/kits/rua-japonesa-v1/surfaces/fachadas.png"
const ROOF_ART := "res://assets/overworld/kits/rua-japonesa-v1/surfaces/telhado-manga.png"
var fringe: Array[Polygon2D] = []
var cloth_hem: Line2D
var cloth_phase := 0.0

func facade(face_u: bool,t: float,out: float,z: float) -> Vector2:
 return point(width_cells+out,depth_cells*(1.0-t),z) if face_u else point(width_cells*t,depth_cells+out,z)

func face_patch(face_u: bool,t0: float,t1: float,out: float,low: float,high: float,color: Color) -> void:
 solid(PackedVector2Array([facade(face_u,t0,out,high),facade(face_u,t1,out,high),facade(face_u,t1,out,low),facade(face_u,t0,out,low)]),color)

func beam(face_u: bool,t0: float,t1: float,inside: float,outside: float,low: float,high: float,color: Color) -> void:
 # All faces share endpoints; the extrusion is measured in terrain cells.
 solid(PackedVector2Array([facade(face_u,t0,inside,high),facade(face_u,t1,inside,high),facade(face_u,t1,outside,high),facade(face_u,t0,outside,high)]),color.lightened(.13))
 var end := t0 if face_u else t1
 solid(PackedVector2Array([facade(face_u,end,inside,high),facade(face_u,end,outside,high),facade(face_u,end,outside,low),facade(face_u,end,inside,low)]),color.darkened(.20))
 face_patch(face_u,t0,t1,outside,low,high,color)
 line(PackedVector2Array([facade(face_u,t0,inside,high),facade(face_u,t0,outside,high),facade(face_u,t1,outside,high),facade(face_u,t1,outside,low),facade(face_u,t0,outside,low)]),Color("293B41"),.8)

func window_detail(face_u: bool,t0: float,t1: float,low: float,high: float,shutter: bool=false) -> void:
 # Dark reveal behind the raised timber frame; sill extends beyond the frame.
 face_patch(face_u,t0,t1,.018,low,high,Color("243C4A"))
 face_patch(face_u,t0+.025,t1-.025,.024,low+2,high-2,Color("28758D"))
 solid(PackedVector2Array([facade(face_u,t0+.025,.026,high-3),facade(face_u,t1-.025,.026,high-3),facade(face_u,t1-.025,.026,low+4)]),Color("459CAC"))
 var wood := Color("B76B41")
 beam(face_u,t0-.018,t1+.018,.03,.15,high-1,high+2,wood)
 beam(face_u,t0-.018,t0+.016,.03,.12,low,high,wood)
 beam(face_u,t1-.016,t1+.018,.03,.12,low,high,wood)
 beam(face_u,(t0+t1)*.5-.008,(t0+t1)*.5+.008,.03,.10,low+1,high-1,wood.darkened(.08))
 beam(face_u,t0-.035,t1+.035,.0,.24,low-3,low,Color("D19A62"))
 if shutter:
  var panel := PackedVector2Array([facade(face_u,t0-.022,.13,high),facade(face_u,t0-.14,.48,high-1),facade(face_u,t0-.14,.48,low),facade(face_u,t0-.022,.13,low)])
  solid(panel,Color("8B5140"))
  var contour := panel.duplicate()
  contour.append(panel[0])
  line(contour,Color("293B41"),1.0)
  for h in [low+5,high-5]:line(PackedVector2Array([facade(face_u,t0-.04,.18,h),facade(face_u,t0-.12,.43,h)]),Color("D09155"),1.2)

func balcony() -> void:
 const T0 := .23
 const T1 := .88
 const DEPTH := .65
 const FLOOR := 62.0
 # Crisp cel shadow on the wall; the floor itself is a separate projecting slab.
 face_patch(false,T0,T1,.006,44,60,Color(.20,.25,.22,.32))
 for t in [T0+.045,T1-.045]:
  line(PackedVector2Array([facade(false,t,.02,44),facade(false,t,.55,FLOOR-4)]),Color("293B41"),4.4)
  line(PackedVector2Array([facade(false,t,.02,44),facade(false,t,.55,FLOOR-4)]),Color("A8623D"),2.7)
 beam(false,T0,T1,0,DEPTH,FLOOR-4,FLOOR,Color("AF774B"))
 for out in [.20,.42]:line(PackedVector2Array([facade(false,T0,out,FLOOR+.1),facade(false,T1,out,FLOOR+.1)]),Color("825C40"),.65)
 # Side rails connect the façade to the front railing; glass stays behind them.
 for t in [T0,T1]:
  for out in [.02,.32,DEPTH]:line(PackedVector2Array([facade(false,t,out,FLOOR),facade(false,t,out,FLOOR+20)]),Color("80503A"),2.2)
  line(PackedVector2Array([facade(false,t,0,FLOOR+20),facade(false,t,DEPTH,FLOOR+20)]),Color("293B41"),3.2)
  line(PackedVector2Array([facade(false,t,0,FLOOR+20),facade(false,t,DEPTH,FLOOR+20)]),Color("D99B5F"),1.6)
 for i in range(6):
  var t := lerpf(T0,T1,float(i)/5.0)
  beam(false,t-.012,t+.012,DEPTH-.025,DEPTH+.025,FLOOR,FLOOR+20,Color("A9623D"))
 beam(false,T0-.02,T1+.02,DEPTH-.04,DEPTH+.06,FLOOR+18,FLOOR+21,Color("D39459"))
 beam(false,T0,T1,DEPTH-.02,DEPTH+.03,FLOOR+3,FLOOR+5,Color("A9623D"))

func awning() -> void:
 # Triangular iron arms run from the wall to the fixed outer spar.
 for t in [.10,.90]:
  line(PackedVector2Array([facade(true,t,.025,47),facade(true,t,.8,56),facade(true,t,.025,66)]),Color("293B41"),2.0)
 var outs := [0.0,.22,.52,.80]
 var heights := [66.0,65.0,61.0,56.0]
 for i in range(6):
  var t0 := .055+float(i)*.15
  var t1 := t0+.15
  var color := Color("EBD9AC") if i%2==0 else Color("C56849")
  for j in range(3):
   solid(PackedVector2Array([facade(true,t0,outs[j],heights[j]),facade(true,t1,outs[j],heights[j]),facade(true,t1,outs[j+1],heights[j+1]),facade(true,t0,outs[j+1],heights[j+1])]),color.darkened(float(j)*.035))
  var cloth := Polygon2D.new()
  cloth.color = color.darkened(.10)
  add_child(cloth)
  fringe.append(cloth)
 cloth_hem = Line2D.new()
 cloth_hem.width = .8
 cloth_hem.default_color = Color("293B41")
 cloth_hem.antialiased = true
 add_child(cloth_hem)
 line(PackedVector2Array([facade(true,.055,0,66),facade(true,.955,0,66)]),Color("293B41"),2)
 line(PackedVector2Array([facade(true,.055,.8,56),facade(true,.955,.8,56)]),Color("293B41"),1.3)
 update_cloth()

func update_cloth() -> void:
 var hem := PackedVector2Array()
 for i in range(fringe.size()):
  var t0 := .055+float(i)*.15
  var t1 := t0+.15
  var bend := sin(cloth_phase+float(i)*.55)*.025
  var z := 50.0+sin(cloth_phase+float(i)*.55)*.65
  # Top hem is fixed to the spar; only the free bottom edge moves.
  fringe[i].polygon = PackedVector2Array([facade(true,t0,.8,56),facade(true,t1,.8,56),facade(true,t1,.82+bend,z+.5),facade(true,(t0+t1)*.5,.84+bend,z),facade(true,t0,.82+bend,z+.5)])
  hem.append(facade(true,t0,.82+bend,z+.5))
  hem.append(facade(true,(t0+t1)*.5,.84+bend,z))
  hem.append(facade(true,t1,.82+bend,z+.5))
 if is_instance_valid(cloth_hem):cloth_hem.points = hem

func _process(delta: float) -> void:
 if fringe.is_empty():return
 cloth_phase += delta*1.4
 update_cloth()

func point(u: float,v: float,z: float) -> Vector2:
 return Vector2((u-width_cells-v+depth_cells)*32.0,(u-width_cells+v-depth_cells)*16.0-z)

func line(points: PackedVector2Array,color: Color,width: float=1.0) -> void:
 var node := Line2D.new()
 node.points = points
 node.default_color = color
 node.width = width
 node.antialiased = true
 add_child(node)

func solid(points: PackedVector2Array,color: Color) -> void:
 var node := Polygon2D.new()
 node.polygon = points
 node.color = color
 add_child(node)

func wall(points: PackedVector2Array,panel: Vector2i) -> void:
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = points
 # Slight inset prevents neighboring atlas panels leaking through filtering.
 var origin := Vector2(panel)*0.5+Vector2.ONE*0.002
 var size_uv := 0.496
 arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([origin,origin+Vector2(size_uv,0),origin+Vector2.ONE*size_uv,origin+Vector2(0,size_uv)])
 arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var node := MeshInstance2D.new()
 node.mesh = mesh
 node.texture = load(ATLAS)
 node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(node)

func roof_point(across: float,along: float,z: float) -> Vector2:
 return point(along,across,z) if house else point(across,along,z)

func roof_art(points: PackedVector2Array,near_side: bool) -> void:
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = points
 arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0,1),Vector2(0,0),Vector2(1,0),Vector2(1,1)])
 arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var node := MeshInstance2D.new()
 node.mesh = mesh
 node.texture = load(ROOF_ART)
 node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 node.modulate = Color("CBD8D8") if not near_side else Color.WHITE
 add_child(node)

func _ready() -> void:
 if house:
  width_cells = 2.8
  depth_cells = 2.4
 var w := width_cells
 var d := depth_cells
 wall(PackedVector2Array([point(w,d,HEIGHT),point(w,0,HEIGHT),point(w,0,0),point(w,d,0)]),Vector2i(1,1) if house else Vector2i(0,0))
 wall(PackedVector2Array([point(0,d,HEIGHT),point(w,d,HEIGHT),point(w,d,0),point(0,d,0)]),Vector2i(0,1) if house else Vector2i(1,0))
 # A continuous foundation follows the very same planes as the wall textures.
 solid(PackedVector2Array([point(w,0,4),point(w,d,4),point(w,d,0),point(w,0,0)]),Color("ADA995"))
 solid(PackedVector2Array([point(0,d,4),point(w,d,4),point(w,d,0),point(0,d,0)]),Color("CDC6AD"))
 line(PackedVector2Array([point(0,d,0),point(w,d,0),point(w,0,0)]),Color("41443B"),1.2)
 line(PackedVector2Array([point(w,d,0),point(w,d,HEIGHT)]),Color("3E3E34"),1.0)
 if house:
  window_detail(true,.16,.36,75,94,true)
  window_detail(true,.64,.84,75,94)
  balcony()
 else:
  window_detail(false,.55,.77,72,93,true)
  awning()
 var across := d if house else w
 var along := w if house else d
 var center := across*0.5
 # Front gable and both roof planes are built from common ridge/eave vertices.
 solid(PackedVector2Array([roof_point(0,along,HEIGHT),roof_point(center,along,HEIGHT+RIDGE),roof_point(across,along,HEIGHT)]),Color("E4D7AD"))
 for near_side in [false,true]:
  var edge := across+OVERHANG if near_side else -OVERHANG
  var roof := PackedVector2Array([roof_point(edge,-OVERHANG,HEIGHT+2),roof_point(center,-OVERHANG,HEIGHT+RIDGE),roof_point(center,along+OVERHANG,HEIGHT+RIDGE),roof_point(edge,along+OVERHANG,HEIGHT+2)])
  roof_art(roof,near_side)
  var border := roof.duplicate()
  border.append(roof[0])
  line(border,Color("203741"),2.1)
 line(PackedVector2Array([roof_point(center,-OVERHANG,HEIGHT+RIDGE),roof_point(center,along+OVERHANG,HEIGHT+RIDGE)]),Color("1F333E"),3.0)
