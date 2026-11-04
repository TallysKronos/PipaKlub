extends Node2D
## Isolated multi-surface dock fixture. No campaign state or production navigation.
@export var geometry_only := false
@export var decorate := true
@export var cutaway_surfaces: Array[String] = []
const BASE := "res://assets/overworld/kits/cais-v1/"
var parts: Array[Dictionary] = []
var surfaces: Array[Dictionary] = []
var rocks: Array[Dictionary] = []
var textures: Dictionary = {}
var probe: Node2D
var active_surface := "terminal"
var probe_cell := Vector2(8.5,22.5)
var ocean_material: ShaderMaterial
var rendering_surface := "terrain"
var ordering_review: Dictionary = {}

static func iso(p: Vector2,h: float=0) -> Vector2:
 return Vector2((p.x-p.y)*32,(p.x+p.y)*16-h)

static func rect(b: Array) -> PackedVector2Array:
 return PackedVector2Array([Vector2(b[0],b[1]),Vector2(b[2],b[1]),Vector2(b[2],b[3]),Vector2(b[0],b[3])])

func queue(node: Node2D,depth: float,polygon: PackedVector2Array=PackedVector2Array(),plane: Vector3=Vector3.ZERO) -> void:
 var bounds := Rect2()
 if polygon.size()>0:
  bounds = Rect2(polygon[0],Vector2.ZERO)
  for p in polygon:bounds = bounds.expand(p)
 parts.append({"node":node,"depth":depth,"surface":rendering_surface,"polygon":polygon,"bounds":bounds,"plane":plane if plane!=Vector3.ZERO else Vector3(0,0,depth)})

func depth_plane(p: PackedVector2Array,d: PackedFloat32Array) -> Vector3:
 for i in range(1,p.size()-1):
  var ab := p[i]-p[0]
  var ac := p[i+1]-p[0]
  var determinant := ab.cross(ac)
  if absf(determinant)<.00001:continue
  var a := ((d[i]-d[0])*ac.y-(d[i+1]-d[0])*ab.y)/determinant
  var b := (ab.x*(d[i+1]-d[0])-ac.x*(d[i]-d[0]))/determinant
  return Vector3(a,b,d[0]-a*p[0].x-b*p[0].y)
 return Vector3(0,0,d[0])

func order_faces() -> void:
 ordering_review = load("res://scripts/overworld/pier_visibility.gd").resolve(parts)

func set_surface_visible(id: String,value: bool) -> void:
 for item in parts:
  if item.surface==id:item.node.visible = value

func face(points: Array,uv: PackedVector2Array,kind: String,tint: Color=Color.WHITE) -> void:
 var projected := PackedVector2Array()
 var depth := 0.0
 var values := PackedFloat32Array()
 for p: Vector3 in points:
  projected.append(iso(Vector2(p.x,p.y),p.z))
  depth += (p.x+p.y)*32+p.z
  values.append((p.x+p.y)*32+p.z)
 depth /= float(points.size())
 var node: Node2D
 if not geometry_only and textures.has(kind):
  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = projected
  arrays[Mesh.ARRAY_TEX_UV] = uv
  arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(projected)
  var mesh := ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  var painted := MeshInstance2D.new()
  painted.mesh = mesh
  painted.texture = textures[kind]
  painted.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
  painted.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  painted.modulate = tint
  node = painted
 else:
  var poly := Polygon2D.new()
  poly.polygon = projected
  poly.color = tint if kind=="ink" else (Color("C0AC82") if kind=="wood" else Color("557C80"))
  if geometry_only and kind=="wood":poly.color = Color.from_hsv(fmod(points[0].z/400.0+.05,1.0),.30,.80)*tint
  node = poly
 queue(node,depth,projected,depth_plane(projected,values))

func quad(a: Vector2,b: Vector2,c: Vector2,d: Vector2,ha: float,hb: float,hc: float,hd: float,kind: String,tint: Color=Color.WHITE) -> void:
 face([Vector3(a.x,a.y,ha),Vector3(b.x,b.y,hb),Vector3(c.x,c.y,hc),Vector3(d.x,d.y,hd)],PackedVector2Array([a/4,b/4,c/4,d/4]),kind,tint)

