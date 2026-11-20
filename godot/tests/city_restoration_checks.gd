extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const QA=preload("res://scripts/campaign/qa_jump.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Story=preload("res://scripts/campaign/endgame_story.gd")
const State=preload("res://scripts/campaign/state.gd")
var checks:=0
var failures:=0
class FailingStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot: Dictionary) -> Dictionary:return {"status":"io_error"}
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr(message)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	var front:=Front.new()
	root.add_child(front)
	await process_frame
	front.preferences.reduced_motion=not "--motion" in OS.get_cmdline_user_args()
	front.session._store=preload("res://scripts/campaign/save_store.gd").new("user://city-restoration-"+State.new_id())
	front.session.start("slot-1")
	var fixture: Dictionary=QA.build("gerador")
	fixture.player.flags.demoEndingSeen=true
	check(front.session.checkpoint(fixture.checkpoint,fixture.player).status=="ok","fixture saved")
	for id in ["desalmado-centro","desalmado-lajes"]:
		var step: Dictionary=Story.STEPS[id]
		var view=load("res://scripts/campaign/park_overworld_view.gd").new()
		view.saved_checkpoint=CP.make(step.scene,CP.spawn(step.scene),CP.SPACE)
		view.saved_player=fixture.player.duplicate(true)
		view.saved_player.flags[step.flag]=true
		view.content=front.content
		root.add_child(view)
		view.set_physics_process(false)
		var soul: Node2D
		var body: Node2D
		for actor in view.npc_nodes:
			if actor.root.get_meta("event",{}).get("props",{}).get("step","")==id:
				body=actor.root
				soul=actor.visual.get_node_or_null("CitySoul")
		check(soul!=null,"creature replaces human placeholder: "+id)
		if soul!=null:
			check(body.visible and soul.life==0.0,"calmed creature stays gray and present")
			var healed: Dictionary=view.saved_player.duplicate(true)
			healed.flags.geradorLigado=true
			view.refresh(healed)
			check(body.visible and soul.life==1.0,"healed creature stays in city")
			check(not Story.ready(healed,id),"healed creature cannot start another duel")
		view.queue_free()
		await process_frame
	front._show_saved()
	var ready_start:=Time.get_ticks_msec()
	while not is_instance_valid(front.park) and Time.get_ticks_msec()-ready_start<10000:await process_frame
	check(is_instance_valid(front.park),"mountain loaded before interaction")
	if not is_instance_valid(front.park):quit(1);return
	var original: Node2D=front.park
	var before: Dictionary=front.session.snapshot()
	front._endgame_step("gerador")
	for node in front.get_children():
		if node.get("ok_button_text")=="Continuar" and node.has_signal("canceled"):node._finish(false)
	for frame in 3:await process_frame
	check(not front.session.snapshot().player.flags.get("geradorLigado",false),"cancel preserves the uncompleted step")
	check(front.get_node_or_null("CityRestoration")==null and not original.paused,"cancel leaves exploration available")
	var disk=front.session._store
	front.session._store=FailingStore.new()
	front._endgame_step("gerador")
	for node in front.get_children():
		if node.get("ok_button_text")=="Continuar" and node.has_signal("confirmed"):node._finish(true)
	for frame in 3:await process_frame
	check(not front.session.snapshot().player.flags.get("geradorLigado",false),"failed save does not activate the generator")
	check(front.get_node_or_null("CityRestoration")==null,"failed save starts no cutaway")
	for node in front.get_children():
		if node.get("ok_button_text")!=null and node.has_signal("confirmed") and not node.is_queued_for_deletion():node._finish(true)
	for frame in 3:await process_frame
	front.session._store=disk
	front._endgame_step("gerador")
	var dialog: Node
	for node in front.get_children():
		if node.get("ok_button_text")=="Continuar" and node.has_signal("confirmed"):dialog=node
	check(dialog!=null,"generator confirmation available")
	if dialog==null:quit(1);return
	dialog._finish(true)
	var start:=Time.get_ticks_msec()
	var seen:=false
	var restored: Array[String]=[]
	while Time.get_ticks_msec()-start<25000:
		var cut:=front.get_node_or_null("CityRestoration")
		if cut!=null and not seen:
			seen=true
			check(front.flow_busy,"story input stays locked during cutaway")
			var action:=InputEventAction.new()
			action.action="campaign_map"
			action.pressed=true
			front._unhandled_input(action)
			check(front.park==original,"map key cannot replace the underlying scene")
			cut.restored.connect(func(scene: String):restored.append(scene))
			if "--capture" in OS.get_cmdline_user_args():cut.capture_folder=ProjectSettings.globalize_path("res://../tmp/city-review")
		if seen and cut==null:break
		await process_frame
	for frame in 4:await process_frame
	for node in front.get_children():
		if node.get("ok_button_text")!=null and node.has_signal("confirmed") and not node.is_queued_for_deletion():node._finish(true)
	for frame in 3:await process_frame
	check(seen,"tower triggers city cutaways")
	check(restored==["kronasta-centro-b","kronasta-lajes-a"],"both districts visibly restored")
	check(front.get_node_or_null("CityRestoration")==null,"cutaway removed")
	check(front.park==original and not original.paused and not front.flow_busy,"mountain exploration restored")
	var after: Dictionary=front.session.snapshot()
	check(after.player.flags.get("geradorLigado",false),"generator completion persists")
	check(after.checkpoint==before.checkpoint,"cutaway does not move the save")
	check(after.player.inventory==before.player.inventory,"cutaway grants no inventory")
	check(front.session.resume_slot("slot-1").status=="ok" and front.session.snapshot().player.flags.get("geradorLigado",false),"activation survives reload")
	for voice in front.sound.get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
			voice.stream=null
	front.queue_free()
	await process_frame
	await process_frame
	print("CITY RESTORATION: %d checks; %d failures"%[checks,failures])
	quit(int(failures>0))
