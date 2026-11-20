extends SceneTree

const View = preload("res://scripts/campaign/park_overworld_view.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const State = preload("res://scripts/campaign/state.gd")
const Platyx = preload("res://scripts/campaign/platyx_overworld.gd")
const EREMOR := "res://assets/overworld/kits/camara-do-elo-v1/eremor-overworld-idle.png"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var view := chamber("kronasta-coracao-c", Vector2(24.5, 19.5))
	var partner := view.actors.get_node_or_null("PlatyxOverworld") as Sprite2D
	var grampo: Dictionary = {}
	for actor: Dictionary in view.npc_nodes:
		if actor.root.get_meta("event").props.get("acao") == "ruinasDuel":
			grampo = actor
			break
	if partner == null or grampo.is_empty():
		fail("Missing Grampo or Platyx")
		return
	await Platyx.refuse(view, true)
	var route: PackedVector2Array = view.model.path_to(grampo.point, Vector2(25.5, 6.5))
	if route.size() < 3:
		fail("No usable chamber exit route")
		return
	var start := partner.position
	view.camera.position_smoothing_enabled = false
	view.camera.position = view.model.project(route[route.size() >> 1]) - Vector2(0, 25)
	view.camera.reset_smoothing()
	Platyx.leave_for_chamber(view)
	await create_timer(.7).timeout
	if partner.position.distance_to(start) < 8.0 or not partner.visible:
		fail("Platyx did not follow Grampo")
		return
	await capture("camara-grampo-platyx-saida")
	var end: Vector2 = view.model.project(route[-1])
	var deadline := Time.get_ticks_msec() + 5000
	while grampo.root.visible and Time.get_ticks_msec() < deadline:
		await process_frame
	if grampo.root.visible or partner.visible or not partner.position.is_equal_approx(end):
		fail("Both actors must reach and leave through the chamber exit")
		return
	view.free()

	view = chamber("kronasta-coracao-d", CP.spawn("kronasta-coracao-d"), true)
	for actor: Dictionary in view.npc_nodes:
		for child in actor.visual.get_children():
			if child is Sprite2D and child.texture != null and child.texture.resource_path == EREMOR and child.is_visible_in_tree():
				view.player = CP.safe("kronasta-coracao-d", actor.point + Vector2(0, 4))
				view.follower = view.player + Vector2(.5, .5)
				view._refresh_positions()
				view.camera.position_smoothing_enabled = false
				view.camera.position = child.global_position.lerp(view.player_root.global_position, .45) - Vector2(0, 45)
				view.camera.reset_smoothing()
				await capture("camara-eremor-desperto")
				view.free()
				print("CHAMBER REVIEW: Grampo, Platyx and Eremor verified")
				quit()
				return
	fail("Awakened Eremor not visible")

func chamber(scene: String, point: Vector2, awakened := false) -> View:
	var view := View.new()
	view.saved_checkpoint = CP.make(scene, CP.safe(scene, point), CP.SPACE)
	view.saved_player = State.fresh("slot-1").player
	view.saved_player.journey = {"lesson":5,"phase":"complete"}
	view.saved_player.flags.enamorDesperto = awakened
	view.content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	view.reduced_motion = true
	root.add_child(view)
	view.set_physics_process(false)
	view.paused = true
	return view

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://../documentation/campaign/overworld-sprites/capturas")
	var result := root.get_texture().get_image().save_png(directory.path_join(label + ".png"))
	assert(result == OK)

func fail(message: String) -> void:
	printerr(message)
	quit(1)