func wall(a: Vector2,b: Vector2,bottom: float,top: float,kind: String,tint: Color=Color.WHITE) -> void:
 if top<=bottom+.01:return
 var steps := maxi(1,ceili(a.distance_to(b)/.5))
 for i in range(steps):
  var aa := a.lerp(b,float(i)/steps)
  var bb := a.lerp(b,float(i+1)/steps)
  var count := maxi(1,ceili((top-bottom)/32.0))
  for j in range(count):
   var z0 := lerpf(bottom,top,float(j)/count)
   var z1 := lerpf(bottom,top,float(j+1)/count)
   var u0 := (aa.x+aa.y)/4.0
   var u1 := (bb.x+bb.y)/4.0
   var uv := PackedVector2Array([Vector2(u0,z1/100),Vector2(u1,z1/100),Vector2(u1,z0/100),Vector2(u0,z0/100)])
   if kind=="wood" and top-bottom>15:
    uv = PackedVector2Array([Vector2(z1/100,u0),Vector2(z1/100,u1),Vector2(z0/100,u1),Vector2(z0/100,u0)])
   face([Vector3(aa.x,aa.y,z1),Vector3(bb.x,bb.y,z1),Vector3(bb.x,bb.y,z0),Vector3(aa.x,aa.y,z0)],uv,kind,tint)

func line3(points: Array,color: Color,width: float=1.0,bias: float=.5) -> void:
 var node := Line2D.new()
 node.width = width
 node.default_color = color
 node.antialiased = true
 var depth := 0.0
 for p: Vector3 in points:
  node.add_point(iso(Vector2(p.x,p.y),p.z))
  depth += (p.x+p.y)*32+p.z
 var polygon := PackedVector2Array()
 var plane := Vector3(0,0,depth/points.size()+bias)
 if points.size()==2:
  var a := node.points[0]
  var b := node.points[1]
  var delta := b-a
  var normal := Vector2(-delta.y,delta.x).normalized()*width*.5
  polygon = PackedVector2Array([a+normal,b+normal,b-normal,a-normal])
  var da: float = (points[0].x+points[0].y)*32+points[0].z+bias
  var db: float = (points[1].x+points[1].y)*32+points[1].z+bias
  var gradient := delta*(db-da)/maxf(delta.length_squared(),.0001)
  plane = Vector3(gradient.x,gradient.y,da-gradient.dot(a))
 queue(node,depth/points.size()+bias,polygon,plane)

func post(p: Vector2,bottom: float,top: float,width: float=.10) -> void:
 wall(p+Vector2(-width,-width),p+Vector2(width,-width),bottom,top,"wood",Color("BCA886"))
 wall(p+Vector2(width,-width),p+Vector2(width,width),bottom,top,"wood",Color("A27D62"))
 wall(p+Vector2(width,width),p+Vector2(-width,width),bottom,top,"wood",Color("D6B68E"))
 quad(p+Vector2(-width,-width),p+Vector2(width,-width),p+Vector2(width,width),p+Vector2(-width,width),top,top,top,top,"wood")

func top_rect(b: Array,h: float,kind: String="wood") -> void:
 var u := float(b[0])
 while u<float(b[2])-.001:
  var v := float(b[1])
  var u1 := minf(u+.5,float(b[2]))
  while v<float(b[3])-.001:
   var v1 := minf(v+.5,float(b[3]))
   quad(Vector2(u,v),Vector2(u1,v),Vector2(u1,v1),Vector2(u,v1),h,h,h,h,kind)
   v = v1
  u = u1

func add_surface(id: String,bounds: Array,h: float,neighbors: Array) -> void:
 surfaces.append({"id":id,"bounds":bounds,"height":h,"neighbors":neighbors})

