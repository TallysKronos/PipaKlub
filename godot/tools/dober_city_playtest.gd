extends SceneTree
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const Quest = preload("res://scripts/campaign/mount_quest.gd")
var view: Node2D
var app: Control
var failures := 0
var checks := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, msg: String) -> void:
	checks += 1
	print(("OK " if ok else "FAIL ") + msg)
	if not ok: failures += 1
func input(x: float, y: float, run_on: bool = false) -> void:
	for pair in [["left", -x], ["right", x], ["up", -y], ["down", y], ["run", 1.0 if run_on else 0.0]]:
		var action: String = "campaign_" + pair[0]
		if pair[1] > 0.0: Input.action_press(action, pair[1])
		else: Input.action_release(action)
func place(p: Vector2) -> void:
	view.cell = p
	view.surface = view.world.cell_id(floori(p.x), floori(p.y))
	view.elevation = view.world.surface_height(view.world.find_surface(view.surface), p, true)
	view.follower = p
	view.follower_surface = view.surface
	view.follower_height = view.elevation
	view.trail.clear()
	view._refresh_visuals()
	view._update_hint()
func tick(steps: int) -> void:
	for i in steps:
		view._physics_process(1.0 / 60.0)
		view.avatar._process(1.0 / 60.0)
		if is_instance_valid(view.avatar.mount_rig): view.avatar.mount_rig._process(1.0 / 60.0)
func capture(label: String) -> void:
	view.camera.position_smoothing_enabled = false
	view.camera.position = view.player_root.position - Vector2(0, 35)
	view.camera.reset_smoothing()
	await process_frame
	await RenderingServer.frame_post_draw
	var p := ProjectSettings.globalize_path("res://../documentation/qa/dober-city-playtest/" + label + ".png")
	check(root.get_texture().get_image().save_png(p) == OK, "capture " + label)
func run() -> void:
	root.size = Vector2i(1280, 720)
	app = load("res://scripts/campaign/front_end.gd").new()
	app.session._store = load("res://scripts/campaign/save_store.gd").new("res://../tmp/playtest-dober/profile")
	app.preferences.storage_path = "res://../tmp/playtest-dober/preferences.cfg"
	root.add_child(app)
	app.preferences.reduced_motion = true
	Fixtures.show(app, "street")
	for i in 480:
		await process_frame
		if is_instance_valid(app.park) and not app.flow_busy and not is_instance_valid(app.scene_loading): break
	view = app.park
	if not is_instance_valid(view):
		quit(1); return
	view.set_physics_process(false)
	view.avatar.set_process(false)
	view.paused = false
	view.saved_player.inventory["apito-de-elo"] = 1
	Quest.grant_partner(view.saved_player)
	place(Vector2(14.5, 22.5))
	view.toggle_mount()
	check(view.avatar.mounted, "mounts in city")
	var rig: Node2D = view.avatar.mount_rig
	rig.set_process(false)
	var point: Vector2 = view.cell
	input(-1, 1)
	tick(8)
	check(view.cell.distance_to(point) > .05 and rig.animation_key == "walk-sw", "southwest walk through movement input: " + rig.animation_key)
	await capture("01-caminhada-sudoeste")
	var frame_before: Rect2 = rig.animated.region_rect
	input(-1, 1, true)
	tick(8)
	check(rig.animation_key == "run-sw", "southwest sprint input: " + rig.animation_key)
	await capture("02-corrida-sudoeste")
	input(0, 0)
	tick(1)
	check(not rig.animated.visible and rig.rider.visible and rig.facing == "sw", "stop returns to southwest saddle")
	await capture("03-repouso-sudoeste")
	place(Vector2(18.5, 11.5))
	var base: float = view.elevation
	input(1, -.5)
	tick(42)
	check(view.avatar.mounted and view.elevation > base + 12, "ramp ascent remains mounted " + str([base, view.elevation, view.cell]))
	await capture("04-subida-rampa")
	input(-1, .5)
	tick(42)
	check(view.avatar.mounted and view.elevation < base + 5, "ramp descent returns to bottom " + str([base, view.elevation, view.cell]))
	input(0, 0)
	view.toggle_mount()
	var heights: Array[float] = []
	for target in ["zeca", "assis"]:
		for person in view.world.people:
			if person.id != target: continue
			place(person.p + Vector2(-.7, .4))
			heights.append(view.elevation)
			var outline: Node = person.art.get_node_or_null("InteractionOutline")
			check(view.outlined_person == person.art and outline != null and outline.visible, "outline on " + target)
			await capture("05-contorno-" + target)
			place(Vector2(11.5, 11.5))
			check(view.outlined_person == null and not outline.visible, "outline clears outside range " + target)
	check(heights.size() == 2 and absf(heights[0]-heights[1]) >= 40, "NPCs on different elevations " + str(heights))
	print("CITY PLAYTEST: ", checks, " checks; ", failures, " failures")
	app.session.close_session()
	app.free()
	quit(int(failures > 0))
