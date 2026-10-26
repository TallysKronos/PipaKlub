extends Node2D
## Root sorts on ground depth; art is lifted without changing the collision cell.
@export var definition: Dictionary = {}

func configure(info: Dictionary, footprint: Vector2i, level: float, blocks: bool, center_offset: Vector2 = Vector2.ZERO) -> void:
	definition = info
	var art := get_node_or_null("Art") as Sprite2D
	if art == null:
		art = Sprite2D.new()
		add_child(art)
	art.texture = load(info.texture)
	art.centered = false
	art.position = center_offset - Vector2(info.anchor[0], info.anchor[1]) - Vector2(0, level * 64)
	var contact := get_node_or_null("Contact") as Sprite2D
	if contact == null:
		contact = Sprite2D.new()
		add_child(contact)
	contact.texture = load(info.shadow_texture)
	contact.position = center_offset + Vector2(0, -level * 64)
	contact.z_index = 0
	move_child(contact,0)
	var previous := get_node_or_null("Body")
	if previous != null: remove_child(previous); previous.queue_free()
	if blocks:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		body.position = center_offset
		var collider := CollisionPolygon2D.new()
		var a := footprint.x * 32.0
		var b := footprint.y * 32.0
		collider.polygon = PackedVector2Array([Vector2((b-a)*.5, -(a+b)*.25), Vector2((a+b)*.5, (a-b)*.25), Vector2((a-b)*.5, (a+b)*.25), Vector2(-(a+b)*.5, (b-a)*.25)])
		body.add_child(collider)
		add_child(body)
	set_meta("navigation_footprint", footprint)
	set_meta("blocks", blocks)
	set_meta("center_offset", center_offset)
