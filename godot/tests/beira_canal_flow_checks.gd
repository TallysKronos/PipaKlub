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
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/beira-canal-v1")
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
func run()->void:
	root.size=Vector2i(1280,720)
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new();app.session._store=Store.new("user://beira-canal-flow-"+State.new_id());root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var p:Dictionary=app.session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	p.flags.merge({"ninaAccepted":true,"ninaBambuzalOrder":true,"bosqueClareiraDescoberta":true,"tylerClareiraMet":true,"guardianDefeated":true,"ninaReturned":true,"leagueGreen":true,"leagueGreenSeen":true,"ninaGlideLoanAvailable":true,"ninaGlideTutorialDone":true,"demoEndingSeen":true,"firstInsigniaSeen":true})
	for stage:Dictionary in Rules.definition("bambuzal").stages:
		var planned:Dictionary=Rules.prepare(p,"bambuzal",stage.id);p=Rules.settle(p,planned.context,"won").player
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(p);p.flags.pipeiroDocumentsSeen=true
	check(app.session.checkpoint(CP.make("kronasta-beira-canal-a",CP.spawn("kronasta-beira-canal-a"),CP.SPACE),p).status=="ok","Mikka-complete fixture")
	app._show_park();await ready_park()
	for i in 5:
		if i==4:
			await glide_flow()
			await gate_flow()
		var id:="beira-canal-"+str(i+1)
		var entry:=Service.stage(id)
		if app.session.snapshot().checkpoint.scene!=entry.scene:await exit_to(entry.scene)
		var event:Dictionary={}
		for item:Dictionary in app.park.interaction_events:
			if item.props.get("duel","")==id:event=item
		check(not event.is_empty(),"NPC event "+entry.name)
		if event.is_empty():app.free();quit(1);return
		check(walk(Vector2(event.u+.5,event.v+1.5)),"walk to "+entry.name)
		if i in [0,2,4]:await capture(["01-praca","02-miolo","03-arena"][i/2])
		app.park.nearby=event;app.park.interact();await frames()
		check(is_instance_valid(dialog()),"interaction opens "+entry.name)
		if not is_instance_valid(dialog()):app.free();quit(1);return
		while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
		dialog().get_ok_button().pressed.emit();await frames()
		check(is_instance_valid(app.battle) and app.session.snapshot().checkpoint.kind=="encounter","actual battle view "+entry.name)
		if not is_instance_valid(app.battle):app.free();quit(1);return
		check(app.battle.model.q.name==entry.name and app.battle.model.q.level==entry.level,"correct rival and level")
		if i==4:await capture("04-duelo-kleie")
		app.battle.model.outcome="won";app.battle.model.p.rounds=app.battle.model.rounds_to_win
		if i==4:
			app.battle._update_result(1.0);app.battle.queue_redraw()
			await capture("05-recompensa")
		app.battle.finish_requested.emit();await ready_park()
		check(Rules.entry(app.session.snapshot().player,"beira-canal").wonDuels.has(id),"battle finish commits "+id)
		await close_notice()
	check(Rules.completed(app.session.snapshot().player,"beira-canal") and app.session.snapshot().player.districtEmblems.has("bairro-03"),"Kleie victory and emblem in actual frontend")
	check(app.session.snapshot().player.flags.get("bosqueClareiraDescoberta",false),"other discovery remains intact")
	await capture("06-bairro-vencido")
	app.free();await process_frame
	print("BEIRA CANAL FLOW: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

func gate_flow()->void:
	var travel=preload("res://scripts/campaign/bosque_campaign.gd").new(app.session)
	check(travel.travel("park-veredas").status=="ok","normal travel to Veredas")
	app._show_park();await ready_park()
	var at:Vector2=preload("res://scripts/campaign/canal_gate.gd").AT
	check(walk(at),"walk to Grampo at control")
	await capture("06-grampo-controle")
	app._park_event("10900");await frames()
	check(is_instance_valid(dialog()),"Grampo introduction")
	if not is_instance_valid(dialog()):return
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await frames()
	check(is_instance_valid(app.battle) and app.battle.model.enemy_model_id=="platyx-draft","actual Platyx battle")
	if not is_instance_valid(app.battle):return
	await capture("07-grampo-duelo")
	app.battle.model.outcome="won";app.battle.finish_requested.emit();await ready_park()
	# F10: Grampo reacts to the duel and points to the canal control; close it first.
	for wait in 30:
		if is_instance_valid(dialog()):break
		await process_frame
	check(is_instance_valid(dialog()) and str(dialog().dialog_text).begins_with("Grampo:") and str(dialog().dialog_text).contains("comporta"),"Grampo reacts and points to the canal control")
	if is_instance_valid(dialog()):dialog().get_ok_button().pressed.emit();await frames()
	app._park_event("10901");await frames()
	check(is_instance_valid(dialog()),"valve confirmation after victory")
	if not is_instance_valid(dialog()):return
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await frames()
	check(app.session.snapshot().player.flags.get("comportaVeredasAberta",false),"actual valve saved")
	check(travel.travel("kronasta-beira-canal-a").status=="ok","return to district")
	app._show_park();await ready_park()
	await exit_to("kronasta-beira-canal-b")
	await exit_to("kronasta-beira-canal-c")

func glide_flow()->void:
	var at:=Vector2(28.5,17.5)
	check(walk(at),"walk to optional glide branch")
	app._park_event("10803");await frames()
	check(is_instance_valid(dialog()),"optional glide confirmation")
	if not is_instance_valid(dialog()):return
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await frames()
	check(not app.park.glide_record.is_empty(),"optional glide launches")
	for tick in 80:app.park._physics_process(1.0/60)
	app.park._process(0);app.park.exploration_hud._layout()
	await capture("08-planar-desvio")
	for tick in 150:app.park._physics_process(1.0/60)
	check(app.park.glide_record.is_empty() and app.park.player.distance_to(Vector2(28.5,24.5))<.01,"optional glide lands safely")
