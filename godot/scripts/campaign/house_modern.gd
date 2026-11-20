extends RefCounted
const BASE="res://assets/campaign/casa-moderna-v1/"
const INK=Color("263544")
static func applies(data:Dictionary) -> bool:return data.get("floorImage","") in ["bedroom-floor.png","home-floor.png"]
static func geometry() -> bool:return OS.get_environment("KAEL_ROOM_GEOMETRY")=="1"
static func room_data(source:Dictionary) -> Dictionary:
 if source.get("floorImage","")!="home-floor.png":return source
 if source.get("homeModernLayout",0)==2:return source
 var data:Dictionary=source.duplicate(true)
 data.homeModernLayout=2
 data.layout.floor.w=1440;data.layout.floor.h=1056
 data.floor=[384,288,1440,1056];data.walkable=[data.floor.duplicate()]
 data.width=2016;data.height=1472
 # Preserve staging coordinates. Only the view zoom and its prop rectangles change.
 var ratio:float=1.0/float(data.camera.scale)
 data.camera.scale=1.0
 for p in data.props:
  for i in 4:p.rect[i]*=ratio
 data.props.append({"id":"porta-mae","kind":"wallRight","footprint":null,"rect":[800.0,244.0,56.0,168.0]})
 return data
static func poly(root:Node2D,points:PackedVector2Array,color:Color,stroke:bool=true,width:float=1.5) -> void:
 var shape:=Polygon2D.new();shape.polygon=points;shape.color=color;root.add_child(shape)
 if stroke:
  var edge:=Line2D.new();edge.points=points;edge.closed=true;edge.default_color=INK;edge.width=width;edge.antialiased=true;root.add_child(edge)
static func line(root:Node2D,a:Vector2,b:Vector2,color:Color,width:float=1.5) -> void:
 var edge:=Line2D.new();edge.points=PackedVector2Array([a,b]);edge.default_color=color;edge.width=width;edge.antialiased=true;root.add_child(edge)
static func rect(room,root:Node2D,x:float,y:float,w:float,h:float,color:Color,stroke:bool=true) -> void:
 poly(root,PackedVector2Array([room.project(Vector2(x,y)),room.project(Vector2(x+w,y)),room.project(Vector2(x+w,y+h)),room.project(Vector2(x,y+h))]),color,stroke,1.)
