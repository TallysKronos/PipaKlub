extends SceneTree
## Assisted playthrough: prior district wins are a fixture; Mikka is fought using
## normal input actions and the native battle view. Never assigns a battle result.
const State=preload("res://scripts/campaign/state.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
const Badges=preload("res://scripts/campaign/district_badges.gd")
var app:Control
var checks:=0
var failures:=0
var output:="res://../documentation/qa/demo-championship-2026-10-31"
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 8:await process_frame
func capture(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func confirm_dialog() -> void:
	var dialogs:=get_nodes_in_group("manga_dialogue")
	check(dialogs.size()==1,"one active dialogue")
	if dialogs.is_empty():return
	var dialog=dialogs[0]
	while dialog.page_index<dialog.pages.size()-1:dialog.next_page()
	dialog.accept.pressed.emit()
	await settle()
func action(id:String,strength:float) -> void:
	if strength>.01:Input.action_press("campaign_"+id,strength)
	else:Input.action_release("campaign_"+id)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://championship-playthrough-"+State.new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder)
	app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	check(app.session.start("slot-1").status=="ok","isolated slot created")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"}
	player.partners=[{"id":"demo-partner","modelId":"rabbito","xp":Model.xp_for_level(8),"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="demo-partner"
	load("res://scripts/campaign/pipeiro_identity.gd").issue_into(player)
	player.flags.pipeiroDocumentsSeen=true
	player.morro=load("res://scripts/campaign/morro_rules.gd").defaults()
	for stage in ["morro-1","morro-2","morro-3","morro-4"]:player.morro.stars[stage]=2
	player.morro.mastery=4
	var data:Dictionary=app.Morro.maps()["morro-area-5"]
	var place:Dictionary=data.places.filter(func(p):return p.has("stage"))[0]
	check(app.session.checkpoint({"kind":"world","scene":"morro-area-5","position":place.point},player).status=="ok","pre-champion checkpoint")
	app._show_saved();await settle()
	app._morro_action(place.id);await settle();await confirm_dialog()
	check(is_instance_valid(app.battle),"dialogue starts native battle")
	if not is_instance_valid(app.battle):quit(1);return
	var battle=app.battle
	battle.set_physics_process(false)
	var model=battle.model
	for frame in 4000:
		var p:Dictionary=model.p;var q:Dictionary=model.q
		var aim:=Vector2(q.anchor,585).lerp(Vector2(q.x,q.y),.62)
		aim=Vector2(clampf(p.anchor+(aim.x-p.anchor)/.82,55,945),clampf(585+(aim.y-585)/.82,70,480))
		var motion:Vector2=(aim-Vector2(p.x,p.y))/80
		action("left",clampf(-motion.x,0,1));action("right",clampf(motion.x,0,1))
		action("up",clampf(-motion.y,0,1));action("down",clampf(motion.y,0,1))
		var attack:bool=model.contact(p,q).get("valid",false) or Vector2(p.x,p.y).distance_to(Vector2(q.x,q.y))<48
		action("cut",float(attack));action("skill",float(attack and p.energy>50));action("signature",float(attack and p.energy>45))
		battle._physics_process(.05)
		if frame%25==0:await process_frame
		if not model.outcome.is_empty():break
	for id in ["left","right","up","down","cut","skill","signature"]:action(id,0)
	print("NATIVE BATTLE: ",model.outcome,"; simulated seconds ",model.time,"; rounds ",model.p.rounds," / ",model.q.rounds)
	check(model.outcome=="won","Mikka defeated through ordinary input actions")
	if model.outcome!="won":quit(1);return
	await settle();await capture("01-victory")
	battle.finish_button.pressed.emit();await settle()
	check(Badges.has_first(app.session.snapshot().player),"victory commits insignia")
	await confirm_dialog()
	# Let the actual 2.5-second banner complete, including its save acknowledgement.
	await create_timer(3).timeout;await settle()
	check(not Badges.pending(app.session.snapshot()),"banner acknowledgement persisted")
	await confirm_dialog()
	var case:Control
	for child in app.get_children():
		if child.has_meta("emblem_case"):case=child
	check(is_instance_valid(case) and case.count.text.ends_with("1 / 12"),"case displays earned first badge")
	await capture("02-earned-badge")
	var before:Dictionary=app.session.snapshot().player
	app.free();await settle()
	# Fresh application and session read from disk, not from the old snapshot.
	app=load("res://scripts/campaign/front_end.gd").new()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder)
	app.preferences.storage_path=folder+".cfg"
	root.add_child(app)
	check(app.session.resume_slot("slot-1").status=="ok","new application reloads disk save")
	var after:Dictionary=app.session.snapshot().player
	# JSON numbers reload as floats; compare both snapshots in their disk form.
	var disk_before:Dictionary=JSON.parse_string(JSON.stringify(before))
	check(after.districtEmblems==disk_before.districtEmblems,"emblem metadata survives fresh application")
	check(after.coins==disk_before.coins and after.partners==disk_before.partners,"money and partner rewards persist exactly")
	check(not Badges.pending(app.session.snapshot()),"ceremony does not repeat on reload")
	app._show_saved();await settle();app._open_emblem_case(0);await settle()
	await capture("03-reloaded-badge")
	check(get_nodes_in_group("manga_dialogue").is_empty(),"no reward dialogue repeats")
	app.free();await settle()
	print("CHAMPIONSHIP PLAYTHROUGH: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
