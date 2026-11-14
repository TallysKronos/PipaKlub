extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Tyler=preload("res://scripts/campaign/tyler_clareira.gd")
const Dialog=preload("res://scripts/campaign/hud_dialogue.gd")
var app:Control
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL "+text)
func freeze(node:Node)->void:
	node.set_process(false);node.set_physics_process(false)
	for c in node.get_children():freeze(c)
func frames()->void:
	for i in 5:await process_frame
	freeze(app)
func dialog()->Control:
	for c in app.get_children():
		if c.get_script()==Dialog:return c
	return null
func capture(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await frames();await RenderingServer.frame_post_draw
	var path:=ProjectSettings.globalize_path("res://../documentation/qa/tyler-clareira-v1");DirAccess.make_dir_recursive_absolute(path)
	check(root.get_texture().get_image().save_png(path.path_join(name+".png"))==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720)
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new();app.session._store=Store.new("user://tyler-flow-"+State.new_id());root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=app.session.snapshot().player;p.partners=[{"id":"r","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	for stage:Dictionary in Rules.definition("bambuzal").stages:
		var plan:=Rules.prepare(p,"bambuzal",stage.id);p=Rules.settle(p,plan.context,"won").player
	p.flags.firstInsigniaSeen=true;p.flags.demoEndingSeen=true;p.flags.ninaAccepted=true;p.flags.ninaBambuzalOrder=true
	check(app.session.checkpoint(CP.make("park-clearing",CP.spawn("park-clearing"),CP.SPACE),p).status=="ok","Lohan won fixture")
	app._show_park();await frames()
	var rai_visible := false
	for actor: Dictionary in app.park.npc_nodes:
		if int(actor.root.get_meta("event", {}).get("id", -1)) != 10602:
			continue
		for sprite in actor.visual.get_children():
			if sprite is Sprite2D and sprite.is_visible_in_tree() and sprite.texture != null:
				rai_visible = sprite.texture.resource_path.ends_with("/rai-overworld-idle-eight.png") and sprite.region_rect.size == Vector2(64, 96)
	check(rai_visible, "Rai uses the directional sprite beside Tyler")
	app.park.encounter_grace=100000;app.park.paused=false;app.park.walk_to(Tyler.point()+Vector2.DOWN)
	for i in 12000:
		if app.park.player.distance_to(Tyler.point()+Vector2.DOWN)<.1:break
		app.park._physics_process(1.0/60)
	check(app.park.player.distance_to(Tyler.point()+Vector2.DOWN)<.1,"real controller reaches Tyler")
	await capture("01-encontro")
	app._show_tyler_clareira();await frames()
	for i in Tyler.nodes().size():
		check(is_instance_valid(dialog()),"line dialogue "+str(i))
		if not is_instance_valid(dialog()):app.free();quit(1);return
		if i in [0,3,6]:await capture("02-cena-"+str(i))
		while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
		if i==2:
			dialog().get_cancel_button().pressed.emit();await frames()
			check(not app.park.paused and Tyler.step(app.session.snapshot().player)==2,"postpone preserves line and restores movement")
			app._show_tyler_clareira();await frames()
			while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
		dialog().get_ok_button().pressed.emit();await frames()
	check(Tyler.done(app.session.snapshot().player) and not app.park.paused,"scene done exploration restored")
	check(app.park.exploration_hud.objective.text!="Converse com o rapaz e seu parceiro na roda da Clareira.","objective advances")
	var saved:Dictionary=app.session.snapshot();saved.player.encounter={"id":State.new_id(),"kind":"wild","scene":"kronasta-bambuzal-a","space":CP.SPACE,"dropRoll":0.0,"returnPoint":[24.5,37.5],"rewardXp":42,"state":load("res://scripts/campaign/encounter_model.gd").new(saved.player.partners[0],{"modelId":"rascunho-bicho-pau","level":8}).snapshot()}
	check(app.session.checkpoint({"kind":"encounter"},saved.player).status=="ok","draft encounter fixture")
	app._show_encounter();await frames();check(app.battle.art_ids[1]=="rascunho-bicho-pau","draft art consumed")
	await capture("03-selvagem-rascunho")
	saved=app.session.snapshot()
	saved.player.encounter.state=load("res://scripts/campaign/encounter_model.gd").new(saved.player.partners[0],{"modelId":"rascunho-joaninha","level":8}).snapshot()
	check(app.session.checkpoint(saved.checkpoint,saved.player).status=="ok","second draft fixture")
	app._show_encounter();await frames();await capture("04-joaninha-rascunho")
	app.free();await process_frame
	print("TYLER FLOW: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