static func build_floor(room) -> void:
 var root:=Node2D.new();root.name="CasaModernaFloor";root.z_index=0;room.add_child(root)
 var home:bool=room.data.floorImage=="home-floor.png"
 var scale:float=room.camera.scale;var height:=160.0*scale
 var f:Dictionary=room.data.layout.floor
 var back:Vector2=room.project(Vector2(f.x,f.y));var left:Vector2=room.project(Vector2(f.x,f.y+f.h));var right:Vector2=room.project(Vector2(f.x+f.w,f.y));var front:Vector2=room.project(Vector2(f.x+f.w,f.y+f.h))
 var up:=Vector2(0,-height)
 poly(root,PackedVector2Array([left,back,back+up,left+up]),Color("9eafb8") if geometry() else (Color("e7e5dc") if home else Color("87a6b8")),true,3.)
 poly(root,PackedVector2Array([back,right,right+up,back+up]),Color("c7d4d8") if geometry() else Color("f2eee5"),true,3.)
 for side in [left,right]:
  poly(root,PackedVector2Array([back,side,side-Vector2(0,9*scale),back-Vector2(0,9*scale)]),Color("597c92"),true,1.)
  line(root,back+up,side+up,Color("e7e9e3"),5.)
 line(root,back,back+up,INK,3.)
 poly(root,PackedVector2Array([left,left+Vector2(0,12),front+Vector2(0,12),front]),Color("959f9d"),true,2.)
 poly(root,PackedVector2Array([front,front+Vector2(0,12),right+Vector2(0,12),right]),Color("c1c8c2"),true,2.)
 if home:
  for row in int(ceil(float(f.h)/192.0)):
   for col in int(ceil(float(f.w)/192.0)):
    var x:float=f.x+col*192;var y:float=f.y+row*192
    var w:float=minf(192,f.x+f.w-x);var h:float=minf(192,f.y+f.h-y)
    if w>0 and h>0:
     var tone:float=float((row+col)%3)*.008
     rect(room,root,x,y,w,h,Color(.75+tone,.76+tone,.74+tone),false)
     line(root,room.project(Vector2(x,y)),room.project(Vector2(x+w,y)),Color("a6afad"),.7)
     line(root,room.project(Vector2(x,y)),room.project(Vector2(x,y+h)),Color("a6afad"),.7)
 else:
  for row in 16:
   var y:float=f.y+row*48
   for col in 5:
    var start:float=f.x+col*288-(144 if row%2 else 0)
    var x:float=maxf(f.x,start);var end:float=minf(f.x+f.w,start+288)
    if y>=864:x=maxf(x,672)
    if end<=x:continue
    var tone:float=float((row*7+col*3)%5)*.01
    rect(room,root,x,y,end-x,48,Color(.76+tone,.71+tone,.61+tone) if not geometry() else Color("c5ac82"),false)
    line(root,room.project(Vector2(x,y)),room.project(Vector2(end,y)),Color("9e9c8d"),.7)
 if not home:
  stairs_down(room,root)
  if not geometry():
   # A handmade paper kite identifies the maker's room without adding a floor obstacle.
   var center:Vector2=room.project(Vector2(384,760))-Vector2(0,110*scale)
   var top:Vector2=center-Vector2(0,34*scale);var bottom:Vector2=center+Vector2(0,34*scale)
   var side:Vector2=Vector2(23*scale,-11.5*scale)
   poly(root,PackedVector2Array([top,center+side,bottom,center-side]),Color("ba684e"),true,2.)
   poly(root,PackedVector2Array([top,center,bottom,center-side]),Color("e0b66b"),false)
   line(root,top,bottom,INK,1.);line(root,center-side,center+side,INK,1.)
   line(root,bottom,bottom+Vector2(-9,23),Color("495967"),1.2)
 else:
  # The private hall is on the same walking plane, with a small doorstep mat.
  rect(room,root,1632,320,168,96,Color("e5e4d8"),true)
  rect(room,root,1644,332,144,72,Color("718e9c"),false)
 room.set_meta("house_art","modern-v1")
