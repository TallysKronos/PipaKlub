extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Morro=preload("res://scripts/campaign/morro.gd")
const Dialogue=preload("res://scripts/campaign/hud_dialogue.gd")
var app:Control
var checks:=0
var failures:Array[String]=[]
func check(value:bool,text:String)->void:
	checks+=1
	if not value:failures.append(text);printerr("FAIL "+text)
func settle_frames()->void:
	for i in 5:await process_frame
func dialog()->Control:
	for child in app.get_children():
		if child.get_script()==Dialogue:return child
	return null
func capture(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await settle_frames();await RenderingServer.frame_post_draw
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/pip-92")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func place(index:int)->Dictionary:
	var stage:Dictionary=Rules.definition("morro").stages[index]
	return Morro.maps()[stage.scene].places.filter(func(p):return p.has("stage"))[0]
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720)
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store=Store.new("user://pip92-flow-"+State.new_id())
	root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var p:Dictionary=app.session.snapshot().player
	p.partners=[{"id":"test","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="test"
	p.journey={"phase":"complete","lesson":5};p.morro=Morro.Rules.defaults()
	for id in Morro.Rules.IDS:p.morro.stars[id]=3
	Rules.store(p,"morro",Rules.entry(p,"morro"));Rules.award_emblem(p,"morro")
	p.flags.firstInsigniaSeen=true;p.flags.demoEndingSeen=true
	check(app.session.checkpoint({"kind":"world","scene":"morro","position":place(0).point},p).status=="ok","champion fixture")
	app._show_morro();await settle_frames()
	app.park.set_physics_process(false)
	app._morro_action(place(0).id);await settle_frames()
	check(is_instance_valid(dialog()),"NPC interaction opens defense dialogue")
	check(Rules.status(app.session.snapshot().player,"morro")=="defense_pending","pending challenge committed before prompt")
	await capture("01-defesa-pendente")
	if not is_instance_valid(dialog()):app.free();quit(1);return
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	check(dialog().get_ok_button().visible and dialog().get_cancel_button().visible,"final page exposes defend/postpone actions")
	await capture("01b-confirmacao-defesa")
	dialog().get_cancel_button().pressed.emit();await settle_frames()
	check(not app.park.paused and not Rules.entry(app.session.snapshot().player,"morro").pendingDefense.is_empty(),"postpone keeps challenge and restores exploration")
	app._morro_action(place(0).id);await settle_frames()
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await settle_frames()
	check(app.session.snapshot().checkpoint.kind=="encounter" and is_instance_valid(app.battle),"confirmation enters actual battle view")
	if not is_instance_valid(app.battle):app.free();quit(1);return
	app.battle.set_physics_process(false)
	check(app.battle.model.q.name=="Zeca","battle view uses challenger")
	app.battle.model.outcome="lost";app.battle.model.q.rounds=3
	var saved:Dictionary=app.session.snapshot();saved.player.encounter.state=app.battle.model.snapshot()
	check(app.session.checkpoint(saved.checkpoint,saved.player).status=="ok" and app.morro.settle().status=="ok","battle result commits title loss")
	app._return_morro_result();await settle_frames()
	check(Rules.status(app.session.snapshot().player,"morro")=="requalifying","frontend returns to requalification")
	check(app.park.goal.text.contains("0/4"),"HUD explains requalification count")
	await capture("02-requalificacao")
	if is_instance_valid(dialog()):dialog().confirmed.emit();await settle_frames()
	saved=app.session.snapshot()
	check(app.session.checkpoint({"kind":"world","scene":"morro-area-5","position":place(4).point},saved.player).status=="ok","visit current champion")
	app._show_morro();await settle_frames();app.park.set_physics_process(false)
	check(app.park.data.npcs[0].name=="Zeca","world champion identity changes with title")
	await capture("03-campeao-atual")
	app.free();await process_frame
	print("DISTRICT FLOW: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
