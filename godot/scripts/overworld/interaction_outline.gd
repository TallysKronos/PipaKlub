extends Node2D
## Draw only the silhouette rim beneath the original sprite and its material.
const OUTLINE = preload("res://shaders/overworld/interaction_outline.gdshader")
const NODE_NAME := "InteractionOutline"

var target_art: Node2D
var previous_texture: Texture2D
var previous_source := Rect2()
var previous_body := Rect2()
var previous_flip := Vector2.ZERO
var previous_width := 0.0

static func set_active(target: Node2D, active: bool) -> void:
	if not is_instance_valid(target):
		return
	var outline := target.get_node_or_null(NodePath(NODE_NAME))
	if outline == null:
		if not active:
			return
		var instance := new()
		instance.name = NODE_NAME
		instance.target_art = target
		target.add_child(instance)
		outline = instance
	outline.visible = active
	outline.set_process(active)

func _ready() -> void:
	show_behind_parent = true
	var shader_material := ShaderMaterial.new()
	shader_material.shader = OUTLINE
	material = shader_material
	_process(0.0)

func _process(_delta: float) -> void:
	var texture: Texture2D = target_art.get("texture")
	if texture == null:
		if previous_texture != null:
			previous_texture = null
			queue_redraw()
		return
	var body: Rect2
	var source := Rect2(Vector2.ZERO, texture.get_size())
	var flip := Vector2.ONE
	if target_art is Sprite2D:
		var sprite := target_art as Sprite2D
		body = sprite.get_rect()
		if sprite.region_enabled:
			source = sprite.region_rect
		else:
			source.size /= Vector2(sprite.hframes, sprite.vframes)
			source.position = Vector2(sprite.frame_coords) * source.size
		flip = Vector2(-1 if sprite.flip_h else 1, -1 if sprite.flip_v else 1)
	else:
		body = target_art.get_meta("interaction_outline_rect", Rect2())
	if not body.has_area():
		return
	var texel := body.size.x / maxf(source.size.x, 1.0)
	var width := maxf(1.5 / maxf(absf(target_art.global_scale.x), 0.01), texel)
	if texture == previous_texture and source == previous_source and body == previous_body and flip == previous_flip and is_equal_approx(width, previous_width):
		return
	previous_texture = texture
	previous_source = source
	previous_body = body
	previous_flip = flip
	previous_width = width
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("sprite_texture", texture)
	shader_material.set_shader_parameter("source_rect", Vector4(source.position.x, source.position.y, source.size.x, source.size.y))
	shader_material.set_shader_parameter("body_rect", Vector4(body.position.x, body.position.y, body.size.x, body.size.y))
	shader_material.set_shader_parameter("flip_axis", flip)
	shader_material.set_shader_parameter("stroke_width", width)
	queue_redraw()

func _draw() -> void:
	if previous_texture != null and previous_body.has_area():
		draw_rect(previous_body.grow(previous_width), Color.WHITE)
