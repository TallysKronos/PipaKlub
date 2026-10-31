extends Node2D
const Controls = preload("res://scripts/campaign/controls.gd")
const CompanionFollow = preload("res://scripts/campaign/companion_follow.gd")
const Locomotion = preload("res://scripts/campaign/locomotion.gd")
## Uses the original room coordinates, footprints and 2:1 projection.
signal interacted(id: String)
const Avatar = preload("res://scripts/avatar.gd")
const NpcPixels = preload("res://scripts/npc_pixel_sprite.gd")
var data: Dictionary
var actor := Vector2.ZERO
var can_walk := false
var target_hotspot := ""
var avatar: Node2D
var props: Array[Dictionary] = []
var camera: Dictionary
var near := ""
var companion: Sprite2D
var companion_frames: Array = []
var companion_point := Vector2.ZERO
var trail: Array[Vector2] = []
var clock := 0.0
var mother_sprite: Sprite2D
var mother_point := Vector2.ZERO
var mother_facing := 0
var mother_walking := false
var mother_reveal := 1.0
var story_paused := false
var cinematic_actor_moving := false
var companion_follow := true
var opening_tv: Node2D
var target_marker: Node2D

func configure(room: Dictionary, point: Array, walk: bool, target: String, mother: bool, partner: bool) -> void:
	for child in get_children():
		child.free()
	props.clear()
	companion = null
	mother_sprite = null
	companion_frames.clear()
	trail.clear()
	data = room
	target_marker=Node2D.new()
	target_marker.z_index=250
	target_marker.draw.connect(_draw_target)
	add_child(target_marker)
	camera = data.camera
	actor = Vector2(point[0], point[1])
	can_walk = walk
	target_hotspot = target
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = load("res://assets/campaign/" + data.floorImage)
	floor_sprite.centered = false
	floor_sprite.z_index = 0
	add_child(floor_sprite)
	for prop in data.props:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/campaign/" + prop.image)
		sprite.centered = false
		sprite.position = Vector2(prop.rect[0], prop.rect[1])
		sprite.scale = Vector2(prop.rect[2], prop.rect[3]) / sprite.texture.get_size()
		add_child(sprite)
		props.append({"node": sprite, "rect": prop.footprint, "layer": "flat" if prop.kind == "flat" else "wall" if prop.kind.begins_with("wall") else ""})
	avatar = Avatar.new()
	add_child(avatar)
	avatar.scale = Vector2.ONE * .80 * Avatar.BODY_SCALE * float(camera.scale)
	props.append({"node": avatar, "rect": {}, "layer": "", "actor": true})
	if mother:
		var npc := Sprite2D.new()
		if data.get("id") == "professor":
			NpcPixels.setup(npc,"professor",NpcPixels.height_for("professor",avatar.scale.y))
		else:
			NpcPixels.setup(npc,"mae",NpcPixels.height_for("mae",avatar.scale.y))
		var location: Array = data.layout.blocking.mother
		mother_point=Vector2(location[0],location[1])
		mother_sprite=npc
		npc.position = project(Vector2(location[0], location[1]))
		add_child(npc)
		props.append({"node": npc, "rect": _foot(Vector2(location[0], location[1])), "layer": ""})
	if partner:add_companion()
	_update_order()

func add_companion() -> void:
	if not is_instance_valid(companion):
		var rabbit := Sprite2D.new()
		rabbit.texture = load("res://assets/rabbito.png")
		var atlas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rabbito.json"))
		var frame: Dictionary = atlas.frames[atlas.animations.idle[0]].frame
		rabbit.region_enabled = true
		rabbit.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
		rabbit.offset = Vector2(0, -100)
		rabbit.scale = Vector2.ONE * .27 * float(camera.scale)
		companion_point = actor + Vector2(-60, 30)
		if not _safe(companion_point):
			companion_point = actor
		rabbit.position = project(companion_point)
		companion = rabbit
		for key in atlas.animations.idle:
			companion_frames.append(atlas.frames[key].frame)
		trail.append(actor)
		add_child(rabbit)
		props.append({"node": rabbit, "rect": _foot(companion_point), "layer": "", "follower": true})
	_update_order()

func opening_pose() -> void:
	avatar.position=project(actor)
	if is_instance_valid(mother_sprite):
		mother_sprite.position=project(mother_point)+Vector2(0,(1.0-mother_reveal)*40.0*float(camera.scale))
		if data.get("id")!="professor":
			if mother_sprite.material!=null:
				NpcPixels.reveal(mother_sprite,mother_reveal)
		for item in props:
			if item.node==mother_sprite:item.rect=_foot(mother_point)
	_update_order()

func face_actor(target: Vector2) -> void:
	var direction := project(target)-project(actor)
	avatar.face_motion(direction)

func face_mother(target: Vector2) -> void:
	var direction := project(target)-project(mother_point)
	mother_facing=(2 if direction.x>0 else 1) if absf(direction.x)>absf(direction.y) else (3 if direction.y<0 else 0)
	if is_instance_valid(mother_sprite):NpcPixels.face_motion(mother_sprite,direction)

func enable_stair_reveal() -> void:
	if not is_instance_valid(mother_sprite) or mother_sprite.material!=null:return
	NpcPixels.reveal(mother_sprite,mother_reveal)

func set_story_paused(value: bool) -> void:
	story_paused=value
	avatar.set_process(not value)
	if value:avatar.moving=false; avatar.running=false
	if is_instance_valid(opening_tv):
		if opening_tv.has_method("set_cinematic_paused"):opening_tv.set_cinematic_paused(value or not opening_tv.visible)
		else:opening_tv.set_process(not value and opening_tv.visible)

