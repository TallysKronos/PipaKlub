extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
const Assets=preload("res://scripts/overworld/industrial_structures.gd")
static func build(view) -> void:
 var sky:=Polygon2D.new();sky.polygon=PackedVector2Array([Vector2(-10000,-10000),Vector2(10000,-10000),Vector2(10000,10000),Vector2(-10000,10000)]);sky.color=Color("9ab9c2");sky.z_index=-100;view.actors.add_child(sky)
 if not S.geometry():
  panorama(view)
  field(view)
 for piece:Dictionary in view.model.data.pieces:
  if piece.asset!="montanha-crista":continue
  if S.geometry():Assets.block(view,Vector2(piece.u,piece.v),piece.fu,piece.fv,110,"barreira",true);continue
  var at:=Vector2(piece.u+piece.fu*.5,piece.v+piece.fv*.5)
  var texture:=Assets.texture("res://assets/overworld/kits/montanha-v1/pecas/crista.png")
  if texture==null:continue
  var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
  var sprite:=Sprite2D.new();sprite.name="Art";sprite.centered=false;sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  var scale:float=.23+float(view.model.data.forest.baseLevel)*.035
  sprite.scale=Vector2.ONE*scale;sprite.position=-Vector2(texture.get_width()*.5,texture.get_height()*.94)*scale-Vector2(0,view.model.height_at(at)*64)
  var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");sprite.material=cutout
  root.add_child(sprite);view.occluders.append(root)
 if not S.geometry():vegetation(view)
static func mask(model) -> Texture2D:
 var im:=Image.create(int(model.data.w),int(model.data.h),false,Image.FORMAT_RGBA8)
 for v in int(model.data.h):
  for u in int(model.data.w):im.set_pixel(u,v,Color(1 if model.cell_at(Vector2i(u,v)).material=="rocha" else 0,0,0,1))
 return ImageTexture.create_from_image(im)
static func panorama(view) -> void:
 var texture:=Assets.texture("res://assets/overworld/kits/montanha-v1/panorama-v2.png")
 if texture==null:return
 var backdrop:=Sprite2D.new();backdrop.texture=texture;backdrop.position=Vector2(128,360 if int(view.model.data.forest.baseLevel)==0 else 750 if int(view.model.data.forest.baseLevel)==2 else 1100);backdrop.scale=Vector2.ONE*(5000.0/texture.get_width());backdrop.z_index=-90;backdrop.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;view.actors.add_child(backdrop)
static func field(view) -> void:
 var model=view.model
 var texture:=Assets.texture("res://assets/overworld/kits/montanha-v1/pecas/macico-v2.png")
 if texture==null:return
 # Authored clusters, not a repeated carpet. Every base must be wholly supported.
 var anchors:Array=[[7,8],[40,7],[8,23],[46,31],[5,39]] if int(model.data.forest.baseLevel)==0 else [[7,5],[39,7],[29,23],[47,30]] if int(model.data.forest.baseLevel)==2 else [[8,6],[38,5],[30,25]]
 for anchor:Array in anchors:
  var u:int=anchor[0];var v:int=anchor[1]
  var cell:Dictionary=model.cell_at(Vector2i(u,v));var level:float=cell.get("level",-1)
  if level<0:continue
  var safe:=true
  for dv in range(-2,3):
   for du in range(-2,3):
    var c:Dictionary=model.cell_at(Vector2i(u+du,v+dv))
    if c.is_empty() or c.get("material")!="rocha" or c.get("level")!=level:safe=false
  if not safe:continue
  var scale:float=.33 if int(model.data.forest.baseLevel)==0 else .39
  var at:=Vector2(u+.5,v+.5);var screen:=S.iso(at,level*64)
  for point:Array in model.data.forest.clearViews:
   var delta:Vector2=screen-model.project(Vector2(point[0],point[1]))
   if absf(delta.x)<texture.get_width()*scale*.45 and delta.y>0 and delta.y<texture.get_height()*scale:safe=false
  if not safe:continue
  var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
  var art:=Sprite2D.new();art.texture=texture;art.centered=false;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;art.scale=Vector2.ONE*scale
  art.position=-Vector2(texture.get_width()*.5,texture.get_height()*.93)*scale-Vector2(0,level*64)
  var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cutout;root.add_child(art)
static func vegetation(view) -> void:
 var model=view.model
 if int(model.data.forest.baseLevel)==0:foothill_trees(view)
 for v in int(model.data.h):
  for u in int(model.data.w):
   var c:Dictionary=model.cell_at(Vector2i(u,v))
   if c.material not in ["grama","mato"] or c.get("ramp")!=null:continue
   var noise:float=fmod(absf(sin(u*33.17+v*16.3)*43758.5),1.)
   if noise>(.40 if c.material=="mato" else .11):continue
   preload("res://scripts/overworld/swamp_structures.gd").grass(view,Vector2(u+.5,v+.5),float(c.level)*64,36+noise*14)

static func foothill_trees(view) -> void:
 var model=view.model
 for point:Array in [[6,22],[9,40],[42,40],[47,20],[18,6],[32,6]]:
  var cell:Dictionary=model.cell_at(Vector2i(point[0],point[1]))
  if cell.get("material")!="rocha" or float(cell.get("level",-1))<0:continue
  var at:=Vector2(point[0]+.5,point[1]+.5);var level:float=cell.level;var safe:=true
  for target:Array in model.data.forest.clearViews:
   var d:Vector2=S.iso(at,level*64)-model.project(Vector2(target[0],target[1]))
   if absf(d.x)<105 and d.y>0 and d.y<220:safe=false
  if not safe:continue
  var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
  var art:=Sprite2D.new();art.name="Art";art.centered=false;art.texture=load("res://assets/overworld/kits/comum/pecas/arvore-a.png");art.scale=Vector2.ONE*.85;art.modulate=Color(.72,.78,.67);art.position=Vector2(-96*.85,-272*.85-level*64);root.add_child(art);view.occluders.append(root)