func plan() -> void:
 add_surface("peak",[-3,4,-.65,6],288,["middle"])
 add_surface("middle",[-1,4,1.25,7],224,["peak","cliff_landing"])
 add_surface("cliff_landing",[1,5,3,8],128,["middle","left_bridge"])
 add_surface("left_bridge",[3,7,5,8],128,["cliff_landing","upper_hub"])
 add_surface("upper_hub",[5,6,9,9],128,["left_bridge","north_bridge","hub_stairs"])
 add_surface("north_bridge",[6.5,2,8,6],128,["upper_hub","tower_base"])
 add_surface("tower_base",[5,-2,10,2],128,["north_bridge","outpost","tower_stairs"])
 add_surface("outpost",[10,-1,12,1],128,["tower_base"])
 add_surface("tower_floor",[5.5,-2,8.5,0],192,["tower_stairs","tower_upper"])
 add_surface("tower_upper",[5.5,-2,8.5,0],256,["tower_floor"])
 add_surface("lower_hub",[5,11,11,14],64,["hub_stairs","underpass","east_branch","dock_stairs"])
 add_surface("underpass",[8,7.5,9,11],64,["lower_hub","east_branch"])
 add_surface("east_branch",[9,9,12,11],64,["underpass","lower_hub","beach_approach"])
 add_surface("beach_approach",[12,10,14,11],64,["east_branch","beach_stairs"])
 add_surface("beach",[16,8,20,13],8,["beach_stairs"])
 add_surface("dock",[5,16,7,18],12,["dock_stairs","cross_dock"])
 add_surface("cross_dock",[5,18,9,19],12,["dock","zigzag"])
 add_surface("zigzag",[8,19,9,22],12,["cross_dock","terminal"])
 add_surface("terminal",[7,22,10,23],12,["zigzag"])
 surfaces.append({"id":"hub_stairs","bounds":[7,9,8.5,11],"height":128,"end_height":64,"axis":"v","steps":8,"neighbors":["upper_hub","lower_hub"]})
 surfaces.append({"id":"tower_stairs","bounds":[7,0,8,2],"height":192,"end_height":128,"axis":"v","steps":8,"neighbors":["tower_floor","tower_base","north_bridge"]})
 surfaces.append({"id":"beach_stairs","bounds":[14,10,16,11],"height":64,"end_height":8,"axis":"u","steps":8,"neighbors":["beach_approach","beach"]})
 surfaces.append({"id":"dock_stairs","bounds":[5,14,7,16],"height":64,"end_height":12,"axis":"v","steps":13,"neighbors":["lower_hub","dock"]})
 rocks = [
  {"points":PackedVector2Array([Vector2(-4.5,3.5),Vector2(-3.8,2.7),Vector2(-1,3),Vector2(-1,7),Vector2(-2,7.4),Vector2(-4,6.8)]),"height":272.0},
  {"points":rect([-1,3,1,7]),"height":208.0},
  {"points":PackedVector2Array([Vector2(1,3),Vector2(2.8,3.4),Vector2(3,5),Vector2(3,7.8),Vector2(1,7.8)]),"height":112.0},
  {"points":PackedVector2Array([Vector2(4.7,-2.2),Vector2(7,-3),Vector2(9.8,-2),Vector2(10,2),Vector2(7,2.4),Vector2(5,1.7)]),"height":112.0},
  {"points":PackedVector2Array([Vector2(10,-1),Vector2(11.7,-1.4),Vector2(12.3,0),Vector2(12,1.4),Vector2(10,1)]),"height":112.0},
  {"points":PackedVector2Array([Vector2(-3,10),Vector2(-1,10),Vector2(1,11),Vector2(1,14),Vector2(-1,15),Vector2(-3,14)]),"height":80.0}]

func rock_height(p: Vector2) -> float:
 var height := 0.0
 for rock in rocks:
  if Geometry2D.is_point_in_polygon(p,rock.points):height = maxf(height,rock.height)
 return height

func rock(region: Dictionary) -> void:
 var poly: PackedVector2Array = region.points
 var h: float = region.height
 var triangles := Geometry2D.triangulate_polygon(poly)
 for i in range(0,triangles.size(),3):
  var points := []
  var uv := PackedVector2Array()
  for index in [triangles[i],triangles[i+1],triangles[i+2]]:
   points.append(Vector3(poly[index].x,poly[index].y,h))
   uv.append(poly[index]/5)
  face(points,uv,"grass",Color("B3C79F"))
 for i in range(poly.size()):
  var a := poly[i]
  var b := poly[(i+1)%poly.size()]
  var outward := Vector2(b.y-a.y,a.x-b.x).normalized()
  var steps := maxi(1,ceili(a.distance_to(b)/.5))
  for j in range(steps):
   var aa := a.lerp(b,float(j)/steps)
   var bb := a.lerp(b,float(j+1)/steps)
   var bottom := rock_height((aa+bb)*.5+outward*.015)
   wall(aa,bb,bottom,h,"rock",Color("DBE3D3") if outward.y>0 else Color("ADBEBB"))
  line3([Vector3(a.x,a.y,h),Vector3(b.x,b.y,h)],Color("385652"),1.2)

