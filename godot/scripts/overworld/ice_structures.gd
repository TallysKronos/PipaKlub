extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
const Assets=preload("res://scripts/overworld/industrial_structures.gd")
const BASE="res://assets/overworld/kits/gelo-v1/pecas/"
static func mask(model) -> Texture2D:
 var im:=Image.create(int(model.data.w),int(model.data.h),false,Image.FORMAT_RGBA8)
 for v in int(model.data.h):
  for u in int(model.data.w):im.set_pixel(u,v,Color(1 if model.cell_at(Vector2i(u,v)).material=="piso" else 0,0,0,1))
 return ImageTexture.create_from_image(im)
static func build(view) -> void:
 var bg:=Polygon2D.new();bg.polygon=PackedVector2Array([Vector2(-10000,-10000),Vector2(10000,-10000),Vector2(10000,10000),Vector2(-10000,10000)]);bg.color=Color.BLACK;bg.z_index=-100;view.actors.add_child(bg)
 if S.geometry():
  for p:Dictionary in view.model.data.pieces:Assets.block(view,Vector2(p.u,p.v),p.fu,p.fv,60 if p.asset=="gelo-marker" else 150,"barreira",true)
  return
 for p:Dictionary in view.model.data.pieces:
  if p.asset=="gelo-prop":prop(view,p)
  if p.asset=="gelo-marker":marker(view,p)
 footprints(view)
 if view.model.data.forest.part=="B":lake_cracks(view)
static func line(root:Node2D,a:Vector2,b:Vector2,color:Color,width:float) -> void:
 var l:=Line2D.new();l.points=PackedVector2Array([a,b]);l.default_color=color;l.width=width;l.antialiased=true;root.add_child(l)
static func prop(view,p:Dictionary) -> void:
 var kind:String=str(p.props.get("variante","rocha"));var texture:=Assets.texture(BASE+kind+".png")
 if texture==null:return
 var at:=Vector2(p.u+p.fu*.5,p.v+p.fv*.5);var height:float=view.model.height_at(at)*64
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(at,false);view.actors.add_child(root)
 var scale:float=240.0/texture.get_height() if kind=="pinheiro" else (360.0 if kind=="formacao" and p.fu>=4 else 255.0 if kind=="formacao" else 250.0 if kind=="abrigo" else 190.0)/texture.get_width()
 var shadow:=Polygon2D.new();var points:=PackedVector2Array()
 for k in 20:points.append(Vector2(cos(TAU*k/20.0)*p.fu*15,sin(TAU*k/20.0)*p.fv*7)-Vector2(0,height))
 shadow.polygon=points;shadow.color=Color(.12,.29,.48,.20);root.add_child(shadow)
 var art:=Sprite2D.new();art.name="Art";art.texture=texture;art.centered=false;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;art.scale=Vector2.ONE*scale
 var anchor:float=.95 if kind=="pinheiro" else .87
 art.position=-Vector2(texture.get_width()*.5,texture.get_height()*anchor)*scale-Vector2(0,height)
 var cut:=ShaderMaterial.new();cut.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cut;root.add_child(art);view.occluders.append(root)
static func marker(view,p:Dictionary) -> void:
 var at:=Vector2(p.u+.5,p.v+.5);var height:float=view.model.height_at(at)*64
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(at,false);view.actors.add_child(root)
 var base:=Vector2(0,-height)
 line(root,base,base-Vector2(0,59),Color("20364b"),7);line(root,base-Vector2(1,1),base-Vector2(1,58),Color("8a6950"),4)
 var flag:=Polygon2D.new();flag.polygon=PackedVector2Array([base+Vector2(0,-55),base+Vector2(21,-48),base+Vector2(15,-42),base+Vector2(0,-45)]);flag.color=Color("386fba");root.add_child(flag)
 line(root,base+Vector2(0,-55),base+Vector2(21,-48),Color("b6dbf0"),1.5)
static func footprints(view) -> void:
 for route:Array in view.model.data.forest.trails:
  for n in range(1,route.size()):
   var a:=Vector2(route[n-1][0]+.5,route[n-1][1]+.5);var b:=Vector2(route[n][0]+.5,route[n][1]+.5);var count:int=floori(a.distance_to(b)/2.5)
   for i in count:
    var at:Vector2=a.lerp(b,float(i+1)/(count+1))
    var cell:Dictionary=view.model.cell_at(Vector2i(at.floor()))
    if cell.get("material")!="terra":continue
    var root:=Node2D.new();root.position=view.model.project(at,false);view.actors.add_child(root)
    for side in [-1,1]:
     var mark:=Polygon2D.new();var points:=PackedVector2Array()
     for k in 8:points.append(Vector2(cos(TAU*k/8.0)*2.7+side*3.5,sin(TAU*k/8.0)*1.4+side*2.5)-Vector2(0,view.model.height_at(at)*64))
     mark.polygon=points;mark.color=Color(.35,.56,.74,.35);root.add_child(mark)
static func lake_cracks(view) -> void:
 for branch:Array in [[[15,28],[19,29],[22,27],[26,28],[28,30]],[[19,29],[18,31],[21,32]],[[22,27],[23,25]],[[26,28],[27,26]]]:
  for n in range(1,branch.size()):
   var a:=Vector2(branch[n-1][0]+.5,branch[n-1][1]+.5);var b:=Vector2(branch[n][0]+.5,branch[n][1]+.5)
   var root:=Node2D.new();root.position=view.model.project((a+b)*.5,false);view.actors.add_child(root)
   line(root,view.model.project(a)-root.position,view.model.project(b)-root.position,Color(.08,.32,.54,.5),2)
   line(root,view.model.project(a)-root.position-Vector2(0,1),view.model.project(b)-root.position-Vector2(0,1),Color(.83,.96,1.,.6),.8)
