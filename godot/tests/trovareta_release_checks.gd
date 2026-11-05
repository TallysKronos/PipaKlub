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
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:failures+=1;printerr(message)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	var front:=Front.new()
	root.add_child(front)
	await process_frame
	front.preferences.reduced_motion=not "--motion" in OS.get_cmdline_user_args()
	var disk=preload("res://scripts/campaign/save_store.gd").new("user://trovareta-release-"+State.new_id())
	front.session._store=disk
	front.session.start("slot-1")
	var fixture: Dictionary=QA.build("trovareta")
	fixture.player.flags.demoEndingSeen=true
	fixture.player.flags["endgame-trovareta-0"]=true
	var at: Vector2=Story.point("kronasta-bosque-c",Story.STEPS.trovareta.anchor)+Vector2(-1.5,0)
	fixture.checkpoint=CP.make("kronasta-bosque-c",at,CP.SPACE)
	for outcome in ["lost","fled","won"]:
		check(front.session.checkpoint(fixture.checkpoint,fixture.player).status=="ok","fixture: "+outcome)
		var story=Story.new(front.session)
		check(story.begin("trovareta",at).status=="ok","duel begins: "+outcome)
		var saved: Dictionary=front.session.snapshot()
		saved.player.encounter.state.outcome=outcome
		front.session.checkpoint(saved.checkpoint,saved.player)
		check(story.settle().status=="ok","duel settles: "+outcome)
		check(Story.release_pending(front.session.snapshot())==(outcome=="won"),"release only follows victory")
	preload("res://scripts/campaign/pipeiro_identity.gd").ensure_legacy(front.session)
	preload("res://scripts/campaign/district_badges.gd").ensure_legacy(front.session)
	var before: Dictionary=front.session.snapshot()
	check(front.session.resume_slot("slot-1").status=="ok" and Story.release_pending(front.session.snapshot()),"interrupted return resumes the pending scene")
	front.session._store=FailingStore.new()
	check(Story.new(front.session).finish_release().status=="io_error","failed presentation save reported")
	check(Story.release_pending(front.session.snapshot()),"failed save preserves pending presentation")
	front.session._store=disk
	var beats: Array[String]=[]
	front.child_entered_tree.connect(func(node: Node):
		if node.name!="TrovaretaRelease":return
		if "--capture" in OS.get_cmdline_user_args():node.capture_folder=ProjectSettings.globalize_path("res://../tmp/trovareta-release-review")
		node.beat_finished.connect(func(beat: String):
			beats.append(beat)
			var dialogs:=front.get_children().filter(func(c):return c.get("ok_button_text")!=null and c.visible and not c.is_queued_for_deletion())
			check(dialogs.is_empty(),"dialogue waits until staging finishes: "+beat)))
	front._show_saved()
	var start:=Time.get_ticks_msec()
	var dialogue: Node
	while Time.get_ticks_msec()-start<20000:
		for child in front.get_children():
			if beats.size()==3 and child.get("ok_button_text")=="Continuar" and child.has_signal("confirmed"):dialogue=child
		if dialogue!=null:break
		await process_frame
	for frame in 4:await process_frame
	check(beats==["line","flight","rato"],"line, departure and Rato occur in order")
	check(Story.release_pending(front.session.snapshot()),"closing dialogue remains resumable until acknowledged")
	check(front.session.resume_slot("slot-1").status=="ok" and Story.release_pending(front.session.snapshot()),"quit during the closing dialogue preserves the scene in the saved slot")
	check(dialogue!=null,"Rato speaks after arriving")
	if dialogue!=null:dialogue._finish(true)
	for frame in 3:await process_frame
	check(not Story.release_pending(front.session.snapshot()) and front.session.snapshot().player.flags.get("trovaretaReleaseSeen",false),"presentation completion saved after dialogue")
	check(not front.flow_busy and not front.park.paused,"exploration restored after dialogue")
	check(front.session.snapshot().checkpoint==before.checkpoint,"staging preserves the return position")
	var inventory: Dictionary=front.session.snapshot().player.inventory
	check(inventory.size()==before.player.inventory.size() and before.player.inventory.keys().all(func(key):return inventory.has(key) and int(inventory[key])==int(before.player.inventory[key])),"staging grants no extra items")
	check(front.get_node_or_null("TrovaretaRelease")==null,"temporary scene cleaned")
	check(front.session.resume_slot("slot-1").status=="ok" and not Story.release_pending(front.session.snapshot()),"completed scene does not replay on resume")
	for voice in front.sound.get_children():
		if voice is AudioStreamPlayer:voice.stop();voice.stream=null
	front.queue_free()
	await process_frame
	await process_frame
	print("TROVARETA RELEASE: %d checks; %d failures"%[checks,failures])
	quit(int(failures>0))
