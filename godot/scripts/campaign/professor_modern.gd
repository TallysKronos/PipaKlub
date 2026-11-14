extends RefCounted
const H=preload("res://scripts/campaign/house_modern.gd")
const PIXEL_ART := "res://assets/campaign/professor-pixel-v2/"
# Atlas cells and front-corner pivots on the 2:1 grid.
const FURNITURE := {
 "library": [Rect2(14, 582, 144, 207), Vector2(120, 785)],
 "study": [Rect2(254, 582, 144, 207), Vector2(360, 785)],
 "workbench": [Rect2(462, 572, 207, 217), Vector2(600, 785)],
 "desk": [Rect2(734, 582, 174, 207), Vector2(840, 785)],
 "chest": [Rect2(46, 861, 115, 79), Vector2(120, 937)],
}
static func applies(data:Dictionary) -> bool:return data.get("id","")=="professor"
static func build_floor(room) -> void:
 var root:=Node2D.new();root.name="AtelieModernoFloor";room.add_child(root)
 if applies(room.data) and not H.geometry():
  var shell := Sprite2D.new()
  shell.texture = load(PIXEL_ART + "estrutura.png")
  shell.centered = false
  shell.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  root.add_child(shell)
  room.set_meta("professor_art","pixel-v2")
  return
 var f:Dictionary=room.data.layout.floor;var s:float=room.camera.scale
 var back:Vector2=room.project(Vector2(f.x,f.y));var left:Vector2=room.project(Vector2(f.x,f.y+f.h));var right:Vector2=room.project(Vector2(f.x+f.w,f.y));var front:Vector2=room.project(Vector2(f.x+f.w,f.y+f.h));var up:=Vector2(0,-160*s)
 H.poly(root,PackedVector2Array([left,back,back+up,left+up]),Color("a9bcc7") if H.geometry() else Color("dae5e6"),true,2.)
 H.poly(root,PackedVector2Array([back,right,right+up,back+up]),Color("c9d7dc") if H.geometry() else Color("f0f2eb"),true,2.)
 for end in [left,right]:
  H.poly(root,PackedVector2Array([back,end,end-Vector2(0,12*s),back-Vector2(0,12*s)]),Color("31566e"))
  H.line(root,back+up,end+up,Color("faf8ee"),4.)
  H.line(root,back-Vector2(0,22*s),end-Vector2(0,22*s),Color("6dabb6"),2.)
 H.line(root,back,back+up,Color("425b6d"),2.)
 H.poly(root,PackedVector2Array([left,front,front+Vector2(0,12),left+Vector2(0,12)]),Color("8a9fa9"))
 H.poly(root,PackedVector2Array([front,right,right+Vector2(0,12),front+Vector2(0,12)]),Color("b5c3c5"))
 for row in int(ceil(float(f.h)/192)):
  for col in int(ceil(float(f.w)/192)):
   var x:float=f.x+col*192;var y:float=f.y+row*192;var w:float=minf(192,f.x+f.w-x);var h:float=minf(192,f.y+f.h-y)
   var t:float=float((row+col)%3)*.009
   H.rect(room,root,x,y,w,h,Color(.73+t,.79+t,.81+t),false)
   H.line(root,room.project(Vector2(x,y)),room.project(Vector2(x+w,y)),Color("9cafb5"),.7)
   H.line(root,room.project(Vector2(x,y)),room.project(Vector2(x,y+h)),Color("9cafb5"),.7)
 room.set_meta("professor_art","pixel-v2")

