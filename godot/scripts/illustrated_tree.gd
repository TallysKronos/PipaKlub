extends Node2D
## The image has real alpha. The root anchor, not the crown, controls depth.
@export var texture: Texture2D
@export var fit_size := Vector2(216,182)
@export var root_offset := Vector2(0,-7)
@export var root_radius := Vector2(45,14)
var sprite: Sprite2D
var alpha_bounds: Rect2i

func _draw() -> void:
	# Small flat contact mark anchors the roots without adding volumetric lighting.
	draw_set_transform(root_offset,0,Vector2(1,.22))
	draw_circle(Vector2.ZERO,root_radius.x,Color(.08,.18,.08,.12))

func _ready() -> void:
	var image:=texture.get_image()
	alpha_bounds=image.get_used_rect()
	sprite=Sprite2D.new()
	sprite.name="TreeArt"
	sprite.texture=texture
	sprite.region_enabled=true
	sprite.region_rect=Rect2(alpha_bounds)
	sprite.centered=false
	var factor:=minf(fit_size.x/alpha_bounds.size.x,fit_size.y/alpha_bounds.size.y)
	sprite.scale=Vector2.ONE*factor
	sprite.position=Vector2(-alpha_bounds.size.x*factor/2,-alpha_bounds.size.y*factor)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	# Native collider mirrors the root footprint used by the authored ground.
	var body:=StaticBody2D.new()
	body.name="Roots"
	body.collision_layer=2
	body.collision_mask=0
	add_child(body)
	var shape:=CollisionPolygon2D.new()
	var polygon:=PackedVector2Array()
	for i in 24:
		var angle:=TAU*i/24.0
		polygon.append(root_offset+Vector2(cos(angle)*root_radius.x,sin(angle)*root_radius.y))
	shape.polygon=polygon
	body.add_child(shape)