func project(p: Vector2) -> Vector2:
	var point := Vector2((p.x - p.y) * .82, (p.x + p.y) * .41) if data.get("projection") == "street" else Vector2((p.x - p.y) / 3, (p.x + p.y) / 6)
	return (point - Vector2(camera.x, camera.y)) * float(camera.scale)

func _foot(p: Vector2) -> Dictionary:
	var u: float = (p.x - data.layout.floor.x) / 96
	var v: float = (p.y - data.layout.floor.y) / 96
	return {"u0": u - .12, "u1": u + .12, "v0": v - .12, "v1": v + .12}

func _behind(a: Dictionary, b: Dictionary) -> bool:
	return a.u1 <= b.u0 + .000001 or a.v1 <= b.v0 + .000001

func _update_order() -> void:
	avatar.position = project(actor)
	if data.get("projection") == "street":
		position = Vector2(480, 320) - avatar.position
	var rest: Array[Dictionary] = []
	var ordered: Array[Dictionary] = []
	for layer in ["wall", "flat"]:
		for item in props:
			if item.layer == layer:
				ordered.append(item)
	for item in props:
		if item.get("actor", false):
			item.rect = _foot(actor)
		if item.get("follower", false):
			item.rect = _foot(companion_point)
		if item.layer == "":
			rest.append(item)
	while not rest.is_empty():
		var pick := -1
		for i in rest.size():
			var blocked := false
			for j in rest.size():
				if i != j and _behind(rest[j].rect, rest[i].rect) and not _behind(rest[i].rect, rest[j].rect):
					blocked = true
					break
			if not blocked:
				pick = i
				break
		if pick < 0:
			pick = 0
			for i in rest.size():
				if rest[i].rect.u1 + rest[i].rect.v1 < rest[pick].rect.u1 + rest[pick].rect.v1:
					pick = i
		ordered.append(rest.pop_at(pick))
	for i in ordered.size():
		ordered[i].node.z_index = i + 1

func _safe(p: Vector2) -> bool:
	for dx in [-14, 0, 14]:
		for dy in [-14, 0, 14]:
			var inside := false
			for r in data.walkable:
				inside = inside or Rect2(r[0], r[1], r[2], r[3]).has_point(p + Vector2(dx, dy))
			if not inside:
				return false
	for r in data.blocked:
		if Rect2(r[0] - 14, r[1] - 14, r[2] + 28, r[3] + 28).has_point(p):
			return false
	return true

func _process(delta: float) -> void:
	if not is_instance_valid(avatar):
		return
	if story_paused:return
	clock += delta
	if is_instance_valid(target_marker):target_marker.queue_redraw()
	if is_instance_valid(mother_sprite):opening_pose()
	if is_instance_valid(companion) and companion_follow:
		var frame: Dictionary = companion_frames[int(clock * 12) % companion_frames.size()]
		companion.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
		if trail.is_empty() or trail.back().distance_to(actor) > 8:
			trail.append(actor)
		companion_point=CompanionFollow.advance(companion_point,trail,minf(delta,.05),720.0,70.0,_companion_segment)
		companion.position = project(companion_point)
		CompanionFollow.orient(companion,avatar.facing)
		_update_order()
	near = ""
	var nearest := INF
	for spot in data.hotspots:
		if target_hotspot!="*" and spot.id!=target_hotspot:continue
		var distance:=Vector2(spot.x,spot.y).distance_to(actor)
		var reach:=150.0 if spot.id=="stairs" else 110.0
		if distance<=reach and distance<nearest:
			near=spot.id;nearest=distance
	avatar.running=false
	avatar.moving = cinematic_actor_moving
	if not can_walk:
		return
	Locomotion.update()
	var input := Controls.direction()
	if input.length() < .1:
		return
	# Invert the room projection so screen directions match the player's input.
	var world := Vector2(1.5 * input.x + 3 * input.y, 3 * input.y - 1.5 * input.x).normalized() * input.length() * 360 * Locomotion.multiplier() * minf(delta, .05)
	var steps := maxi(1, ceili(world.length() / 4))
	var before := actor
	for i in steps:
		var move := world / steps
		var previous:=actor
		if _safe(actor + move):
			actor += move
		elif _safe(actor + Vector2(move.x, 0)):
			actor.x += move.x
		elif _safe(actor + Vector2(0, move.y)):
			actor.y += move.y
		if actor!=previous and is_instance_valid(companion) and companion_follow:
			if trail.is_empty():trail.append(previous)
			trail.append(actor)
	avatar.moving = actor.distance_to(before)>.01
	avatar.running=avatar.moving and Locomotion.requested()
	if avatar.moving:avatar.face_motion(project(actor)-project(before))
	if is_instance_valid(companion):CompanionFollow.orient(companion,avatar.facing)
	_update_order()

func _companion_segment(from:Vector2,to:Vector2) -> bool:
	var samples:=maxi(1,ceili(from.distance_to(to)/4.0))
	for i in range(1,samples+1):
		if not _safe(from.lerp(to,float(i)/samples)):return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if can_walk and Controls.pressed(event, "interact") and not near.is_empty() and (near == target_hotspot or target_hotspot == "*"):
		get_viewport().set_input_as_handled()
		interacted.emit(near)

func _draw_target() -> void:
	if not can_walk:return
	for spot in data.get("hotspots",[]):
		if spot.id!=target_hotspot:continue
		var at:=project(Vector2(spot.x,spot.y))
		var color:=Color("55CCD5")
		target_marker.draw_arc(at,20,0,TAU,32,color,2,true)
		target_marker.draw_colored_polygon(PackedVector2Array([at+Vector2(-7,-38),at+Vector2(7,-38),at+Vector2(0,-27)]),color)
