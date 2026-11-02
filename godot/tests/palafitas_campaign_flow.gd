extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Service=preload("res://scripts/campaign/district_campaign.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
var app:Control
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func ready_world(scene:String)->void:
	for i in 1200:
		await process_frame
		if is_instance_valid(app.park) and app.park.get_meta("campaign_scene","")==scene and not is_instance_valid(app.scene_loading):return
	check(false,"world ready "+scene)
func capture(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/palafitas-championship-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder+"/"+name+".png")==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,720)
	app=load("res://scripts/campaign/front_end.gd").new()
	app.session._store=Store.new("user://palafitas-flow-"+State.new_id())
	root.add_child(app);app.preferences.reduced_motion=true
	check(app.session.start("slot-1").status=="ok","isolated save")
	var p:Dictionary=app.session.snapshot().player
	p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	var prior:=Rules.fresh("industrial");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(p,"industrial",prior)
	p.flags.mormacoLiberto=true
	var service:=Service.new(app.session)
	for i in 5:
		var id:="palafitas-"+str(i+1)
		var stage:=Service.stage(id)
		var at:=Vector2(stage.point[0]+.5,stage.point[1]+.5)
		var origin:=at+Vector2(1,0)
		check(CP.model_for(stage.scene).point_walkable(origin),"neighbor supported")
		for partner:Dictionary in p.partners:partner.condition={"line":100,"structure":100}
		check(app.session.checkpoint(CP.make(stage.scene,origin,CP.SPACE),p).status=="ok","visit "+id)
		app._show_world();await ready_world(stage.scene)
		var found:=false
		for actor in app.park.npc_nodes:
			if actor.root.get_meta("event",{}).get("props",{}).get("duel","")==id:
				found=actor.root.visible and actor.visual.get_child_count()>0
		check(found,"real event has visible art "+id)
		await capture(stage.npcId+"-map")
		app._district_action(id)
		await process_frame
		var dialogue:Control
		for child in app.get_children():
			if child.get_script()==load("res://scripts/campaign/hud_dialogue.gd"):dialogue=child
		check(is_instance_valid(dialogue),"duel confirmation "+id)
		if not is_instance_valid(dialogue):app.queue_free();quit(1);return
		dialogue.confirmed.emit()
		for tick in 40:await process_frame
		check(is_instance_valid(app.battle),"real battle screen "+id)
		if i==4:await capture("caio-battle-provisional-art")
		var saved:Dictionary=app.session.snapshot()
		var model:=Model.new();model.restore(saved.player.encounter.state);model.outcome="won"
		saved.player.encounter.state=model.snapshot()
		check(app.session.checkpoint(saved.checkpoint,saved.player).status=="ok","terminal fixture")
		check(service.settle().status=="ok","receipt "+id)
		p=app.session.snapshot().player
	check(p.districtEmblems.has("bairro-07"),"seventh emblem")
	app.queue_free();await process_frame
	print("PALAFITAS NATIVE FLOW: %d checks; %d failures; UI routing plus terminal outcome fixtures"%[checks,failures])
	quit(0 if failures==0 else 1)
