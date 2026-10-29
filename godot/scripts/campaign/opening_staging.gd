extends RefCounted
## Presentation only: no rewards, flags or checkpoints are committed here.
## Paths stay on room floor; only explicit stair segments enter the stairwell.
static func alive(room: Node2D) -> bool:
	return is_instance_valid(room) and room.is_inside_tree()

static func wait(room: Node2D,seconds: float) -> void:
	var tree: SceneTree=room.get_tree()
	var elapsed := 0.0
	while alive(room) and elapsed<seconds:
		await tree.process_frame
		if alive(room) and not room.story_paused:elapsed+=minf(room.get_process_delta_time(),.05)

static func walk(room: Node2D,who: String,points: Array,speed: float=200.0,stair: int=0) -> void:
	if not alive(room):return
	var tree: SceneTree=room.get_tree()
	for target: Vector2 in points:
		if not alive(room):return
		var origin: Vector2=room.actor if who=="kael" else room.mother_point
		var distance := origin.distance_to(target)
		var moved := 0.0
		if who=="kael":room.face_actor(target);room.cinematic_actor_moving=true
		else:room.face_mother(target);room.mother_walking=true
		while alive(room) and moved<distance:
			await tree.process_frame
			if not alive(room):return
			if room.story_paused:continue
			moved=minf(distance,moved+speed*minf(room.get_process_delta_time(),.05))
			var t := moved/maxf(distance,.001)
			if who=="kael":room.actor=origin.lerp(target,t)
			else:
				room.mother_point=origin.lerp(target,t)
				if stair!=0:room.mother_reveal=t if stair>0 else 1.0-t
			room.opening_pose()
	if alive(room):room.cinematic_actor_moving=false;room.mother_walking=false

static func pass_tail(room: Node2D,from: Vector2,to: Vector2) -> void:
	if not alive(room):return
	var item:=Sprite2D.new()
	item.texture=preload("res://scripts/campaign/hud.gd").icon("tail")
	item.scale=Vector2.ONE*30.0/maxf(item.texture.get_width(),item.texture.get_height())
	item.z_index=200
	room.add_child(item)
	var start: Vector2=room.project(from)-Vector2(0,45)
	var finish: Vector2=room.project(to)-Vector2(0,45)
	var elapsed:=0.0
	var tree: SceneTree=room.get_tree()
	while alive(room) and elapsed<.65:
		await tree.process_frame
		if not alive(room):return
		if room.story_paused:continue
		elapsed+=minf(room.get_process_delta_time(),.05)
		var t:=clampf(elapsed/.65,0,1)
		item.position=start.lerp(finish,t)-Vector2(0,sin(t*PI)*14)
	if is_instance_valid(item):item.queue_free()

static func play(room: Node2D,step: int) -> void:
	if not alive(room):return
	room.can_walk=false
	room.companion_follow=false
	var block: Dictionary=room.data.layout.blocking
	if step<=1:
		room.face_actor(Vector2(768,384))
	elif step==2:
		if is_instance_valid(room.opening_tv):
			for i in range(10):
				if not alive(room):return
				room.opening_tv.modulate.a=1.0-float(i+1)/10.0
				await wait(room,.025)
			room.opening_tv.visible=false
			if room.opening_tv.has_method("stop_broadcast"):room.opening_tv.stop_broadcast()
			else:room.opening_tv.set_process(false)
		room.face_actor(Vector2(block.kaelDesk[0],block.kaelDesk[1]))
		await wait(room,.25)
	elif step==4:
		# Returning to the desk preserves the position reached by player movement.
		await walk(room,"kael",[Vector2(block.kaelDesk[0],block.kaelDesk[1])],190)
		room.face_actor(Vector2(1200,432))
		await wait(room,.4)
	elif step==5:
		room.mother_sprite.show();room.enable_stair_reveal()
		room.mother_point=Vector2(528,928);room.mother_reveal=0
		await walk(room,"mother",[Vector2(528,816)],150,1)
		await walk(room,"mother",[Vector2(624,784),Vector2(760,704),Vector2(880,640)],190)
		if not alive(room):return
		await walk(room,"kael",[Vector2(1120,560),Vector2(1030,610)],190)
		room.face_actor(room.mother_point);room.face_mother(room.actor)
		await wait(room,.2)
	elif step==7:
		await pass_tail(room,room.mother_point,room.actor)
	elif step==8:
		await walk(room,"kael",[Vector2(1100,640),Vector2(1200,528)],190)
		if alive(room):room.face_actor(Vector2(1200,432));room.face_mother(room.actor)
	elif step==9:
		await pass_tail(room,room.actor,Vector2(1200,432))
		if not alive(room):return
		room.add_companion()
		room.companion_point=Vector2(1145,640)
		room.companion.position=room.project(room.companion_point)
		room.companion.modulate.a=0
		for i in range(12):
			if not alive(room):return
			room.companion.modulate.a=float(i+1)/12.0
			await wait(room,.025)
		if alive(room):room.face_actor(room.companion_point)
	elif step==11:
		room.enable_stair_reveal()
		await walk(room,"mother",[Vector2(760,704),Vector2(624,784),Vector2(528,816)],190)
		await walk(room,"mother",[Vector2(528,928)],150,-1)
		if alive(room):room.mother_sprite.hide()
	elif step==12:
		room.mother_point=Vector2(1424,1104)
		room.mother_sprite.show();room.mother_reveal=1
		await walk(room,"mother",[Vector2(1240,1104),Vector2(1080,960),Vector2(960,864)],190)
		if alive(room):room.face_mother(room.actor);room.face_actor(room.mother_point)
	if alive(room):
		room.can_walk=step in [3,11,13]
		room.companion_follow=step>=11
		room.opening_pose()


static func leave(room: Node2D,step: int) -> void:
	if not alive(room):return
	room.can_walk=false
	if step==11:
		await walk(room,"kael",[Vector2(528,816)],160)
		if not alive(room):return
		room.avatar.set_motion_action("descer")
		await walk(room,"kael",[Vector2(528,872)],120)
	elif step==13:
		await walk(room,"kael",[Vector2(432,1008)],170)
	if not alive(room):return
	for i in range(10):
		if not alive(room):return
		room.avatar.modulate.a=1.0-float(i+1)/10.0
		if is_instance_valid(room.companion):room.companion.modulate.a=room.avatar.modulate.a
		await wait(room,.025)
