extends RefCounted
const S=preload("res://scripts/overworld/forest_structures.gd")
const Assets=preload("res://scripts/overworld/industrial_structures.gd")
static func build(view) -> void:
 if S.geometry():return
 var texture:=Assets.texture("res://assets/overworld/kits/pantano-v1/pecas/arvore-cipos.png")
 if texture==null:return
 for at:Array in view.model.data.forest.get("waterTrees",[]):
  tree(view,texture,Vector2(at[0],at[1]),-12,.17)
 for piece:Dictionary in view.model.data.pieces:
  if piece.asset!="pantano-arvore":continue
  var at:=Vector2(piece.u+.5,piece.v+.5)
  tree(view,texture,at,view.model.height_at(at)*64,.19)
static func tree(view,texture:Texture2D,at:Vector2,height:float,scale:float) -> void:
 var root:=Node2D.new();root.set_meta("scenery",true);root.position=S.iso(at);view.actors.add_child(root)
 var art:=Sprite2D.new();art.name="Art";art.texture=texture;art.centered=false;art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 art.scale=Vector2.ONE*scale
 art.position=-Vector2(texture.get_width()*.5,texture.get_height()*.94)*scale-Vector2(0,height)
 var cutout:=ShaderMaterial.new();cutout.shader=preload("res://shaders/industrial_cutout.gdshader");art.material=cutout
 root.add_child(art);view.occluders.append(root)