func surface_height(s: Dictionary,p: Vector2,stepped: bool=false) -> float:
 if s.id=="north_bridge":return 128.0-12.0*sin(clampf((p.y-2.0)/4.0,0,1)*PI)
 if not s.has("end_height"):return float(s.height)
 var b: Array = s.bounds
 var t := clampf((p.x-b[0])/(b[2]-b[0]),0,1) if s.axis=="u" else clampf((p.y-b[1])/(b[3]-b[1]),0,1)
 if stepped and t<1.0:t = floor(t*int(s.steps))/float(s.steps)
 return lerpf(float(s.height),float(s.end_height),t)

func deck(s: Dictionary) -> void:
 if s.id=="north_bridge":
  suspension_bridge(s)
  return
 var b: Array = s.bounds
 var h: float = s.height
 top_rect(b,h)
 var p := rect(b)
 for i in range(4):
  var a := p[i]
  var bb := p[(i+1)%4]
  var steps := maxi(1,ceili(a.distance_to(bb)/.5))
  var outward := Vector2(bb.y-a.y,a.x-bb.x).normalized()
  for j in range(steps):
   var aa := a.lerp(bb,float(j)/steps)
   var end := a.lerp(bb,float(j+1)/steps)
   var sample := (aa+end)*.5+outward*.015
   var joined := false
   for other in surfaces:
    if other.id==s.id:continue
    if Geometry2D.is_point_in_polygon(sample,rect(other.bounds)) and absf(surface_height(other,sample)-h)<1.0:
     joined = true
     break
   if not joined:wall(aa,end,h-5,h,"wood",Color("AE8466"))
  line3([Vector3(a.x,a.y,h),Vector3(bb.x,bb.y,h)],Color("664C3A"),.65)
 if s.id in ["tower_floor","tower_upper"]:return
 for corner in p:
  var base := rock_height(corner)
  for other in surfaces:
   if other.id==s.id or not contains(other,corner):continue
   var support := surface_height(other,corner)
   if support<h-5:base = maxf(base,support)
  if base<h-5:post(corner,base,h-3)

func suspension_bridge(s: Dictionary) -> void:
 for i in range(16):
  var v0 := 2.0+float(i)*.25
  var v1 := v0+.25
  var h0 := surface_height(s,Vector2(7,v0))
  var h1 := surface_height(s,Vector2(7,v1))
  quad(Vector2(6.5,v0),Vector2(8,v0),Vector2(8,v1),Vector2(6.5,v1),h0,h0,h1,h1,"wood")
  for u in [6.5,8.0]:
   quad(Vector2(u,v0),Vector2(u,v1),Vector2(u,v1),Vector2(u,v0),h0,h1,h1-4,h0-4,"wood",Color("BE986F"))
   line3([Vector3(u,v0,h0+16),Vector3(u,v1,h1+16)],Color("D7BA79"),1.3)
 for u in [6.5,8.0]:
  for v in [2.0,6.0]:post(Vector2(u,v),124,150,.04)

func stairs(s: Dictionary) -> void:
 var b: Array = s.bounds
 var count := int(s.steps)
 for i in range(count):
  var t0 := float(i)/count
  var t1 := float(i+1)/count
  var z0 := lerpf(float(s.height),float(s.end_height),t0)
  var z1 := lerpf(float(s.height),float(s.end_height),t1)
  var box := b.duplicate()
  if s.axis=="u":
   box[0] = lerpf(float(b[0]),float(b[2]),t0)
   box[2] = lerpf(float(b[0]),float(b[2]),t1)
  else:
   box[1] = lerpf(float(b[1]),float(b[3]),t0)
   box[3] = lerpf(float(b[1]),float(b[3]),t1)
  top_rect(box,z0)
  var p := rect(box)
  var a := p[1] if s.axis=="u" else p[2]
  var bb := p[2] if s.axis=="u" else p[3]
  wall(a,bb,z1,z0,"wood",Color("B18A6B"))
  line3([Vector3(a.x,a.y,z0),Vector3(bb.x,bb.y,z0)],Color("624A3C"),.7)
 # Open timber stringers stay below the treads; they taper along the flight.
 for edge in [0,1]:
  var a := Vector2(b[0],b[1])
  var bb := Vector2(b[2],b[1]) if s.axis=="u" else Vector2(b[0],b[3])
  if edge==1:
   a = Vector2(b[0],b[3]) if s.axis=="u" else Vector2(b[2],b[1])
   bb = Vector2(b[2],b[3])
  line3([Vector3(a.x,a.y,s.height-4),Vector3(bb.x,bb.y,s.end_height-4)],Color("6D503B"),3.0,-1)

