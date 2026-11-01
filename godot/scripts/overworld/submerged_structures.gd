extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
const Assets=preload("res://scripts/overworld/industrial_structures.gd")
const BASE="res://assets/overworld/kits/submerso-v2/pecas/"
static func mask(model) -> Texture2D:
 var im:=Image.create(int(model.data.w),int(model.data.h),false,Image.FORMAT_RGBA8)
 for v in int(model.data.h):
  for u in int(model.data.w):im.set_pixel(u,v,Color(1 if model.cell_at(Vector2i(u,v)).material=="piso" else 0,0,0,1))
 return ImageTexture.create_from_image(im)
static func build(view) -> void:
 var bg:=Polygon2D.new();bg.polygon=PackedVector2Array([Vector2(-10000,-10000),Vector2(10000,-10000),Vector2(10000,10000),Vector2(-10000,10000)]);bg.color=Color("03121c");bg.z_index=-100;view.actors.add_child(bg)
 if S.geometry():
  for p:Dictionary in view.model.data.pieces:Assets.block(view,Vector2(p.u,p.v),p.fu,p.fv,45 if p.asset=="submerso-marker" else 130,"barreira",true)
  return
 var tint:=CanvasModulate.new();tint.color=Color(.80,.94,1.0);view.actors.add_child(tint)
 for p:Dictionary in view.model.data.pieces:
  if p.asset=="submerso-prop":prop(view,p)
  elif p.asset=="submerso-marker":beacon(view,p)
 details(view)
 var ambience:=preload("res://scripts/overworld/submerged_ambience.gd").new();ambience.model=view.model;view.actors.add_child(ambience)
static func prop(view,p:Dictionary) -> void:
 var kind:String=str(p.props.get("variante","rocha"))
 var path:String="res://assets/overworld/kits/cavernas-v3/props/rocha-solta.png" if kind=="rocha" else BASE+kind+".png"
 if not FileAccess.file_exists(path):return
 var texture:=Assets.texture(path)
 if texture==null:return
 var at:=Vector2(p.u+p.fu*.5,p.v+p.fv*.5);var height:float=view.model.height_at(at)*64
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(at,false);view.actors.add_child(root)
 var scale:float=175.0/texture.get_height() if kind=="alga" else (340.0 if kind=="colonia" and p.fu>=4 else 270.0 if kind=="colonia" else 180.0 if kind=="rocha" else 190.0)/texture.get_width()
 if kind=="espirao":scale=330.0/texture.get_height()
 scale*=float(p.props.get("escala",1.0))
 var shadow:=Polygon2D.new();var points:=PackedVector2Array()
 for k in 20:points.append(Vector2(cos(TAU*k/20.0)*p.fu*15,sin(TAU*k/20.0)*p.fv*7)-Vector2(0,height))
 shadow.polygon=points;shadow.color=Color(.02,.09,.18,.30);root.add_child(shadow)
 var art:=Sprite2D.new();art.name="Art";art.texture=texture;art.centered=false;art.flip_h=bool(p.props.get("espelho",false));art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;art.scale=Vector2.ONE*scale
 var anchor:float=.94 if kind=="alga" else .87
 art.position=-Vector2(texture.get_width()*.5,texture.get_height()*anchor)*scale-Vector2(0,height)
 if kind=="rocha":art.modulate=Color(.46,.72,.78)
 var cut:=ShaderMaterial.new();cut.shader=preload("res://shaders/submerged_sprite.gdshader");cut.set_shader_parameter("sway",9.0 if kind=="alga" else 0.0);cut.set_shader_parameter("phase",float(p.u)*.7+p.v);cut.set_shader_parameter("still",OS.get_environment("SUBMERSO_CAPTURE")=="1");art.material=cut
 root.add_child(art);view.occluders.append(root)
static func beacon(view,p:Dictionary) -> void:
 var at:=Vector2(p.u+.5,p.v+.5);var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(at,false);view.actors.add_child(root)
 var shape:=Node2D.new();shape.position=Vector2(0,-view.model.height_at(at)*64);root.add_child(shape)
 var rock:=Polygon2D.new();rock.polygon=PackedVector2Array([Vector2(-12,0),Vector2(-8,-10),Vector2(4,-14),Vector2(12,-5),Vector2(7,3)]);rock.color=Color("315467");shape.add_child(rock)
 for k in 3:
  var stem:=Line2D.new();stem.points=PackedVector2Array([Vector2(k*6-6,-5),Vector2(k*6-6,-25-k*5)]);stem.default_color=Color("3d998f");stem.width=3;shape.add_child(stem)
  var polyp:=Polygon2D.new();var top:=Vector2(k*6-6,-25-k*5);polyp.polygon=PackedVector2Array([top+Vector2(0,-5),top+Vector2(4,0),top+Vector2(0,5),top+Vector2(-4,0)]);polyp.color=Color("f1ca78");shape.add_child(polyp)

static func details(view) -> void:
 for v in range(6,int(view.model.data.h)-4,4):
  for u in range(6,int(view.model.data.w)-4,4):
   var c:Dictionary=view.model.cell_at(Vector2i(u,v))
   if int(c.level)<0 or c.ramp!=null or c.material not in ["grama","piso"]:continue
   var clear:=true
   for delta in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
    var other:Dictionary=view.model.cell_at(Vector2i(u,v)+delta)
    if other.ramp!=null or other.level!=c.level:clear=false
   if not clear:continue
   var root:=Node2D.new();root.set_meta("scenery",true);root.position=view.model.project(Vector2(u+.5,v+.5),false);view.actors.add_child(root)
   for k in 2:
    var pos:=Vector2(k*13-6,-float(c.level)*64+k*4)
    var pebble:=Polygon2D.new();pebble.polygon=PackedVector2Array([pos+Vector2(-4,0),pos+Vector2(-2,-4),pos+Vector2(3,-3),pos+Vector2(5,0),pos+Vector2(1,2)]);pebble.color=Color("4d8d95") if (u+v+k)%3 else Color("a1c8bd");root.add_child(pebble)
