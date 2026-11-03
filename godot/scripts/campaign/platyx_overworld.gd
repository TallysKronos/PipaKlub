extends RefCounted

const PLATYX := preload("res://assets/campaign/beira-canal-v1/platyx-overworld-eight.png")

static func place(view) -> Sprite2D:
	var grampo := Vector2(24.5, 16.5)
	var sprite := Sprite2D.new()
	sprite.name = "PlatyxOverworld"
	sprite.texture = PLATYX
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.frame = 7
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 1.0
	sprite.offset.y = -44.0
	sprite.position = view.model.project(grampo + Vector2(1, 0))
	view.actors.add_child(sprite)
	return sprite

static func refuse(view, reduced_motion: bool) -> void:
	var sprite := view.actors.get_node_or_null("PlatyxOverworld") as Sprite2D
	if sprite == null:
		return
	var jamile := Vector2(25.5, 14.5)
	var grampo := Vector2(24.5, 16.5)
	var shield: Vector2 = view.model.project(grampo.lerp(jamile, .72))
	var contact: Vector2 = view.model.project(grampo + Vector2(.68, -.42))
	var camera: Camera2D = view.camera
	var original_offset := camera.offset
	var focus: Vector2 = view.model.project(grampo.lerp(jamile, .5))
	var movement: Tween = view.create_tween()
	var retreat := Vector2(24.5, 19.5)
	if view.model.point_walkable(retreat):
		movement.tween_method(func(point: Vector2):
			view.player = point
			view.follower = point + Vector2(.6, .6)
			view._refresh_positions(), Vector2(view.player), retreat, .35)
	if not reduced_motion:
		var target := original_offset + (focus - camera.get_screen_center_position()) * .55
		movement.tween_property(camera, "offset", target, .32).set_trans(Tween.TRANS_SINE)
	sprite.frame = 5 if shield.x > sprite.position.x else 3
	movement.tween_property(sprite, "position", shield, .55).set_trans(Tween.TRANS_SINE)
	movement.tween_interval(.52)
	movement.tween_callback(func(): sprite.frame = 1 if contact.x < shield.x else 7)
	movement.tween_property(sprite, "position", contact, .65).set_trans(Tween.TRANS_SINE)
	var visual: Node2D
	for actor in view.npc_nodes:
		if actor.point == grampo:
			actor.root.show()
			visual = actor.visual
			break
	movement.tween_property(sprite, "rotation", -.16, .25)
	if visual != null:
		movement.parallel().tween_property(visual, "rotation", .10, .25)
	movement.tween_interval(.52)
	movement.tween_property(sprite, "rotation", 0.0, .25)
	if visual != null:
		movement.parallel().tween_property(visual, "rotation", 0.0, .25)
	if not reduced_motion:
		movement.tween_property(camera, "offset", original_offset, .28).set_trans(Tween.TRANS_SINE)
	await movement.finished
