extends RefCounted
## PIP-105: peças sobre a mesma projeção e cota usadas pela navegação.
const Building=preload("res://scripts/overworld/street_building.gd")
const S=preload("res://scripts/overworld/forest_structures.gd")
const BASE="res://assets/overworld/kits/bambuzal-v1/"
const LAJES_HOUSES={
 "a":{Vector2i(6,5):["casa-geminada",416],Vector2i(7,19):["casa-ecologica",256]},
 "b":{Vector2i(7,19):["sobrado-varanda",288],Vector2i(38,19):["casa-ecologica",256]},
 "c":{Vector2i(37,5):["residencia-terraco",288],Vector2i(7,19):["sobrado-varanda",288]},
}
static func grove(view,p:Vector2,level:float,variant:String,scale:float=.58) -> void:
 var node:=Node2D.new();node.position=view.model.project(p,false);node.set_meta("scenery",true);view.actors.add_child(node)
 var art:=Sprite2D.new();art.name="Art";art.texture=load(BASE+variant+".svg")
 art.centered=false;art.scale=Vector2.ONE*scale
 var seed:int=posmod(int(p.x)*13+int(p.y)*19,11)
 art.modulate=Color(1.0,.93+float(seed%4)*.025,.84+float(seed%5)*.032)
 art.position=-Vector2(128,367)*scale-Vector2(0,level*64)
 node.add_child(art);view.occluders.append(node)
