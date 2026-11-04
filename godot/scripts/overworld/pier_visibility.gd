extends RefCounted
## Resolve opaque face visibility in projected space using affine ray depth.
## Convex subtraction emits convex fragments, including holes as separate pieces.

static func value(p: Vector2,plane: Vector3) -> float:
 return plane.x*p.x+plane.y*p.y+plane.z

static func clip(poly: PackedVector2Array,plane: Vector3,positive: bool=true) -> PackedVector2Array:
 var result := PackedVector2Array()
 if poly.is_empty():return result
 var previous := poly[-1]
 var before := value(previous,plane)*(1.0 if positive else -1.0)
 for current in poly:
  var after := value(current,plane)*(1.0 if positive else -1.0)
  if (before>=0)!=(after>=0):result.append(previous.lerp(current,before/(before-after)))
  if after>=0:result.append(current)
  previous = current
  before = after
 return result

static func area(poly: PackedVector2Array) -> float:
 var a := 0.0
 for i in range(poly.size()):a += poly[i].cross(poly[(i+1)%poly.size()])
 return a*.5

static func subtract(subject: PackedVector2Array,cutter: PackedVector2Array) -> Array[PackedVector2Array]:
 var pieces: Array[PackedVector2Array] = []
 var inside := subject
 var orientation := 1.0 if area(cutter)>0 else -1.0
 for i in range(cutter.size()):
  var a := cutter[i]
  var b := cutter[(i+1)%cutter.size()]
  var plane := Vector3(a.y-b.y,b.x-a.x,b.y*a.x-b.x*a.y)*orientation
  var outside := clip(inside,plane,false)
  if outside.size()>2 and absf(area(outside))>.002:pieces.append(outside)
  inside = clip(inside,plane,true)
  if inside.size()<3:break
 return pieces

static func uv_plane(points: PackedVector2Array,uv: PackedVector2Array,axis: int) -> Vector3:
 for i in range(1,points.size()-1):
  var ab := points[i]-points[0]
  var ac := points[i+1]-points[0]
  var determinant := ab.cross(ac)
  if absf(determinant)<.00001:continue
  var d0: float = uv[0][axis]
  var d1: float = uv[i][axis]-d0
  var d2: float = uv[i+1][axis]-d0
  var a := (d1*ac.y-d2*ab.y)/determinant
  var b := (ab.x*d2-ac.x*d1)/determinant
  return Vector3(a,b,d0-a*points[0].x-b*points[0].y)
 return Vector3.ZERO

static func rebuild(item: Dictionary,pieces: Array[PackedVector2Array]) -> void:
 var original: Node2D = item.node
 var texture: Texture2D
 var color := Color.WHITE
 var pu := Vector3.ZERO
 var pv := Vector3.ZERO
 if original is MeshInstance2D:
  var arrays: Array = original.mesh.surface_get_arrays(0)
  texture = original.texture
  color = original.modulate
  pu = uv_plane(arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_TEX_UV],0)
  pv = uv_plane(arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_TEX_UV],1)
 elif original is Polygon2D:color = original.color
 elif original is Line2D:color = original.default_color
 var vertices := PackedVector2Array()
 var uv := PackedVector2Array()
 var indices := PackedInt32Array()
 for poly in pieces:
  var offset := vertices.size()
  for p in poly:
   vertices.append(p)
   uv.append(Vector2(value(p,pu),value(p,pv)))
  for i in range(1,poly.size()-1):indices.append_array(PackedInt32Array([offset,offset+i,offset+i+1]))
 var result := MeshInstance2D.new()
 if indices.size()>0:
  var mesh_arrays := []
  mesh_arrays.resize(Mesh.ARRAY_MAX)
  mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
  mesh_arrays[Mesh.ARRAY_TEX_UV] = uv
  mesh_arrays[Mesh.ARRAY_INDEX] = indices
  var mesh := ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_arrays)
  result.mesh = mesh
 result.texture = texture
 result.material = original.material
 result.modulate = color
 result.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
 result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 if item.get("transparent",false):result.z_index = 1
 original.free()
 item.node = result

static func resolve(parts: Array[Dictionary]) -> Dictionary:
 var bins: Dictionary = {}
 for i in range(parts.size()):
  var box: Rect2 = parts[i].bounds
  for x in range(floori(box.position.x/48),floori(box.end.x/48)+1):
   for y in range(floori(box.position.y/48),floori(box.end.y/48)+1):
    var key := Vector2i(x,y)
    if not bins.has(key):bins[key] = []
    bins[key].append(i)
 var all_fragments := 0
 var hidden := 0
 var cuts := 0
 for i in range(parts.size()):
  var item := parts[i]
  if item.polygon.size()<3:continue
  var candidates: Dictionary = {}
  var box: Rect2 = item.bounds
  for x in range(floori(box.position.x/48),floori(box.end.x/48)+1):
   for y in range(floori(box.position.y/48),floori(box.end.y/48)+1):
    for j: int in bins[Vector2i(x,y)]:
     if j!=i and not parts[j].get("transparent",false) and box.intersects(parts[j].bounds):candidates[j] = true
  var pieces: Array[PackedVector2Array] = [item.polygon]
  for j: int in candidates:
   var other := parts[j]
   if item.get("skip_terrain_clip",false) and other.surface=="terrain":continue
   if other.polygon.size()<3:continue
   var difference: Vector3 = other.plane-item.plane
   difference.z -= .015
   var cutter := clip(other.polygon,difference)
   if cutter.size()<3 or absf(area(cutter))<.002:continue
   var next: Array[PackedVector2Array] = []
   for piece in pieces:
    # No overlap: do not split an unrelated polygon along infinite edge lines.
    if Geometry2D.intersect_polygons(piece,cutter).is_empty():next.append(piece)
    else:
     next.append_array(subtract(piece,cutter))
     cuts += 1
   pieces = next
   if pieces.is_empty():break
  if pieces.is_empty():hidden += 1
  all_fragments += pieces.size()
  rebuild(item,pieces)
 parts.sort_custom(func(a,b):return a.depth<b.depth)
 return {"method":"projected opaque visibility with affine depth and convex fragments","sourceFaces":parts.size(),"visibleConvexFragments":all_fragments,"hiddenFaces":hidden,"cuts":cuts,"centroidFallbackFaces":0}
