extends SceneTree
## Cosmetic receive-item flow, isolated fixture. Never grants inventory or writes saves.
var view: Node2D
var failures: Array[String]=[]
var notices := {}
var output := "res://../documentation/overworld/kael-item-v1"
func _initialize() -> void:call_deferred("review")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))
func review() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	view=load("res://scripts/campaign/park_view.gd").new()
	view.saved_player={"name":"Kael","partners":[],"flags":{},"openedChests":["lookout"],"coins":0,"inventory":{}}
	root.add_child(view);view.set_physics_process(false)
	view.action_requested.connect(func(id: String):failures.append("presentation emitted gameplay action: "+id))
	var point: Vector2=load("res://scripts/campaign/park_data.gd").CHESTS.lookout.point
	view.player=point+Vector2(20,0);view.follower=point+Vector2(0,25)
	view._refresh_positions();view.camera.position=view.landscape.project(view.player)
	view.camera.position_smoothing_enabled=false;view.avatar.facing="nw"
	await create_timer(.8).timeout
	var saved: Dictionary=view.saved_player.duplicate(true)
	var position: Vector2=view.player
	view.route=PackedVector2Array([view.player+Vector2(10,0)])
	check(view.celebrate_item("Baú encontrado · Rabiola de Azulão"),"confirmed receipt starts")
	check(view.route.is_empty(),"old click route cleared")
	check(not view.celebrate_item("duplicate"),"reentry rejected")
	view._interact()
	check(not view._start_jump(),"cannot jump during receipt")
	view.paused=true;view._physics_process(.5)
	check(view.item_receipt.elapsed==0,"pause freezes pose")
	view.paused=false
	for frame in 44:
		if not view.item_receipt.is_empty():view._advance_item_receipt(.05)
		for notice in view.exploration_hud.notices:notices[notice.panel.get_instance_id()]=true
		check(view.player==position,"feet do not translate")
		await capture("frame-%03d"%frame)
	check(view.item_receipt.is_empty(),"one-shot completes")
	check(view.avatar.facing=="s" and view.avatar.item_time<0,"returns to front-facing idle")
	check(notices.size()==1,"one acquisition notice")
	check(view.saved_player==saved,"presentation never modifies rewards or flags")
	check(view.avatar._timed_frame(view.avatar.item_frames,0)==0,"first pose")
	check(view.avatar._timed_frame(view.avatar.item_frames,1)==15,"last pose clamps")
	FileAccess.open(output.path_join("review.json"),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"noticeCount":notices.size(),"inventoryWrites":false,"campaignWrites":false,"resolution":[1280,720]},"  "))
	for failure in failures:push_error(failure)
	print("Item receipt: facing, stationary support, timing, pause, input/reentry lock, one notice, zero reward writes; failures=",failures.size())
	view.free();quit(0 if failures.is_empty() else 1)
