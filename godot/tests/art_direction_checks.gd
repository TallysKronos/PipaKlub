extends SceneTree
const Front = preload("res://scripts/campaign/front_end.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
var count := 0
var failed := 0
func check(value: bool, message: String) -> void:
	count += 1
	print(("PASS " if value else "FAIL ") + message)
	if not value: failed += 1
func _initialize() -> void:
	call_deferred("run_checks")
func settle() -> void:
	for i in 8: await process_frame
func freeze(node: Node) -> void:
	node.set_physics_process(false)
	for child in node.get_children(): freeze(child)
func run_checks() -> void:
	root.size = Vector2i(1270, 710)
	var front := Front.new()
	front.session._store = Store.new("user://art-check-" + State.new_id())
	front.preferences.storage_path = "user://art-check-" + State.new_id() + ".cfg"
	root.add_child(front)
	Fixtures.show(front, "street")
	await settle()
	front._process(0)
	await settle()
	check(front.status.autowrap_mode == TextServer.AUTOWRAP_OFF, "interaction prompt cannot wrap one letter per line")
	check(front.status.get_parent().size.x > 180 and front.status.size.y < 60, "interaction prompt has readable dimensions")
	Fixtures.show(front, "battle")
	await settle()
	freeze(front)
	var battle: Control = front.battle
	battle.paused = false
	battle.model.intro = 0
	battle.model.p.energy = 100
	battle.model.p.skillCooldown = 0
	var tile: Control = battle.move_cards[1].tile
	var point := tile.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	check(battle.pointer_tapped.get("skill", false), "actual pointer click queues skill")
	battle._physics_process(.016)
	check(battle.model.p.skillCooldown > 0 and battle.model.p.energy < 80, "pointer skill reaches real combat rules and consumes energy")
	check(battle.pointer_tapped.is_empty() and not battle.pointer_held.get("skill", false), "pointer release cannot leave skill held")
	check(battle.move_cards.size() == 6 and battle.move_cards[5].cost == 40, "exclusive action displays actual energy cost")
	var left: Vector2 = battle._project_field(Vector2(55, 200))
	var right: Vector2 = battle._project_field(Vector2(945, 200))
	check(right.x - left.x > front.size.x * .8, "usable battle span fills over 80 percent of the viewport")
	check(battle._project_field(Vector2(90, 585)).y < battle.bottom_panel.position.y - 12, "string anchors remain above the action cards")
	check(tile.size.y <= 140, "compact action cards reserve more arena space")
	check(battle._project_field(Vector2(55, 70)).y - 110 * battle._arena_factor() > 165, "upper flight limit stays below status HUD")
	check(battle._project_field(Vector2(945, 480)).y + 110 * battle._arena_factor() < battle.bottom_panel.position.y, "lower flight limit stays above action cards")
	front.free()
	print("ART DIRECTION: %d checks, %d failures" % [count, failed])
	quit(1 if failed > 0 else 0)
