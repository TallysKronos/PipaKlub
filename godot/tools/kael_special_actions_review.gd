extends SceneTree

const Avatar = preload("res://scripts/avatar.gd")
const View = preload("res://scripts/campaign/park_overworld_view.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const OUTPUT := "res://../art/characters/kael-especiais-iso-v2"
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var board := Node2D.new()
	root.add_child(board)
	for row in Avatar.DIRECTIONS.size():
		var avatar := Avatar.new()
		board.add_child(avatar)
		avatar.set_process(false)
		avatar.position = Vector2(160 + row % 4 * 320, 315 + (row >> 2) * 330)
		avatar.scale = Vector2.ONE * 1.55
		avatar.facing = Avatar.DIRECTIONS[row]
		check(avatar.jumping != null and avatar.jumping.get_size() == Vector2(576, 896), "Invalid eight-row jump sheet")
		check(avatar.item_texture != null and avatar.item_texture.get_size() == Vector2(576, 144), "Invalid item sheet")
		avatar.set_mounted(true)
		avatar.mount_rig.set_facing(avatar.facing)
		check(avatar.mount_rig.rider.texture != null and avatar.mount_rig.seat.position.y < 0, "Missing rider or invalid saddle " + avatar.facing)
		for state in ["walk", "run"]:
			avatar.moving = true
			avatar.running = state == "run"
			avatar.mount_rig.set_facing(avatar.facing)
			check(avatar.mount_rig.animated.visible and avatar.mount_rig.animated.texture != null, "Missing mounted " + state + " " + avatar.facing)
		avatar.moving = false
		avatar.mount_rig.set_facing(avatar.facing)
	await capture("montaria")
	for avatar in board.get_children():
		avatar.jump_pose(.4)
		check(not avatar.mounted and avatar.jump_time == .4, "Jump should dismount")
	await capture("salto")
	var item_times := [.0, .10, .15, .22, .34, .65, .87, .99]
	for avatar in board.get_children():
		avatar.stop_jump()
		avatar.set_mounted(true)
		var t: float = item_times[avatar.get_index()]
		avatar.item_pose(t, avatar.facing)
		check(not avatar.mounted and is_equal_approx(avatar.item_time, t), "Item should dismount")
	await capture("item")
	board.free()
	await review_outline()
	print("Kael special actions: ", failures, " failures")
	quit(int(failures > 0))

func review_outline() -> void:
	var player: Dictionary = State.fresh("slot-1").player
	player.journey = {"lesson": 5, "phase": "complete"}
	for district: Dictionary in Rules.catalog():
		var entry: Dictionary = Rules.entry(player, district.id)
		entry.completed = true
		entry.champion = "player"
		Rules.store(player, district.id, entry)
	var view := View.new()
	var scene := "kronasta-centro-a"
	view.saved_player = player
	view.saved_checkpoint = CP.make(scene, CP.spawn(scene), CP.SPACE)
	view.content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	view.reduced_motion = true
	root.add_child(view)
	view.set_physics_process(false)
	var targets: Array[Dictionary] = []
	for actor: Dictionary in view.npc_nodes:
		var event: Dictionary = actor.root.get_meta("event", {})
		if event.name in ["Davi", "Vitra"]:
			targets.append(actor)
	check(targets.size() == 2, "Expected two directional NPCs in Centro")
	for actor: Dictionary in targets:
		view.player = actor.point
		view._physics_process(0)
		check(view.outlined_npc == actor.visual, "Wrong NPC highlighted at " + str(actor.point))
		var sprite := actor.visual.get_child(0) as Sprite2D
		if sprite != null:
			var outline := sprite.get_node_or_null("InteractionOutline") as Node2D
			check(outline != null and outline.visible, "Outline missing from selected sprite")
	if targets.size() == 2:
		# Exercise the real nearest-event selector with both NPCs in range.
		var first: Dictionary = targets[0]
		var second: Dictionary = targets[1]
		var event_a: Dictionary = first.root.get_meta("event").duplicate(true)
		var event_b: Dictionary = second.root.get_meta("event").duplicate(true)
		var base: Vector2 = first.point
		var adjacent := base + Vector2(1, 0)
		event_b.u = adjacent.x - .5
		event_b.v = adjacent.y - .5
		view.interaction_events.assign([event_a, event_b])
		for sample in [[base.lerp(adjacent, .2), first.visual], [base.lerp(adjacent, .8), second.visual]]:
			view.player = sample[0]
			view._physics_process(0)
			check(view.outlined_npc == sample[1], "Outline must switch to the nearest NPC when both are in range")
	view.player = CP.spawn(scene)
	view._physics_process(0)
	check(view.outlined_npc == null, "Outline remains outside interaction range")
	view.free()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUTPUT.path_join(label + ".png"))
	check(root.get_texture().get_image().save_png(path) == OK, "Capture failed: " + label)
