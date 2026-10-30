extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
static var textures:Dictionary={}
static func texture(file:String) -> Texture2D:
 if textures.has(file):return textures[file]
 var image:=Image.load_from_file(ProjectSettings.globalize_path(file))
 if image==null or image.is_empty():return null
 var result:=ImageTexture.create_from_image(image)
 textures[file]=result
 return result
static func build(view) -> void:
 var model=view.model
 var simple:=S.geometry()
 # Boundary architecture is a continuous wall, not props hiding terrain seams.
 for v in int(model.data.h):
  for u in int(model.data.w):
   var c:Dictionary=model.cell_at(Vector2i(u,v))
   if c.material=="rocha":block(view,Vector2(u,v),1,1,36,"barreira",simple)
 for b:Dictionary in model.data.forest.get("buildings",[]):
  block(view,Vector2(b.u,b.v),float(b.w),float(b.h),float(b.z),str(b.style),simple)
static func block(view,at:Vector2,w:float,h:float,z:float,style:String,simple:bool) -> void:
 var model=view.model
 var level:float=model.height_at(at+Vector2(.5,.5))*64
 var root:=Node2D.new();root.set_meta("scenery",true)
 root.position=S.iso(at+Vector2(w,h));view.actors.add_child(root)
 var a:=S.iso(at,level)-root.position
 var b:=S.iso(at+Vector2(w,0),level)-root.position
 var c:=S.iso(at+Vector2(w,h),level)-root.position
 var d:=S.iso(at+Vector2(0,h),level)-root.position
 var lift:=Vector2(0,z)
 if style=="caldeira" and not simple:
  var art:=Sprite2D.new();art.name="Art"
  art.texture=texture("res://assets/overworld/kits/industrial-v1/pecas/caldeiras.png")
  art.centered=false;art.scale=Vector2.ONE*.23
  art.position=S.iso(at+Vector2(w*.5,h*.5),level)-root.position-Vector2(768,850)*.23
  var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cutout
  root.add_child(art);view.occluders.append(root)
  return
 var face_color:=Color("bc8763") if style in ["galpao","usina"] else Color("397c86") if style=="container" else Color("6d7f7e")
 if simple:face_color=Color("7b9297")
 var metal:Texture2D=null
 var file:="res://assets/overworld/kits/industrial-v1/superficies/metal-azul.png"
 if not simple and style!="barreira":metal=texture(file)
 for points in [PackedVector2Array([d-lift,c-lift,c,d]),PackedVector2Array([c-lift,b-lift,b,c])]:
  var wall:=S.quad(root,points,face_color if points[0]==d-lift else face_color.darkened(.22))
  if metal and style=="container":
   wall.texture=metal;wall.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
   wall.uv=PackedVector2Array([Vector2(0,0),Vector2(w*56,0),Vector2(w*56,z*3),Vector2(0,z*3)])
   wall.color=Color.WHITE if points[0]==d-lift else Color("b0c1c2")
  if style!="barreira":S.line(root,PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),1.5,Color("374b50"))
 var top:=S.quad(root,PackedVector2Array([a-lift,b-lift,c-lift,d-lift]),Color("91a8a7") if simple else Color.WHITE,metal)
 if metal:
  top.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
  top.uv=PackedVector2Array([Vector2(0,0),Vector2(w*56,0),Vector2(w*56,h*56),Vector2(0,h*56)])
 else:top.color=face_color.lightened(.18)
 if style!="barreira":S.line(root,PackedVector2Array([a-lift,b-lift,c-lift,d-lift,a-lift]),2,Color("34464d"))
 if simple:return
 if style in ["galpao","usina"]:
  # Brick courses follow measured wall edges; no baked perspective in the art.
  for y in range(16,int(z),16):
   S.line(root,PackedVector2Array([d-Vector2(0,y),c-Vector2(0,y),b-Vector2(0,y)]),1,Color("815f4d",.5))
   for k in range(1,int(w*2)):
    var t:=float(k)/(w*2);var p:=d.lerp(c,t)
    S.line(root,PackedVector2Array([p-Vector2(0,y),p-Vector2(0,minf(y+8,z))]),1,Color("815f4d",.35))
  # A measured loading shutter belongs to the front wall, with no extra collision.
  var left:=d.lerp(c,.3);var right:=d.lerp(c,.7)
  S.quad(root,PackedVector2Array([left-Vector2(0,z*.66),right-Vector2(0,z*.66),right,left]),Color("375a65"))
  for t in [.2,.4,.6]:S.line(root,PackedVector2Array([left-Vector2(0,z*.66*t),right-Vector2(0,z*.66*t)]),2,Color("799c9d"))
  for t in [.15,.8]:
   var p:=b.lerp(c,t)-Vector2(0,z*.7)
   S.quad(root,PackedVector2Array([p,p+Vector2(-18,-9),p+Vector2(-18,15),p+Vector2(0,24)]),Color("a4d3d0"))
  for k in range(0,int(w*2)):
   var p:=d.lerp(c,float(k)/(w*2))
   var q:=d.lerp(c,float(k+1)/(w*2))
   S.quad(root,PackedVector2Array([p,q,q-Vector2(0,7),p-Vector2(0,7)]),Color("e4bc51") if k%2==0 else Color("39474e"))
 if style=="container":
  for k in range(1,int(w*4)):
   var p:=d.lerp(c,float(k)/(w*4));S.line(root,PackedVector2Array([p-Vector2(0,z-4),p-Vector2(0,4)]),2,Color("203f4a",.65))
 if style=="caldeira":
  S.line(root,PackedVector2Array([(b+c)*.5-lift,(b+c)*.5-Vector2(0,z+28)]),15,Color("b5b6a0"))
 if style=="usina":
  var p:=S.iso(at+Vector2(2,2),level)-root.position
  S.quad(root,PackedVector2Array([p-Vector2(12,z),p+Vector2(12,-z),p+Vector2(12,-z-140),p-Vector2(12,z+140)]),Color("98674e"))
  for k in 6:S.line(root,PackedVector2Array([p+Vector2(-12,-z-20-k*20),p+Vector2(12,-z-20-k*20)]),2,Color("c29671"))