func ladder(p: Vector2,bottom: float,top: float,mount_x: float=INF) -> void:
 for offset in [-.18,.18]:post(p+Vector2(0,offset),bottom,top+5,.035)
 var steps := ceili((top-bottom)/9)
 for i in range(steps+1):
  var z := lerpf(bottom,top,float(i)/steps)
  line3([Vector3(p.x,p.y-.18,z),Vector3(p.x,p.y+.18,z)],Color("E5B76D"),2.0)
 if is_finite(mount_x):
  for z in [bottom+18,top-10]:
   for v in [-.18,.18]:line3([Vector3(mount_x,p.y+v,z),Vector3(p.x,p.y+v,z)],Color("7C6242"),1.4)

func tower() -> void:
 for p in rect([5.5,-2,8.5,0]):post(p,128,320,.085)
 ladder(Vector2(8.55,-.85),192,256)
 var previous_surface := rendering_surface
 rendering_surface = "tower_roof"
 var bottom := rect([5.15,-2.35,8.85,.35])
 var top := rect([6.35,-1.25,7.65,-.75])
 for i in range(4):
  var j := (i+1)%4
  face([Vector3(bottom[i].x,bottom[i].y,320),Vector3(bottom[j].x,bottom[j].y,320),Vector3(top[j].x,top[j].y,352),Vector3(top[i].x,top[i].y,352)],PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]),"thatch",Color.WHITE if i>0 else Color("B6BCAF"))
  line3([Vector3(bottom[i].x,bottom[i].y,320),Vector3(bottom[j].x,bottom[j].y,320)],Color("4A4B3A"),1.3)
 top_rect([6.35,-1.25,7.65,-.75],352,"thatch")
 rendering_surface = previous_surface

func rug(b: Array,h: float,color: Color) -> void:
 var p := rect(b)
 quad(p[0],p[1],p[2],p[3],h+.20,h+.20,h+.20,h+.20,"ink",color)
 var center := Vector2((b[0]+b[2])*.5,(b[1]+b[3])*.5)
 var r := .28
 var points := []
 for v in [Vector2(-r,-r),Vector2(r,-r),Vector2(r,r),Vector2(-r,r)]:points.append(Vector3(center.x+v.x,center.y+v.y,h+.3))
 face(points,PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),"ink",Color("E7C67E"))
 # Depth of the painted rug is its actual support height, never a global layer.

func palm(p: Vector2,h: float,scale_value: float=.65) -> void:
 var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"palma/rig.json"))
 var node := Node2D.new()
 node.position = iso(p,h)
 node.scale = Vector2.ONE*scale_value
 for part: Dictionary in rig.parts:
  if not part.get("visible",true):continue
  var sprite := Sprite2D.new()
  var path := "palma/"+str(part.asset)+".png"
  sprite.texture = load(BASE+path)
  sprite.centered = false
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  sprite.position = Vector2(part.rect[0]-rig.rootPivot[0],part.rect[1]-rig.rootPivot[1])
  sprite.scale = Vector2(part.rect[2]/sprite.texture.get_width(),part.rect[3]/sprite.texture.get_height())
  node.add_child(sprite)
 var order := 0
 for child in node.get_children():
  var r := Rect2(child.position*scale_value,child.texture.get_size()*child.scale*scale_value)
  r.position += node.position
  var polygon := PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = polygon
  arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN])
  arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
  var mesh := ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  var painted := MeshInstance2D.new()
  painted.mesh = mesh
  painted.texture = child.texture
  var bias := float(order)*.001
  queue(painted,(p.x+p.y)*32+h+bias,polygon,Vector3(0,-1,(p.x+p.y)*32+h+node.position.y+bias))
  parts.back()["transparent"] = true
  order += 1
 node.free()

