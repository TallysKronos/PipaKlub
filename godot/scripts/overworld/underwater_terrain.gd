extends RefCounted
## Shared measured footprints define tops, exposed faces, ramps and prop support.
const HIGH := 32.0
const LOW := -24.0

static func iso(cell: Vector2) -> Vector2:
 return Vector2((cell.x-cell.y)*32.0,(cell.x+cell.y)*16.0)

static func plateau() -> PackedVector2Array:
 var p := PackedVector2Array([Vector2(-.5,-.5)])
 for i in range(25):
  var v := -.5+float(i)*.5
  var edge := 4.5 if v>=6.0 and v<=8.5 else 4.5+sin((v-6.0)*1.256637)*0.35
  p.append(Vector2(edge,v))
 p.append(Vector2(-.5,11.5))
 return p

static func high_ramp() -> PackedVector2Array:
 return PackedVector2Array([Vector2(4.5,6),Vector2(7.5,6),Vector2(7.5,8.5),Vector2(4.5,8.5)])

static func basin() -> PackedVector2Array:
 return PackedVector2Array([Vector2(10,5.5),Vector2(12,5.5),Vector2(12.5,7),Vector2(12.1,9),Vector2(12.7,11.52),Vector2(8.5,11.52),Vector2(8.8,9.5),Vector2(9.2,7)])

static func low_ramp() -> PackedVector2Array:
 return PackedVector2Array([Vector2(10,3),Vector2(12,3),Vector2(12,5.5),Vector2(10,5.5)])

static func height_at(cell: Vector2) -> float:
 if Geometry2D.is_point_in_polygon(cell,high_ramp()):return HIGH*(7.5-cell.x)/3.0
 if Geometry2D.is_point_in_polygon(cell,low_ramp()):return LOW*(cell.y-3.0)/2.5
 if Geometry2D.is_point_in_polygon(cell,plateau()):return HIGH
 if Geometry2D.is_point_in_polygon(cell,basin()):return LOW
 return 0.0

static func projected(p: PackedVector2Array,height: float=0.0) -> PackedVector2Array:
 var result := PackedVector2Array()
 for cell in p:result.append(iso(cell)-Vector2(0,height))
 return result

static func floor_piece(parent: Node2D,p: PackedVector2Array,height: float,base: ShaderMaterial,geometry: bool) -> ShaderMaterial:
 var material := base.duplicate() as ShaderMaterial
 material.set_shader_parameter("layer_height",height)
 var node := Polygon2D.new()
 node.name = "Patamar_"+str(int(height))
 node.polygon = projected(p)
 node.position.y = -height
 node.material = null if geometry else material
 node.color = Color("719496") if height==0.0 else (Color("B2BA91") if height>0.0 else Color("3B657C"))
 if not geometry:node.color = Color.WHITE
 parent.add_child(node)
 return material

static func face(parent: Node2D,cells: PackedVector2Array,top_heights: PackedFloat32Array,bottom_height: float,geometry: bool) -> void:
 var vertices := PackedVector2Array()
 for i in range(cells.size()):vertices.append(iso(cells[i])-Vector2(0,top_heights[i]))
 for i in range(cells.size()-1,-1,-1):
  var point := iso(cells[i])-Vector2(0,bottom_height)
  if not vertices.has(point):vertices.append(point)
 if vertices.size()<3:return
 wall(parent,vertices,geometry)

static func wall(parent: Node2D,vertices: PackedVector2Array,geometry: bool) -> void:
 var node := Polygon2D.new()
 node.name = "FaceSustentada"
 node.polygon = vertices
 if geometry:node.color = Color("536B78")
 else:
  node.texture = load("res://assets/overworld/kits/cavernas-v3/surfaces/parede-umida.png")
  node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
  var uv := PackedVector2Array()
  for point in vertices:uv.append(Vector2(point.x*2.0+point.y,point.y*2.0))
  node.uv = uv
  node.color = Color(0.53,0.78,0.83)
 parent.add_child(node)

static func ramp(parent: Node2D,p: PackedVector2Array,mode: int,base: ShaderMaterial,geometry: bool) -> ShaderMaterial:
 var vertices := PackedVector2Array()
 var uv := PackedVector2Array()
 for point in p:
  var height := HIGH*(7.5-point.x)/3.0 if mode==1 else LOW*(point.y-3.0)/2.5
  vertices.append(iso(point)-Vector2(0,height))
  uv.append(point)
 var node := MeshInstance2D.new()
 node.name = "RampaContinua_"+str(mode)
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_TEX_UV] = uv
 arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 node.mesh = mesh
 var material := base.duplicate() as ShaderMaterial
 material.set_shader_parameter("use_cell_uv",true)
 material.set_shader_parameter("ramp_mode",mode)
 node.material = null if geometry else material
 node.modulate = Color("C79862") if geometry else Color.WHITE
 parent.add_child(node)
 return material

static func build(parent: Node2D,base: ShaderMaterial,geometry: bool=false) -> Array[ShaderMaterial]:
 var materials: Array[ShaderMaterial] = []
 var high := plateau()
 var low := basin()
 var upper_ramp := high_ramp()
 var lower_ramp := low_ramp()
 var room := PackedVector2Array([Vector2(-.5,-.5),Vector2(13.5,-.5),Vector2(13.5,11.5),Vector2(-.5,11.5)])
 # Subtract whole footprints, including ramps, before adding any surface art.
 var pieces: Array[PackedVector2Array] = [room]
 for cut in [high,low,upper_ramp,lower_ramp]:
  var next: Array[PackedVector2Array] = []
  for piece in pieces:next.append_array(Geometry2D.clip_polygons(piece,cut))
  pieces = next
 materials.append(floor_piece(parent,low,LOW,base,geometry))
 for i in range(low.size()):
  var a := low[i]
  var b := low[(i+1)%low.size()]
  # The rear ramp mouth and front map outlet have no transverse wall.
  if (is_equal_approx(a.y,5.5) and is_equal_approx(b.y,5.5)) or (a.y>11.5 and b.y>11.5):continue
  face(parent,PackedVector2Array([a,b]),PackedFloat32Array([0.0,0.0]),LOW,geometry)
 for u in [10.0,12.0]:
  wall(parent,PackedVector2Array([iso(Vector2(u,3)),iso(Vector2(u,5.5)),iso(Vector2(u,5.5))-Vector2(0,LOW)]),geometry)
 for piece in pieces:materials.append(floor_piece(parent,piece,0.0,base,geometry))
 # Raised cliff, with an opening exactly matching the upper ramp's high end.
 for i in range(high.size()):
  var a := high[i]
  var b := high[(i+1)%high.size()]
  if is_equal_approx(a.x,4.5) and is_equal_approx(b.x,4.5) and minf(a.y,b.y)>=6.0 and maxf(a.y,b.y)<=8.5:continue
  face(parent,PackedVector2Array([a,b]),PackedFloat32Array([HIGH,HIGH]),0.0,geometry)
 for v in [6.0,8.5]:
  face(parent,PackedVector2Array([Vector2(4.5,v),Vector2(7.5,v)]),PackedFloat32Array([HIGH,0.0]),0.0,geometry)
 materials.append(ramp(parent,lower_ramp,2,base,geometry))
 materials.append(ramp(parent,upper_ramp,1,base,geometry))
 materials.append(floor_piece(parent,high,HIGH,base,geometry))
 return materials
