extends SceneTree

const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const View = preload("res://scripts/campaign/park_overworld_view.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Follow = preload("res://scripts/campaign/companion_follow.gd")
const SCENE := "kronasta-centro-a"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280,720)
	var app := Front.new()
	app.session._store = Store.new("user://rastro-review-"+State.new_id())
	root.add_child(app)
	app.preferences.reduced_motion = true
	if app.session.start("slot-1").status != "ok":
		fail("Cannot initialize isolated slot")
		return
	var player: Dictionary = app.session.snapshot().player
	player.partners = [{"id":"rastro","modelId":"rastro-dos-ventos","personalName":"Rastro dos Ventos","xp":4000}]
	player.equippedPartnerId = "rastro"
	player.journey = {"lesson":5,"phase":"complete"}
	if app.session.checkpoint({"kind":"world","scene":"kael-home","position":[1040,912]},player).status != "ok":
		fail("Cannot save Rastro in the house")
		return
	app._show_world()
	for i in 20: await process_frame
	if not is_instance_valid(app.room) or not uses_rastro(app.room.companion):
		fail("House did not use the overworld sprite")
		return
	await capture("rastro-em-casa")

	if app.session.checkpoint({"kind":"world","scene":"quintal","space":"bairro-inicial-v2","position":[4.4,17.4]},player).status != "ok":
		fail("Cannot save Rastro in the neighborhood")
		return
	await app._show_neighborhood()
	if not is_instance_valid(app.park) or not uses_rastro(app.park.partner):
		fail("Neighborhood did not use the overworld sprite")
		return
	app.park.walk(Vector2(1.2,.1))
	app.park._refresh_visuals()
	await capture("rastro-na-vila")
	var content: Dictionary = app.content
	app.free()

	var view := View.new()
	view.saved_checkpoint = CP.make(SCENE,CP.safe(SCENE,Vector2(24.5,32.5)),CP.SPACE)
	view.saved_player = player
	view.content = content
	root.add_child(view)
	view.set_physics_process(false)
	if not uses_rastro(view.companion):
		fail("Campaign map did not use the overworld sprite")
		return
	var poses := {}
	var headings := {}
	for destination in [Vector2(24.5,30.5),Vector2(24.5,34.5)]:
		view.path = view.model.path_to(view.player,destination)
		if view.path.is_empty():
			fail("No walkable route in the plaza")
			return
		for i in 220:
			view._physics_process(1.0/60)
			var x: float = view.companion.region_rect.position.x
			if x >= 128.0:
				poses[x] = true
				headings[view.companion.flip_h] = true
	if poses.size() != 2 or headings.size() != 2 or view.companion.region_rect.position.x >= 128.0:
		fail("Running, turning or idle frames were not reached: %s %s %s" % [poses, headings, view.companion.region_rect])
		return
	view.camera.reset_smoothing()
	await capture("rastro-no-centro")
	view.free()
	print("RASTRO REVIEW: house, neighborhood, campaign map, two strides and both headings")
	quit()

func uses_rastro(sprite: Sprite2D) -> bool:
	return sprite != null and sprite.texture != null and sprite.texture.resource_path == Follow.RASTRO

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://../documentation/campaign/overworld-sprites/capturas")
	assert(root.get_texture().get_image().save_png(dir.path_join(label+".png")) == OK)

func fail(message: String) -> void:
	printerr(message)
	quit(1)