static func create_prop(room,p:Dictionary) -> Node2D:
 var root:=Node2D.new();root.name="Modern_"+str(p.id)
 var r:=Rect2(p.rect[0],p.rect[1],p.rect[2],p.rect[3]);var id:String=p.id
 if id=="porta-mae":
  var a:=r.position;var b:=a+Vector2(r.size.x,r.size.x*.5)
  var d:=a+Vector2(0,140);var c:=b+Vector2(0,140)
  poly(root,PackedVector2Array([a,b,c,d]),Color("f1f0e8"),true,2.)
  var left:=a+Vector2(5,9);var right:=b+Vector2(-5,4)
  poly(root,PackedVector2Array([left,right,right+Vector2(0,126),left+Vector2(0,126)]),Color("9ac4d1") if geometry() else Color("d4bd91"),true,1.)
  line(root,left+Vector2(8,6),left+Vector2(8,121),Color("315a7a"),4.)
  line(root,right+Vector2(-7,64),right+Vector2(-7,83),Color("edf0eb"),3.)
  return root
 if id=="abertura-escada":
  stairwell_rail(room,root)
  return root
 if id=="tapete":
  var footprint:Dictionary=p.footprint;var f:Dictionary=room.data.layout.floor
  var x:float=f.x+footprint.u0*96;var y:float=f.y+footprint.v0*96;var w:float=(footprint.u1-footprint.u0)*96;var h:float=(footprint.v1-footprint.v0)*96
  rect(room,root,x,y,w,h,Color("e8e7dd"));rect(room,root,x+12,y+12,w-24,h-24,Color("507894"))
  rect(room,root,x+24,y+35,w-48,20,Color("aec4cb"),false)
  rect(room,root,x+24,y+h-55,w-48,20,Color("aec4cb"),false)
  return root
 if id=="porta":
  var slant:float=r.size.x*.5
  poly(root,PackedVector2Array([r.position+Vector2(0,slant),r.position+Vector2(r.size.x,0),r.end-Vector2(0,slant),r.position+Vector2(0,r.size.y)]),Color("e8e8df"),true,2.)
  var left:Vector2=r.position+Vector2(5,slant+2);var right:Vector2=r.position+Vector2(r.size.x-5,6)
  poly(root,PackedVector2Array([left,right,right+Vector2(0,r.size.y-slant-12),left+Vector2(0,r.size.y-slant-12)]),Color("234f77"),true,1.)
  line(root,right+Vector2(-10,55),right+Vector2(-10,90),Color("c9d6d9"),3.)
  return root
 if id=="escada":
  stairs_up(room,root)
  return root
 if id=="quadros":
  for i in 3:
   var at:=Vector2(r.position.x+i*24,r.position.y+i*12)
   poly(root,PackedVector2Array([at,at+Vector2(20,10),at+Vector2(20,39),at+Vector2(0,29)]),Color("f8edcf"),true,1.)
   line(root,at+Vector2(4,5),at+Vector2(16,11),Color("bd9d64"),3.)
   line(root,at+Vector2(7,15),at+Vector2(14,27),Color("4d7480"),1.)
   line(root,at+Vector2(14,27),at+Vector2(6,24),Color("4d7480"),1.)
  return root
 if geometry():
  if p.footprint is Dictionary:
   var footprint:Dictionary=p.footprint;var f:Dictionary=room.data.layout.floor
   var a:Vector2=room.project(Vector2(f.x+footprint.u0*96,f.y+footprint.v0*96));var b:Vector2=room.project(Vector2(f.x+footprint.u1*96,f.y+footprint.v0*96));var c:Vector2=room.project(Vector2(f.x+footprint.u1*96,f.y+footprint.v1*96));var d:Vector2=room.project(Vector2(f.x+footprint.u0*96,f.y+footprint.v1*96))
   var rise:=Vector2(0,-maxf(25,a.y-r.position.y));var lift:=Vector2(0,r.end.y-c.y)
   a+=lift;b+=lift;c+=lift;d+=lift
   poly(root,PackedVector2Array([b,c,c+rise,b+rise]),Color("4c6e81"));poly(root,PackedVector2Array([c,d,d+rise,c+rise]),Color("608698"));poly(root,PackedVector2Array([a+rise,b+rise,c+rise,d+rise]),Color("aac9ce"))
  else:poly(root,PackedVector2Array([r.position+Vector2(0,r.size.y*.4),r.position+Vector2(r.size.x,0),r.end-Vector2(0,r.size.y*.4),r.position+Vector2(0,r.size.y)]),Color("9ac4d1"))
  return root
 var asset:String=id
 if room.data.floorImage=="home-floor.png" and id!="janela":asset="home-banco" if id in ["banco-jantar","banco-fundo"] else "home-"+id
 var path:String=BASE+asset+".png"
 if not ResourceLoader.exists(path):return root
 var texture:Texture2D=load(path)
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"kit.json"))
 var spec:Dictionary=manifest.pieces[asset]
 var bounds:=Rect2(spec.bounds[0],spec.bounds[1],spec.bounds[2],spec.bounds[3])
 var sprite:=Sprite2D.new();sprite.name="Art";sprite.texture=texture;sprite.centered=false;sprite.region_enabled=true;sprite.region_rect=bounds
 var scale:float=minf(r.size.x/bounds.size.x,r.size.y/bounds.size.y)
 sprite.scale=Vector2.ONE*scale
 sprite.position=Vector2(r.position.x+(r.size.x-bounds.size.x*scale)*.5,r.end.y-bounds.size.y*scale)
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var cut:=ShaderMaterial.new();cut.shader=preload("res://shaders/industrial_cutout.gdshader");sprite.material=cut;root.add_child(sprite)
 return root

