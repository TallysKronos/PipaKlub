extends Node2D
## Reusable bicycle prop. Register before the world's visibility/depth bake.
@export var cell := Vector2(2.0,18.85)
@export var flip_h := false
const TEXTURE := "res://assets/overworld/props/kael-bicycle/bicicleta.png"
var art_part:Dictionary={}

func install(world:Node2D) -> void:
	assert(art_part.is_empty(),"Bicycle must only be installed once")
	world.add_child(self)
	var texture:Texture2D=load(TEXTURE)
	# Native height makes the source-pixel scale exactly 1, with the wheels at support.
	world.billboard(TEXTURE,cell,world.support(cell),texture.get_image().get_used_rect().size.y,flip_h)
	art_part=world.parts.back()
	art_part.node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	art_part["prop_id"]="kael-bicycle"
	art_part["prop_component"]=self
	art_part.node.name="BicycleArt"

func art() -> Node2D:
	# Visibility reconstruction replaces the mesh, while retaining this dictionary.
	return art_part.get("node")
