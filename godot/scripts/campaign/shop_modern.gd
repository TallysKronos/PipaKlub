extends RefCounted
## Montagem do quadro aprovado por atlas em escala nativa.
const D=preload("res://scripts/campaign/shop_data.gd")
const BASE:="res://assets/campaign/loja-interior-v2/"
const OLD:="res://assets/campaign/loja-tcg-v1/"
const ARCHITECTURE:=["piso","parede-esquerda","parede-fundo","janela-esquerda","janela-direita","quadro-pipa-a","quadro-pipa-b","quadro-pipa-c","capacho"]
const GROUPS:={
	"prateleira-a":["prateleira-a"],
	"prateleira-b":["prateleira-b"],
	"expositor-pipas":["expositor-pipas"],
	"gondola":["gondola"],
	"balcao":["balcao","terminal"],
	"mesa-fundo":["mesa-fundo","banco-fundo"],
	"mesa-frente":["mesa-frente","banco-frente"],
	"porta-vidro":["porta-vidro"],
}
static var atlas:Texture2D
static var pieces:Dictionary={}

static func applies(data:Dictionary)->bool:
	return data.get("id","")=="kite-shop"

static func visible_point(point:Vector2)->Vector2:
	return D.project(point)

static func camera_offset(actor:Vector2)->Vector2:
	var at:=visible_point(actor)
	return Vector2(clampf(480-at.x,-160,0),clampf(295-at.y,-230,0)).round()

static func load_kit()->void:
	if atlas!=null:
		return
	atlas=preload("res://scripts/pixelgen_sprites.gd").load_texture(BASE+"atlas.png")
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"manifesto.json"))
	for part:Dictionary in manifest.parts:
		pieces[part.id]=part

static func sprite_for(id:String)->Sprite2D:
	var part:Dictionary=pieces[id]
	var bounds:Array=part.atlas_rect
	var texture:=AtlasTexture.new()
	texture.atlas=atlas
	texture.region=Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
	texture.filter_clip=true
	var sprite:=Sprite2D.new()
	sprite.name=id
	sprite.texture=texture
	sprite.centered=false
	sprite.position=Vector2(part.position_px[0]-part.pivot_px[0],part.position_px[1]-part.pivot_px[1])
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite

static func build_floor(room:Node2D)->void:
	load_kit()
	var root:=Node2D.new()
	root.name="ShopFloor"
	root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	room.add_child(root)
	for id in ARCHITECTURE:
		root.add_child(sprite_for(id))
	room.set_meta("shop_art","interior-moderno-v2")

static func create_prop(_room:Node2D,prop:Dictionary)->Node2D:
	var root:=Node2D.new()
	root.name="Shop_"+str(prop.id)
	root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for id in GROUPS[prop.id]:
		root.add_child(sprite_for(id))
	return root

static func add_owner(room:Node2D)->void:
	var root:=Node2D.new()
	root.name="ShopOwner"
	root.position=room.project(D.OWNER)
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OLD+"kit.json"))
	var bounds:Array=manifest.pieces.owner.bounds
	var sprite:=Sprite2D.new()
	sprite.name="Art"
	sprite.texture=load(OLD+"owner.png")
	sprite.centered=false
	sprite.region_enabled=true
	sprite.region_rect=Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
	var fit:float=76.0/float(bounds[3])
	sprite.scale=Vector2.ONE*fit
	sprite.position=Vector2(-bounds[2]*fit*.5,-76)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var cut:=ShaderMaterial.new()
	cut.shader=preload("res://shaders/industrial_cutout.gdshader")
	sprite.material=cut
	root.add_child(sprite)
	room.add_child(root)
	room.props.append({"node":root,"rect":room._foot(D.OWNER),"layer":""})
