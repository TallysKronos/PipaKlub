extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Story=preload("res://scripts/campaign/endgame_story.gd")
const QA=preload("res://scripts/campaign/qa_jump.gd")
const State=preload("res://scripts/campaign/state.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
var checks:=0
var failures:=0
class FailingStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_saved: Dictionary) -> Dictionary:return {"status":"io_error"}
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr(message)
func _initialize() -> void:run.call_deferred()
func dialog(front: Node) -> Node:
	for node in front.get_children():
		if node.get("ok_button_text")=="Continuar" and node.has_signal("confirmed") and not node.is_queued_for_deletion():return node
	return null
func close_notices(front: Node) -> void:
	for node in front.get_children():
		if node.get("ok_button_text")=="Entendi" and node.has_signal("confirmed") and not node.is_queued_for_deletion():node._finish(true)
func run() -> void:
	root.size=Vector2i(1280,720)
	var front:=Front.new()
	root.add_child(front)
	await process_frame
	front.preferences.reduced_motion=not "--motion" in OS.get_cmdline_user_args()
	var disk=preload("res://scripts/campaign/save_store.gd").new("user://champions-meeting-"+State.new_id())
	front.session._store=disk
	front.session.start("slot-1")
	var fixture: Dictionary=QA.build("reuniao")
	fixture.player.flags.demoEndingSeen=true
	var at: Vector2=Story.point("kronasta-centro-a",Story.STEPS.reuniao.anchor)+Vector2(-1.5,0)
	fixture.checkpoint=CP.make("kronasta-centro-a",at,CP.SPACE)
	front.session.checkpoint(fixture.checkpoint,fixture.player)
	front._show_saved()
	var start:=Time.get_ticks_msec()
	while (not is_instance_valid(front.park) or is_instance_valid(front.scene_loading) or front.flow_busy) and Time.get_ticks_msec()-start<10000:await process_frame
	check(is_instance_valid(front.park),"plaza loaded")
	if not is_instance_valid(front.park):quit(1);return
	var view: Node2D=front.park
	var camera_before: Vector2=view.camera.position
	front._endgame_step("reuniao")
	var panel:=dialog(front)
	check(panel!=null,"meeting dialogue opens")
	if panel==null:quit(1);return
	var cast: Node2D=view.actors.get_node("EndgameStaging")
	check(cast.get_child_count()==7,"all seven champions accompany Mikka")
	check(cast.has_node("Dona Neve") and cast.get_node("Dona Neve").get_meta("placeholder",false),"Neve has the authorized professor mock")
	for first: Node2D in cast.get_children():
		check(view.model.point_walkable(first.get_meta("ground_point")),"champion is on walkable ground")
		check(view.model.cell_at(Vector2i(first.get_meta("ground_point"))).get("ramp")==null,"champion stands clear of stairs and ramps")
		for second: Node2D in cast.get_children():
			if first!=second:
				check(first.position.distance_to(second.position)>=64.0,"champions remain separated")
				check(absf(first.position.x-second.position.x)>=60.0 or absf(first.position.y-second.position.y)>=100.0,"champion silhouettes do not overlap")
	var marker: Node2D=view.actors.get_node("MeetingSpeaker")
	for index in panel.pages.size():
		var speaker: String=panel.pages[panel.page_index].speaker
		check(marker.visible and marker.get_meta("speaker","")==speaker,"world highlight follows "+speaker)
		if (index==0 or speaker=="Dona Neve") and "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var folder:=ProjectSettings.globalize_path("res://../tmp/meeting-review")
			DirAccess.make_dir_recursive_absolute(folder)
			root.get_texture().get_image().save_png(folder.path_join("meeting.png" if index==0 else "neve.png"))
		panel.next_page()
	panel._finish(false)
	for frame in 4:await process_frame
	check(not front.session.snapshot().player.flags.get("reuniaoCampeoes",false),"cancel does not complete the meeting")
	check(not view.actors.has_node("EndgameStaging") and not view.actors.has_node("MeetingSpeaker"),"cancel cleans cast and marker")
	check(view.camera.position.distance_to(camera_before)<.01 and not view.paused,"cancel restores camera and exploration")
	front.session._store=FailingStore.new()
	front._endgame_step("reuniao")
	dialog(front)._finish(true)
	for frame in 4:await process_frame
	check(not front.session.snapshot().player.flags.get("reuniaoCampeoes",false),"failed save keeps meeting available")
	close_notices(front)
	for frame in 3:await process_frame
	front.session._store=disk
	front._endgame_step("reuniao")
	dialog(front)._finish(true)
	start=Time.get_ticks_msec()
	while (front.flow_busy or view.actors.has_node("EndgameStaging")) and Time.get_ticks_msec()-start<10000:await process_frame
	for frame in 3:await process_frame
	close_notices(front)
	for frame in 3:await process_frame
	check(front.session.snapshot().player.flags.get("reuniaoCampeoes",false),"meeting completes")
	check(Story.ready(front.session.snapshot().player,"exame-vermelho"),"Vermelha evaluation is the next step")
	check(not view.actors.has_node("MeetingSpeaker") and not view.actors.has_node("EndgameStaging"),"successful exit cleans temporary actors")
	check(not view.paused and not front.flow_busy and view.camera.position.distance_to(camera_before)<.01,"control and camera restored")
	check(front.session.resume_slot("slot-1").status=="ok" and not Story.ready(front.session.snapshot().player,"reuniao"),"completed meeting does not repeat after loading")
	for voice in front.sound.get_children():
		if voice is AudioStreamPlayer:voice.stop();voice.stream=null
	front.queue_free()
	await process_frame
	await process_frame
	print("CHAMPIONS MEETING: %d checks; %d failures"%[checks,failures])
	quit(int(failures>0))
