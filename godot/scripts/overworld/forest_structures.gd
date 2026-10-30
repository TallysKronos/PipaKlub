extends RefCounted
## Estruturas da floresta. Um contorno medido serve ao recorte e ao volume do poço.
const FALL=preload("res://scripts/overworld/cave_waterfall.gd")
const BASE="res://assets/overworld/kits/"
static func geometry() -> bool:return OS.get_environment("KRONASTA_GEOMETRIA")=="1"
static func iso(p:Vector2,h:float=0) -> Vector2:return Vector2((p.x-p.y)*32,(p.x+p.y)*16-h)
static func uv_points(values:Array) -> PackedVector2Array:
 var result:=PackedVector2Array()
 for p in values:result.append(Vector2(p[0],p[1]))
 return result
static func shapes(model) -> Array:
 var w:Dictionary=model.data.get("forest",{}).get("water",{}) if model.data.get("forest",{}).get("water")!=null else {}
 return [uv_points(w.contour),uv_points(w.channel)] if not w.is_empty() else []
static func is_water(model,p:Vector2) -> bool:
 for shape:PackedVector2Array in shapes(model):
  if shape.is_empty():continue
  if Geometry2D.is_point_in_polygon(p,shape):return true
 return false
static func floor_cut(model,node:Node2D,poly:Polygon2D,corners:Array,u:int,v:int) -> void:
 var c:Dictionary=model.cell_at(Vector2i(u,v))
 if c.is_empty():c={"material":"grama","level":0}
 for stairs:Dictionary in model.data.get("forest",{}).get("stairs",[]):
  if u>=int(stairs.u) and u<int(stairs.u+stairs.width) and v>=int(stairs.v) and v<int(stairs.v+2):poly.free();return
 var fragments:Array=[PackedVector2Array(corners)]
 if c.get("material","")!="ponte":
  for shape:PackedVector2Array in shapes(model):
   if shape.is_empty():continue
   var next:Array=[]
   for f:PackedVector2Array in fragments:next.append_array(Geometry2D.clip_polygons(f,shape))
   fragments=next
 if fragments.is_empty():poly.free();return
 for index in fragments.size():
  var fragment:PackedVector2Array=fragments[index]
  var target:Polygon2D=poly if index==0 else poly.duplicate()
  var points:=PackedVector2Array()
  for p in fragment:points.append(iso(p,model.surface_height(c,p-Vector2(u,v))*64)-node.position)
  target.polygon=points
  target.uv=fragment
  var shade:Color=poly.vertex_colors[0] if poly.vertex_colors.size()>0 else Color.WHITE
  target.vertex_colors=PackedColorArray()
  target.color=shade
  if c.get("material","")=="piso":
   target.material=null
   target.texture=null if geometry() else load(BASE+"terrenos-v1/superficies/bloquete.png")
   target.color=Color("c5b88b") if geometry() else Color.WHITE
   target.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
   var paving_uv:=PackedVector2Array()
   for p in points:paving_uv.append((p+node.position)*2.8)
   target.uv=paving_uv
  if c.get("material","")=="ponte":
   target.material=null
   target.texture=null
   target.color=Color("b08a52")
  node.add_child(target)
static func line(parent:Node2D,points:PackedVector2Array,width:float,color:Color) -> void:
 var node:=Line2D.new();node.points=points;node.width=width;node.default_color=color;parent.add_child(node)
static func quad(parent:Node2D,points:PackedVector2Array,color:Color,texture:Texture2D=null) -> Polygon2D:
 var node:=Polygon2D.new();node.polygon=points;node.color=color;node.texture=texture;parent.add_child(node);return node
