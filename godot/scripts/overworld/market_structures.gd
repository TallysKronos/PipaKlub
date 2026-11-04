extends RefCounted
## Barracas derivadas da pegada 3x2; projeção e ordenação seguem o piso.
const S=preload("res://scripts/overworld/forest_structures.gd")
static func build(view)->void:
 for piece:Dictionary in view.model.data.pieces:
  if piece.asset!="feira-banca":continue
  var node:=Node2D.new()
  node.position=view.model.project(Vector2(piece.u+3,piece.v+2),false)
  node.set_meta("scenery",true);view.actors.add_child(node)
  var feet:=PackedVector2Array()
  for uv:Vector2 in [Vector2(piece.u,piece.v),Vector2(piece.u+3,piece.v),Vector2(piece.u+3,piece.v+2),Vector2(piece.u,piece.v+2)]:feet.append(view.model.project(uv)-node.position)
  var roof:=PackedVector2Array()
  var counter:=PackedVector2Array()
  for foot:Vector2 in feet:
   S.line(node,PackedVector2Array([foot,foot-Vector2(0,92)]),5,Color("4b3c36"))
   roof.append(foot-Vector2(0,92));counter.append(foot-Vector2(0,33))
  S.quad(node,PackedVector2Array([counter[1],counter[2],feet[2],feet[1]]),Color("825d42"))
  S.quad(node,PackedVector2Array([counter[2],counter[3],feet[3],feet[2]]),Color("624a3c"))
  S.quad(node,counter,Color("cca170"))
  if not S.geometry():
   for i in 4:
    var c:Vector2=counter[3].lerp(counter[2],.15+i*.2)-Vector2(0,5)
    S.quad(node,PackedVector2Array([c+Vector2(-8,0),c+Vector2(0,-5),c+Vector2(8,0),c+Vector2(0,5)]),Color("e5bd62") if i%2==0 else Color("87a979"))
  var accent:=Color("c9795c")
  if piece.props.get("variante")=="teal":accent=Color("559c9b")
  elif piece.props.get("variante")=="ochre":accent=Color("d3ad57")
  if S.geometry():accent=Color("73868b")
  S.quad(node,roof,accent)
  for i in 6:
   var a:Vector2=roof[0].lerp(roof[1],float(i)/6)
   var b:Vector2=roof[0].lerp(roof[1],float(i+1)/6)
   var c:Vector2=roof[3].lerp(roof[2],float(i+1)/6)
   var d:Vector2=roof[3].lerp(roof[2],float(i)/6)
   if i%2==0:S.quad(node,PackedVector2Array([a,b,c,d]),Color("efe1ba") if not S.geometry() else accent.lightened(.1))
  var edge:=PackedVector2Array([roof[3],roof[2],roof[1]])
  S.line(node,edge,2,Color("443b36"))
  S.quad(node,PackedVector2Array([roof[3],roof[2],roof[2]+Vector2(0,12),roof[3]+Vector2(0,12)]),accent.darkened(.15))
