extends SceneTree
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Demo = preload("res://scripts/campaign/demo_flow.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
var checks := 0
var failures := 0
var app: Control

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)
func settle() -> void:
	for i in 10: await process_frame
func run() -> void:
	app = load("res://scripts/campaign/front_end.gd").new()
	var folder := "user://demo-completion-" + State.new_id()
	app.session._store = Store.new(folder)
	app.preferences.storage_path = folder + ".cfg"
	root.add_child(app)
	app.preferences.reduced_motion = true
	check(app.session.start("slot-1").status == "ok", "isolated save")
	check(not Demo.pending(app.session.snapshot()), "opening cannot end demo")
	check(Demo.acknowledge(app.session).status == "wrong_step", "reject premature acknowledgement")
	var saved: Dictionary = app.session.snapshot()
	saved.player.journey = {"phase":"complete", "lesson":5}
	saved.player.partners = [{"id":"demo-partner", "modelId":"rabbito", "xp":880, "condition":{"line":100,"structure":100}}]
	saved.player.equippedPartnerId = "demo-partner"
	saved.player.flags = {"ninaAccepted":true,"guardianDefeated":true}
	var nina := Checkpoint.target("park-trail", "nina")
	var cp := Checkpoint.make("park-trail", nina, Checkpoint.SPACE)
	check(app.session.checkpoint(cp, saved.player).status == "ok", "boss victory saved")
	check(not Demo.pending(app.session.snapshot()), "boss victory alone is not ending")
	check(app.exploration.return_tail(nina).status == "wrong_step", "cannot return missing tail")
	saved = app.session.snapshot()
	saved.player.flags.ninaTail = true
	saved.player.inventory["quest-nina-tail"] = 1
	check(app.session.checkpoint(cp, saved.player).status == "ok", "tail collected")
	check(not Demo.pending(app.session.snapshot()), "collecting tail does not skip return")
	check(app.exploration.return_tail(nina + Vector2(20,20)).status == "wrong_step", "cannot hand over remotely")
	var newer: Dictionary = app.session._store.load_slot("slot-1").data
	check(app.session._store.save_slot(newer).status == "ok", "simulate conflict before handover")
	check(app.exploration.return_tail(nina).status == "stale", "failed handover reports save conflict")
	check(not Demo.pending(app.session.snapshot()) and app.session.snapshot().player.inventory.get("quest-nina-tail",0) == 1, "failed handover preserves quest item and pending quest")
	check(app.session.resume_slot("slot-1").status == "ok", "recover latest handover revision")
	var before: Dictionary = app.session.snapshot().player
	app._show_park()
	await settle()
	app._park_action("nina")
	await settle()
	check(app.session.snapshot().player.flags.get("ninaReturned", false), "actual Nina interaction commits handover")
	var dialogues := get_nodes_in_group("manga_dialogue")
	check(dialogues.size() == 1 and app.park.paused, "homecoming dialogue holds gameplay")
	if not dialogues.is_empty(): dialogues[0].confirmed.emit()
	await settle()
	check(app.last_scene_key == "page:DEMO CONCLUÍDA", "homecoming confirmation opens ending")
	check(Demo.pending(app.session.snapshot()), "handover opens pending ending")
	check(not app.session.snapshot().player.inventory.has("quest-nina-tail"), "quest item removed")
	check(app.session.snapshot().player.partners == before.partners and app.session.snapshot().player.coins == before.coins, "ending grants no extra XP or money")
	check(app.exploration.return_tail(nina).status == "already_applied", "handover cannot repeat")
	check(app.session.resume_slot("slot-1").status == "ok" and Demo.pending(app.session.snapshot()), "interrupted ending resumes from disk")
	app._show_saved()
	await settle()
	check(app.last_scene_key == "page:DEMO CONCLUÍDA", "resume shows actual ending")
	check(Vector2(app.session.snapshot().checkpoint.position[0],app.session.snapshot().checkpoint.position[1]).is_equal_approx(nina), "world position preserved")
	var ending: Control
	for child in app.get_children():
		if child.get_script() == load("res://scripts/campaign/hud_demo_complete.gd"): ending = child
	check(is_instance_valid(ending), "ending view attached")
	if not is_instance_valid(ending): quit(1); return
	for viewport in [Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = viewport
		if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(viewport)
		await settle()
		for button in ending.buttons.values():
			check(root.get_visible_rect().encloses(button.get_global_rect()), "ending action fits %s" % viewport)
		check(root.gui_get_focus_owner() == ending.buttons.explore, "initial keyboard focus")
		if "--capture" in OS.get_cmdline_user_args():
			var output := ProjectSettings.globalize_path("res://../documentation/qa/demo-completion-v1")
			DirAccess.make_dir_recursive_absolute(output)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("ending-%dx%d.png" % [viewport.x,viewport.y]))
	# A stale writer must keep the ending and its acknowledgement uncommitted.
	var external: Dictionary = app.session._store.load_slot("slot-1").data
	check(app.session._store.save_slot(external).status == "ok", "simulate concurrent save")
	app._finish_demo("explore")
	check(app.last_scene_key == "page:DEMO CONCLUÍDA" and not app.session.snapshot().player.flags.get("demoEndingSeen",false), "save failure stays on ending")
	check(app.session.resume_slot("slot-1").status == "ok", "reload latest revision")
	app._show_saved()
	for child in app.get_children():
		if child.get_script() == load("res://scripts/campaign/hud_demo_complete.gd"): child.buttons.map.pressed.emit()
	await settle()
	check(app.last_scene_key == "page:REGIÃO DE KRONASTA", "map choice opens atlas")
	check(not Demo.pending(app.session.snapshot()), "ending acknowledged atomically")
	check(app.session.snapshot().checkpoint == cp, "atlas keeps world checkpoint")
	app._show_saved()
	await settle()
	check(is_instance_valid(app.park) and app.last_scene_key.begins_with("world:"), "exploration resumes without repeating ending")
	var resumed_partner: Dictionary = app.session.snapshot().player.partners[0]
	check(resumed_partner.xp == before.partners[0].xp and resumed_partner.condition.line == before.partners[0].condition.line and resumed_partner.condition.structure == before.partners[0].condition.structure, "resume preserves partner XP and condition")
	app._show_demo_complete()
	var escape := InputEventKey.new(); escape.pressed = true; escape.physical_keycode = KEY_ESCAPE
	app._unhandled_input(escape)
	await settle()
	check(is_instance_valid(app.park), "Escape returns to exploration")
	app._show_demo_complete()
	for child in app.get_children():
		if child.get_script() == load("res://scripts/campaign/hud_demo_complete.gd"): child.buttons.menu.pressed.emit()
	await settle()
	check(app.last_scene_key == "menu" and app.session.snapshot().is_empty(), "menu choice closes session")
	check(app.session.resume_slot("slot-1").status == "ok" and not Demo.pending(app.session.snapshot()), "menu save can resume without ending loop")
	app.queue_free()
	await settle()
	print("DEMO COMPLETION: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)

