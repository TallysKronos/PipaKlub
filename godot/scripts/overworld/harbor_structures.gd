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
  var top:=PackedVector2Array()
  for p in floor:top.append(p-Vector2(0,b.height))
  surface(node,PackedVector2Array([top[1],top[2],floor[2],floor[1]]),Color.WHITE if not S.geometry() else Color("6d818a"),"fachada.png")
  surface(node,PackedVector2Array([top[2],top[3],floor[3],floor[2]]),Color(.78,.85,.87) if not S.geometry() else Color("4b646f"),"fachada.png")
  surface(node,top,Color.WHITE if not S.geometry() else Color("a5bac1"),"telhado.png")
 for p:Dictionary in view.model.data.forest.get("props",[]):sprite(view,Vector2(p.u+p.w*.5,p.v+p.h*.5),p.asset+".png",p.width)
 for p:Dictionary in view.model.data.forest.get("ships",[]):sprite(view,Vector2(p.u,p.v),"barco.png",190,.83,true)
