extends RefCounted
## Measured blockout volumes; art will replace their surfaces after geometry review.
const S=preload("res://scripts/overworld/forest_structures.gd")
const KIT="res://assets/overworld/kits/cais-v1/"
const COAST="res://assets/overworld/kits/costa-studio-v1/"
const CARGO={
 "bobina":["bobina-em-palete",Vector2(38,69)],
 "cabeco":["cabeco-com-corda",Vector2(26,45)],
 "rede":["rede-e-covo",Vector2(38,67)],
 "conteiner":["conteiner-ocre",Vector2(58,105)],
 "portico":["portico-de-icamento",Vector2(58,98)],
 "tambores":["tambores",Vector2(31,65)],
}
static func surface(parent,points:PackedVector2Array,color:Color,file:String)->void:
 var texture:Texture2D=load(KIT+file) if not S.geometry() else null
 var poly:=S.quad(parent,points,color,texture)
 if texture:poly.uv=PackedVector2Array([Vector2.ZERO,Vector2(texture.get_width(),0),Vector2(texture.get_width(),texture.get_height()),Vector2(0,texture.get_height())])
static func sprite(view,point:Vector2,file:String,width:float,pivot:float=1.0,water:bool=false)->void:
 var node:=Node2D.new();node.position=view.model.project(point,false);node.set_meta("scenery",true);view.actors.add_child(node)
 var foot:Vector2=view.model.project(point)-node.position
 if water:foot=Vector2.ZERO
 if S.geometry():
  S.quad(node,PackedVector2Array([foot+Vector2(-width/2,-12),foot+Vector2(0,-36),foot+Vector2(width/2,-12),foot+Vector2(0,12)]),Color("83979e"));return
 var texture:Texture2D=load(KIT+file)
 var art:=Sprite2D.new();art.texture=texture;art.centered=false;art.scale=Vector2.ONE*width/texture.get_width()
 art.position=foot-Vector2(width/2,texture.get_height()*art.scale.y*pivot);node.add_child(art)
static func build(view)->void:
 var model=view.model
 var district:=str(model.data.id).trim_prefix("kronasta-").get_slice("-",0)
 for dock:Dictionary in view.model.data.forest.get("docks",[]):
  if S.geometry():continue
  var node:=Node2D.new();var uv:=Vector2(dock.u+dock.w,dock.v+dock.h)
  node.position=model.project(uv,false)
  if district in ["porto","palafitas"]:
   # The deck is painted cell by cell with the floor; a single large sprite
   # sorted at its front corner can hide Kael when he crosses the bridge.
   if district=="palafitas":
    view.actors.add_child(node)
    dock_piles(view,node,dock)
   else:node.free()
   continue
  view.actors.add_child(node)
  var deck:=PackedVector2Array()
  for p in [Vector2(dock.u,dock.v),Vector2(dock.u+dock.w,dock.v),uv,Vector2(dock.u,dock.v+dock.h)]:deck.append(S.iso(p,64)-node.position)
  S.quad(node,deck,Color("b39568"))
  for y in range(int(dock.v)*3,int(dock.v+dock.h)*3):
   var v:=float(y)/3
   S.line(node,PackedVector2Array([S.iso(Vector2(dock.u,v),64)-node.position,S.iso(Vector2(dock.u+dock.w,v),64)-node.position]),1,Color("806a4d"))
 for b:Dictionary in view.model.data.forest.get("buildings",[]):
  var at:=Vector2(b.u+b.w,b.v+b.h)
  var node:=Node2D.new();node.position=view.model.project(at,false);node.set_meta("scenery",true);view.actors.add_child(node)
  var floor:=PackedVector2Array()
  for uv in [Vector2(b.u,b.v),Vector2(b.u+b.w,b.v),at,Vector2(b.u,b.v+b.h)]:floor.append(view.model.project(uv)-node.position)
  if district in ["porto","palafitas"] and not S.geometry():
   var variant:=posmod(int(b.u)+int(b.v)*2,3)
   if district=="palafitas":
    var file:String=["palafita-ocre","palafita-verde","palafita-azul"][variant]
    coast_art(node,file,floor[2],Vector2(98,172),minf(b.w,b.h)/2.75)
    continue
   if b.u==32 and b.v==6:
    coast_art(node,"galpao-terminal",floor[2],Vector2(162,240),minf(b.w,b.h)/4.65)
    continue
   variant=1 if b.u==5 else 0
   preload("res://scripts/overworld/district_architecture.gd").build(node,floor,district,float(b.height),variant)
   continue
  var top:=PackedVector2Array()
  for p in floor:top.append(p-Vector2(0,b.height))
  surface(node,PackedVector2Array([top[1],top[2],floor[2],floor[1]]),Color.WHITE if not S.geometry() else Color("6d818a"),"fachada.png")
  surface(node,PackedVector2Array([top[2],top[3],floor[3],floor[2]]),Color(.78,.85,.87) if not S.geometry() else Color("4b646f"),"fachada.png")
  surface(node,top,Color.WHITE if not S.geometry() else Color("a5bac1"),"telhado.png")
 for p:Dictionary in view.model.data.forest.get("props",[]):sprite(view,Vector2(p.u+p.w*.5,p.v+p.h*.5),p.asset+".png",p.width)
 for p:Dictionary in view.model.data.forest.get("ships",[]):sprite(view,Vector2(p.u,p.v),"barco.png",190,.83,true)
 if district in ["porto","palafitas"]:
  for piece:Dictionary in model.data.pieces:
   var asset:=str(piece.asset)
   if not asset.begins_with(district+"-"):continue
   var kind:=asset.get_slice("-",1)
   if kind=="poste" and not S.geometry():
    studio_cargo(view,piece,["",Vector2(26,85)],"res://assets/overworld/kits/centro-studio-v1/poste-de-rua.png")
   elif CARGO.has(kind) or kind=="poste":
    studio_cargo(view,piece,CARGO.get(kind,[]))