static func stairs_up(room,root:Node2D) -> void:
 var scale:float=room.camera.scale
 var back:Vector2=room.project(Vector2(1536,768));var front:Vector2=room.project(Vector2(1536,1056))
 var side:=PackedVector2Array([back,front])
 for k in range(7,-1,-1):
  var v:float=768+k*36;var h:float=(8-k)*20*scale
  side.append(room.project(Vector2(1536,v+36))-Vector2(0,h))
  side.append(room.project(Vector2(1536,v))-Vector2(0,h))
 poly(root,side,Color("a9b7bb"),true,2.)
 for k in 8:
  var v:float=768+k*36;var h:float=(8-k)*20*scale
  var a:Vector2=room.project(Vector2(1344,v))-Vector2(0,h);var b:Vector2=room.project(Vector2(1536,v))-Vector2(0,h)
  var c:Vector2=room.project(Vector2(1536,v+36))-Vector2(0,h);var d:Vector2=room.project(Vector2(1344,v+36))-Vector2(0,h)
  poly(root,PackedVector2Array([a,b,c,d]),Color("dacdb0"),true,1.)
  poly(root,PackedVector2Array([d,c,c+Vector2(0,20*scale),d+Vector2(0,20*scale)]),Color("e9ece5"),true,1.)
 for u in [1344,1536]:
  var tops:Array[Vector2]=[]
  for v in [804,912,1020]:
   var h:float=(1056-v)/288.*160*scale
   var base:Vector2=room.project(Vector2(u,v))-Vector2(0,h)
   line(root,base,base-Vector2(0,34*scale),Color("315a7a"),3.)
   tops.append(base-Vector2(0,34*scale))
  line(root,tops[0],tops[2],Color("315a7a"),4.)

static func stairs_down(room,root:Node2D) -> void:
 var scale:float=room.camera.scale
 var a:Vector2=room.project(Vector2(384,864));var b:Vector2=room.project(Vector2(672,864));var c:Vector2=room.project(Vector2(672,1056));var d:Vector2=room.project(Vector2(384,1056))
 var hole:=PackedVector2Array([a,b,c,d])
 poly(root,hole,Color("172b3a"),true,2.)
 # Recessed white stringers establish a real opening; each tread is clipped to it.
 # Clip the inner walls too: no face or tread may escape the floor cut.
 for edge in [PackedVector2Array([a,d,d+Vector2(0,70*scale),a+Vector2(0,70*scale)]),PackedVector2Array([b,c,c+Vector2(0,70*scale),b+Vector2(0,70*scale)])]:
  for clipped in Geometry2D.intersect_polygons(edge,hole):poly(root,clipped,Color("8498a1"),false)
 for k in range(7,-1,-1):
  var v:float=864+k*24;var drop:=Vector2(0,k*8*scale)
  var pa:Vector2=room.project(Vector2(400,v))+drop;var pb:Vector2=room.project(Vector2(656,v))+drop
  var pc:Vector2=room.project(Vector2(656,v+24))+drop;var pd:Vector2=room.project(Vector2(400,v+24))+drop
  for tread in Geometry2D.intersect_polygons(PackedVector2Array([pa,pb,pc,pd]),hole):poly(root,tread,Color(.83-k*.042,.80-k*.041,.71-k*.039),true,.9)
  for riser in Geometry2D.intersect_polygons(PackedVector2Array([pd,pc,pc+Vector2(0,8*scale),pd+Vector2(0,8*scale)]),hole):poly(root,riser,Color(.77-k*.045,.80-k*.043,.78-k*.04),true,.8)
 line(root,a,b,Color("e9e8df"),5.)
 line(root,b,c,Color("e9e8df"),5.)
 line(root,d,c,Color("315a7a"),5.)

static func stairwell_rail(room,root:Node2D) -> void:
 var scale:float=room.camera.scale
 var tops:Array[Vector2]=[]
 for v in [900,978,1056]:
  var base:Vector2=room.project(Vector2(672,v))
  line(root,base,base-Vector2(0,38*scale),Color("315a7a"),3.)
  tops.append(base-Vector2(0,38*scale))
 line(root,tops[0],tops[2],Color("315a7a"),4.)
 line(root,tops[0]+Vector2(0,19*scale),tops[2]+Vector2(0,19*scale),Color("6d92a6"),2.)

