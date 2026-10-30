extends SceneTree
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
var checks:=0
var failures:Array[String]=[]
var app:Control
func _initialize() -> void:call_deferred("run")
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL ",text)
func cinema() -> Node:
	return find(app,"res://scripts/campaign/lacertubo_cinematic.gd")
func find(node:Node,path:String) -> Node:
	if node.get_script()!=null and node.get_script().resource_path==path:return node
	for child in node.get_children():
		var value:=find(child,path)
		if value!=null:return value
	return null
func shot(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/lacertubo-cinematic-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	var suffix:="" if root.size==Vector2i(1280,720) else "-%dx%d"%[root.size.x,root.size.y]
	root.get_texture().get_image().save_png(folder.path_join(name+suffix+".png"))
func advance(intro:Node,seconds:float) -> void:
	if "--realtime" in OS.get_cmdline_user_args():
		intro.set_process(true)
		await create_timer(seconds).timeout
		if is_instance_valid(intro):intro.set_process(false)
	else:intro.advance(seconds)
func run() -> void:
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store=Store.new(ProjectSettings.globalize_path("res://../tmp/lacertubo-cinematic-"+State.new_id()))
	root.add_child(app);check(app.session.start("slot-1").status=="ok","isolated save")
	var player:Dictionary=app.session.snapshot().player
	player.partners=[{"id":"cinema-rabbito","modelId":"rabbito","personalName":"Rabbito","xp":1260,"craftBonus":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="cinema-rabbito";player.journey={"phase":"complete","lesson":5};player.flags.ninaAccepted=true
	var point:Vector2=Checkpoint.target("park-veredas","boss")+Vector2(0,5)
	check(app.session.checkpoint(Checkpoint.make("park-veredas",point,Checkpoint.SPACE),player).status=="ok","valid approach fixture")
	app._show_park()
	for i in 900:
		await process_frame
		if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):break
	check(is_instance_valid(app.park),"real park opens")
	app.park.set_physics_process(false)
	var before:Dictionary=app.session.snapshot().player
	var position:Vector2=app.park.player
	app.preferences.reduced_motion=false
	app.park._physics_process(.016)
	var intro:Node=cinema();check(intro!=null,"approach starts cinematic")
	if intro==null:quit(1);return
	intro.set_process(false)
	check(app.park.paused and app.park.guardian_focus,"exploration locked during cinematic")
	check(not app.park.exploration_hud.visible and not app.park.exploration_hud.map.visible,"HUD and minimap hidden")
	check(not app.session.snapshot().player.flags.get("lacertuboIntroduced",false),"unfinished scene is not marked watched")
	var original:Vector2=intro.initial_camera
	await advance(intro,2.2);check(app.park.camera.position.distance_to(original)>1,"camera reveals guardian")
	check(not intro.pipes.is_empty(),"pipe artwork participates in staging")
	await shot("01-canos")
	await advance(intro,2.3)
	check(intro.portrait_layer.visible and intro.name_label.visible,"manga boss cut-in")
	check(intro.portrait.parts.head.asset=="expressions","guardian has fierce expression")
	for part in intro.portrait.ordered:
		var r:Array=part.rect
		var left:float=intro.portrait_layer.position.x+(float(r[0])-intro.portrait.foot.x)*intro.portrait.scale.x
		check(left>=20,"portrait part remains inside viewport: "+str(part.id))
	check(intro.called.size()==3,"sound cues emitted once")
	await shot("02-lacertubo")
	await advance(intro,3.8)
	check(not intro.portrait_layer.visible and intro.caption.text.contains("Nina"),"returns to Kael with quest motivation")
	await shot("03-kael")
	await advance(intro,2.3)
	await process_frame
	check(not app.park.paused and not app.park.guardian_focus,"natural ending restores control")
	check(app.park.camera.position.distance_to(original)<.01,"camera restored exactly")
	check(app.park.player==position,"cinematic never teleports player")
	var after:Dictionary=app.session.snapshot().player
	check(after.flags.get("lacertuboIntroduced",false),"ending persists introduction")
	check(after.partners==before.partners and after.inventory==before.inventory and after.coins==before.coins,"no XP inventory or coin mutation")
	check(after.get("encounter",{}).is_empty(),"no forced battle")
	check(app.park.exploration_hud.visible and app.park.exploration_hud.map.visible,"HUD restored")
	var resumed=load("res://scripts/campaign/session.gd").new();resumed._store=app.session._store
	check(resumed.resume_slot("slot-1").status=="ok" and resumed.snapshot().player.flags.lacertuboIntroduced,"introduction survives reload");resumed.free()
	app.park._physics_process(.01);check(cinema()==null,"watched cinematic does not repeat")
	# Direct scene replay is test-only: verifies skipping and accessibility independently.
	var layer:=CanvasLayer.new();layer.layer=30;app.add_child(layer)
	var replay=load("res://scripts/campaign/lacertubo_cinematic.gd").new();replay.park=app.park;replay.reduced_motion=true;layer.add_child(replay);replay.set_process(false)
	replay.advance(4.5)
	check(app.park.camera.zoom==replay.initial_zoom and app.park.camera.offset==Vector2.ZERO,"reduced motion removes zoom and shake")
	check(replay.get_global_rect().encloses(replay.skip.get_global_rect()),"skip button fits viewport")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.keycode=KEY_ESCAPE;escape.pressed=true
	replay._input(escape)
	check(replay.done and not app.park.paused,"Escape skips and restores controls")
	var final:Vector2=app.park.camera.position;replay.advance(5)
	check(app.park.camera.position==final,"finished scene cannot animate camera again")
	layer.queue_free();await process_frame
	for audio in app.find_children("*","AudioStreamPlayer",true,false):audio.stop()
	await create_timer(.15).timeout
	app.queue_free();await process_frame
	print("LACERTUBO CINEMATIC ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
