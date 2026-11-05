extends CanvasLayer
## Brief cutaways into the actual city maps. No campaign mutation or player travel.
signal restored(scene: String)
var current_view: Node2D
var last_soul: Node2D
var capture_folder:=""

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func play(player: Dictionary, content: Dictionary, reduced: bool) -> void:
	name="CityRestoration"
	layer=30
	var screen:=SubViewportContainer.new()
	screen.size=get_viewport().get_visible_rect().size
	screen.stretch=true
	screen.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(screen)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(screen.size)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	screen.add_child(viewport)
	for scene: String in ["kronasta-centro-b","kronasta-lajes-a"]:
		var checkpoint=load("res://scripts/campaign/park_checkpoint.gd")
		var story=load("res://scripts/campaign/endgame_story.gd")
		var id:="desalmado-centro" if scene=="kronasta-centro-b" else "desalmado-lajes"
		var at: Vector2=story.point(scene,story.STEPS[id].anchor)
		var view=load("res://scripts/campaign/park_overworld_view.gd").new()
		current_view=view
		view.saved_checkpoint=checkpoint.make(scene,checkpoint.spawn(scene),checkpoint.SPACE)
		view.saved_player=player.duplicate(true)
		view.saved_player.flags.tylerCreatedKnown=true
		view.saved_player.flags.geradorLigado=false
		view.reduced_motion=reduced
		view.content=content
		viewport.add_child(view)
		view.paused=true
		view.set_physics_process(false)
		view.exploration_hud.hide()
		if is_instance_valid(view.exploration_hud.map):view.exploration_hud.map.hide()
		view.player_root.hide()
		view.follower_root.hide()
		view.camera.position_smoothing_enabled=false
		view.camera.position=view.model.project(at)+Vector2(0,-30)
		view.camera.zoom=Vector2.ONE*1.25
		for actor: Dictionary in view.npc_nodes:
			if actor.root.get_meta("event",{}).get("props",{}).get("step","")==id:
				last_soul=actor.visual.get_node("CitySoul")
		await get_tree().process_frame
		if not is_instance_valid(last_soul):
			viewport.remove_child(view)
			view.queue_free()
			current_view=null
			continue
		await capture(viewport,id+"-before")
		if not reduced:await get_tree().create_timer(.45).timeout
		var mote:=Polygon2D.new()
		mote.color=Color("#fff0b0")
		mote.polygon=PackedVector2Array([Vector2(0,-8),Vector2(5,0),Vector2(0,8),Vector2(-5,0)])
		var hand: Vector2=view.model.project(at)+Vector2(0,-42)
		mote.position=hand+Vector2(-90,-110)
		view.actors.add_child(mote)
		var veil: CanvasItem=view.exploration_hud.get_parent().get_node_or_null("StoryLight")
		if reduced:
			last_soul.set_life(1.0)
			mote.hide()
			if veil!=null:veil.modulate.a=0.0
		else:
			var arrival:=create_tween()
			arrival.tween_property(mote,"position",hand,.65).set_trans(Tween.TRANS_SINE)
			await arrival.finished
			var restore:=create_tween().set_parallel(true)
			restore.tween_method(last_soul.set_life,0.0,1.0,.65)
			restore.tween_property(mote,"modulate:a",0.0,.65)
			if veil!=null:restore.tween_property(veil,"modulate:a",0.0,.65)
			await restore.finished
		await capture(viewport,id+"-after")
		restored.emit(scene)
		await get_tree().create_timer(.3 if reduced else .7).timeout
		last_soul=null
		viewport.remove_child(view)
		view.queue_free()
		await get_tree().process_frame
		current_view=null
	screen.queue_free()

func capture(viewport: SubViewport, filename: String) -> void:
	if capture_folder.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(capture_folder)
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(capture_folder.path_join(filename+".png"))
