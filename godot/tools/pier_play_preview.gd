extends SceneTree
## Native visual walkthrough of the independent playable fixture.
var play: Node2D
var output := "res://../documentation/overworld/cais-v1/jogavel"
var observations: Array = []

func _initialize() -> void:call_deferred("start")

func capture(id: String) -> void:
	play._refresh_visuals()
	play._update_hint()
	play.camera.position = play.player_root.position-Vector2(0,65)
	play.camera.reset_smoothing()
	for i in range(24):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))

func travel(target: Vector2) -> void:
	var previous: Vector2 = play.cell
	for i in range(4000):
		if play.cell.distance_to(target)<.02:break
		var before: Vector2 = play.cell
		play.walk((target-play.cell).normalized()*minf(.025,play.cell.distance_to(target)))
		if play.cell.distance_to(before)<.00001:break
	play.avatar.moving = play.cell.distance_to(previous)>.01
	observations.append({"target":[target.x,target.y],"actual":[play.cell.x,play.cell.y],"surface":play.surface,"arrived":play.cell.distance_to(target)<.03})

func climb() -> void:
	play.interact()
	for i in range(180):
		if play.ladder.is_empty():break
		play._advance_ladder(1.0/60.0)

func start() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	play = load("res://scenes/overworld/pier/cais-jogavel.tscn").instantiate()
	if not play.has_method("walk"):
		quit(1)
		return
	root.add_child(play)
	current_scene = play
	await capture("01-desembarque")
	for p in [Vector2(8.5,21.5),Vector2(8.5,18.5),Vector2(6,18.5),Vector2(6,17.5),Vector2(6,15.9),Vector2(6,14),Vector2(7.75,13.6),Vector2(7.75,11.7)]:travel(p)
	await capture("02-patamar-inferior")
	# Same XY below and above the deck, reached by different connected paths.
	for p in [Vector2(9,11.7),Vector2(10,11.5),Vector2(10,10.5),Vector2(8.5,10.5),Vector2(8.5,8.5)]:travel(p)
	await capture("03-sob-o-deck")
	for p in [Vector2(8.5,10.5),Vector2(10,10.5),Vector2(10,11.5),Vector2(7.75,11.7),Vector2(7.75,10),Vector2(7.75,8),Vector2(8.5,8.5)]:travel(p)
	await capture("04-sobre-o-deck")
	for p in [Vector2(7.2,8),Vector2(7.2,4.2)]:travel(p)
	await capture("05-ponte-suspensa")
	for p in [Vector2(7.2,2.1),Vector2(7.5,2.1),Vector2(7.5,1),Vector2(7.5,-.5),Vector2(8.22,-.85)]:travel(p)
	play.interact()
	for i in range(48):play._advance_ladder(1.0/60.0)
	await capture("06-escada-de-mao")
	climb()
	# If still climbing, finish the same interaction instead of starting another.
	for i in range(180):
		if play.ladder.is_empty():break
		play._advance_ladder(1.0/60.0)
	travel(Vector2(7,-1))
	play.interact()
	await capture("07-mirante")
	travel(Vector2(8.22,-.85))
	climb()
	for p in [Vector2(7.5,-.5),Vector2(7.5,1),Vector2(7.5,2.1),Vector2(7.2,2.1),Vector2(7.2,5.9),Vector2(7.2,8),Vector2(6,7.5),Vector2(4,7.5),Vector2(2,7.5),Vector2(1.55,6.4)]:travel(p)
	climb()
	for p in [Vector2(.3,5.6),Vector2(-.35,5.6)]:travel(p)
	climb()
	travel(Vector2(-2,5.3))
	await capture("08-patamar-alto")
	travel(Vector2(-.85,5.6))
	climb()
	for p in [Vector2(.3,5.6),Vector2(1.03,6.4)]:travel(p)
	climb()
	for p in [Vector2(2,7.5),Vector2(4,7.5),Vector2(6,7.5),Vector2(7.75,8),Vector2(7.75,10),Vector2(7.75,11.7),Vector2(10,11.5),Vector2(10,10.5),Vector2(12.5,10.5),Vector2(15,10.5),Vector2(16.5,10.5),Vector2(17,11.5)]:travel(p)
	await capture("09-praia")
	for p in [Vector2(16.5,10.5),Vector2(15,10.5),Vector2(12.5,10.5),Vector2(10,10.5),Vector2(10,11.5),Vector2(6,13.5),Vector2(6,14.2),Vector2(6,16.5),Vector2(6,18.5),Vector2(8.5,18.5),Vector2(8.5,22.5)]:travel(p)
	await capture("10-retorno")
	play.set_paused(true)
	await capture("11-pausa")
	play.set_paused(false)
	var record := {"scope":"native visual walkthrough, no campaign save and no project test suites", "observations":observations,"finished":play.finished,"depthAtlasSize":[play.depth.texture.get_width(),play.depth.texture.get_height()],"depthBakeMs":play.depth.bake_ms}
	var file := FileAccess.open(output.path_join("percurso.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  "))
	print(JSON.stringify(record))
	quit()
