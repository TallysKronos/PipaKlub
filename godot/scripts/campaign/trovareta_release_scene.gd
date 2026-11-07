extends Node
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")
signal beat_finished(beat: String)
var capture_folder:=""
var world: Node2D

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func play(view: Node2D, reduced: bool) -> bool:
	world=view
	var cast: Node2D=view.actors.get_node_or_null("StormCast")
	if cast==null or not cast.has_node("TrovaretaBound"):return false
	var mon: Sprite2D=cast.get_node("TrovaretaBound")
	var cord: Line2D=cast.get_node("CarretelLine")
	var old_camera: Vector2=view.camera.position
	var old_zoom: Vector2=view.camera.zoom
	var had_hud: bool=view.exploration_hud.visible
	var map_visible: bool=is_instance_valid(view.exploration_hud.map) and view.exploration_hud.map.visible
	view.exploration_hud.hide()
	if is_instance_valid(view.exploration_hud.map):view.exploration_hud.map.hide()
	view.camera.position=(view.model.project(view.player)+mon.position)*.5+Vector2(0,-35)
	view.camera.zoom=Vector2.ONE
	var broken:=Node2D.new()
	broken.name="BrokenLine"
	cast.add_child(broken)
	var source: Vector2=cord.points[0]
	var target: Vector2=cord.points[-1]
	var middle:=source.lerp(target,.5)
	cord.hide()
	for endpoints in [[source,middle],[middle,target]]:
		var strand:=Line2D.new()
		strand.width=3.0
		strand.default_color=Tokens.CAROL_STRAND
		strand.points=PackedVector2Array(endpoints)
		broken.add_child(strand)
	if not reduced:
		var snap:=create_tween().set_parallel(true)
		snap.tween_method(func(t: float):
			broken.get_child(0).points=PackedVector2Array([source,middle.lerp(source,t)])
			broken.get_child(1).points=PackedVector2Array([middle.lerp(target,t),target]),0.0,1.0,.45)
		snap.tween_property(mon,"modulate",Tokens.UNTINTED,.45)
		await snap.finished
	else:mon.modulate=Tokens.UNTINTED
	broken.queue_free()
	await capture("line-broken")
	beat_finished.emit("line")
	mon.clip="flight"
	mon.age=0.0
	if not reduced:
		var flight:=create_tween().set_parallel(true)
		flight.tween_property(mon,"position",mon.position+Vector2(90,-210),1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		flight.tween_property(mon,"modulate:a",0.0,1.25).set_delay(.2)
		var sky: Node=view.exploration_hud.get_parent()
		for id in ["StoryRain","StoryLight"]:
			var effect:=sky.get_node_or_null(id)
			if effect==null:continue
			if id=="StoryLight":flight.tween_property(effect,"color",Tokens.UNTINTED,1.0)
			else:
				var rain_material: ShaderMaterial=effect.material
				flight.tween_method(func(amount: float):rain_material.set_shader_parameter("strength",amount),1.0,0.0,1.0)
		await get_tree().create_timer(.6).timeout
		await capture("taking-flight")
		await flight.finished
	else:mon.hide()
	beat_finished.emit("flight")
	var released: Dictionary=view.saved_player.duplicate(true)
	released.flags.trovaretaReleasePending=false
	view.refresh(released)
	cast=view.actors.get_node_or_null("StormCast")
	if cast==null or not cast.has_node("RatoWatching"):restore(view,old_camera,old_zoom,had_hud,map_visible);return false
	var rato: Sprite2D=cast.get_node("RatoWatching")
	var destination: Vector2=rato.get_meta("ground_point")
	var route:=PackedVector2Array()
	for delta in [Vector2(-2,0),Vector2(0,2),Vector2(2,0),Vector2(0,-2)]:
		var start: Vector2=destination+delta
		if not view.model.point_walkable(start) or absf(view.model.height_at(start)-view.model.height_at(destination))>.25:continue
		var candidate: PackedVector2Array=view.model.path_to(start,destination)
		var safe:=not candidate.is_empty()
		for step: Vector2 in candidate:
			if view.model.project(step).distance_to(view.model.project(view.player))<65.0:safe=false
		if safe:route=candidate;break
	if route.is_empty():restore(view,old_camera,old_zoom,had_hud,map_visible);return false
	if not reduced:
		rato.position=view.model.project(route[0])
		for step: Vector2 in route:
			var goal: Vector2=view.model.project(step)
			var motion:=goal-rato.position
			if motion.length_squared()<.01:continue
			var facing:=posmod(roundi(-motion.angle()/(PI/4.0)),8)
			rato.region_rect=Rect2(facing*64,0,64,96)
			var walk:=create_tween()
			walk.tween_property(rato,"position",goal,maxf(.08,rato.position.distance_to(goal)/110.0))
			await walk.finished
		rato.region_rect=Rect2(448,0,64,96)
	await capture("rato-arrived")
	beat_finished.emit("rato")
	restore(view,old_camera,old_zoom,had_hud,map_visible)
	return true

func restore(view: Node2D, camera: Vector2, zoom: Vector2, hud: bool, map_visible: bool) -> void:
	view.camera.position=camera
	view.camera.zoom=zoom
	view.exploration_hud.visible=hud
	if is_instance_valid(view.exploration_hud.map):view.exploration_hud.map.visible=map_visible

func capture(filename: String) -> void:
	if capture_folder.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(capture_folder)
	await RenderingServer.frame_post_draw
	world.get_viewport().get_texture().get_image().save_png(capture_folder.path_join(filename+".png"))
