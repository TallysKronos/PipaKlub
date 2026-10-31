extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
const Assets=preload("res://scripts/overworld/industrial_structures.gd")
const BASE="res://assets/overworld/kits/mina-ferro-v1/pecas/"
static func mask(model) -> Texture2D:
 var im:=Image.create(int(model.data.w),int(model.data.h),false,Image.FORMAT_RGBA8)
 for v in int(model.data.h):
  for u in int(model.data.w):im.set_pixel(u,v,Color(1 if model.cell_at(Vector2i(u,v)).material=="rocha" else 0,0,0,1))
 return ImageTexture.create_from_image(im)
static func build(view) -> void:
 var bg:=Polygon2D.new();bg.polygon=PackedVector2Array([Vector2(-10000,-10000),Vector2(10000,-10000),Vector2(10000,10000),Vector2(-10000,10000)]);bg.color=Color.BLACK;bg.z_index=-100;view.actors.add_child(bg)
 if S.geometry():
  for piece:Dictionary in view.model.data.pieces:
   if str(piece.asset).begins_with("mina-"):Assets.block(view,Vector2(piece.u,piece.v),piece.fu,piece.fv,128 if piece.asset=="mina-suporte" else 65,"barreira",true)
  return
 for route:Array in view.model.data.forest.rails:track(view,route)
 for frame:Dictionary in view.model.data.forest.frames:portal(view,frame)
 for piece:Dictionary in view.model.data.pieces:
  if piece.asset=="mina-prop":prop(view,piece)
  if piece.asset=="mina-cave":cave_prop(view,piece)
static func line(root:Node2D,a:Vector2,b:Vector2,color:Color,width:float) -> void:
 var l:=Line2D.new();l.points=PackedVector2Array([a,b]);l.default_color=color;l.width=width;l.antialiased=true;root.add_child(l)
static func curved(route:Array) -> Array:
 var result:Array=[]
 for n in route.size():
  var p:=Vector2(route[n][0]+.5,route[n][1]+.5)
  if n==0 or n==route.size()-1:result.append(p);continue
  var prev:=Vector2(route[n-1][0]+.5,route[n-1][1]+.5);var next:=Vector2(route[n+1][0]+.5,route[n+1][1]+.5)
  var before:Vector2=p-(p-prev).normalized()*minf(.8,p.distance_to(prev)*.4)
  var after:Vector2=p+(next-p).normalized()*minf(.8,p.distance_to(next)*.4)
  result.append(before)
  for k in range(1,7):
   var t:float=k/6.0;result.append(before*(1-t)*(1-t)+p*2*t*(1-t)+after*t*t)
 return result
static func track(view,route:Array) -> void:
 var points:Array=curved(route)
 for n in range(1,points.size()):
  var a:Vector2=points[n-1];var b:Vector2=points[n]
  var d:Vector2=(b-a).normalized();var side:=Vector2(-d.y,d.x);var steps:int=ceili(a.distance_to(b)*2)
  for i in steps:
   var p:Vector2=a.lerp(b,float(i)/steps);var q:Vector2=a.lerp(b,float(i+1)/steps);var mid:Vector2=(p+q)*.5
   var root:=Node2D.new();root.position=view.model.project(mid,false);view.actors.add_child(root)
   var tie_a:Vector2=view.model.project(mid-side*.7)-root.position;var tie_b:Vector2=view.model.project(mid+side*.7)-root.position
   line(root,tie_a+Vector2(0,2),tie_b+Vector2(0,2),Color("10121b"),9)
   line(root,tie_a,tie_b,Color("69482d"),6);line(root,tie_a-Vector2(0,1),tie_b-Vector2(0,1),Color("ad8252"),1)
   for sign in [-1,1]:
    var start:Vector2=view.model.project(p+side*.40*sign)-root.position
    var end:Vector2=view.model.project(q+side*.40*sign)-root.position
    line(root,start+Vector2(0,2),end+Vector2(0,2),Color("121722"),6)
    line(root,start,end,Color("777f86"),3.5);line(root,start-Vector2(0,.7),end-Vector2(0,.7),Color("b8bbad"),1)
