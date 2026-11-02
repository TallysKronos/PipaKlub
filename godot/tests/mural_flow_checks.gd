extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Service=preload("res://scripts/campaign/district_campaign.gd")
const Dialog=preload("res://scripts/campaign/hud_dialogue.gd")
var app:Control
var checks:=0
var failures:Array[String]=[]
func check(value:bool,text:String)->void:
	checks+=1
	if not value:failures.append(text);printerr("FAIL "+text)
func freeze(node:Node)->void:
	if node==app.scene_loading:return
	node.set_process(false);node.set_physics_process(false)
	for child in node.get_children():freeze(child)
func frames()->void:
	for i in 5:await process_frame
	freeze(app)
func ready_park()->void:
	for i in 600:
		await physics_frame
		if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):break
		if i==599:check(false,"scene transition timeout");quit(1);return
	await frames();app.park.paused=false;app.park.encounter_grace=100000
func dialog()->Control:
	for child in app.get_children():
		if child.get_script()==Dialog:return child
	return null
func close_notice()->void:
	if is_instance_valid(dialog()):dialog().confirmed.emit()
	await frames()
func walk(at:Vector2)->bool:
	var view=app.park
	view.paused=false;view.encounter_grace=100000
	view.walk_to(at)
	for tick in 12000:
		if view.player.distance_to(at)<.1:return true
		view._physics_process(1.0/60)
	check(false,"controller reaches "+str(at));return false
func capture(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await frames();await RenderingServer.frame_post_draw
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/mural-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name+".png"))==OK,"capture "+name)
func exit_to(scene:String)->void:
	for event:Dictionary in app.park.model.data.events:
		if event.type!="saida" or event.props.get("destino","")!=scene:continue
		check(walk(Vector2(event.u+.5,event.v+.5)),"walk to exit "+scene)
		# Real movement may already trigger the exit. Otherwise use the real interaction.
		if app.session.snapshot().checkpoint.scene!=scene:app._park_exit(event)
		await ready_park()
		check(app.session.snapshot().checkpoint.scene==scene,"connected transition "+scene)
		return
	check(false,"exit exists "+scene)
func _initialize()->void:call_deferred("run")
func accept()->void:
	await frames()
	check(is_instance_valid(dialog()),"confirmation visible")
	if not is_instance_valid(dialog()):return
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await frames()
func story_win()->void:
	check(is_instance_valid(app.battle),"story battle visible")
	if not is_instance_valid(app.battle):return
	app.battle.model.outcome="won";app.battle.finish_requested.emit();await ready_park();await close_notice()
func run()->void:
	root.size=Vector2i(1280,720)
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new();app.session._store=Store.new("user://mural-flow-"+State.new_id());root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var p:Dictionary=app.session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.flags.merge({"leagueGreen":true,"leagueGreenSeen":true,"demoEndingSeen":true,"firstInsigniaSeen":true,"feiraApitoVerdadeiro":true});p.inventory["apito-de-vento"]=1
	var district:=Rules.fresh("feira");district.completed=true;district.rewardClaimed=true;district.champion="player";Rules.store(p,"feira",district)
	check(app.session.checkpoint(CP.make("park-veredas",Vector2(39.5,29.5),CP.SPACE),p).status=="ok","cave fixture")
	app._show_park();await ready_park()
	app._request_feira_story("door");await accept();await ready_park()
	check(app.session.snapshot().checkpoint.scene=="caverna-mural-a","true whistle door enters cave")
	await capture("01-vestibulo")
	await exit_to("caverna-mural-b");await capture("02-galeria")
	await exit_to("caverna-mural-c")
	check(walk(Vector2(20.5,10.5)),"walk to Tyler")
	app._show_mural_story();await frames();await capture("03-primeiro-laco")
	await accept()
	check(preload("res://scripts/campaign/mural_story.gd").step(app.session.snapshot().player)==1,"first panel saved")
	if is_instance_valid(dialog()):dialog().canceled.emit()
	await frames()
	app._show_mural_story();await frames()
	check(is_instance_valid(dialog()),"reading resumes")
	await accept();await accept()
	check(app.session.snapshot().player.flags.get("muralPrimeiroLaco",false),"mural completed")
	await capture("04-lembranca")
	app.free();print("MURAL FLOW: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
