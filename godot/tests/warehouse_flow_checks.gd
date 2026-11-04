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
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/warehouse-v1")
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
	app=load("res://scripts/campaign/front_end.gd").new();root.add_child(app)
	app.session._store=Store.new("user://warehouse-flow-"+State.new_id());app.preferences.reduced_motion=true
	check(app.session.start("slot-1").status=="ok","start isolated")
	var p:Dictionary=app.session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":preload("res://scripts/campaign/encounter_model.gd").xp_for_level(25),"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	var prior:=Rules.fresh("cais");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(p,"cais",prior)
	p.flags.retalhoBosqueVencido=true;p.flags.fotoExpedicaoLida=true
	# Four existing district wins are a fixture; their full service flow has its own test.
	var qualified:=Rules.fresh("industrial");qualified.qualification=["industrial-1","industrial-2","industrial-3","industrial-4"];Rules.store(p,"industrial",qualified)
	check(app.session.checkpoint(CP.make("kronasta-industrial-b",Vector2(29.5,14.7),CP.SPACE),p).status=="ok","fixture checkpoint")
	app._show_saved();await ready_park();await capture("01-gollia")
	app._request_warehouse(true);await frames();await capture("02-duelo-gollia");await accept();await frames()
	check(is_instance_valid(app.battle),"Gollia battle enters")
	if not is_instance_valid(app.battle):quit(1);return
	app.battle.model.outcome="won";app.battle.finish_requested.emit();await ready_park();await close_notice()
	check(app.session.snapshot().player.flags.get("golliaCarretelVencida",false),"Gollia flag")
	await exit_to("kronasta-industrial-d");await capture("03-entrada-galpao")
	check(walk(Vector2(24.5,24.5)),"walk to confrontation")
	app._request_warehouse(false);await frames();await capture("04-tres-rabiolas")
	dialog().canceled.emit();await frames()
	check(not app.park.paused,"cancel restores exploration")
	app._request_warehouse(false);await accept();await frames();await capture("05-retalho")
	await accept();await frames();await capture("06-tyler")
	await accept();await frames();await capture("07-desatada")
	check(app.session.snapshot().player.flags.get("galpaoTylerDesatou",false),"intervention saved")
	await accept();await frames();check(is_instance_valid(app.battle),"dragon battle enters")
	if not is_instance_valid(app.battle):quit(1);return
	app.battle.model.intro=0;app.battle.queue_redraw();await capture("08-batalha")
	check(app.battle.art_ids[1]=="pipa-dragao-desatada","correct boss artwork")
	app.battle.model.outcome="won";app.battle.finish_requested.emit();await ready_park();await capture("09-recompensa");await close_notice()
	check(app.session.snapshot().player.inventory.get("agulha-desatar",0)==1,"unique needle")
	check(app.session.snapshot().player.flags.get("pipaDragaoDesatadaVencida",false),"Bruno prerequisite")
	await exit_to("kronasta-industrial-b")
	await exit_to("kronasta-industrial-c")
	check(walk(Vector2(29.5,14.5)),"walk to Bruno")
	await capture("10-bruno-liberado")
	app._district_action("industrial-5");await accept();await frames()
	check(is_instance_valid(app.battle),"Bruno battle enters after warehouse result")
	if not is_instance_valid(app.battle):quit(1);return
	app.battle.model.outcome="won";app.battle.finish_requested.emit();await ready_park();await capture("11-sexto-emblema");await close_notice()
	check(Rules.completed(app.session.snapshot().player,"industrial"),"district completed")
	check(app.session.snapshot().player.districtEmblems.has("bairro-06"),"sixth emblem persisted")
	app._show_bag();await frames()
	for child:Node in app.page.get_children():
		if child.get_script()!=load("res://scripts/campaign/hud_inventory.gd"):continue
		child.populate("Missão");child.select_item("agulha-desatar");await frames()
		check(child.item_name.text=="Agulha de desatar" and child.item_art.texture!=null,"needle mission card")
		check(not child.use_button.visible,"no unimplemented remount action")
	await capture("12-agulha-na-mochila")
	print("WAREHOUSE FLOW ",checks," checks; ",failures.size()," failures; UI/controller flow, terminal battles are fixtures")
	app.free();quit(0 if failures.is_empty() else 1)
