extends SceneTree
const Speech=preload("res://scripts/campaign/hud_world_speech.gd")
const State=preload("res://scripts/campaign/state.gd")
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr(message)
func run() -> void:
	root.size=Vector2i(1280,720)
	root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	app.session._store=load("res://scripts/campaign/save_store.gd").new("user://polish-"+State.new_id())
	app.preferences.storage_path="user://polish-test.cfg"
	root.add_child(app)
	app.preferences.reduced_motion=true
	for sample in [
		[{"kind":"opening","step":2},"Quarto do Kael","bedroom-floor.png"],
		[{"kind":"opening","step":12},"Casa do Kael","home-floor.png"],
		[{"kind":"starter"},"Ateliê do Sr. Assis","workshop-background.png"],
		[{"kind":"workshop"},"Ateliê do Sr. Assis","workshop-background.png"],
		[{"kind":"world","scene":"morro-area-5"},"Morro do Sol · Praça da Campeã",""]]:
		var location:Dictionary=app._slot_location({"checkpoint":sample[0]})
		check(location.name==sample[1],"correct save location "+sample[1])
		check(location.texture!=null,"save thumbnail exists")
		if not sample[2].is_empty():check(location.texture.resource_path.ends_with(sample[2]),"thumbnail matches checkpoint")
	var full:String=load("res://scripts/campaign/morro_rules.gd").content().stories["morro-5"].before[0][1]
	check(Speech.preview(full)=="Então foi você que atravessou o bairro!","approach uses only the greeting")
	check(full.length()>Speech.preview(full).length(),"full dialogue remains available")
	load("res://tools/player_audit_fixtures.gd").show(app,"morro-area-5")
	for i in 12:await process_frame
	var place:Dictionary={}
	for candidate in app.park.data.places:
		if candidate.get("stage","")=="morro-5":place=candidate
	check(not place.is_empty(),"champion exists")
	var point:=Vector2(place.point[0],place.point[1])
	app.park.player=point+Vector2(55,35)
	app.park.ambient_seen.clear()
	app.park.ambient_speech(place.id)
	for i in 8:await process_frame
	var bubbles:=get_nodes_in_group("world_manga_speech")
	check(bubbles.size()==1,"one ambient balloon")
	var panel:Control=bubbles[0].get_child(0)
	check(panel.size.y<=100,"compact balloon height")
	check(bubbles[0].position.y+panel.size.y<=point.y-100,"balloon clears character head")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../tmp/playtest-polish.png")
	print("Playtest polish: %d checks, %d failures"%[checks,failures])
	app.free()
	quit(1 if failures else 0)
