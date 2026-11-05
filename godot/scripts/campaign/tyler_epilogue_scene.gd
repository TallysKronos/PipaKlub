extends Node2D
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")
const Navigation=preload("res://scripts/campaign/tutorial_staging.gd")
var world: Node2D
var tyler: Sprite2D
var point: Vector2
var footprint: Dictionary
var reduced_motion := false
var previous_scale: Vector2
var previous_position: Vector2
var flower: Node2D
var hidden_npcs: Array[CanvasItem]=[]

func configure(room: Node2D, reduced: bool) -> bool:
	name="TylerEpilogue"
	world=room
	previous_scale=world.scale
	previous_position=world.position
	reduced_motion=reduced
	for offset in [Vector2(120,-48),Vector2(-120,48),Vector2(0,-144),Vector2(144,0)]:
		if room._safe(room.actor+offset):
			point=room.actor+offset
			break
	if point==Vector2.ZERO:return false
	for npc in [room.mother_sprite,room.get_node_or_null("RetalhoAtelie")]:
		if is_instance_valid(npc) and npc.visible:
			hidden_npcs.append(npc)
			npc.hide()
	tyler=Sprite2D.new()
	tyler.texture=load("res://assets/campaign/tyler-clareira-v1/tyler-overworld-idle-eight.png")
	tyler.region_enabled=true
	tyler.region_rect=Rect2(192,96,64,96)
	tyler.offset.y=-48
	tyler.scale=Vector2.ONE*room.avatar.scale.y
	add_child(tyler)
	position=room.project(point)
	footprint={"node":self,"rect":room._foot(point),"layer":""}
	room.props.append(footprint)
	room.face_actor(point)
	face_tyler(room.project(room.actor)-position)
	room._update_order()
	var focus: Vector2=room.project((room.actor+point)*.5)
	var viewport_size: Vector2=room.get_viewport_rect().size
	var destination: Vector2=room.get_parent().get_global_transform().affine_inverse()*Vector2(viewport_size.x*.5,viewport_size.y*.34)
	world.scale=previous_scale*1.5
	world.position=destination-focus*world.scale
	return true

func give_flower() -> void:
	world.can_walk=false
	world.set_story_paused(false)
	world.face_actor(point)
	flower=Node2D.new()
	flower.name="CherryBlossom"
	flower.z_index=200
	world.add_child(flower)
	for petal in 5:
		var shape:=Polygon2D.new()
		shape.color=Tokens.CHERRY_BLOSSOM
		var vertices:=PackedVector2Array()
		for index in 10:
			var angle:=float(index)*TAU/10.0
			vertices.append(Vector2(cos(angle)*4,sin(angle)*7)+Vector2(0,-5))
		shape.polygon=vertices
		shape.rotation=float(petal)*TAU/5.0
		flower.add_child(shape)
	var start: Vector2=world.project(world.actor)+Vector2(0,-42)
	var end: Vector2=world.project(point)+Vector2(0,-42)
	flower.position=start
	if reduced_motion:
		flower.position=end
		return
	var pass_item:=create_tween()
	pass_item.tween_property(flower,"position",end,.65).set_trans(Tween.TRANS_SINE)
	await pass_item.finished
	var reaction:=create_tween()
	reaction.tween_property(tyler,"rotation",-.07,.22)
	reaction.tween_property(tyler,"rotation",0.0,.28)
	await reaction.finished

func leave_together() -> bool:
	var exit_point:=Vector2.INF
	for hotspot in world.data.hotspots:
		if hotspot.id=="exit":exit_point=Vector2(hotspot.x,hotspot.y)
	if not exit_point.is_finite():return false
	var target:=exit_point+Vector2(-96,-48)
	if not world._safe(target):return false
	var actor_before: Vector2=world.actor
	world.actor=point
	var route: Array=Navigation.route(world,target)
	world.actor=actor_before
	if route.is_empty():return false
	if is_instance_valid(flower):flower.queue_free()
	for next: Vector2 in route:
		if reduced_motion:point=next
		else:
			var move:=create_tween()
			move.tween_method(func(at: Vector2):
				face_tyler(world.project(at)-world.project(point))
				point=at
				position=world.project(point)
				footprint.rect=world._foot(point)
				world._update_order(),point,next,point.distance_to(next)/260.0)
			await move.finished
		position=world.project(point)
		footprint.rect=world._foot(point)
		world._update_order()
	if reduced_motion:
		if Navigation.route(world,exit_point).is_empty():return false
		world.actor=exit_point
		world.opening_pose()
	else:
		if not await Navigation.approach(world,exit_point):return false
	return true

func dispose() -> void:
	for npc in hidden_npcs:
		if is_instance_valid(npc):npc.show()
	if is_instance_valid(world):
		world.scale=previous_scale
		world.position=previous_position
		world.props.erase(footprint)
	if is_instance_valid(flower):flower.queue_free()
	queue_free()

func face_tyler(direction: Vector2) -> void:
	if direction.length_squared()<.001:return
	var index:=posmod(roundi(direction.angle()/(PI/4.0))+6,8)
	tyler.region_rect=Rect2((index%4)*64,(index/4)*96,64,96)