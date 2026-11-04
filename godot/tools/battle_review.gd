extends SceneTree
## Interactive review launcher. Temporary campaign and preferences; no player save access.
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var fixture:="battle"
	var reduce:=false
	var smoke:="--smoke" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):fixture=arg.trim_prefix("--fixture=")
		if arg=="--reduced-motion":reduce=true
	if fixture not in ["battle","morro-battle","boss-intro","lesson-0","lesson-1","lesson-2","lesson-3","lesson-4"]:
		printerr("Unknown review scenario");quit(1);return
	root.size=Vector2i(1280,720)
	var front:=Front.new()
	var directory:="user://manual-battle-review-"+State.new_id()
	front.session._store=Store.new(directory)
	front.preferences.storage_path=directory.path_join("preferences.cfg")
	root.add_child(front)
	front.preferences.reduced_motion=reduce
	var created:Dictionary=front.session.start("slot-1")
	if created.status!="ok":printerr("Cannot create isolated review");quit(1);return
	Fixtures.show(front,fixture)
	var saved:Dictionary=front.session.snapshot()
	saved.revision=created.data.revision
	if saved.checkpoint.kind=="encounter":
		saved.player.encounter.id=State.new_id()
		saved.player.encounter.returnPoint=[208,816]
		if fixture=="morro-battle":saved.player.encounter.scene="morro-area-3"
	front.session._snapshot=saved
	var committed:Dictionary=front.session.checkpoint(saved.checkpoint,saved.player)
	if committed.status!="ok":printerr("Invalid isolated review scenario: ",committed.status);quit(1);return
	# Fixtures freeze screenshots. Restore normal processing for the interactive player.
	if is_instance_valid(front.battle):
		front.battle.set_physics_process(true)
		front.battle.suspend_actions()
		front.battle.resume_button.grab_focus.call_deferred()
	var practice:Control=front._practice_view()
	if is_instance_valid(practice):
		practice.set_process(true)
		practice.suspend_actions()
		practice.resume_button.show()
		practice.resume_button.grab_focus.call_deferred()
	DisplayServer.window_set_title("Soulmonsters · teste isolado · "+fixture)
	print("REVIEW READY: ",fixture,"; isolated=",directory)
	if smoke:
		await create_timer(.15).timeout
		front.free();quit(0)
