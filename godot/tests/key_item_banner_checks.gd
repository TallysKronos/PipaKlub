extends SceneTree
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Identity = preload("res://scripts/campaign/pipeiro_identity.gd")
const Banner = preload("res://scripts/campaign/hud_key_item_banner.gd")
var checks := 0
var failures := 0
var app: Control
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ",message)
func settle() -> void:
	for frame in 8: await process_frame
func run() -> void:
	app = load("res://scripts/campaign/front_end.gd").new()
	var folder := ProjectSettings.globalize_path("res://../tmp/key-banner-"+State.new_id())
	app.session._store = Store.new(folder)
	app.preferences.storage_path = folder+".cfg"
	root.add_child(app)
	app.preferences.reduced_motion = true
	check(app.session.start("slot-1").status=="ok","isolated save")
	var saved: Dictionary = app.session.snapshot()
	saved.player.journey = {"lesson":5,"phase":"choose"}
	saved.player.partners = [{"id":"banner-partner","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}]
	saved.player.equippedPartnerId = "banner-partner"
	Identity.issue_into(saved.player)
	check(app.session.checkpoint({"kind":"starter"},saved.player).status=="ok","documents already committed")
	var before: Dictionary = app.session.snapshot()
	for id in ["carteira-pipeiro","porta-emblemas"]:
		var png: Image = load("res://assets/ui/key-items/"+id+".png").get_image()
		check(png.get_size()==Vector2i(128,128),"native 128x128 "+id)
		var colors := {}; var alpha_ok := true
		for y in 128:
			for x in 128:
				var color := png.get_pixel(x,y)
				if color.a>0: colors[color.to_html()]=true
				if color.a!=0 and color.a!=1: alpha_ok=false
		check(alpha_ok,"no semitransparent sprite pixels "+id)
		check(colors.size()<=13,"limited palette "+id)
	load("res://scripts/campaign/tutorial_staging.gd").professor_stage(app,Vector2(1152,864))
	app.room.can_walk=false
	var banner := Banner.new()
	banner.item_name="Carteira de Pipeiro"
	banner.item_texture=load("res://assets/ui/key-items/carteira-pipeiro.png")
	app.add_child(banner)
	banner.set_process(false)
	check(banner.DURATION==2.5,"short 2.5-second acquisition")
	check(banner.opacity_at(0)==0 and banner.opacity_at(.6)==1 and banner.opacity_at(2.5)==0,"fade in, hold, fade out")
	check(banner.item_scale_at(.1)==0 and banner.item_scale_at(.32)>1 and banner.item_scale_at(.8)==1,"small item impact settles")
	banner.reduced_motion=true
	check(banner.item_scale_at(.2)==1,"reduced motion removes scale impact")
	banner.reduced_motion=false
	check(banner.band.gradient.get_color(0).a==0 and banner.band.gradient.get_color(3).a==0,"band ends fade to transparency")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.keycode=KEY_ESCAPE;escape.pressed=true
	root.push_input(escape,true)
	await settle()
	check(not is_instance_valid(app.pause_overlay) and not app.room.can_walk,"banner blocks gameplay and pause input")
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=viewport
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		banner.elapsed=.8
		banner.queue_redraw()
		await settle()
		check(banner.size==app.size,"banner spans viewport %s" % viewport)
		if "--capture" in OS.get_cmdline_user_args():
			var output:=ProjectSettings.globalize_path("res://../documentation/qa/key-item-banner-v1")
			DirAccess.make_dir_recursive_absolute(output)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("banner-%dx%d.png" % [viewport.x,viewport.y]))
	var completions := [0]
	banner.finished.connect(func():completions[0]+=1)
	banner._process(5)
	banner._process(5)
	check(banner.done and completions[0]==1,"finished emits once")
	check(app.session.snapshot().player==before.player,"presentation changes no inventory or XP")
	banner.queue_free()
	await settle()
	check(app.session.resume_slot("slot-1").status=="ok" and Identity.pending(app.session.snapshot()),"interrupted delivery resumes")
	app._show_saved()
	var observed := []
	var help_seen := false
	var conflict_injected := false
	var retry_seen := false
	for frame in 180:
		if app.last_scene_key=="page:oficina": break
		for child in app.get_children():
			if child.has_meta("key_item_banner") and not child.done:
				observed.append(child.item_name)
				child._process(2.5)
		for dialog in get_nodes_in_group("manga_dialogue"):
			if dialog.is_queued_for_deletion():continue
			if "menu de pausa" in dialog.dialog_text:
				help_seen=true
				if not conflict_injected:
					var newer:Dictionary=app.session._store.load_slot("slot-1").data
					check(app.session._store.save_slot(newer).status=="ok","simulate save conflict at delivery end")
					conflict_injected=true
				dialog.confirmed.emit()
			elif dialog.ok_button_text=="Tentar novamente":
				retry_seen=true
				check(Identity.pending(app.session.snapshot()),"failed acknowledgement preserves pending delivery")
				check(app.session.resume_slot("slot-1").status=="ok","reload conflict revision")
				dialog.confirmed.emit()
		await process_frame
	check(observed==["Carteira de Pipeiro","Porta-emblemas"],"two separate banners, correct order, no repeats")
	check(help_seen,"menu guidance follows both banners")
	check(retry_seen and app.last_scene_key=="page:oficina","retry recovers without trapping player")
	check(not Identity.pending(app.session.snapshot()),"delivery acknowledged only at the end")
	check(app.session.snapshot().player.pipeiroIdentity.id==before.player.pipeiroIdentity.id and app.session.snapshot().player.inventory["carteira-pipeiro"]==1 and app.session.snapshot().player.inventory["porta-emblemas"]==1,"replayed presentation never regrants items")
	app._show_saved()
	await settle()
	check(app.last_scene_key=="page:oficina" and not app.get_children().any(func(child):return child.has_meta("key_item_banner")),"completed presentation does not repeat on load")
	app.queue_free()
	await settle()
	print("KEY ITEM BANNER: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
