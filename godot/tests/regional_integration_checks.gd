extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func run() -> void:
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://regional-"+State.new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder)
	app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	app.session.start("slot-1")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"}
	player.partners=[{"id":"regional-partner","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="regional-partner"
	app.session.checkpoint({"kind":"world","scene":"quintal","position":[4.4,17.4],"space":"bairro-inicial-v2"},player)
	player=app.session.snapshot().player.duplicate(true)
	var service=load("res://scripts/campaign/bosque_campaign.gd").new(app.session)
	for scene in CP.MAPS:
		if not (scene.begins_with("mina-ferro-") or scene.begins_with("gelo-") or scene.begins_with("submerso-")):continue
		check(service.travel(scene).status=="ok","travel "+scene)
		check(app.session.resume_slot("slot-1").status=="ok","reload "+scene)
		var saved:Dictionary=app.session.snapshot()
		check(State.inspect(saved,"slot-1")=="ok" and saved.checkpoint.scene==scene,"valid restored destination "+scene)
		check(CP.is_regional_preview(scene),"exploration without campaign encounters "+scene)
		for event in CP.data(scene).events:
			if event.type!="saida":continue
			var cp:Dictionary=CP.make(scene,Vector2(event.u+.5,event.v+.5),CP.SPACE)
			var target:Dictionary=CP.exit_target(cp,str(int(event.id)),saved.player)
			check(target.status=="ok","campaign exit "+scene+"/"+str(event.id))
			if target.status=="ok":
				check(target.scene==event.props.destino and target.point==Vector2(event.props.chegada_u+.5,event.props.chegada_v+.5),"authored arrival "+scene)
		app._show_park()
		for frame in 5:await process_frame
		check(is_instance_valid(app.park) and app.park.area_id==scene,"actual campaign renderer "+scene)
		check(app.park.model.point_walkable(app.park.player),"supported player "+scene)
		if "--capture" in OS.get_cmdline_user_args() and scene in ["mina-ferro-a","gelo-a","submerso-a"]:
			var out:=ProjectSettings.globalize_path("res://../documentation/qa/integracao-regional-2026-11-01")
			DirAccess.make_dir_recursive_absolute(out)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join(scene+".png"))
	check(app.session.snapshot().player.partners[0].xp==player.partners[0].xp and app.session.snapshot().player.coins==player.coins,"exploration grants no automatic XP or money")
	app.free();await process_frame
	print("REGIONAL INTEGRATION: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