static func dock_piles(view,node:Node2D,dock:Dictionary)->void:
 var model=view.model
 var waterline:=PackedVector2Array()
 for p in [Vector2(dock.u,dock.v),Vector2(dock.u+dock.w,dock.v),Vector2(dock.u+dock.w,dock.v+dock.h),Vector2(dock.u,dock.v+dock.h)]:
  waterline.append(S.iso(p,0)-node.position)
 var under_deck:=S.quad(node,waterline,Color.WHITE)
 under_deck.vertex_colors=PackedColorArray([Color("143a46"),Color("164854"),Color("176075"),Color("164854")])
 under_deck.z_index=-1
 for offset in range(0,int(dock.w),2):
  var edge:=Vector2(float(dock.u+offset)+.5,float(dock.v+dock.h))
  if model.cell_at(Vector2i(edge)).get("material")!="agua":continue
  var deck_foot:=S.iso(edge,64)-node.position
  var water_foot:=S.iso(edge,0)-node.position
  S.line(node,PackedVector2Array([deck_foot,water_foot]),10,Color("544439"))
  S.line(node,PackedVector2Array([deck_foot+Vector2(-2,1),water_foot+Vector2(-2,-2)]),3,Color("9b7755"))
 for offset in range(0,int(dock.h),2):
  var edge:=Vector2(float(dock.u+dock.w),float(dock.v+offset)+.5)
  if model.cell_at(Vector2i(edge)).get("material")!="agua":continue
  var deck_foot:=S.iso(edge,64)-node.position
  var water_foot:=S.iso(edge,0)-node.position
  S.line(node,PackedVector2Array([deck_foot,water_foot]),10,Color("544439"))
  S.line(node,PackedVector2Array([deck_foot+Vector2(-2,1),water_foot+Vector2(-2,-2)]),3,Color("9b7755"))

static func coast_art(node:Node2D,file:String,foot:Vector2,anchor:Vector2,factor:float=1.0,resource_path:String="")->void:
 var texture:=load(COAST+file+".png" if resource_path.is_empty() else resource_path) as Texture2D
 if texture==null:return
 var art:=Sprite2D.new()
 art.texture=texture;art.centered=false
 art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 art.scale=Vector2.ONE*factor
 art.position=foot-anchor*factor
 node.add_child(art)

static func studio_cargo(view,piece:Dictionary,spec:Array,resource_path:String="")->void:
 var model=view.model
 var start:=Vector2(piece.u,piece.v)
 var size:=Vector2(piece.fu,piece.fv)
 var node:=Node2D.new()
 node.position=model.project(start+size,false)
 node.set_meta("scenery",true)
 view.actors.add_child(node)
 if S.geometry():
  var outline:=PackedVector2Array()
  for offset in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
   var point:Vector2=start+offset
   outline.append(model.project(point)-node.position)
  S.quad(node,outline,Color("6e8e8c"))
 else:
  coast_art(node,spec[0],model.project(start+size*.5)-node.position,spec[1],1.0,resource_path)

