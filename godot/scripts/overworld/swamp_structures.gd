extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
const Assets=preload("res://scripts/overworld/industrial_structures.gd")
static func build(view) -> void:
 if S.geometry():return
 bridge(view)
 var texture:=Assets.texture("res://assets/overworld/kits/pantano-v1/pecas/arvore-cipos-v2.png")
 if texture==null:return
 for at:Array in view.model.data.forest.get("waterTrees",[]):
  tree(view,texture,Vector2(at[0],at[1]),-12,.17)
 for piece:Dictionary in view.model.data.pieces:
  if piece.asset!="pantano-arvore":continue
  var at:=Vector2(piece.u+.5,piece.v+.5)
  tree(view,texture,at,view.model.height_at(at)*64,.19)
static func tree(view,texture:Texture2D,at:Vector2,height:float,scale:float) -> void:
 var base:=S.iso(at,height)
 for point:Array in view.model.data.forest.get("clearViews",[]):
  var access:Vector2=view.model.project(Vector2(point[0],point[1]))
  var delta:=base-access
  if absf(delta.x)<110 and delta.y>0 and delta.y<300:return
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
 var art:=Sprite2D.new();art.name="Art";art.texture=texture;art.centered=false;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 art.scale=Vector2.ONE*scale
 art.position=-Vector2(texture.get_width()*.5,texture.get_height()*.94)*scale-Vector2(0,height)
 var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cutout
 root.add_child(art);view.occluders.append(root)
static func grass(view,at:Vector2,height:float,size:float) -> void:
 var texture:=Assets.texture("res://assets/overworld/kits/pantano-v1/pecas/grama-manga.png")
 if texture==null:return
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
 var art:=Sprite2D.new();art.centered=false;art.texture=texture;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var scale:=size/texture.get_width();art.scale=Vector2.ONE*scale
 art.position=-Vector2(texture.get_width()*.5,texture.get_height()*.825)*scale-Vector2(0,height)
 var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cutout
 root.add_child(art)
static func outlined(root:Node2D,points:PackedVector2Array,color:Color) -> void:
 S.quad(root,points,color)
 var edge:=points.duplicate();edge.append(points[0]);S.line(root,edge,1.7,Color("384443"))
static func bridge(view) -> void:
 var b:Dictionary=view.model.data.forest.water.bridge
 var u:float=b.u;var v:float=b.v;var w:float=b.w;var h:float=b.h
 # Measured deck remains at ground0 above water-12. Art never changes passage width.
 for row in int(h*3):
  var a:=Vector2(u,v+row/3.0);var end:=a+Vector2(w,1.0/3)
  var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso((a+end)*.5)+Vector2(0,4);view.actors.add_child(root)
  var p:=PackedVector2Array([S.iso(a),S.iso(a+Vector2(w,0)),S.iso(end),S.iso(a+Vector2(0,1.0/3))])
  for i in p.size():p[i]-=root.position
  var edge:=PackedVector2Array([p[1],p[2],p[2]+Vector2(0,5),p[1]+Vector2(0,5)])
  outlined(root,edge,Color("665142"))
  if row==int(h*3)-1:outlined(root,PackedVector2Array([p[2],p[3],p[3]+Vector2(0,5),p[2]+Vector2(0,5)]),Color("71553e"))
  outlined(root,p,[Color("b79664"),Color("c8aa73"),Color("ae885b")][row%3])
  S.line(root,PackedVector2Array([p[0]+Vector2(1,1),p[1]+Vector2(-1,1)]),1.3,Color("e0c28a"))
  # Two large, readable nail heads; a few broad grain curves instead of noisy texture.
  for t in [.08,.92]:
   var nail:=p[0].lerp(p[1],t).lerp(p[3].lerp(p[2],t),.5)
   var dot:=PackedVector2Array()
   for n in 8:dot.append(nail+Vector2.from_angle(TAU*n/8)*1.5)
   S.quad(root,dot,Color("4e5145"))
  if row%5==1:
   S.line(root,PackedVector2Array([p[0].lerp(p[1],.25)+Vector2(0,2),p[0].lerp(p[1],.40)+Vector2(0,4),p[0].lerp(p[1],.60)+Vector2(0,2)]),1.2,Color("80663e"))
 # Rope boundaries and tapered posts sit on the exact deck edges, not across the entry.
 for x in [u,u+w]:
  for y in [v,v+h*.5,v+h]:
   var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(Vector2(x,y))+Vector2(0,5);view.actors.add_child(root)
   outlined(root,PackedVector2Array([Vector2(-4,-5),Vector2(4,-5),Vector2(6,-35),Vector2(-5,-37)]),Color("98744d"))
   outlined(root,PackedVector2Array([Vector2(-6,-37),Vector2(0,-40),Vector2(7,-36),Vector2(0,-33)]),Color("d3b783"))
   S.line(root,PackedVector2Array([Vector2(-6,-26),Vector2(6,-22)]),3,Color("c3ab7a"))
  for n in 2:
   var a:=S.iso(Vector2(x,v+n*h*.5))-Vector2(0,24)
   var c:=S.iso(Vector2(x,v+(n+1)*h*.5))-Vector2(0,24)
   var root:=Node2D.new();root.set_meta("scenery",true);root.position=c+Vector2(0,30);view.actors.add_child(root)
   var line:=PackedVector2Array([a-root.position,a.lerp(c,.3)-root.position+Vector2(0,5),a.lerp(c,.7)-root.position+Vector2(0,5),c-root.position])
   S.line(root,line,4,Color("475047"));S.line(root,line,2,Color("c6b17a"))
