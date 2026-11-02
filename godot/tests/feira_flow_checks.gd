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
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/feira-v1")
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
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new();app.session._store=Store.new("user://feira-flow-"+State.new_id());root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var p:Dictionary=app.session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5};p.coins=100
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	p.flags.merge({"ninaAccepted":true,"ninaBambuzalOrder":true,"bosqueClareiraDescoberta":true,"tylerClareiraMet":true,"guardianDefeated":true,"ninaReturned":true,"leagueGreen":true,"leagueGreenSeen":true,"ninaGlideLoanAvailable":true,"ninaGlideTutorialDone":true,"demoEndingSeen":true,"firstInsigniaSeen":true,"comportaVeredasAberta":true})
	for district:String in ["bambuzal","beira-canal"]:
		for stage:Dictionary in Rules.definition(district).stages:
			var planned:Dictionary=Rules.prepare(p,district,stage.id);p=Rules.settle(p,planned.context,"won").player
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(p);p.flags.pipeiroDocumentsSeen=true
	check(app.session.checkpoint(CP.make("kronasta-feira-a",CP.spawn("kronasta-feira-a"),CP.SPACE),p).status=="ok","Feira fixture")
	app._show_park();await ready_park()
	for i in 5:
		if i==4:await whistle_flow()
		var id:="feira-"+str(i+1);var entry:=Service.stage(id)
		if app.session.snapshot().checkpoint.scene!=entry.scene:await exit_to(entry.scene)
		var event:Dictionary={}
		for e:Dictionary in app.park.interaction_events:
			if e.props.get("duel")==id:event=e
		check(not event.is_empty(),"NPC event "+entry.name)
		if event.is_empty():app.free();quit(1);return
		check(walk(Vector2(event.u+.5,event.v+1.5)),"walk to "+entry.name)
		if i in [0,2,4]:await capture(["01-praca","02-mercado","03-zulmira"][i/2])
		app.park.nearby=event;app.park.interact();await accept()
		check(is_instance_valid(app.battle),"district battle visible")
		if not is_instance_valid(app.battle):app.free();quit(1);return
		app.battle.model.outcome="won";app.battle.model.p.rounds=app.battle.model.rounds_to_win
		if i==4:
			app.battle._update_result(1);check("FEIRA DO LARGO" in app.battle.result_header.context,"correct reward district title");app.battle.queue_redraw();await capture("06-emblema")
		app.battle.finish_requested.emit();await ready_park();await close_notice()
		check(id in Rules.entry(app.session.snapshot().player,"feira").wonDuels,"reward committed "+id)
	check(Rules.completed(app.session.snapshot().player,"feira") and app.session.snapshot().player.districtEmblems.has("bairro-04"),"Feira and emblem")
	check(app.session.snapshot().player.inventory.get("apito-de-vento",0)==1,"whistle retained after champion")
	app.free();await process_frame
	print("FEIRA FLOW: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func whistle_flow()->void:
	var travel=preload("res://scripts/campaign/bosque_campaign.gd").new(app.session)
	check(travel.travel("kronasta-feira-a").status=="ok","normal return to Lalau");app._show_park();await ready_park()
	var at:=Vector2(20.5,26.5);check(walk(at),"walk to Lalau")
	for e:Dictionary in app.park.interaction_events:
		if e.props.get("feiraAction")=="lalau":app._park_event(str(int(e.id)));break
	await accept();check(app.session.snapshot().player.flags.get("feiraApitoComprado",false),"purchase via UI")
	await capture("04-apito-recebido")
	check(travel.travel("park-veredas").status=="ok","travel to door");app._show_park();await ready_park()
	check(walk(Vector2(39.5,29.5)),"walk to door")
	app._park_event("11100");await accept();await close_notice()
	check(app.session.snapshot().player.flags.get("feiraApitoFalsoTestado",false),"door test via UI")
	check(travel.travel("kronasta-feira-a").status=="ok","return to market");app._show_park();await ready_park();check(walk(at),"walk to confession")
	app._request_feira_story("lalau");await accept();await story_win()
	check(app.session.snapshot().player.flags.get("feiraLalauVencido",false),"Lalau confession saved")
	await exit_to("kronasta-feira-b");check(walk(Vector2(34.5,17.5)),"walk to Grampo")
	app._request_feira_story("grampo");await accept()
	if is_instance_valid(app.battle):await capture("05-grampo-platyx")
	await story_win()
	check(app.session.snapshot().player.flags.get("feiraApitoVerdadeiro",false),"true whistle saved")
