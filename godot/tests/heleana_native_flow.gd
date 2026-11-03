extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
var app:Control
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720)
	app=load("res://scripts/campaign/front_end.gd").new();app.session._store=Store.new("user://heleana-native-"+State.new_id());root.add_child(app)
	app.preferences.reduced_motion=true
	check(app.session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=app.session.snapshot().player
	p.flags.retalhoRecusadoKael=true
	p.partners=[{"id":"r","modelId":"rabbito","xp":0}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	var district:=Rules.fresh("palafitas");district.completed=true;district.rewardClaimed=true;district.champion="player";Rules.store(p,"palafitas",district)
	check(app.session.checkpoint({"kind":"world","scene":"kael-home","position":[432,1008]},p).status=="ok","home checkpoint")
	app._show_world()
	for i in 20:await process_frame
	check(is_instance_valid(app.room) and is_instance_valid(app.room.mother_sprite),"real house and mother loaded")
	# Returning home starts the grunt automatically.
	for i in 6:await process_frame
	var dialog:=app.get_node_or_null("HeleanaConfessionDialogue")
	check(is_instance_valid(dialog) and app.flow_busy and not app.room.can_walk,"dialogue locks movement")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var dir:=ProjectSettings.globalize_path("res://../documentation/qa/heleana-confession-v1");DirAccess.make_dir_recursive_absolute(dir)
		root.get_texture().get_image().save_png(dir+"/confissao-casa.png")
	if is_instance_valid(dialog):dialog.canceled.emit()
	for i in 6:await process_frame
	check(not app.flow_busy and app.room.can_walk,"cancel releases movement")
	app._show_heleana_confession()
	for step in 13:
		for frame in 30:await process_frame
		var active:=app.get_node_or_null("HeleanaConfessionDialogue")
		check(is_instance_valid(active),"dialogue continues "+str(step))
		if not is_instance_valid(active):break
		if step==3:
			active.canceled.emit()
			for frame in 6:await process_frame
			check(not app.park.paused,"outside cancel releases controls")
			app.park.interact()
			for frame in 6:await process_frame
			active=app.get_node_or_null("HeleanaConfessionDialogue")
			check(is_instance_valid(active),"outside interaction resumes confession")
			if not is_instance_valid(active):break
		if step==8 and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/qa/heleana-confession-v1/reconhecimento-exterior.png"))
		active.confirmed.emit()
	for frame in 6:await process_frame
	check(app.session.snapshot().player.flags.get("retalhoParceiraHeleana",false),"reunion saved through real dialogue signals")
	check(is_instance_valid(app.park) and not app.park.paused and not app.flow_busy,"outside completion releases movement")
	check(app.session.snapshot().player.partners.size()==1,"refused partner never added to bank")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/qa/heleana-confession-v1/reuniao-exterior.png"))
	p=app.session.snapshot().player
	check(app.session.checkpoint({"kind":"world","scene":"kael-home","position":[432,1008]},p).status=="ok","return home after reunion")
	app._show_world()
	for frame in 20:await process_frame
	check(is_instance_valid(app.room.retalho_resident),"Heleana's partner appears inside the house")
	if is_instance_valid(app.room.retalho_resident):
		var start:Vector2=app.room.retalho_point
		var safe:=true
		for frame in 180:
			app.room._process(1.0/60.0)
			safe=safe and app.room._safe(app.room.retalho_point)
		check(safe and start.distance_to(app.room.retalho_point)>12,"Retalho roams through walkable interior")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/qa/heleana-confession-v1/retalho-em-casa.png"))
	check(app.session.start("slot-2").status=="ok","accepted branch save")
	p=app.session.snapshot().player
	p.partners=[{"id":"ret","modelId":"retalho-original","personalName":"Nuvem","xp":0}]
	p.equippedPartnerId="ret";p.flags.retalhoAcolhido=true;p.journey={"phase":"complete","lesson":5}
	check(app.session.checkpoint({"kind":"world","scene":"kael-home","position":[1040,912]},p).status=="ok","accepted home")
	app._show_world()
	for frame in 20:await process_frame
	check(not is_instance_valid(app.get_node_or_null("HeleanaConfessionDialogue")),"accepted branch waits for interaction")
	check(not is_instance_valid(app.room.retalho_resident) and app.room.retalho_follower,"Kael's Retalho uses the directional sheet as follower")
	app._world_interact("mother")
	for step in 13:
		for frame in 6:await process_frame
		var active:=app.get_node_or_null("HeleanaConfessionDialogue")
		check(is_instance_valid(active),"accepted dialogue "+str(step))
		if not is_instance_valid(active):break
		active.confirmed.emit()
	for frame in 6:await process_frame
	p=app.session.snapshot().player
	check(p.flags.get("heleanaLacoKael",false) and p.flags.get("heleanaReconheceuRetalho",false),"accepted bond preserved")
	check(p.partners[0].personalName=="Nuvem" and not p.flags.get("retalhoParceiraHeleana",false),"no reunion or rename on accepted route")
	app.queue_free();await process_frame
	print("HELEANA NATIVE FLOW: ",failures," failures");quit(0 if failures==0 else 1)