static func aracati_props(view) -> void:
 var placements := {
  "a": [
   ["cancela",23,37], ["biruta",28,24], ["banco",13,22], ["banco",13,12],
   ["arvore-costeira",10,19], ["arvore-costeira",30,9], ["arvore-costeira",33,24],
   ["mato-costeiro",11,20], ["mato-costeiro",31,10], ["mato-costeiro",34,24],
   ["mato-costeiro",20,28], ["mato-costeiro",15,12], ["mato-costeiro",30,26],
  ],
  "b": [
   ["biruta",35,12], ["banco",17,29], ["banco",11,17],
   ["arvore-costeira",7,22], ["arvore-costeira",35,15],
   ["mato-costeiro",8,23], ["mato-costeiro",34,16], ["mato-costeiro",15,14],
   ["mato-costeiro",31,23], ["mato-costeiro",17,30],
  ],
  "c": [
   ["biruta",17,10], ["banco",11,27],
   ["arvore-costeira",9,25], ["arvore-costeira",31,7],
   ["mato-costeiro",10,26], ["mato-costeiro",32,8], ["mato-costeiro",15,13],
   ["mato-costeiro",18,21], ["mato-costeiro",31,13],
  ],
 }
 for prop in placements.get(str(view.model.data.id).right(1),[]):
  var point := Vector2(prop[1]+.5,prop[2]+.5)
  if not view.model.point_walkable(point):continue
  var sprite := Sprite2D.new()
  sprite.texture = load("res://assets/overworld/kits/aracati-v1/"+prop[0]+".png")
  if sprite.texture == null:continue
  var root:=Node2D.new()
  root.position=view.model.project(point,false)
  root.set_meta("scenery",true)
  view.actors.add_child(root)
  sprite.position = view.model.project(point)-root.position
  var foot:=sprite.position
  S.quad(root,PackedVector2Array([foot+Vector2(-16,0),foot+Vector2(0,-7),foot+Vector2(22,0),foot+Vector2(0,7)]),Color(0.20,0.21,0.12,0.24))
  sprite.offset.y = -sprite.texture.get_height()*.5
  if prop[0] == "banco":
   sprite.scale = Vector2.ONE * 1.55
  if prop[0] == "arvore-costeira":sprite.offset.x = sprite.texture.get_width()*.16
  root.add_child(sprite)

static func mirante_props(view) -> void:
 var part:=str(view.model.data.id).right(1)
 var placements := {
  "a": [["casa",17,29],["casa",20,24],["casa",30,18],["poste",19,30],["poste",27,22],["balaustrada",29,32],["balaustrada",31,30],["banco",18,27]],
  "b": [["jacaranda",19,20],["banco",17,21],["banco",20,23],["poste",30,24],["poste",15,23],["casa",31,15],["casa",34,20],["balaustrada",14,24],["balaustrada",33,25]],
  "c": [["bandeira",16,8],["bandeira",31,8],["bandeira",16,18],["bandeira",31,18],["balaustrada",15,14],["balaustrada",32,14],["banco",29,20]],
 }
 for prop in placements.get(part,[]):
  var point := Vector2(prop[1]+.5,prop[2]+.5)
  if not view.model.point_walkable(point):continue
  var sprite := Sprite2D.new()
  sprite.texture = load("res://assets/overworld/kits/mirante-v1/"+prop[0]+".png")
  var holder := Node2D.new()
  holder.position = view.model.project(point,false)
  sprite.position = view.model.project(point) - holder.position
  sprite.offset.y = -sprite.texture.get_height()*.5
  if prop[0] == "banco":
   sprite.scale = Vector2.ONE * 1.55
  view.actors.add_child(holder)
  holder.add_child(sprite)
 var waypoints:Dictionary={
  "a":[Vector2(24.5,35.5),Vector2(24.5,25.5),Vector2(24.5,10.8)],
  "b":[Vector2(24.5,34.5),Vector2(24.5,25.5),Vector2(24.5,18.5),Vector2(24.5,10.8)],
  "c":[Vector2(24.5,34.5),Vector2(24.5,24.9),Vector2(24.5,19.5)],
 }
 for point:Vector2 in waypoints.get(part,[]):
  mirante_waymark(view,point)

static func mirante_waymark(view,point:Vector2) -> void:
 var model=view.model
 var tips:=PackedVector2Array()
 for offset in [Vector2(-.38,.24),Vector2(0,-.23),Vector2(.38,.24)]:
  var sample:Vector2=point+offset
  if not model.point_walkable(sample) or not is_equal_approx(model.height_at(sample),model.height_at(point)):return
  tips.append(model.project(sample)-Vector2(0,.8))
 var ground:=Node2D.new()
 ground.position=model.project(point,false)
 view.actors.add_child(ground)
 for i in tips.size():tips[i]-=ground.position
 S.line(ground,tips,6,Color("534c3d"))
 S.line(ground,tips,3,Color("d2bd84"))