static func build(view) -> void:
 var model=view.model
 var f:Dictionary=model.data.get("forest",{})
 if f.is_empty():return
 var w:Dictionary=f.get("water",{}) if f.get("water")!=null else {}
 if not w.is_empty():
  var contours:=shapes(model)
  for index in contours.size():
   var contour:PackedVector2Array=contours[index]
   if contour.is_empty():continue
   if index==0:
    contour.insert(1,Vector2(35,9))
    contour.insert(2,Vector2(36,9))
   var depth:float=float(w.depth if index==0 else w.channelDepth)
   var surface:=Node2D.new();surface.z_index=-2;view.actors.add_child(surface)
   var bottom:=PackedVector2Array()
   for p in contour:bottom.append(iso(p)+Vector2(0,depth))
   var water:=quad(surface,bottom,Color("2a7490") if geometry() else Color(.65,.87,.93),null if geometry() else load(BASE+"aguas-v1/surfaces/rio-claro.png"))
   if not geometry():
    water.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
    var uv:=PackedVector2Array();for p in bottom:uv.append(p*.8)
    water.uv=uv
   for i in contour.size():
    var uv_a:Vector2=contour[i];var uv_b:Vector2=contour[(i+1)%contour.size()]
    if index==0 and uv_a==Vector2(35,9) and uv_b==Vector2(36,9):continue
    if index==1 and maxf(uv_a.x,uv_b.x)>=23 and minf(uv_a.x,uv_b.x)<=26:continue
    var a:Vector2=iso(uv_a);var b:Vector2=iso(uv_b)
    var bank:=Node2D.new();bank.position=Vector2(0,maxf(a.y,b.y)+3);view.actors.add_child(bank)
    var pts:=PackedVector2Array([a-bank.position,b-bank.position,b+Vector2(0,depth)-bank.position,a+Vector2(0,depth)-bank.position])
    var aperture:=PackedVector2Array()
    for p in contour:aperture.append(iso(p)-bank.position)
    # The same upper aperture clips the bank faces. The near bank is occluded by
    # the uncut upper floor, so its translated bottom cannot leak outside the hole.
    for fragment:PackedVector2Array in Geometry2D.intersect_polygons(pts,aperture):
     var face:=quad(bank,fragment,Color("907049") if geometry() else Color(.65,.67,.58),null if geometry() else load(BASE+"terrenos-v1/superficies/terra-barranco.png"))
     if not geometry():
      face.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
      var face_uv:=PackedVector2Array()
      for p in fragment:face_uv.append((p+bank.position)*2)
      face.uv=face_uv
    line(bank,PackedVector2Array([a-bank.position,b-bank.position]),3,Color("84a54a"))
    if Geometry2D.is_point_in_polygon((a+b)*.5+Vector2(0,depth)-bank.position,aperture):line(bank,PackedVector2Array([a+Vector2(0,depth)-bank.position,b+Vector2(0,depth)-bank.position]),3,Color(.05,.12,.13,.6))
  if w.get("fall")!=null:
   var fall_root:=Node2D.new();fall_root.position=iso(Vector2(w.fall[0],w.fall[1]));view.actors.add_child(fall_root)
   var fall:=Node2D.new();fall.set_script(FALL);fall.width_cells=1;fall.drop_levels=1;fall.drop_pixels_override=float(w.lipHeight)+float(w.depth);fall.position=Vector2(0,-float(w.lipHeight));fall.preview_time=.4;fall_root.add_child(fall)
   if geometry():
    fall.hide();var plane:=Node2D.new();plane.position=fall_root.position;view.actors.add_child(plane)
    var lip:float=float(w.lipHeight);var water_height:float=float(w.depth)
    quad(plane,PackedVector2Array([Vector2(0,-lip),Vector2(32,16-lip),Vector2(32,16+water_height),Vector2(0,water_height)]),Color("8ed3e0"))
 # Bridge timbers laid in the same cell footprint, head posts only at the two banks.
 for v in int(model.data.h):
  for u in int(model.data.w):
   if model.cell_at(Vector2i(u,v)).material!="ponte":continue
   var plank:=Node2D.new();plank.position=iso(Vector2(u,v))+Vector2(0,3);view.actors.add_child(plank)
   for t in [0.0,.33,.66]:line(plank,PackedVector2Array([iso(Vector2(u,v+t))-plank.position,iso(Vector2(u+1,v+t))-plank.position]),1.4,Color("735333"))
 if not w.is_empty():
  for at in [Vector2(23,19),Vector2(26,19),Vector2(23,25),Vector2(26,25)]:
   var post:=Node2D.new();post.position=iso(at)+Vector2(0,4);view.actors.add_child(post)
   line(post,PackedVector2Array([Vector2(0,-4),Vector2(0,-30)]),7,Color("79542f"))
   line(post,PackedVector2Array([Vector2(-3,-30),Vector2(3,-30)]),3,Color("dbba78"))
 for guard:Dictionary in f.get("guards",[]):_guard(view,guard)
 for stairs:Dictionary in f.get("stairs",[]):_stairs(view,stairs)
 if f.get("landmark")!=null:_landmark(view,f.landmark)
 if not geometry():
  for track:Array in f.get("footprints",[]):
   var point:=Vector2(track[0],track[1])
   var node:=Node2D.new();node.position=view.model.project(point,false)+Vector2(0,2);view.actors.add_child(node)
   var base:Vector2=view.model.project(point)-node.position
   # Flat impressions in the earth, three joined toes and a heel. These are
   # surface geometry, with the same height/depth as the measured ground.
   var shape:=PackedVector2Array([Vector2(-5,2),Vector2(-8,-1),Vector2(-5,-4),Vector2(-1,-1),Vector2(0,-5),Vector2(3,-4),Vector2(3,0),Vector2(7,-2),Vector2(8,1),Vector2(2,5),Vector2(-2,5)])
   for i in shape.size():shape[i]=shape[i]*Vector2(1,.6)+base
   quad(node,shape,Color("785734",.85))
  if not f.get("footprints",[]).is_empty():
   var strand:=Node2D.new();var point:=Vector2(23.7,34.5);strand.position=view.model.project(point,false)+Vector2(0,2);view.actors.add_child(strand)
   var base:Vector2=view.model.project(point)-strand.position
   line(strand,PackedVector2Array([base+Vector2(-14,0),base+Vector2(-6,-3),base+Vector2(2,0),base+Vector2(9,-4),base+Vector2(18,-2)]),1.4,Color("514c42"))
