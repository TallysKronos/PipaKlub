extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
var app:Control
var checks:=0
var failures:=0
var output:="res://../documentation/qa/care-camp-v1"
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 12:await process_frame
func current_camp() -> Node:
	for child in app.get_children():
		if child.has_meta("care_camp"):return child
	return null
func care_view() -> Node:
	var found:=app.find_children("*","Control",true,false).filter(func(child):return child.get_script()==load("res://scripts/campaign/partner_care_view.gd"))
	return null if found.is_empty() else found[0]
func capture(name:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://camp-"+State.new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder);app.preferences.storage_path=folder+".cfg"
	root.add_child(app)
	app.preferences.reduced_motion=false
	app.session.start("slot-1")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"};player.coins=24;player.inventory["kit-remendo"]=1
	player.partners=[{"id":"camp-partner","modelId":"rabbito","xp":1380,"condition":{"line":18,"structure":35}}];player.equippedPartnerId="camp-partner"
	load("res://scripts/campaign/pipeiro_identity.gd").issue_into(player);player.flags.pipeiroDocumentsSeen=true
	var data:Dictionary=app.Morro.maps()["morro-area-5"]
	check(app.session.checkpoint({"kind":"world","scene":"morro-area-5","position":data.spawn},player).status=="ok","isolated world save")
	app._show_collection();await settle()
	app._show_partner_care("camp-partner")
	await process_frame
	var camp:Node=current_camp()
	check(is_instance_valid(camp) and is_instance_valid(app.park),"care first returns to actual overworld")
	check(not is_instance_valid(care_view()),"care room waits for camping")
	check(app.park.paused and app.flow_busy,"movement blocked during pitching")
	app._show_partner_care("camp-partner")
	check(current_camp()==camp,"double click does not duplicate transition")
	await create_timer(.5).timeout;await capture("01-kit-lancado")
	check(camp.blackout==0,"no blackout during throw")
	await create_timer(1.1).timeout;await capture("02-barraca-subindo")
	await create_timer(.8).timeout;await capture("03-barraca-fechada")
	check(not is_instance_valid(care_view()),"closed tent precedes room")
	await create_timer(.4).timeout;await capture("04-escurecendo")
	await create_timer(.9).timeout;await settle()
	check(is_instance_valid(care_view()),"care opens after black screen")
	check(not is_instance_valid(current_camp()) and not app.flow_busy,"transition cleans up and releases input")
	var saved:Dictionary=app.session.snapshot()
	check(saved.player.inventory["kit-remendo"]==1 and saved.player.coins==24,"presentation costs no supplies")
	check(saved.player.partners[0].condition.line==18,"pitching does not repair partner")
	await capture("05-cuidados")
	care_view().back_requested.emit();await settle()
	check(is_instance_valid(app.park) and not app.park.paused,"exit returns to playable overworld")
	check(app.session.snapshot().checkpoint.position==saved.checkpoint.position,"exit preserves map position")
	app.preferences.reduced_motion=true
	app._show_partner_care();await create_timer(1.4).timeout;await settle()
	check(is_instance_valid(care_view()) and not app.flow_busy,"reduced motion completes shorter handoff")
	var escape:=InputEventKey.new();escape.pressed=true;escape.physical_keycode=KEY_ESCAPE
	app._unhandled_input(escape);await settle()
	check(is_instance_valid(app.park) and not is_instance_valid(care_view()),"Escape also returns to overworld")
	app.free();await settle()
	print("CARE CAMP: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
