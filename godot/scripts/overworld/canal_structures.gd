extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
static func build(view)->void:
 for piece:Dictionary in view.model.data.pieces:
  if not piece.asset.begins_with("canal-"):continue
  var node:=Node2D.new();var point:=Vector2(piece.u+1,piece.v+1)
  node.position=view.model.project(point,false);node.set_meta("scenery",true);view.actors.add_child(node)
  var base:Vector2=view.model.project(point)-node.position
  var top:=PackedVector2Array([base+Vector2(0,-72),base+Vector2(54,-45),base+Vector2(0,-18),base+Vector2(-54,-45)])
  S.quad(node,PackedVector2Array([top[1],top[2],base+Vector2(0,10),base+Vector2(54,-17)]),Color("526e7a"))
  S.quad(node,PackedVector2Array([top[2],top[3],base+Vector2(-54,-17),base+Vector2(0,10)]),Color("354e60"))
  S.quad(node,top,Color("9caca8"));S.line(node,PackedVector2Array([top[3],top[2],top[1]]),2,Color("172b3b"))
  if S.geometry():continue
  if piece.asset=="canal-bomba":
   for x in [-25,25]:
    S.line(node,PackedVector2Array([base+Vector2(x,-44),base+Vector2(x,-92),base+Vector2(x+12,-103)]),15,Color("263f52"))
    S.line(node,PackedVector2Array([base+Vector2(x-2,-45),base+Vector2(x-2,-90),base+Vector2(x+10,-100)]),7,Color("62a8b5"))
   var wheel:=PackedVector2Array()
   for i in 33:wheel.append(base+Vector2(0,-85)+Vector2(cos(i*TAU/32)*18,sin(i*TAU/32)*13))
   S.line(node,wheel,5,Color("dbab62"))
   S.line(node,PackedVector2Array([base+Vector2(-16,-85),base+Vector2(16,-85)]),4,Color("dbab62"))
   S.line(node,PackedVector2Array([base+Vector2(0,-97),base+Vector2(0,-73)]),4,Color("dbab62"))
  else:
   for x in [-20,15]:
    S.line(node,PackedVector2Array([base+Vector2(x,-28),base+Vector2(x,-62)]),21,Color("bf8a50"))
    S.line(node,PackedVector2Array([base+Vector2(x-12,-63),base+Vector2(x+12,-51)]),4,Color("ebc68b"))
    S.line(node,PackedVector2Array([base+Vector2(x-12,-30),base+Vector2(x+12,-18)]),4,Color("704e3a"))
