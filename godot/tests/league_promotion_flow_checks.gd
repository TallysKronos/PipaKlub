extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Exam=preload("res://scripts/campaign/league_promotion.gd")
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
	var path:=ProjectSettings.globalize_path("res://../documentation/qa/league-green-v1");DirAccess.make_dir_recursive_absolute(path)
	check(root.get_texture().get_image().save_png(path.path_join(name+".png"))==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720);app=load("res://tests/fixtures/park_frontend_fixture.gd").new();app.session._store=Store.new("user://green-flow-"+State.new_id());root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=app.session.snapshot().player;p.partners=[{"id":"r","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	for stage:Dictionary in Rules.definition("bambuzal").stages:
		var plan:=Rules.prepare(p,"bambuzal",stage.id);p=Rules.settle(p,plan.context,"won").player
	p.flags.merge({"tylerClareiraMet":true,"ninaAccepted":true,"ninaBambuzalOrder":true,"ninaTail":true,"guardianDefeated":true,"demoEndingSeen":true,"firstInsigniaSeen":true})
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(p);p.flags.pipeiroDocumentsSeen=true
	p.inventory["quest-nina-tail"]=1
	var at:=CP.target("park-trail","nina")
	check(app.session.checkpoint(CP.make("park-trail",at+Vector2.DOWN,CP.SPACE),p).status=="ok","delivery fixture")
	app._show_park();await frames()
	app._park_action("nina");await frames()
	check(Exam.promoted(app.session.snapshot().player) and is_instance_valid(dialog()),"Nina interaction atomically promotes and opens homecoming")
	if not is_instance_valid(dialog()):app.free();quit(1);return
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await frames()
	check(is_instance_valid(dialog()) and app.park.paused,"promotion scene replaces handoff with world paused")
	if not is_instance_valid(dialog()):app.free();quit(1);return
	while dialog().page_index<1:dialog().next_page()
	await capture("01-categoria-verde")
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await frames()
	check(not Exam.pending(app.session.snapshot()) and not app.park.paused,"acknowledgment restores exploration")
	app._show_identity();await frames();await capture("02-carteira-verde")
	app.free();await process_frame
	print("GREEN EXAM FLOW: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
