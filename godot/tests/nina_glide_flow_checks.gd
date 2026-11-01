extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Glide=preload("res://scripts/campaign/nina_glide.gd")
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
	var path:=ProjectSettings.globalize_path("res://../documentation/qa/nina-glide-v1");DirAccess.make_dir_recursive_absolute(path)
	check(root.get_texture().get_image().save_png(path.path_join(name+".png"))==OK,"capture "+name)
func walk(target:Vector2)->bool:
	app.park.encounter_grace=100000;app.park.paused=false;app.park.walk_to(target)
	for i in 10000:
		if app.park.player.distance_to(target)<.05:return true
		app.park._physics_process(1.0/60)
	return false
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720);app=load("res://tests/fixtures/park_frontend_fixture.gd").new();app.session._store=Store.new("user://glide-flow-"+State.new_id());root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=app.session.snapshot().player;p.partners=[{"id":"r","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.flags.merge({"leagueGreen":true,"leagueGreenSeen":true,"ninaGlideLoanAvailable":true,"guardianDefeated":true,"ninaReturned":true,"ninaAccepted":true,"demoEndingSeen":true,"firstInsigniaSeen":true})
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	var rules=preload("res://scripts/campaign/district_rules.gd")
	for stage:Dictionary in rules.definition("bambuzal").stages:
		var planned:Dictionary=rules.prepare(p,"bambuzal",stage.id);p=rules.settle(p,planned.context,"won").player
	p.flags.merge({"bosqueClareiraDescoberta":true,"tylerClareiraMet":true})
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(p);p.flags.pipeiroDocumentsSeen=true
	check(app.session.checkpoint(CP.make("park-veredas",CP.spawn("park-veredas"),CP.SPACE),p).status=="ok","permission fixture")
	app._show_park();await frames()
	check(app.park.has_method("play_glide"),"campaign glide view")
	if not app.park.has_method("play_glide"):app.free();quit(1);return
	var entry:Dictionary=Glide.data().links[0];var a:=Glide.point(entry.from);var b:=Glide.point(entry.to)
	check(walk(a),"controller walks from entrance to takeoff")
	await capture("01-decolagem")
	app._park_event("10800");await frames()
	check(is_instance_valid(dialog()),"tutorial confirmation")
	if not is_instance_valid(dialog()):app.free();quit(1);return
	while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
	dialog().get_ok_button().pressed.emit();await frames()
	check(not app.park.glide_record.is_empty() and not app.park.paused,"confirmed takeoff persists then starts")
	if app.park.glide_record.is_empty():app.free();quit(1);return
	app.park.paused=true;var elapsed:float=app.park.glide_elapsed
	app.park._physics_process(.5)
	check(app.park.glide_elapsed==elapsed,"pause freezes flight")
	app.park.paused=false
	for i in 80:app.park._physics_process(1.0/60)
	check(not app.park.model.point_walkable(app.park.player),"presentation crosses actual water")
	check(app._save_park(true) and app.session.snapshot().checkpoint.position==[a.x,a.y],"autosave never serializes midair water")
	app.park._process(0);app.park.exploration_hud._layout()
	check(not app.park.exploration_hud.run_button.visible and app.park.hint.text.contains("Planando"),"flight HUD replaces running with glide feedback")
	await capture("02-planando")
	# Reload mid-flight; real frontend recovers instead of resuming inside the gap.
	app._show_park();await frames()
	check(app.park.player.distance_to(a)<.01 and not app.session.snapshot().player.has("ninaGlideFlight"),"reload recovers both to last firm ground")
	check(Glide.new(app.session).begin(entry.id,app.park.player).status=="ok","retry launch")
	app.park.play_glide(app.session.snapshot().player.ninaGlideFlight);app.park.paused=false
	for i in 210:app.park._physics_process(1.0/60)
	check(app.park.glide_record.is_empty() and app.park.player.distance_to(b)<.01 and app.park.follower.distance_to(b)<.01,"both arrive and transaction commits")
	check(app.session.snapshot().player.flags.ninaGlideTutorialDone,"tutorial complete")
	await capture("03-chegada")
	var reverse:Dictionary=Glide.data().links[1]
	check(Glide.new(app.session).begin(reverse.id,b).status=="ok","reverse launch")
	app.park.play_glide(app.session.snapshot().player.ninaGlideFlight)
	for i in 210:app.park._physics_process(1.0/60)
	check(app.park.player.distance_to(a)<.01,"reverse trip complete")
	app.park.hide_characters();app.park.exploration_hud.hide()
	for endpoint in [a,b]:
		app.park.camera.position=app.park.model.project(endpoint);app.park.camera.zoom=Vector2.ONE*2.2;app.park.camera.reset_smoothing()
		await capture("04-detalhe-"+str(int(endpoint.y)))
	OS.set_environment("KRONASTA_GEOMETRIA","1");app._show_park();await frames()
	app.park.hide_characters();app.park.exploration_hud.hide()
	app.park.camera.position=app.park.model.project((a+b)/2);app.park.camera.zoom=Vector2.ONE;app.park.camera.reset_smoothing()
	await capture("05-geometria-travessia")
	for endpoint in [a,b]:
		app.park.camera.position=app.park.model.project(endpoint);app.park.camera.zoom=Vector2.ONE*2.2;app.park.camera.reset_smoothing()
		await capture("06-geometria-"+str(int(endpoint.y)))
	OS.set_environment("KRONASTA_GEOMETRIA","")
	app.free();await process_frame
	print("NINA GLIDE FLOW: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
