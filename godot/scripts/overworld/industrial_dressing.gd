extends RefCounted
## Native 2D inked details: footprints and depth come from the same map as collision.
const S=preload("res://scripts/overworld/forest_structures.gd")
const INK=Color("30494f")
static func panel(root,points:Array,color:Color) -> void:
 var p:=PackedVector2Array(points)
 S.quad(root,p,color)
 p.append(p[0]);S.line(root,p,1.8,INK)
static func cargo(root,a:Vector2,b:Vector2,c:Vector2,d:Vector2,z:float,style:String,simple:bool) -> void:
 var lift:=Vector2(0,z)
 if simple:
  panel(root,[d-lift,c-lift,c,d],Color("7b9297"));panel(root,[c-lift,b-lift,b,c],Color("60747a"));panel(root,[a-lift,b-lift,c-lift,d-lift],Color("a3b5b5"));return
 if style in ["tambor","carretel"]:
  for t in [.28,.72]:
   var center:Vector2=d.lerp(b,t).lerp((a+c)*.5,.35)
   cylinder(root,center,z,18 if style=="tambor" else 24,style)
  return
 if style=="carga":
  for y in 2:
   for x in 2:
    var t0:=x*.5;var t1:=(x+1)*.5
    var a0:=a.lerp(b,t0).lerp(d.lerp(c,t0),y*.5)
    var b0:=a.lerp(b,t1).lerp(d.lerp(c,t1),y*.5)
    var c0:=a.lerp(b,t1).lerp(d.lerp(c,t1),(y+1)*.5)
    var d0:=a.lerp(b,t0).lerp(d.lerp(c,t0),(y+1)*.5)
    cargo(root,a0,b0,c0,d0,z+12 if x==0 and y==0 else z*.7,"caixa",false)
  return
 # Pallet, straps and braced planks stay inside the declared blocking rectangle.
 var color:=Color("c99862")
 panel(root,[d-Vector2(0,7),c-Vector2(0,7),c,d],Color("805d48"))
 panel(root,[c-Vector2(0,7),b-Vector2(0,7),b,c],Color("614c40"))
 panel(root,[d-lift,c-lift,c-Vector2(0,7),d-Vector2(0,7)],color)
 panel(root,[c-lift,b-lift,b-Vector2(0,7),c-Vector2(0,7)],color.darkened(.2))
 panel(root,[a-lift,b-lift,c-lift,d-lift],color.lightened(.2))
 for t in [.25,.5,.75]:
  var p:=d.lerp(c,t);var q:=a.lerp(b,t)
  S.line(root,PackedVector2Array([p-Vector2(0,7),p-lift,q-lift]),3,Color("65594b"))
 if style=="caixa":
  S.line(root,PackedVector2Array([d-Vector2(0,9),c-lift]),4,Color("e5c28b"))
  S.line(root,PackedVector2Array([d-lift,c-Vector2(0,9)]),4,Color("e5c28b"))
 else:
  for t in [.3,.7]:S.line(root,PackedVector2Array([d-Vector2(0,z*t),c-Vector2(0,z*t),b-Vector2(0,z*t)]),4,Color("e5cd95"))
 # Shipping label is pictographic: no fake generated lettering.
 var p:=d.lerp(c,.6)-Vector2(0,z*.65)
 panel(root,[p,p+Vector2(13,6.5),p+Vector2(13,16.5),p+Vector2(0,10)],Color("f0dfb6"))