static func _guard(view,g:Dictionary) -> void:
 var model=view.model
 var a:=Vector2(g.u+1,g.v) if g.side=="u" else Vector2(g.u,g.v+1)
 var b:=Vector2(g.u+1,g.v+1)
 var height:float=model.height_at(Vector2(g.u+.5,g.v+.5))*64
 var base_a:=iso(a,height);var base_b:=iso(b,height)
 var node:=Node2D.new();node.position=iso((a+b)*.5)+Vector2(0,3);view.actors.add_child(node)
 quad(node,PackedVector2Array([base_a-node.position,base_b-node.position,base_b-Vector2(0,20)-node.position,base_a-Vector2(0,20)-node.position]),Color("7e8272") if geometry() else Color("7a8176"))
 line(node,PackedVector2Array([base_a-Vector2(0,20)-node.position,base_b-Vector2(0,20)-node.position]),4,Color("d5c69d"))
 # End caps are explicit vertical strips, also close adjacent corner faces.
 for p in [base_a,base_b]:line(node,PackedVector2Array([p-node.position,p-Vector2(0,20)-node.position]),3,Color("716449"))
static func _stairs(view,s:Dictionary) -> void:
 var u:float=s.u;var v:float=s.v;var width:float=s.width
 for k in 8:
  var low:float=float(k)/8;var high:float=float(k+1)/8;var height:float=high*64
  var a:=Vector2(u,v+2-high*2);var b:=Vector2(u+width,v+2-high*2)
  var c:=Vector2(u+width,v+2-low*2);var d:=Vector2(u,v+2-low*2)
  var node:=Node2D.new();node.position=iso((a+c)*.5)+Vector2(0,4);view.actors.add_child(node)
  quad(node,PackedVector2Array([iso(a,height)-node.position,iso(b,height)-node.position,iso(c,height)-node.position,iso(d,height)-node.position]),Color("d1c69e"))
  quad(node,PackedVector2Array([iso(d,height)-node.position,iso(c,height)-node.position,iso(c,height-8)-node.position,iso(d,height-8)-node.position]),Color("807c67"))
static func _landmark(view,p:Dictionary) -> void:
 var point:=Vector2(p.u,p.v);var pos:Vector2=view.model.project(point);var node:=Node2D.new();node.position=view.model.project(point,false);view.actors.add_child(node)
 node.z_index=1
 node.set_meta("scenery",true)
 var base:Vector2=pos-node.position
 line(node,PackedVector2Array([base,base-Vector2(0,205)]),12,Color("7a5231"))
 line(node,PackedVector2Array([base+Vector2(-64,-170),base+Vector2(64,-170)]),7,Color("a67b43"))
 for k in 5:
  var x:float=-54+k*26;var color:Color=[Color("edb849"),Color("dc7462"),Color("61afae"),Color("6b93b4"),Color("d6b978")][k]
  quad(node,PackedVector2Array([base+Vector2(x,-169),base+Vector2(x+14,-169),base+Vector2(x+30,-88-k%2*18),base+Vector2(x+16,-93-k%2*18)]),color)