static func build(view) -> void:
 var model=view.model
 for piece:Dictionary in model.data.pieces:
  if piece.asset=="bambuzal-touceira":
   if S.geometry():continue
   var seed:float=float(int(piece.u)*7+int(piece.v)*13)
   var p:=Vector2(piece.u+.5+sin(seed)*.31,piece.v+.5+cos(seed*1.3)*.31)
   grove(view,p,model.height_at(p),str(piece.props.get("variante","alto")),.49+float((int(piece.u)*7+int(piece.v)*13)%11)*.021)
  elif piece.asset=="bambuzal-bancada":
   var p:=Vector2(piece.u+2,piece.v+1);var node:=Node2D.new();node.position=model.project(p,false);view.actors.add_child(node)
   var corners:=PackedVector2Array()
   for uv:Vector2 in [Vector2(piece.u,piece.v),Vector2(piece.u+2,piece.v),Vector2(piece.u+2,piece.v+1),Vector2(piece.u,piece.v+1)]:
    var base:Vector2=model.project(uv)-node.position
    S.line(node,PackedVector2Array([base,base-Vector2(0,34)]),5,Color("574330"));corners.append(base-Vector2(0,34))
   S.quad(node,corners,Color("b58d51") if not S.geometry() else Color("727f83"))
   if not S.geometry():
    var c:Vector2=(corners[0]+corners[2])*.5
    S.quad(node,PackedVector2Array([c+Vector2(-22,-6),c+Vector2(1,-17),c+Vector2(25,-6),c+Vector2(1,6)]),Color("d7b95c"))
    S.line(node,PackedVector2Array([c+Vector2(-22,-6),c+Vector2(25,-6)]),1,Color("744c3c"))
    S.line(node,PackedVector2Array([c+Vector2(1,-17),c+Vector2(1,6),c+Vector2(9,10),c+Vector2(3,16)]),1.5,Color("496d87"))
  elif piece.asset=="bambuzal-casa":
   var node:=Node2D.new();var p:=Vector2(piece.u+4,piece.v+4)
   node.position=model.project(p,false);node.set_meta("scenery",true);view.actors.add_child(node)
   var height:float=model.height_at(Vector2(piece.u+2,piece.v+2))*64
   if S.geometry():
    S.quad(node,PackedVector2Array([Vector2(-128,-64-height),Vector2(0,-height),Vector2(128,-64-height),Vector2(0,-128-height)]),Color("5d7281"))
   else:
    var district:=str(model.data.id).trim_prefix("kronasta-").get_slice("-",0)
    if district in ["centro","lajes"]:
     var feet:=PackedVector2Array()
     for at in [Vector2(piece.u,piece.v),Vector2(piece.u+4,piece.v),p,Vector2(piece.u,piece.v+4)]:
      feet.append(S.iso(at,height)-node.position)
     var architecture=preload("res://scripts/overworld/district_architecture.gd")
     var height_px:=172.0 if district=="centro" else 198.0
     if district=="centro":
      if str(model.data.id)=="kronasta-centro-a" and Vector2i(piece.u,piece.v) in [Vector2i(7,19),Vector2i(37,5)]:
       var paper_shop:bool=int(piece.u)==7
       var file:="papelaria-default" if paper_shop else "cafe-do-vento-default"
       var facade:=Sprite2D.new()
       facade.texture=load("res://assets/overworld/kits/urbano/pecas/"+file+".png")
       facade.centered=false
       facade.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
       facade.scale=Vector2.ONE*.8
       facade.position=Vector2(0,-height)-Vector2(160,304 if paper_shop else 368)*.8
       node.add_child(facade)
       continue
      var role := "sobrado"
      if piece.u==6 and piece.v==5:role="matriz"
      elif piece.u==35 and piece.v==10:role="tv"
      elif piece.u==38 and piece.v==19 and str(model.data.id).ends_with("-a"):role="liga"
      architecture.centro(node,feet,role,height_px)
     else:
      var part:=str(model.data.id).right(1)
      var residence:Array=LAJES_HOUSES.get(part,{}).get(Vector2i(piece.u,piece.v),[])
      if not residence.is_empty():
       var facade:=Sprite2D.new()
       facade.texture=load("res://assets/overworld/kits/urbano/pecas/"+residence[0]+"-default.png")
       facade.centered=false
       facade.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
       facade.position=Vector2(0,-height)-Vector2(128,residence[1])
       node.add_child(facade)
      elif part=="a" and piece.u==38 and piece.v==19:
       architecture.lajes_landmark(node,feet,false)
      elif part=="b" and piece.u==35 and piece.v==10:
       architecture.lajes_landmark(node,feet,true)
      else:
       architecture.build(node,feet,district,height_px)
     continue
    var house:=Building.new();house.width_cells=4;house.depth_cells=4
    house.modulate=Color(1,.95,.86) if piece.props.get("variante")=="creme" else Color(.84,.96,1) if piece.props.get("variante")=="azul" else Color(1,.87,.81)
    house.position=Vector2(0,-height);node.add_child(house)
 var f:Dictionary=model.data.forest
 if S.geometry():return
 for stump:Dictionary in f.get("cutStumps",[]):
  var p:=Vector2(stump.u+.5,stump.v+.5);var node:=Node2D.new();node.position=model.project(p,false)
  view.actors.add_child(node);var foot:Vector2=model.project(p)-node.position
  S.line(node,PackedVector2Array([foot,foot-Vector2(2,19)]),9,Color("365a37"))
  S.quad(node,PackedVector2Array([foot+Vector2(-7,-18),foot+Vector2(0,-22),foot+Vector2(7,-18),foot+Vector2(0,-14)]),Color("dbc17d"))
  S.line(node,PackedVector2Array([foot+Vector2(-4,-18),foot+Vector2(4,-18)]),1.2,Color("907e44"))
 if not f.get("cutStumps",[]).is_empty():
  var p:=Vector2(11.8,12.2);var stack:=Node2D.new();stack.position=model.project(p,false);view.actors.add_child(stack)
  var foot:Vector2=model.project(p)-stack.position
  for k in 6:
   var offset:=Vector2(float(k%3)*7,-float(k/3)*6)
   S.line(stack,PackedVector2Array([foot+Vector2(-32,-12)+offset,foot+Vector2(30,18)+offset]),7,Color("31553d"))
   S.line(stack,PackedVector2Array([foot+Vector2(-32,-13)+offset,foot+Vector2(30,17)+offset]),3,Color("a7b86d"))
  for x in [-12,16]:S.line(stack,PackedVector2Array([foot+Vector2(x,-12),foot+Vector2(x-5,18)]),4,Color("574330"))
 if f.get("landmark")==null:return
 var mark:Dictionary=f.landmark;var p:=Vector2(mark.u,mark.v)
 var node:=Node2D.new();node.position=model.project(p,false);node.set_meta("scenery",true);view.actors.add_child(node)
 node.z_index=1
 var foot:Vector2=model.project(p)-node.position
 if mark.kind=="portal":
  for x in [-90,90]:
   S.line(node,PackedVector2Array([foot+Vector2(x,0),foot+Vector2(x,-135)]),12,Color("2e4932"))
   S.line(node,PackedVector2Array([foot+Vector2(x-2,0),foot+Vector2(x-2,-135)]),6,Color("a1b46a"))
  S.line(node,PackedVector2Array([foot+Vector2(-112,-127),foot+Vector2(112,-127)]),12,Color("304e35"))
  S.line(node,PackedVector2Array([foot+Vector2(-112,-130),foot+Vector2(112,-130)]),6,Color("b5c77c"))
  for k in 7:
   var x:float=-75+k*25
   S.quad(node,PackedVector2Array([foot+Vector2(x,-121),foot+Vector2(x+18,-121),foot+Vector2(x+9,-95)]),Color("e2ab57") if k%2 else Color("80aaa0"))
 elif mark.kind=="rest":
  # The actual bench is a colliding source-map prop; this small fountain is beside it.
  S.quad(node,PackedVector2Array([foot+Vector2(36,-8),foot+Vector2(59,3),foot+Vector2(59,-34),foot+Vector2(36,-45)]),Color("687e78"))
  S.quad(node,PackedVector2Array([foot+Vector2(36,-45),foot+Vector2(59,-34),foot+Vector2(70,-40),foot+Vector2(47,-51)]),Color("b2bda0"))
  S.line(node,PackedVector2Array([foot+Vector2(51,-30),foot+Vector2(60,-26),foot+Vector2(60,-20)]),3,Color("446f7d"))
 else:
  # Thin painted ring follows the arena plane; never changes collision.
  var ring:=PackedVector2Array()
  for i in 65:
   var a:float=float(i)*TAU/64;ring.append(foot+Vector2(cos(a)*140,sin(a)*65))
  S.line(node,ring,5,Color("8b7450"))
  S.line(node,ring,2,Color("efe1b0"))
  for x in [-110,110]:
   S.line(node,PackedVector2Array([foot+Vector2(x,-25),foot+Vector2(x,-124)]),10,Color("35563b"))
   S.line(node,PackedVector2Array([foot+Vector2(x-2,-25),foot+Vector2(x-2,-124)]),4,Color("b6c57c"))
  S.line(node,PackedVector2Array([foot+Vector2(-110,-116),foot+Vector2(110,-116)]),3,Color("725333"))
  for k in 9:
   var x:float=-100+k*23
   S.quad(node,PackedVector2Array([foot+Vector2(x,-116),foot+Vector2(x+17,-116),foot+Vector2(x+9,-92)]),Color("dca354") if k%2 else Color("5a9692"))