static func cylinder(root,p:Vector2,z:float,r:float,style:String) -> void:
 var color:=Color("c56f4c") if style=="tambor" else Color("ae8658")
 panel(root,[p+Vector2(-r,0),p+Vector2(r,0),p+Vector2(r,-z),p+Vector2(-r,-z)],color)
 for y in [0.0,z]:
  var ellipse:Array=[]
  for n in 25:
   var angle:=TAU*n/24.0
   ellipse.append(p+Vector2(cos(angle)*r,sin(angle)*r*.5-y))
  panel(root,ellipse,color.lightened(.2) if y>0 else color)
 for y in [z*.25,z*.75]:
  var arc:=PackedVector2Array()
  for n in 13:
   var angle:=PI*n/12.0
   arc.append(p+Vector2(cos(angle)*r,sin(angle)*r*.5-y))
  S.line(root,arc,3,Color("e1b373"))
 if style=="carretel":
  var center:=p-Vector2(0,z)
  S.line(root,PackedVector2Array([center-Vector2(7,0),center+Vector2(7,0)]),4,INK)
static func building(root,a:Vector2,b:Vector2,c:Vector2,d:Vector2,z:float,style:String) -> void:
 if style not in ["galpao","container"]:return
 var lift:=Vector2(0,z)
 # Long roof seams and broad highlight bands, rather than photographic rust.
 for t in [.2,.4,.6,.8]:
  S.line(root,PackedVector2Array([a.lerp(d,t)-lift,b.lerp(c,t)-lift]),2,Color("49676d"))
 S.line(root,PackedVector2Array([a-lift,b-lift]),3,Color("d8ddd0"))
 if style=="container":
  var middle:=b.lerp(c,.5)
  S.line(root,PackedVector2Array([middle-lift,middle]),2,INK)
  for t in [.25,.75]:
   var p:=b.lerp(c,t)
   S.line(root,PackedVector2Array([p-Vector2(0,z-5),p-Vector2(0,5)]),3,Color("f1cf86"))
  return
 # Roof equipment is above an existing blocked building, never over a path.
 var p:=a.lerp(c,.42)-lift
 panel(root,[p+Vector2(-22,0),p+Vector2(0,-11),p+Vector2(26,2),p+Vector2(4,13)],Color("66888b"))
 panel(root,[p+Vector2(-22,0),p+Vector2(4,13),p+Vector2(4,25),p+Vector2(-22,12)],Color("49636a"))
 panel(root,[p+Vector2(4,13),p+Vector2(26,2),p+Vector2(26,14),p+Vector2(4,25)],Color("3b555e"))
 # The illustrated facade already owns its canopy, emblem and downpipe.
 return
static func yard(view) -> void:
 # Flat markings have no blocking silhouette and retain every junction's visibility.
 var model=view.model
 for u in [6,10,14,18]:
  var p:=Vector2(u,18)
  var root:=decal(view,p)
  var h:float=model.height_at(p)*64+.2
  S.line(root,PackedVector2Array([S.iso(p,h),S.iso(p+Vector2(2,0),h),S.iso(p+Vector2(2,2),h)]),2.5,Color("e8c878"))
 for v in [10,14,18,22,26]:
  var p:=Vector2(35,v)
  var root:=decal(view,p)
  S.line(root,PackedVector2Array([S.iso(p,.2),S.iso(p+Vector2(0,1.3),.2)]),3,Color("d6bd7e"))
 # Drain covers and expansion joints lie flush, never pretend to be holes.
 for at in [Vector2(20,20),Vector2(28,27),Vector2(39,32)]:
  var root:=decal(view,at)
  var h:float=model.height_at(at)*64+.2
  var points:=[S.iso(at,h),S.iso(at+Vector2(1,0),h),S.iso(at+Vector2(1,1),h),S.iso(at+Vector2(0,1),h)]
  panel(root,points,Color("748280"))
  for t in [.2,.4,.6,.8]:S.line(root,PackedVector2Array([points[0].lerp(points[1],t),points[3].lerp(points[2],t)]),1,INK)
static func decal(view,at:Vector2) -> Node2D:
 var anchor:=Node2D.new();anchor.position=S.iso(at+Vector2(2,2))+Vector2(0,3);view.actors.add_child(anchor)
 var canvas:=Node2D.new();canvas.position=-anchor.position;anchor.add_child(canvas)
 return canvas