func beach() -> void:
 var poly := beach_polygon()
 var triangles := Geometry2D.triangulate_polygon(poly)
 for i in range(0,triangles.size(),3):
  var points := []
  var uv := PackedVector2Array()
  for index in [triangles[i],triangles[i+1],triangles[i+2]]:
   points.append(Vector3(poly[index].x,poly[index].y,8))
   uv.append(poly[index]/8)
  face(points,uv,"sand")
 for i in range(poly.size()):
  var a := poly[i]
  var b := poly[(i+1)%poly.size()]
  wall(a,b,0,8,"ink",Color("C6AD78"))
  line3([Vector3(a.x,a.y,0),Vector3(b.x,b.y,0)],Color("9AD6D3"),3.0)

func beach_polygon() -> PackedVector2Array:
 return PackedVector2Array([Vector2(16,8),Vector2(17.6,7.7),Vector2(19.5,8),Vector2(20.4,9.5),Vector2(20,11.5),Vector2(18.6,13.3),Vector2(16.5,13),Vector2(15.8,11.4),Vector2(16,10)])

func contains(s: Dictionary,p: Vector2) -> bool:
 return Geometry2D.is_point_in_polygon(p,beach_polygon() if s.id=="beach" else rect(s.bounds))

func parasol(p: Vector2) -> void:
 post(p,8,58,.035)
 var border := [Vector2(-.85,0),Vector2(-.5,-.65),Vector2(.5,-.65),Vector2(.85,0),Vector2(.5,.65),Vector2(-.5,.65)]
 for i in range(6):
  var a: Vector2 = p+border[i]
  var b: Vector2 = p+border[(i+1)%6]
  face([Vector3(a.x,a.y,50),Vector3(b.x,b.y,50),Vector3(p.x,p.y,66)],PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2(.5,1)]),"ink",Color("DDC483") if i%2==0 else Color("B89661"))
  line3([Vector3(a.x,a.y,50),Vector3(b.x,b.y,50)],Color("5B5841"),1)

func canoe(p: Vector2) -> void:
 var outline := PackedVector2Array([p+Vector2(-1.5,0),p+Vector2(-.8,-.38),p+Vector2(.8,-.38),p+Vector2(1.5,0),p+Vector2(.8,.38),p+Vector2(-.8,.38)])
 var points := []
 var uv := PackedVector2Array()
 for v in outline:
  points.append(Vector3(v.x,v.y,3))
  uv.append(v/4)
 face(points,uv,"wood",Color("93694D"))
 for i in range(6):
  var a := outline[i]
  var b := outline[(i+1)%6]
  line3([Vector3(a.x,a.y,4),Vector3(b.x,b.y,4)],Color("E6B277"),3)
 for x in [-.65,.5]:
  var a := p+Vector2(x,-.30)
  var b := p+Vector2(x+.2,.30)
  quad(a,a+Vector2(.18,0),b+Vector2(.18,0),b,8,8,8,8,"wood")

