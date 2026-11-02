extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
static func build(view)->void:
 var f:Dictionary=view.model.data.forest
 if not f.has("muralPanel"):return
 var m:Dictionary=f.muralPanel
 var node:=Node2D.new();var at:=Vector2(m.u+m.width,m.v+.05)
 node.position=view.model.project(at,false);node.set_meta("scenery",true);view.actors.add_child(node)
 var a:Vector2=view.model.project(Vector2(m.u,m.v+.05))-node.position
 var b:Vector2=view.model.project(at)-node.position
 var points:=PackedVector2Array([a-Vector2(0,m.heightPx),b-Vector2(0,m.heightPx),b,a])
 var poly:=Polygon2D.new();poly.polygon=points;poly.color=Color("bda57e");node.add_child(poly)
 if not S.geometry() and ResourceLoader.exists("res://assets/overworld/kits/mural-v1/primeiro-laco.png"):
  var texture:Texture2D=load("res://assets/overworld/kits/mural-v1/primeiro-laco.png")
  poly.texture=texture;poly.color=Color.WHITE
  poly.uv=PackedVector2Array([Vector2.ZERO,Vector2(texture.get_width(),0),Vector2(texture.get_width(),texture.get_height()),Vector2(0,texture.get_height())])
 S.line(node,PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),3,Color("544638"))
