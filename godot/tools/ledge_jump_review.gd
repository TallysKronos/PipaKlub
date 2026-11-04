extends SceneTree
## Actual campaign view, isolated fixture; no Session, disk saves or rewards.
var view: Node2D
var failures: Array[String]=[]
var saves := 0
var output := "res://../documentation/overworld/kael-ledge-jump-v1"
func _initialize() -> void: call_deferred("review")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))
func review() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	view=load("res://scripts/campaign/park_view.gd").new()
	view.saved_player={"name":"Kael","partners":[],"flags":{},"openedChests":[],"coins":0,"inventory":{}}
	root.add_child(view)
	view.set_physics_process(false)
	view.action_requested.connect(func(id: String):
		if id=="autosave":saves+=1
		else:failures.append("unexpected campaign action while jumping: "+id))
	view.camera.position_smoothing_enabled=false
	await create_timer(.8).timeout
	for entry: Dictionary in view.jump_links:
		view.player=entry.from
		view.follower=entry.from-Vector2(12,0)
		view._refresh_positions()
		view.camera.position=view.landscape.project(entry.from)
		view.hint.text="Pular barranco · descer"
		view.hint.get_parent().show()
		await capture(entry.id+"-before")
		check(view._start_jump(),entry.id+": real view starts jump")
		check(not view._start_jump(),entry.id+": no double jump")
		var paused_at: float=view.ledge_jump.elapsed
		view.paused=true;view._physics_process(.5)
		check(view.ledge_jump.elapsed==paused_at,"pause freezes jump")
		view.paused=false
		for frame in 50:
			view._advance_jump(1.0/60)
			if frame<49:check(view.player==entry.from,"persistent point stays grounded until landing")
			if entry.id=="mirante":await capture("frame-%03d"%frame)
			elif frame in [5,18,30,45,49]:await capture(entry.id+"-%02d"%frame)
		check(view.player==entry.to,entry.id+": lands on measured destination")
		check(view.ground.walkable(view.player,2),entry.id+": final sole safe")
		check(view._near_jump().is_empty(),entry.id+": no upward return jump")
		check(view.trail.is_empty(),"no stale trail crosses cliff")
		check(not view.ledge_jump.active,"one-shot animation completed")
	check(saves==2,"one autosave event per landing")
	FileAccess.open(output.path_join("review.json"),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"landingSaveEvents":saves,"campaignWrites":false,"resolution":[1280,720]},"  "))
	for failure in failures: push_error(failure)
	print("Ledge jump campaign review: failures=",failures.size())
	view.free()
	quit(0 if failures.is_empty() else 1)
