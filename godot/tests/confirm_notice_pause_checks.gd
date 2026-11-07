extends SceneTree
## Campaign walker: confirming "Aprender Cavar" opened the "Cavar aprendido" notice from
## the callback; the notice remembered the park as paused by the confirmation, and Kael
## stayed frozen after closing it. Same pattern as every _confirm_park whose callback
## opens a deferred notice.
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; printerr("FAIL ",message)
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for i in 8: await process_frame
func dialog_with(front: Node, text: String) -> Node:
	for node in front.get_children():
		if node.get("dialog_text")!=null and str(node.dialog_text).begins_with(text) and not node.is_queued_for_deletion() and not node.get("_closed"): return node
	return null
func run() -> void:
	var front:=Front.new()
	front.session._store=Store.new("user://confirm-notice-"+State.new_id())
	front.preferences.storage_path="user://confirm-notice-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	Fixtures.show(front,"trail")
	for frame in 600:
		if is_instance_valid(front.park) and not front.flow_busy and not is_instance_valid(front.scene_loading): break
		await process_frame
	await settle()
	check(is_instance_valid(front.park) and not front.park.paused,"park open and moving")
	front._confirm_park("Tatutrama","O tatu arranha a terra.","Aprender Cavar",func(): front._notice.call_deferred("Cavar aprendido."))
	await settle()
	var ask:=dialog_with(front,"O tatu")
	check(ask!=null and front.park.paused,"confirmation pauses the park")
	if ask!=null: ask._finish(true)
	await settle()
	var told:=dialog_with(front,"Cavar aprendido")
	check(told!=null and front.park.paused,"the notice keeps the park paused while it is open")
	if told!=null: told._finish(true)
	await settle()
	check(not front.park.paused,"closing the notice gives movement back")
	# A plain confirmation without a notice still unpauses on its own.
	front._confirm_park("Banco","Descansar?","Descansar",func(): pass)
	await settle()
	var rest:=dialog_with(front,"Descansar?")
	if rest!=null: rest._finish(true)
	await settle()
	check(not front.park.paused,"a confirmation alone gives movement back")
	# A pause that existed before the notice is kept (the flow that set it releases it;
	# the rescue in the Ruínas and the Aracati now release theirs before the notice).
	front.park.paused=true
	front._notice("Nina: Pronto. A linha afrouxou.")
	await settle()
	var freed:=dialog_with(front,"Nina: Pronto")
	if freed!=null: freed._finish(true)
	await settle()
	check(front.park.paused,"a pause set before the notice is kept")
	front.park.paused=false
	var source:=FileAccess.get_file_as_string("res://scripts/campaign/front_end.gd")
	check(source.count("The staging pause ends here")==2,"rescue and Aracati release their staging pause before the notice")
	# Another dialog still open keeps the park paused.
	var ask2:=front._confirm_park("Cadeado","Três nós.","Enfrentar",func(): pass)
	await settle()
	front._notice("Aviso por cima.")
	await settle()
	var over:=dialog_with(front,"Aviso por cima")
	if over!=null: over._finish(true)
	await settle()
	check(front.park.paused,"a dialog still open keeps the park paused")
	var still:=dialog_with(front,"Três nós")
	if still!=null: still._finish(false)
	await settle()
	check(not front.park.paused,"closing the last dialog gives movement back")
	check(await preload("res://tests/audio_teardown.gd").free_view(self,front),"audio released before exit")
	print("CONFIRM NOTICE PAUSE: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