static func portal(view,f:Dictionary) -> void:
 var at:=Vector2(f.u+.5,f.v+.5);var side:=Vector2(1,0) if f.axis=="v" else Vector2(0,1)
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(at,false);view.actors.add_child(root)
 var a:Vector2=view.model.project(at-side*2)-root.position;var b:Vector2=view.model.project(at+side*2)-root.position
 var ta:=a-Vector2(0,132);var tb:=b-Vector2(0,132)
 for pair:Array in [[a,ta],[b,tb],[ta,tb]]:
  line(root,pair[0],pair[1],Color("111620"),17);line(root,pair[0],pair[1],Color("6c472e"),12);line(root,pair[0]-Vector2(2,1),pair[1]-Vector2(2,1),Color("af8250"),3)
 line(root,a-Vector2(0,75),ta.lerp(tb,.2),Color("111620"),11);line(root,a-Vector2(0,75),ta.lerp(tb,.2),Color("8b633e"),7)
 line(root,b-Vector2(0,75),tb.lerp(ta,.2),Color("111620"),11);line(root,b-Vector2(0,75),tb.lerp(ta,.2),Color("8b633e"),7)
 lantern(root,(ta+tb)*.5+Vector2(0,19),(a+b)*.5)
static func lantern(root:Node2D,p:Vector2,floor_point:Vector2) -> void:
 for k in range(4,0,-1):
  var pool:=Polygon2D.new();var points:=PackedVector2Array()
  for i in 24:points.append(floor_point+Vector2(cos(TAU*i/24.0)*k*17,sin(TAU*i/24.0)*k*8))
  pool.polygon=points;pool.color=Color(1,.62,.22,.018);root.add_child(pool)
 line(root,p-Vector2(0,17),p-Vector2(0,8),Color("222a35"),3)
 var cage:=Polygon2D.new();cage.polygon=PackedVector2Array([p+Vector2(-8,-8),p+Vector2(8,-8),p+Vector2(7,11),p+Vector2(-7,11)]);cage.color=Color("1a202c");root.add_child(cage)
 var fire:=Polygon2D.new();fire.polygon=PackedVector2Array([p+Vector2(-4,-4),p+Vector2(4,-4),p+Vector2(3,7),p+Vector2(-3,7)]);fire.color=Color("ffd181");root.add_child(fire)
 line(root,p+Vector2(0,-6),p+Vector2(0,9),Color("866139"),1.5)
static func prop(view,p:Dictionary) -> void:
 var kind:String=str(p.props.get("variante","estoque"));var texture:=Assets.texture(BASE+kind+".png")
 if texture==null:return
 var at:=Vector2(p.u+p.fu*.5,p.v+p.fv*.5);var level:float=view.model.height_at(at)
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(at,false);view.actors.add_child(root)
 var art:=Sprite2D.new();art.name="Art";art.texture=texture;art.centered=false;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var width:float=340 if kind=="veio" and p.fu>=4 else 230 if kind in ["veio","guincho"] else 155 if kind=="estoque" else 140 if kind=="ferramentas" else 180
 var scale:float=width/texture.get_width()
 var shadow:=Polygon2D.new();var shadow_points:=PackedVector2Array()
 for k in 20:shadow_points.append(Vector2(cos(TAU*k/20.0)*width*.22,sin(TAU*k/20.0)*width*.075+4)-Vector2(0,level*64))
 shadow.polygon=shadow_points;shadow.color=Color(0,0,0,.25);root.add_child(shadow)
 var anchor_y:float=.80 if kind=="cheio" else .84 if kind=="vazio" else .805 if kind=="veio" else .86 if kind=="estoque" else .91
 var flip:float=-1 if kind in ["cheio","vazio"] else 1
 art.scale=Vector2(scale*flip,scale);art.position=-Vector2(texture.get_width()*.5*flip,texture.get_height()*anchor_y)*scale-Vector2(0,level*64)
 var cut:=ShaderMaterial.new();cut.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cut;root.add_child(art);view.occluders.append(root)
static func cave_prop(view,p:Dictionary) -> void:
 var kind:String=str(p.props.get("variante","rocha-solta"));var scene:PackedScene=load("res://scenes/overworld/caves-v3/props/"+kind+".tscn")
 if scene==null:return
 var at:=Vector2(p.u+.5,p.v+.5);var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(at,false);view.actors.add_child(root)
 var instance:Node2D=scene.instantiate();instance.position=Vector2(0,-view.model.height_at(at)*64);root.add_child(instance)
