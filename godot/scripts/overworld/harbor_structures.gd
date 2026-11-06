extends RefCounted
## Measured blockout volumes; art will replace their surfaces after geometry review.
const S=preload("res://scripts/overworld/forest_structures.gd")
const KIT="res://assets/overworld/kits/cais-v1/"
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
 for dock:Dictionary in view.model.data.forest.get("docks",[]):
  if S.geometry():continue
  var node:=Node2D.new();var uv:=Vector2(dock.u+dock.w,dock.v+dock.h)
  node.position=view.model.project(uv,false);view.actors.add_child(node)
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
  var district:=str(view.model.data.id).trim_prefix("kronasta-").get_slice("-",0)
  if district in ["porto","palafitas"] and not S.geometry():
   preload("res://scripts/overworld/district_architecture.gd").build(node,floor,district,float(b.height))
   continue
  var top:=PackedVector2Array()
  for p in floor:top.append(p-Vector2(0,b.height))
  surface(node,PackedVector2Array([top[1],top[2],floor[2],floor[1]]),Color.WHITE if not S.geometry() else Color("6d818a"),"fachada.png")
  surface(node,PackedVector2Array([top[2],top[3],floor[3],floor[2]]),Color(.78,.85,.87) if not S.geometry() else Color("4b646f"),"fachada.png")
  surface(node,top,Color.WHITE if not S.geometry() else Color("a5bac1"),"telhado.png")
 for p:Dictionary in view.model.data.forest.get("props",[]):sprite(view,Vector2(p.u+p.w*.5,p.v+p.h*.5),p.asset+".png",p.width)
 for p:Dictionary in view.model.data.forest.get("ships",[]):sprite(view,Vector2(p.u,p.v),"barco.png",190,.83,true)

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
 var placements := {
  "a": [["casa",17,29],["casa",20,24],["casa",30,18],["poste",19,30],["poste",27,22],["balaustrada",29,32],["balaustrada",31,30],["banco",18,27]],
  "b": [["jacaranda",19,20],["banco",17,21],["banco",20,23],["poste",30,24],["poste",15,23],["casa",31,15],["casa",34,20],["balaustrada",14,24],["balaustrada",33,25]],
  "c": [["bandeira",16,8],["bandeira",31,8],["bandeira",16,18],["bandeira",31,18],["balaustrada",15,14],["balaustrada",32,14],["banco",29,20]],
 }
 for prop in placements.get(str(view.model.data.id).right(1),[]):
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
