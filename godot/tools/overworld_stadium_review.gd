extends SceneTree

const View = preload("res://scripts/campaign/park_overworld_view.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const State = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/campaign/endgame_story.gd")
const Finals = preload("res://scripts/campaign/ruinas_elo.gd")
const SCENE := "kronasta-estadio-a"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var player: Dictionary = State.fresh("slot-1").player
	player.journey = {"lesson":5,"phase":"complete"}
	player.flags.ruinasChefeVencido = true
	player.flags.enamorDesperto = true
	player.flags.enamorDerrotado = true
	var lobby_spot := Story.point(SCENE, Finals.LOBBY_SPOT)
	var stands_spot := Story.point(SCENE, Finals.STANDS_SPOT)
	var expected := [["Grampo","Platyx"],["Grampo","Platyx","Tyler"],["Grampo","Platyx","Tyler","Faye","RaposaArtica"],["Grampo","Platyx","Tyler","Jamile","Faye","RaposaArtica"]]
	for round in expected.size():
		# Reload with Kael standing on the default cast spot.
		var view := stadium(player, lobby_spot, true)
		var lobby := view.actors.get_node_or_null("StadiumLobby")
		if lobby == null or lobby.get_child_count() != expected[round].size():
			fail("Missing lobby actors at round %d" % round)
			return
		var positions := {}
		var anchors := {"Faye": Finals.FAYE[0], "RaposaArtica": Finals.RAPOSA_ARTICA[0]}
		for actor in lobby.get_children():
			var at: Vector2 = actor.get_meta("ground_point")
			if str(actor.name) not in expected[round] or positions.has(at) or at.distance_to(view.player) < 1.0:
				fail("Wrong actor or overlap at round %d" % round)
				return
			positions[at] = true
			if anchors.has(str(actor.name)):
				var sprite := actor as Sprite2D
				var expected_zone := lobby_spot if round == 2 else stands_spot
				if sprite.texture == null or sprite.texture.resource_path != anchors[str(actor.name)] or at.distance_to(expected_zone) > 6.0:
					fail("Wrong sprite or position for %s in round %d" % [actor.name, round])
					return
				if actor.name == &"Faye" and (not sprite.region_enabled or sprite.region_rect != Rect2(192, 96, 64, 96)):
					fail("Faye must render a single directional frame")
					return
		view.camera.position_smoothing_enabled = false
		view.camera.position = view.model.project(lobby_spot.lerp(stands_spot,.45)) - Vector2(0,42)
		view.camera.reset_smoothing()
		view.exploration_hud.objective.text = ""
		await capture("estadio-elenco-%d" % (round+1))
		view.free()
		player.flags[Finals.BRACKET[round][3]] = true

	var podium := stadium(player, Vector2(24.5,14.5), false)
	podium.present_championship_victory()
	var strides := {}
	var ribbon: Node
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		var jamile := podium.actors.get_node_or_null("ChampionshipVictory/Jamile") as Sprite2D
		if jamile != null and jamile.texture != null:
			strides[jamile.texture.resource_path.get_file()] = true
		ribbon = podium.actors.get_node_or_null("ChampionshipVictory/TitleRibbon")
		if ribbon != null and ribbon.get_meta("pulled_by_partner", false): break
		await process_frame
	if ribbon == null or not ribbon.get_meta("pulled_by_partner", false) or not strides.has("jamile-1.png") or not strides.has("jamile-2.png"):
		fail("Title ribbon staging incomplete")
		return
	await capture("estadio-jamile-fita")
	podium.free()
	print("STADIUM REVIEW: four lobby states and title ribbon verified")
	quit()

func stadium(player: Dictionary, point: Vector2, reduced: bool) -> View:
	var view := View.new()
	view.saved_checkpoint = CP.make(SCENE, CP.safe(SCENE, point), CP.SPACE)
	view.saved_player = player.duplicate(true)
	view.content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	view.reduced_motion = reduced
	root.add_child(view)
	view.set_physics_process(false)
	return view

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://../documentation/campaign/overworld-sprites/capturas")
	var result := root.get_texture().get_image().save_png(dir.path_join(label+".png"))
	assert(result == OK)

func fail(message: String) -> void:
	printerr(message)
	quit(1)
