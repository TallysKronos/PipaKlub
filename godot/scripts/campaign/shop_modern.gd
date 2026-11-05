extends RefCounted
const H=preload("res://scripts/campaign/house_modern.gd")
const P=preload("res://scripts/campaign/professor_modern.gd")
const D=preload("res://scripts/campaign/shop_data.gd")
const BASE="res://assets/campaign/loja-tcg-v1/"
static func applies(data:Dictionary)->bool:return data.get("id","")=="kite-shop"
static func build_floor(room)->void:
 P.build_floor(room);room.get_node("AtelieModernoFloor").name="ShopFloor";room.remove_meta("professor_art");room.set_meta("shop_art","tcg-v1")
static func create_prop(room,p:Dictionary)->Node2D:
 if p.id in ["rug","exit","window"] or H.geometry():
  var node:=P.create_prop(room,p);node.name="Shop_"+str(p.id);return node
 var root:=Node2D.new();root.name="Shop_"+str(p.id)
 var asset:String="shelf" if str(p.id).begins_with("shelf") else "table" if str(p.id).begins_with("table") else "gondola" if p.id=="showcase" else p.id
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"kit.json"));var spec:Dictionary=manifest.pieces[asset]
 var sprite:=Sprite2D.new();sprite.name="Art";sprite.texture=load(BASE+asset+".png") as Texture2D;sprite.centered=false;sprite.region_enabled=true;sprite.region_rect=Rect2(spec.bounds[0],spec.bounds[1],spec.bounds[2],spec.bounds[3])
 var r:=Rect2(p.rect[0],p.rect[1],p.rect[2],p.rect[3]);var fit:float=minf(r.size.x/sprite.region_rect.size.x,r.size.y/sprite.region_rect.size.y)
 sprite.scale=Vector2.ONE*fit;sprite.position=Vector2(r.position.x+(r.size.x-sprite.region_rect.size.x*fit)*.5,r.end.y-sprite.region_rect.size.y*fit);sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 var cut:=ShaderMaterial.new();cut.shader=preload("res://shaders/industrial_cutout.gdshader");sprite.material=cut;root.add_child(sprite);return root
static func add_owner(room)->void:
 var root:=Node2D.new();root.name="ShopOwner";root.position=room.project(D.OWNER)
 if H.geometry():
  H.poly(root,PackedVector2Array([Vector2(-13,0),Vector2(13,0),Vector2(10,-60),Vector2(-10,-60)]),Color("c28b72"))
 else:
  var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"kit.json"));var spec:Dictionary=manifest.pieces.owner
  var sprite:=Sprite2D.new();sprite.name="Art";sprite.texture=load(BASE+"owner.png") as Texture2D;sprite.centered=false;sprite.region_enabled=true;sprite.region_rect=Rect2(spec.bounds[0],spec.bounds[1],spec.bounds[2],spec.bounds[3])
  var fit:float=102.0*room.camera.scale/sprite.region_rect.size.y;sprite.scale=Vector2.ONE*fit;sprite.position=Vector2(-sprite.region_rect.size.x*fit*.5,-sprite.region_rect.size.y*fit)
  var cut:=ShaderMaterial.new();cut.shader=preload("res://shaders/industrial_cutout.gdshader");sprite.material=cut;root.add_child(sprite)
 room.add_child(root);room.props.append({"node":root,"rect":room._foot(D.OWNER),"layer":""})
