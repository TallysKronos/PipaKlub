extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func run() -> void:
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://care-city-"+State.new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder);app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true;app.session.start("slot-1")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"};player.inventory["kit-remendo"]=1
	player.partners=[{"id":"city-care","modelId":"rabbito","xp":0,"condition":{"line":20,"structure":40}}];player.equippedPartnerId="city-care"
	load("res://scripts/campaign/pipeiro_identity.gd").issue_into(player);player.flags.pipeiroDocumentsSeen=true
	var position:Array=[4.4,17.4]
	check(app.session.checkpoint({"kind":"world","scene":"quintal","position":position,"space":"bairro-inicial-v2"},player).status=="ok","isolated city checkpoint")
	app._show_collection();await process_frame
	app._show_partner_care("city-care")
	var camp_seen:=false
	for i in 500:
		for child in app.get_children():
			if child.has_meta("care_camp"):
				camp_seen=true
				if "--capture" in OS.get_cmdline_user_args() and child.elapsed>2.35 and child.elapsed<2.6:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://../documentation/qa/care-camp-v1/barraca-vila.png")
		if app.last_scene_key=="page:CUIDAR DO PARCEIRO" and not app.flow_busy:break
		await create_timer(.02).timeout
	check(camp_seen,"city actually plays camping animation")
	check(app.last_scene_key=="page:CUIDAR DO PARCEIRO" and not app.flow_busy,"city opens care instead of remaining frozen")
	check(app.session.snapshot().player.inventory["kit-remendo"]==1,"entry preserves kit")
	app._leave_partner_care()
	for i in 500:
		if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading) and not app.flow_busy:break
		await create_timer(.02).timeout
	check(is_instance_valid(app.park) and not app.park.paused,"care exit restores city movement")
	check(app.session.snapshot().checkpoint.scene=="quintal" and app.session.snapshot().checkpoint.position==position,"same city checkpoint preserved")
	app.free();await process_frame
	print("CITY CARE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
