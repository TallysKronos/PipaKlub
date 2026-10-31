extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
const Assets=preload("res://scripts/overworld/industrial_structures.gd")
static func build(view) -> void:
 var sky:=Polygon2D.new();sky.polygon=PackedVector2Array([Vector2(-10000,-10000),Vector2(10000,-10000),Vector2(10000,10000),Vector2(-10000,10000)]);sky.color=Color("9ab9c2");sky.z_index=-100;view.actors.add_child(sky)
 if not S.geometry():field(view)
 for piece:Dictionary in view.model.data.pieces:
  if piece.asset!="montanha-crista":continue
  if S.geometry():Assets.block(view,Vector2(piece.u,piece.v),piece.fu,piece.fv,110,"barreira",true);continue
  var at:=Vector2(piece.u+piece.fu*.5,piece.v+piece.fv*.5)
  var texture:=Assets.texture("res://assets/overworld/kits/montanha-v1/pecas/crista.png")
  if texture==null:continue
  var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
  var sprite:=Sprite2D.new();sprite.name="Art";sprite.centered=false;sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  sprite.scale=Vector2.ONE*.18;sprite.position=-Vector2(texture.get_width()*.5,texture.get_height()*.94)*.18-Vector2(0,view.model.height_at(at)*64)
  var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");sprite.material=cutout
  root.add_child(sprite);view.occluders.append(root)
 if not S.geometry():vegetation(view)
static func mask(model) -> Texture2D:
 var im:=Image.create(int(model.data.w),int(model.data.h),false,Image.FORMAT_RGBA8)
 for v in int(model.data.h):
  for u in int(model.data.w):im.set_pixel(u,v,Color(1 if model.cell_at(Vector2i(u,v)).material=="rocha" else 0,0,0,1))
 return ImageTexture.create_from_image(im)
static func field(view) -> void:
 var model=view.model
 var texture:=Assets.texture("res://assets/overworld/kits/montanha-v1/pecas/rochedos.png")
 if texture==null:return
 var w:int=model.data.w;var h:int=model.data.h
 for v in range(0,h-2,4):
  for u in range(0,w-2,4):
   var same:=true
   var level:float=model.cell_at(Vector2i(clampi(u,0,w-1),clampi(v,0,h-1))).level
   if level<0:continue
   for dv in 3:
    for du in 3:
     var c:Dictionary=model.cell_at(Vector2i(clampi(u+du,0,w-1),clampi(v+dv,0,h-1)))
     if c.material!="rocha" or c.level!=level:same=false
   if not same:continue
   var crag:Dictionary=model.data.forest.crag
   if u>=int(crag.u)-3 and u<=int(crag.u)+5 and v>=int(crag.v)-3 and v<=int(crag.v)+5:continue
   var near:=false
   for dv in range(-2,5):
    for du in range(-2,5):
     if model.walkable(Vector2i(u+du,v+dv)):near=true
   var noise:float=fmod(absf(sin(u*12.98+v*78.23)*43758.5),1.)
   if noise>.62:continue
   var scale:float=(.085+noise*.03) if near else (.17+noise*.06)
   var high:float=texture.get_height()*scale
   var at:=Vector2(u+1.5+(noise-.5)*.4,v+1.5)
   var base:=S.iso(at,level*64)
   var clear:=false
   for point:Array in model.data.forest.clearViews:
    var access:Vector2=model.project(Vector2(point[0],point[1]))
    var delta:=base-access
    if absf(delta.x)<110 and delta.y>0 and delta.y<high+16:clear=true
   if clear:continue
   var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
   var art:=Sprite2D.new();art.texture=texture;art.centered=false;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
   var flip:float=-1 if noise>.5 else 1
   art.scale=Vector2(scale*flip,scale)
   art.position=-Vector2(texture.get_width()*.5*flip,texture.get_height()*.88)*scale-Vector2(0,level*64)
   var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cutout
   root.add_child(art)
static func vegetation(view) -> void:
 var model=view.model
 for v in int(model.data.h):
  for u in int(model.data.w):
   var c:Dictionary=model.cell_at(Vector2i(u,v))
   if c.material not in ["grama","mato"] or c.get("ramp")!=null:continue
   var noise:float=fmod(absf(sin(u*33.17+v*16.3)*43758.5),1.)
   if noise>(.40 if c.material=="mato" else .11):continue
   preload("res://scripts/overworld/swamp_structures.gd").grass(view,Vector2(u+.5,v+.5),float(c.level)*64,36+noise*14)
