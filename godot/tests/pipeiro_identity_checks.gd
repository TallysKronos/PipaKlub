extends SceneTree
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Identity = preload("res://scripts/campaign/pipeiro_identity.gd")
var app: Control
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ",message)
func settle() -> void:
	for i in 12: await process_frame
func card() -> Control:
	for child in app.get_children():
		if child.get_script() == load("res://scripts/campaign/hud_pipeiro_identity.gd"): return child
	return null
func run() -> void:
	app = load("res://scripts/campaign/front_end.gd").new()
	var folder := "user://identity-" + State.new_id()
	app.session._store = Store.new(folder)
	app.preferences.storage_path = folder + ".cfg"
	root.add_child(app)
	app.preferences.reduced_motion = true
	check(app.session.start("slot-1").status=="ok","isolated journey")
	check(Identity.ensure_legacy(app.session).status=="already_applied" and not Identity.issued(app.session.snapshot().player),"no documents before training")
	var saved: Dictionary = app.session.snapshot()
	saved.player.journey = {"lesson":4,"phase":"practice"}
	saved.player.partners = [{"id":"identity-partner","modelId":"rabbito","personalName":"Rabbito","xp":880,"condition":{"line":100,"structure":100}}]
	saved.player.equippedPartnerId = "identity-partner"
	saved.player.coins = 342
	saved.player.tamerXp = 120
	check(app.session.checkpoint({"kind":"practice","lesson":4},saved.player).status=="ok","final training fixture")
	check(app.journey.lesson_completed(3).status=="wrong_step","earlier lesson cannot issue documents")
	var external: Dictionary = app.session._store.load_slot("slot-1").data
	check(app.session._store.save_slot(external).status=="ok","concurrent save fixture")
	check(app.journey.lesson_completed(4).status=="stale" and not Identity.issued(app.session.snapshot().player),"failed lesson save grants no documents")
	check(app.session.resume_slot("slot-1").status=="ok","reload latest revision")
	check(app.journey.lesson_completed(4).status=="ok","last lesson and documents commit together")
	saved = app.session.snapshot()
	var registration: String = saved.player.pipeiroIdentity.id
	check(saved.player.inventory["carteira-pipeiro"]==1 and saved.player.inventory["porta-emblemas"]==1,"both permanent items received once")
	check(Identity.pending(saved) and saved.checkpoint.kind=="starter","receipt leads into workshop choice")
	check(Identity.ensure_legacy(app.session).status=="already_applied" and app.session.snapshot().player.pipeiroIdentity.id==registration,"registration stable on retry")
	check(Identity.tamer_level(0)==1 and Identity.tamer_level(22)==1 and Identity.tamer_level(23)==2 and Identity.tamer_level(120)==4,"tamer curve agrees with battle HUD")
	# Drive the real handoff scene; dialogue confirmation is automated, not a human playtest.
	Engine.time_scale = 30
	load("res://scripts/campaign/tutorial_staging.gd").after_practice(app)
	var confirmed := {}
	for frame in 1600:
		if app.last_scene_key=="page:oficina": break
		for banner in app.get_children():
			if banner.has_meta("key_item_banner"): banner._process(2.5)
		for dialog in get_nodes_in_group("manga_dialogue"):
			if confirmed.has(dialog.get_instance_id()): continue
			confirmed[dialog.get_instance_id()] = true
			dialog.confirmed.emit()
		await process_frame
	Engine.time_scale = 1
	check(app.last_scene_key=="page:oficina" and not is_instance_valid(card()),"professor scene presents banners then goes directly to workshop")
	check(confirmed.size()==2,"both professor handoff conversations complete")
	check(not Identity.pending(app.session.snapshot()),"delivery acknowledged after menu guidance")
	app._show_identity()
	await settle()
	check(card().slots.size()==12,"exactly twelve emblem slots")
	check(card().slots.all(func(slot): return not slot.earned),"training and guardian give no district emblems")
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = viewport
		if DisplayServer.get_name()!="headless": DisplayServer.window_set_size(viewport)
		await settle()
		for slot in card().slots: check(root.get_visible_rect().encloses(slot.get_global_rect()),"emblem fits %s" % viewport)
		check(root.get_visible_rect().encloses(card().back.get_global_rect()),"return button fits")
		check(root.gui_get_focus_owner()==card().back,"initial keyboard focus")
		if "--capture" in OS.get_cmdline_user_args():
			var output := ProjectSettings.globalize_path("res://../documentation/qa/pipeiro-identity-v1")
			DirAccess.make_dir_recursive_absolute(output)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("carteira-%dx%d.png" % [viewport.x,viewport.y]))
	card().slots[11].pressed.emit()
	check("12" in card().detail.text,"slot details selectable")
	check(app.session.resume_slot("slot-1").status=="ok" and not Identity.pending(app.session.snapshot()),"completed presentation remains acknowledged")
	app._show_saved()
	await settle()
	check(not is_instance_valid(card()),"loading does not open full identity automatically")
	await settle()
	check(app.session.snapshot().checkpoint.kind=="starter" and not Identity.pending(app.session.snapshot()),"store documents and continue to workshop")
	check(app.last_scene_key=="page:oficina","workshop selection displayed")
	var player: Dictionary = app.session.snapshot().player
	check(Identity.award_district(player,0,"boss-test","Emblema de teste"),"future boss settlement can assign a slot")
	check(not Identity.award_district(player,0,"boss-test","Emblema de teste"),"same slot cannot reward twice")
	check(not Identity.award_district(player,1,"boss-test","Duplicado"),"same chief cannot occupy two slots")
	check(not Identity.award_district(player,12,"boss-invalid","Inválido"),"no thirteenth slot")
	check(app.session.checkpoint(app.session.snapshot().checkpoint,player).status=="ok","earned emblem serializes")
	check(app.session.resume_slot("slot-1").status=="ok" and app.session.snapshot().player.districtEmblems.size()==1,"earned emblem survives reload")
	var malformed: Dictionary = app.session.snapshot()
	malformed.player.districtEmblems["bairro-13"] = {"name":"Inválido"}
	check(State.inspect(malformed,"slot-1")=="invalid","bad emblem data rejected")
	malformed = app.session.snapshot()
	malformed.player.pipeiroIdentity.id = "bad"
	check(State.inspect(malformed,"slot-1")=="invalid","bad document data rejected")
	# Existing saves receive the documents once without resetting money, XP or location.
	check(app.session.start("slot-2").status=="ok","legacy journey fixture")
	player = app.session.snapshot().player
	player.journey = {"lesson":5,"phase":"complete"}
	player.partners = saved.player.partners
	player.equippedPartnerId = "identity-partner"
	player.coins = 987
	player.tamerXp = 500
	check(app.session.checkpoint({"kind":"world","scene":"professor-home","position":[1152,864]},player).status=="ok","legacy checkpoint")
	check(Identity.ensure_legacy(app.session).status=="ok","legacy documents issued")
	check(app.session.snapshot().player.coins==987 and app.session.snapshot().player.tamerXp==500,"migration preserves progression")
	check(Identity.acknowledge(app.session).status=="ok","legacy presentation acknowledged")
	app._show_saved()
	await settle()
	app._pause_game()
	await settle()
	check(app.pause_overlay.buttons.has("identity") and not app.pause_overlay.buttons.identity.disabled,"pause menu has working identity entry")
	root.size = Vector2i(1280,720)
	await settle()
	for button in app.pause_overlay.buttons.values():check(root.get_visible_rect().encloses(button.get_global_rect()),"expanded pause menu stays on screen")
	app.pause_overlay.buttons.identity.pressed.emit()
	await settle()
	check(is_instance_valid(card()),"pause entry opens identity")
	var long_player: Dictionary = app.session.snapshot().player
	long_player.name = "Um nome de pipeiro extremamente comprido para conferir o recorte"
	check(app.session.checkpoint(app.session.snapshot().checkpoint,long_player).status=="ok","long name fixture")
	app._show_identity()
	await settle()
	check(card().name_label.text==long_player.name and card().name_label.tooltip_text==long_player.name,"long name preserved with tooltip")
	check(root.get_visible_rect().encloses(card().back.get_global_rect()) and root.get_visible_rect().encloses(card().slots[11].get_global_rect()),"long name does not displace controls")
	var escape := InputEventKey.new();escape.pressed=true;escape.physical_keycode=KEY_ESCAPE
	app._unhandled_input(escape)
	await settle()
	check(is_instance_valid(app.pause_overlay) and app.pause_overlay.focus_action=="identity","Escape restores pause focus")
	app.queue_free()
	await settle()
	print("PIPEIRO IDENTITY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