func _ready() -> void:
 for pair in [["wood","madeira"],["rock","rocha"],["thatch","palha"],["sand","areia"],["grass","grama"]]:
  var path: String = BASE+"surfaces/"+pair[1]+".png"
  if ResourceLoader.exists(path):textures[pair[0]] = load(path)
 var sea := Polygon2D.new()
 sea.polygon = PackedVector2Array([Vector2(-5000,-5000),Vector2(5000,-5000),Vector2(5000,5000),Vector2(-5000,5000)])
 sea.uv = sea.polygon
 ocean_material = ShaderMaterial.new()
 ocean_material.shader = load("res://shaders/overworld/pier_ocean.gdshader")
 sea.material = ocean_material
 add_child(sea)
 plan()
 for region in rocks:rock(region)
 beach()
 for s in surfaces:
  if s.id=="beach":continue
  rendering_surface = s.id
  if s.has("steps"):stairs(s)
  else:deck(s)
 rendering_surface = "decor"
 ladder(Vector2(-.60,5.6),224,288,-1)
 ladder(Vector2(1.30,6.4),128,224,1)
 tower()
 if decorate and not geometry_only:
  for r in [[[5.6,6.7,7.3,8.2],128,Color("387F87")],[[6,11.6,9,12.4],64,Color("B26943")],[[8.8,-1.3,9.7,-.3],128,Color("765B82")],[[-2.8,4.3,-1.3,5.7],288,Color("A85C43")],[[5.9,-1.7,7.9,-.3],256,Color("3D8588")]]:
   var center := Vector2((r[0][0]+r[0][2])*.5,(r[0][1]+r[0][3])*.5)
   for s in surfaces:
    if s.height==r[1] and contains(s,center):
     rendering_surface = s.id
     break
   rug(r[0],r[1],r[2])
  rendering_surface = "decor"
  # Keep the whole root flare inside the ledge, not only its center point.
  # The lower ledge has a diagonal back edge: v=3.4 was too close to it.
  for p in [Vector2(-3.6,3.8),Vector2(-2.5,3.5),Vector2(-3.6,5.8),Vector2(0,3.6),Vector2(2.1,4.2),Vector2(-2,11),Vector2(-1.4,13.5),Vector2(.3,12.6)]:palm(p,rock_height(p),.48)
  palm(Vector2(11.2,.2),128,.44)
  palm(Vector2(17,9),8,.62)
  palm(Vector2(18.3,10),8,.53)
  parasol(Vector2(18.7,11.6))
  canoe(Vector2(3.5,18.5))
 if not cutaway_surfaces.is_empty():
  var kept: Array[Dictionary] = []
  for item in parts:
   if item.surface in cutaway_surfaces:item.node.free()
   else:kept.append(item)
  parts = kept
 order_faces()
 for item in parts:add_child(item.node)
 probe = Node2D.new()
 probe.visible = false
 add_child(probe)

func find_surface(id: String) -> Dictionary:
 for s in surfaces:
  if s.id==id:return s
 return {}

func place_probe(id: String,p: Vector2) -> void:
 active_surface = id
 probe_cell = p
 var surface := find_surface(id)
 if surface.is_empty():return
 var h := surface_height(surface,p,true)
 probe.visible = true
 probe.position = iso(p,h)
 if probe.get_child_count()==0:
  var marker := Polygon2D.new()
  marker.color = Color("FFE5A2")
  marker.polygon = PackedVector2Array([Vector2(0,-16),Vector2(6,-10),Vector2(0,-3),Vector2(-6,-10)])
  probe.add_child(marker)
  var contact := Polygon2D.new()
  contact.color = Color("D9F7F0")
  contact.polygon = PackedVector2Array([Vector2(-4,0),Vector2(0,-2),Vector2(4,0),Vector2(0,2)])
  probe.add_child(contact)
 # Insert the inspection marker into the same camera depth order as the faces.
 var depth := (p.x+p.y)*32+h+10
 var index := 1
 for item in parts:
  if item.depth>depth:break
  index += 1
 move_child(probe,mini(index,get_child_count()-1))

func _process(delta: float) -> void:
 if not probe.visible:return
 var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
 if direction==Vector2.ZERO:return
 move_probe(direction.normalized()*delta*2)

func move_probe(delta: Vector2) -> void:
 var next := probe_cell+delta
 var current := find_surface(active_surface)
 # An explicit stair gateway may sit over a lower deck in the same footprint.
 if not current.has("steps"):
  for id in current.neighbors:
   var target := find_surface(id)
   if target.has("steps") and contains(target,next) and absf(surface_height(current,probe_cell)-surface_height(target,next))<2:
    place_probe(id,next)
    return
 if contains(current,next):
  place_probe(active_surface,next)
  return
 for id in current.neighbors:
  var target := find_surface(id)
  if contains(target,next) and absf(surface_height(current,probe_cell)-surface_height(target,next))<12:
   place_probe(id,next)
   return

func _unhandled_key_input(event: InputEvent) -> void:
 if not (event is InputEventKey) or not event.pressed or event.echo or event.keycode!=KEY_E:return
 for link in [["middle","peak",Vector2(-.65,5.6)],["cliff_landing","middle",Vector2(1.25,6.4)],["tower_floor","tower_upper",Vector2(8.5,-.85)]]:
  if active_surface not in [link[0],link[1]] or probe_cell.distance_to(link[2])>.6:continue
  place_probe(link[1] if active_surface==link[0] else link[0],link[2])
  return
