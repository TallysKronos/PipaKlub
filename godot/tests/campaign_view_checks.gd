extends SceneTree
## Integration checks use an injected store, never the player's campaign directory.
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

# The park opens behind an animated loading cover outside headless mode.
func settle_park(view: Node) -> void:
	for frame in 600:
		await process_frame
		if not view.flow_busy and not is_instance_valid(view.scene_loading): return

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var view := FrontEnd.new()
	view.session._store = Store.new("user://campaign-view-checks-" + State.new_id())
	root.add_child(view)
	await process_frame
	check(view.session.start("slot-1").status == "ok", "create integration slot")
	var saved: Dictionary = view.session.snapshot()
	saved.player.partners = [{"id": State.new_id(), "modelId": "rabbito", "personalName": "Brisa", "xp": 0, "craftBonus": 0, "condition": {"line": 100, "structure": 100}}]
	saved.player.equippedPartnerId = saved.player.partners[0].id
	saved.player.journey = {"lesson": 5, "phase": "complete"}
	# The park now uses the native cell space of the overworld maps (park_checkpoint.gd).
	var entry: Vector2 = Checkpoint.spawn("park-veredas")
	check(view.session.checkpoint(Checkpoint.make("park-veredas", entry, Checkpoint.SPACE), saved.player).status == "ok", "park checkpoint")
	view._show_saved()
	await settle_park(view)
	check(is_instance_valid(view.park), "campaign creates park view")
	check(is_instance_valid(view.park.guardian_art) and view.park.guardian_art.is_visible_in_tree(), "boss appears before victory")
	check(not view.park.model.data.is_empty() and view.park.get_meta("campaign_scene") == "park-veredas", "park map loads from the native checkpoint")
	check(view.park.get_node_or_null("UI/Layout") == null, "prototype teleport controls absent")
	var before_pause: Vector2 = view.park.player
	view._pause_game()
	await process_frame
	check(is_instance_valid(view.pause_overlay) and view.park.paused, "pause overlay stops exploration")
	view._resume_game()
	check(not view.park.paused and view.park.player == before_pause, "resume preserves position and movement state")
	view._show_collection()
	await process_frame
	check(view.page != null and not is_instance_valid(view.park), "collection replaces park safely")
	view._show_saved()
	await settle_park(view)
	check(view.park.player.distance_to(before_pause) < .01, "return preserves world position")
	var boss_point: Vector2 = Checkpoint.target("park-veredas", "boss")
	view.park.player = boss_point
	check(view._save_park(), "save actual park position")
	var current: Dictionary = view.session.snapshot()
	current.player.flags.ninaAccepted = true
	check(view.session.checkpoint(current.checkpoint, current.player).status == "ok", "accept quest fixture")
	check(view.encounters.start_boss(boss_point).status == "ok", "start encounter through session")
	view._show_saved()
	await process_frame
	check(is_instance_valid(view.battle), "native battle view instantiates")
	view.battle.model.intro = 0
	view.battle.model.tick(.02, {"x": 1})
	var before_bag_x: float = view.battle.model.p.x
	view._pause_game()
	await process_frame
	check(view.battle.paused, "pause overlay stops encounter model")
	view.pause_overlay.chosen.emit("bag")
	await process_frame
	check(not is_instance_valid(view.battle), "bag replaces paused encounter safely")
	view._return_to_game()
	await process_frame
	check(view.battle.paused, "return from page waits for combat resume")
	check(is_equal_approx(view.battle.model.p.x, before_bag_x), "bag round trip keeps unsaved encounter movement")
	view._return_to_menu()
	await process_frame
	check(view.session.resume_slot("slot-1").status == "ok", "resume saved battle from menu")
	view._show_saved()
	await process_frame
	check(view.battle.model.p.x > 172, "battle movement survives menu/reload")
	view.battle.model.outcome = "won"
	check(view.encounters.save_battle(view.battle.model.snapshot()).status == "ok", "save synthetic victory")
	var preview: Dictionary = load("res://scripts/campaign/hud_rewards.gd").preview(view.session.snapshot().player, view.session.snapshot().player.encounter, view.battle.model)
	check(view.encounters.settle().status == "ok", "settle synthetic victory")
	check(view.session.snapshot().player.lastEncounter.partnerXp == preview.xp, "boss visual XP matches committed reward")
	view._show_saved()
	await settle_park(view)
	check(not is_instance_valid(view.park.guardian_art) or not view.park.guardian_art.is_visible_in_tree(), "boss disappears after victory")
	check(Checkpoint.allowed({"props": {"acao": "veredasTail"}}, view.session.snapshot().player), "quest tail unlocked after victory")
	# Transitions between the park parts are walked by park_campaign_integration.gd.
	view.queue_free()
	await process_frame
	await process_frame
	print("CAMPAIGN VIEW CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
