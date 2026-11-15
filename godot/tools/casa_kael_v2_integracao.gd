extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const CP=preload("res://scripts/campaign/neighborhood_checkpoint.gd")
const House=preload("res://scripts/overworld/kael_house_v2.gd")
const OUT="res://../art/casa-kael-v2/fachada/integracao/"
var app:Control
var checks:Array=[]
func check(ok:bool,label:String) -> void:
	checks.append({"ok":ok,"label":label})
	if not ok:printerr("FAIL ",label)
func _initialize() -> void:call_deferred("run")
func ready_city() -> void:
	for i in 300:
		if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):break
		await process_frame
	app.park.set_physics_process(false)
	app.park.paused=false
func travel(target:Vector2) -> void:
	var play=app.park
	for i in 1200:
		if play.cell.distance_to(target)<.015:break
		var before:Vector2=play.cell
		play.walk((target-play.cell).normalized()*minf(.025,play.cell.distance_to(target)))
		if play.cell.distance_to(before)<.000001:break
	check(play.cell.distance_to(target)<.03,"walk "+str(target))
	play._refresh_visuals();play._update_hint()
func shot(id:String,zoom:float=1.0) -> void:
	var play=app.park
	play._refresh_visuals();play._update_hint()
	play.camera.position_smoothing_enabled=false
	play.camera.zoom=Vector2.ONE*zoom
	play.camera.position=play.world.iso(Vector2(5.5,15))-Vector2(0,150) if zoom<=1 else play.player_root.position-Vector2(0,55)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+id+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.gui_disable_input=true
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:=ProjectSettings.globalize_path("res://../.local/qa/casa-kael-v2-"+State.new_id())
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder)
	app.preferences.storage_path=folder+"/preferences.cfg"
	root.add_child(app)
	app.preferences.reduced_motion=true
	check(app.session.start("slot-1").status=="ok","isolated QA slot")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"}
	player.partners=[{"id":"qa-house-partner","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100},"origin":"visual-qa","certification":"unverified"}]
	player.equippedPartnerId="qa-house-partner"
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(player)
	player.flags.pipeiroDocumentsSeen=true
	check(app.session.checkpoint(CP.make(CP.HOME,player),player).status=="ok","HOME checkpoint accepted")
	app._show_saved()
	await ready_city()
	var play=app.park
	check(play.cell==CP.HOME,"HOME unchanged on load")
	check(not play._obstructed(CP.HOME,"4:17"),"return point unblocked")
	check(not play._obstructed(House.GATE,"4:18"),"gate opening unblocked")
	check(play._obstructed(Vector2(2.0,18.2),"2:18"),"front wall blocks walking")
	var meshes:=0
	for item in play.world.parts:
		var texture:Texture2D=item.node.texture
		if texture!=null and texture.resource_path.begins_with(House.BASE):
			meshes+=1
			check(item.node.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"nearest retained after visibility rebuild")
	check(meshes==8,"seven cutouts and split foreground mounted")
	check((House.origin(play.world)+House.GATE_PIXEL).distance_to(play.world.iso(House.GATE,8))<1,"gate pixel aligned within one pixel")
	await shot("01-geral")
	travel(Vector2(4.4,19.0))
	await shot("02-portao-fora",2.0)
	travel(CP.HOME)
	travel(Vector2(7.0,17.7))
	await shot("03-muro-dentro",2.0)
	travel(CP.HOME)
	travel(Vector2(4.4,19.0))
	travel(Vector2(7.0,18.7))
	await shot("04-muro-fora",2.0)
	travel(Vector2(4.4,19.0))
	travel(CP.HOME)
	travel(Vector2(4.4,16.7))
	travel(House.DOOR)
	check(play.near_house.get("id")=="casa-kael","visible doorway selects house")
	check(play.exploration_hud.prompt.text=="Entrar em casa","doorway shows enter-home prompt")
	await shot("05-soleira",2.0)
	play.interact()
	for i in 100:
		if is_instance_valid(app.room) and app.session.snapshot().checkpoint.scene=="kael-home":break
		await process_frame
	check(app.session.snapshot().checkpoint.scene=="kael-home" and is_instance_valid(app.room),"interaction opens real home interior")
	app._world_interact("exit")
	await ready_city()
	check(app.session.snapshot().checkpoint.scene=="quintal","home exit returns to city")
	check(app.park.cell.distance_to(CP.HOME)<.01,"home exit preserves canonical HOME")
	await shot("06-retorno")
	var failed:=checks.filter(func(c:Dictionary)->bool:return not c.ok).size()
	FileAccess.open(OUT+"qa.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"qa_store":folder,"user_saves_touched":false},"\t"))
	print("CASA KAEL V2: ",checks.size()," checks; ",failed," failures")
	app.session._snapshot.clear()
	app.free()
	quit(1 if failed else 0)