static func create_prop(room,p:Dictionary) -> Node2D:
 var root:=Node2D.new();root.name="Professor_"+str(p.id)
 var r:=Rect2(p.rect[0],p.rect[1],p.rect[2],p.rect[3]);var id:String=p.id
 if applies(room.data) and not H.geometry():
  if id in ["window", "papers"]:
   # Glazing is painted into the two walls.
   return root
  if FURNITURE.has(id):
   var part: Array = FURNITURE[id]
   var fp: Dictionary = p.footprint
   var floor_data: Dictionary = room.data.layout.floor
   var front: Vector2 = room.project(Vector2(floor_data.x + fp.u1 * 96, floor_data.y + fp.v1 * 96))
   var pixels := Sprite2D.new()
   pixels.name = "Art"
   pixels.texture = load(PIXEL_ART + "moveis.png")
   pixels.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
   pixels.centered = false
   pixels.region_enabled = true
   pixels.region_rect = part[0]
   pixels.region_filter_clip_enabled = true
   pixels.position = front.round() + pixels.region_rect.position - Vector2(part[1])
   root.add_child(pixels)
   return root
 if id in ["rug","exit"]:
  var fp:Dictionary=p.footprint;var f:Dictionary=room.data.layout.floor
  var x:float=f.x+fp.u0*96;var y:float=f.y+fp.v0*96;var w:float=(fp.u1-fp.u0)*96;var h:float=(fp.v1-fp.v0)*96
  if applies(room.data) and not H.geometry():
   _floor_marks(room, root, Rect2(x, y, w, h), id)
   return root
  H.rect(room,root,x,y,w,h,Color("e6e9df"));H.rect(room,root,x+12,y+12,w-24,h-24,Color("416c86"))
  if id=="exit":H.rect(room,root,x+12,y+h-24,w-24,12,Color("6cbacb"),false)
  else:
   var center:=Vector2(x+w*.5,y+h*.5)
   var emblem:=Line2D.new();emblem.points=PackedVector2Array([room.project(center+Vector2(-60,-60)),room.project(center+Vector2(60,-60)),room.project(center+Vector2(60,60)),room.project(center+Vector2(-60,60))]);emblem.closed=true;emblem.width=2.;emblem.default_color=Color("a8cfcd");emblem.antialiased=true;root.add_child(emblem)
  return root
 if id=="window":
  var a:=r.position+Vector2(0,r.size.x*.5);var b:=r.position+Vector2(r.size.x,0);var c:=r.end-Vector2(0,r.size.x*.5);var d:=r.position+Vector2(0,r.size.y)
  H.poly(root,PackedVector2Array([a,b,c,d]),Color("f7f7ed"),true,2.)
  a+=Vector2(6,3);b+=Vector2(-6,9);c+=Vector2(-6,-3);d+=Vector2(6,-9)
  H.poly(root,PackedVector2Array([a,b,c,d]),Color("91c9d6"))
  H.line(root,a.lerp(b,.5),d.lerp(c,.5),Color("31566e"),3.)
  H.line(root,a.lerp(d,.5),b.lerp(c,.5),Color("31566e"),3.)
  H.line(root,a+Vector2(8,4),a+Vector2(8,22),Color("e9f6ed"),3.)
  return root
 if id=="papers":
  var a:=r.position;var b:=a+Vector2(r.size.x,r.size.x*.5);var c:=r.end;var d:=a+Vector2(0,r.size.y-r.size.x*.5)
  H.poly(root,PackedVector2Array([a,b,c,d]),Color("31566e"),true,2.)
  for i in 3:
   var at:=a+Vector2(8+i*28,8+i*14)
   H.poly(root,PackedVector2Array([at,at+Vector2(21,10.5),at+Vector2(21,36),at+Vector2(0,25.5)]),Color("f7f4e6"))
   H.line(root,at+Vector2(5,10),at+Vector2(16,24),Color("58a1b5"),2.)
  return root
 if H.geometry():
  var fp:Dictionary=p.footprint;var f:Dictionary=room.data.layout.floor
  var a:Vector2=room.project(Vector2(f.x+fp.u0*96,f.y+fp.v0*96));var b:Vector2=room.project(Vector2(f.x+fp.u1*96,f.y+fp.v0*96));var c:Vector2=room.project(Vector2(f.x+fp.u1*96,f.y+fp.v1*96));var d:Vector2=room.project(Vector2(f.x+fp.u0*96,f.y+fp.v1*96))
  var rise:=Vector2(0,-maxf(25,a.y-r.position.y));var lift:=Vector2(0,r.end.y-c.y)
  a+=lift;b+=lift;c+=lift;d+=lift
  H.poly(root,PackedVector2Array([b,c,c+rise,b+rise]),Color("4c6e81"));H.poly(root,PackedVector2Array([c,d,d+rise,c+rise]),Color("608698"));H.poly(root,PackedVector2Array([a+rise,b+rise,c+rise,d+rise]),Color("aac9ce"))
  return root
 return root

static func _floor_marks(room, root: Node2D, area: Rect2, id: String) -> void:
 var guide := Color("378d9f")
 if id == "exit":
  H.rect(room, root, area.position.x, area.position.y, area.size.x, area.size.y, Color("32576c"))
  for index in 5:
   H.rect(room, root, area.position.x + 15 + index * 33, area.end.y - 23, 21, 9, Color("76d1c4"), false)
  return
 for edge in [area.position, area.end - Vector2(0, area.size.y)]:
  H.rect(room, root, edge.x - 4, edge.y + 8, 12, area.size.y - 16, guide, false)
  for end in [edge.y + 8, edge.y + area.size.y - 20]:
   H.rect(room, root, edge.x - 27, end, 35, 12, guide, false)
 for index in 3:
  var center := area.get_center() + Vector2(0, (index - 1) * 42)
  var diamond := PackedVector2Array()
  for corner in [Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)]:
   diamond.append(room.project(center + corner).round())
  H.poly(root, diamond, Color("80b9c5"), false)
