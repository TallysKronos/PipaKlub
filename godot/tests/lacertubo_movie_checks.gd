extends SceneTree
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Movie=preload("res://scripts/campaign/lacertubo_movie.gd")
var app:Control
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL ",text)
func find(node:Node) -> Node:
	if node.get_script()!=null and node.get_script().resource_path=="res://scripts/campaign/lacertubo_movie.gd":return node
	for child in node.get_children():
		var found:=find(child)
		if found!=null:return found
	return null
func shot(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	var dir:=ProjectSettings.globalize_path("res://../documentation/qa/lacertubo-video-v1")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir.path_join(name+".png"))
func run() -> void:
	check(FileAccess.file_exists(Movie.MOVIE_PATH),"rendered Ogg movie installed")
	if not FileAccess.file_exists(Movie.MOVIE_PATH):quit(1);return
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store=Store.new(ProjectSettings.globalize_path("res://../tmp/lacertubo-movie-"+State.new_id()))
	root.add_child(app);app.preferences.reduced_motion=false
	check(app.session.start("slot-1").status=="ok","isolated save")
	var player:Dictionary=app.session.snapshot().player
	player.partners=[{"id":"movie-partner","modelId":"rabbito","personalName":"Rabbito","xp":1260,"craftBonus":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="movie-partner";player.journey={"phase":"complete","lesson":5};player.flags.ninaAccepted=true
	var point:Vector2=Checkpoint.target("park-veredas","boss")+Vector2(0,5)
	check(app.session.checkpoint(Checkpoint.make("park-veredas",point,Checkpoint.SPACE),player).status=="ok","approach checkpoint")
	app._show_park()
	for i in 900:
		await process_frame
		if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):break
	app.park.set_physics_process(false)
	var before:Dictionary=app.session.snapshot().player
	app.park._physics_process(.016)
	var intro:Node=find(app)
	check(intro!=null,"real approach selects rendered movie")
	if intro==null:quit(1);return
	await create_timer(1).timeout
	check(intro.movie.is_playing() and intro.movie.stream_position>.2,"Theora frames actually advance")
	check(app.park.paused and not app.park.exploration_hud.visible,"exploration paused under footage")
	await shot("game-01-filme")
	await create_timer(4).timeout
	check(intro.movie.stream_position>4,"continuous playback reaches later action")
	await shot("game-02-rugido")
	var deadline:=Time.get_ticks_msec()+12000
	while is_instance_valid(intro) and not intro.film_finished and Time.get_ticks_msec()<deadline:await process_frame
	check(is_instance_valid(intro) and intro.film_finished,"decoder reaches actual end of movie")
	if is_instance_valid(intro):
		check(not intro.playback_error,"movie completes without decoder fallback")
		await shot("game-03-retorno")
	while is_instance_valid(intro) and Time.get_ticks_msec()<deadline:await process_frame
	check(not is_instance_valid(intro),"return line ends cinematic naturally")
	check(not app.park.paused and not app.park.guardian_focus,"exploration control restored")
	var after:Dictionary=app.session.snapshot().player
	check(after.flags.get("lacertuboIntroduced",false),"movie completion saved")
	check(after.partners==before.partners and after.inventory==before.inventory and after.coins==before.coins,"no rewards or stats granted")
	check(after.get("encounter",{}).is_empty(),"battle remains player's choice")
	var layer:=CanvasLayer.new();layer.layer=30;app.add_child(layer)
	var replay:=Movie.new();replay.park=app.park;layer.add_child(replay)
	await create_timer(.4).timeout
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
	replay._input(escape)
	check(replay.done and not replay.movie.is_playing() and not app.park.paused,"skip stops decoder and restores exploration")
	layer.queue_free();await process_frame
	for audio in app.find_children("*","AudioStreamPlayer",true,false):audio.stop()
	await create_timer(.15).timeout
	app.queue_free();await process_frame
	print("LACERTUBO MOVIE ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
