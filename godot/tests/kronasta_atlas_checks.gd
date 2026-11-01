extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Atlas=preload("res://scripts/campaign/kronasta_atlas.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
var checks:=0
var failures:=0
var app:Control
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 8:await process_frame
func run() -> void:
	if await exercise()!=true:failures+=1;printerr("Suite did not complete")
	if is_instance_valid(app):app.queue_free()
	await settle()
	print("KRONASTA ATLAS: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
func exercise() -> bool:
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://atlas-"+State.new_id()
	app.session._store=Store.new(folder)
	app.preferences.storage_path=folder+".cfg"
	root.add_child(app)
	check(app.session.start("slot-1").status=="ok","isolated journey")
	var saved:Dictionary=app.session.snapshot()
	saved.player.partners=[{"id":"atlas-partner","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}]
	saved.player.equippedPartnerId="atlas-partner"
	saved.player.journey={"phase":"complete","lesson":5}
	check(app.session.checkpoint({"kind":"world","scene":"quintal","position":[4.4,17.4],"space":"bairro-inicial-v2"},saved.player).status=="ok","travel-ready player")
	var service=load("res://scripts/campaign/bosque_campaign.gd").new(app.session)
	var before:Dictionary=app.session.snapshot().player.duplicate(true)
	for region in Atlas.REGIONS:
		for scene in region.scenes:
			check(service.travel(scene).status=="ok","travel to "+scene)
			var cp:Dictionary=app.session.snapshot().checkpoint
			check(cp.scene==scene and State.inspect(app.session.snapshot(),"slot-1")=="ok","save validates "+scene)
			if Checkpoint.MAPS.has(scene):check(Checkpoint.model_for(scene).point_walkable(Vector2(cp.position[0],cp.position[1])),"supported spawn "+scene)
	for scene in ["vulcao","ruinas","kronasta-pantano-z","res://invalid"]:
		var old:Dictionary=app.session.snapshot()
		check(service.travel(scene).status=="wrong_step" and app.session.snapshot()==old,"unavailable destination cannot mutate save")
	check(app.session.snapshot().player.partners==before.partners and app.session.snapshot().player.coins==before.coins,"travel grants no XP or money")
	check(service.travel("kronasta-pantano-a").status=="ok","select swamp")
	check(app.session.resume_slot("slot-1").status=="ok" and app.session.snapshot().checkpoint.scene=="kronasta-pantano-a","regional destination survives reload")
	app._show_park()
	await settle()
	check(is_instance_valid(app.park) and app.park.area_id=="kronasta-pantano-a","swamp opens through actual campaign adapter")
	app.park.paused=false
	var map_key:=InputEventKey.new();map_key.pressed=true;map_key.physical_keycode=KEY_M
	app._unhandled_input(map_key)
	await settle()
	check(app.last_scene_key=="page:REGIÃO DE KRONASTA","M map entry opens regional atlas")
	var atlas:Control
	for child in app.get_children():
		if child.get_script()==load("res://scripts/campaign/hud_kronasta_map.gd"):atlas=child
	check(is_instance_valid(atlas),"atlas attached")
	if not is_instance_valid(atlas):return false
	check(atlas.art!=null and atlas.markers.size()==12,"illustration and twelve region points")
	for i in Atlas.REGIONS.size():
		atlas.select(i)
		var region:Dictionary=Atlas.REGIONS[i]
		check(atlas.markers[i].lit==not region.scenes.is_empty(),"marker state "+region.id)
		if region.scenes.is_empty():check(atlas.parts.get_child(0).disabled,"future destination has disabled access")
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=viewport
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		await settle()
		atlas.select(3)
		await settle()
		check(root.get_visible_rect().encloses(atlas.side.get_rect()),"details stay on screen")
		for marker in atlas.markers:check(root.get_visible_rect().encloses(marker.get_rect()),"region marker stays on screen")
		check(root.get_visible_rect().encloses(atlas.footer.get_rect()),"footer fits screen")
		if not root.get_visible_rect().encloses(atlas.footer.get_rect()):
			print("FOOTER ",atlas.footer.get_rect()," minimum ",atlas.footer.get_combined_minimum_size())
			for child in atlas.footer.get_children():print(child.get_class()," ",child.get_rect()," min ",child.get_combined_minimum_size())
		if "--capture" in OS.get_cmdline_user_args():
			var folder_out:=ProjectSettings.globalize_path("res://../documentation/qa/kronasta-atlas-v1")
			DirAccess.make_dir_recursive_absolute(folder_out)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder_out.path_join("atlas-%dx%d.png"%[viewport.x,viewport.y]))
	atlas.select(9)
	check(atlas.parts.get_child(0).disabled,"volcano stays unavailable")
	app._show_local_map()
	await settle()
	check(app.page!=null,"local area map remains accessible")
	return true
