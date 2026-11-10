extends RefCounted

const PLATYX := preload("res://assets/campaign/beira-canal-v1/platyx-overworld-eight.png")
const AVATAR := preload("res://scripts/kael_video_avatar.gd")

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
	if view.campaign_mode and view.get("saved_player").get("flags", {}).get("ruinasJamileLivre", false):
		sprite.hide()
	return sprite

static func refuse(view, reduced_motion: bool) -> void:
	var sprite := view.actors.get_node_or_null("PlatyxOverworld") as Sprite2D
	if sprite == null:
		return
	sprite.show()
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
	if visual != null:
		var reel := preload("res://scripts/campaign/tyler_reel_prop.gd").new()
		reel.position = Vector2(12, -34)
		visual.add_child(reel)
		movement.tween_property(reel, "position", Vector2(20, -5), .3)
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

static func leave_for_chamber(view) -> void:
	var platyx := view.actors.get_node_or_null("PlatyxOverworld") as Sprite2D
	if platyx == null: return
	for actor in view.npc_nodes:
		if actor.root.get_meta("event").props.get("acao") != "ruinasDuel": continue
		var route: PackedVector2Array = view.model.path_to(actor.point, Vector2(25.5, 6.5))
		if route.is_empty(): return
		var grampo: Node2D = actor.root
		var grampo_sprite := actor.visual.get_child(0) as Sprite2D
		var walk: Tween = view.create_tween()
		var previous: Vector2 = actor.point
		var platyx_from := platyx.position
		for step in route:
			var duration := previous.distance_to(step) * .16
			if duration <= 0.0: continue
			var target: Vector2 = view.model.project(step)
			var trail: Vector2 = view.model.project(previous)
			var grampo_frame := facing_index(target - trail)
			var platyx_frame := facing_index(trail - platyx_from, platyx.frame)
			walk.tween_callback(func():
				if grampo_sprite != null:
					grampo_sprite.region_rect.position = Vector2((grampo_frame % 4) * 64, floori(grampo_frame / 4.0) * 96)
				platyx.frame = platyx_frame)
			walk.tween_method(func(point: Vector2):
				view._place_actor(grampo, actor.visual, point, 84.0), previous, step, duration)
			walk.parallel().tween_property(platyx, "position", trail, duration)
			platyx_from = trail
			previous = step
		var exit_point: Vector2 = view.model.project(route[-1])
		walk.tween_callback(func(): platyx.frame = facing_index(exit_point - platyx.position, platyx.frame))
		walk.tween_property(grampo, "modulate:a", 0.0, .22)
		walk.parallel().tween_property(platyx, "position", exit_point, .22)
		walk.parallel().tween_property(platyx, "modulate:a", 0.0, .22)
		await walk.finished
		grampo.hide()
		platyx.hide()
		return

static func facing_index(direction: Vector2, fallback: int = 7) -> int:
	return AVATAR.DIRECTIONS.find(AVATAR.facing_for(direction, AVATAR.DIRECTIONS[fallback]))
