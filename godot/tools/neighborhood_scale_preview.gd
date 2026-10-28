extends SceneTree
## Static native scale comparisons, using Kael on each prop's ground level.
var play: Node2D
const OUTPUT := "res://../documentation/overworld/bairro-inicial-v2/"

func _initialize() -> void:call_deferred("start")

func start() -> void:
	root.size=Vector2i(1280,720)
	play=load("res://scenes/overworld/neighborhood/bairro-jogavel.tscn").instantiate()
	root.add_child(play)
	play.set_physics_process(false)
	for shot in [["escala-ponto-onibus",Vector2(6.9,26.7),Vector2(6,25.4)],["escala-fusca",Vector2(8.2,23.4),Vector2(7,22.5)],["escala-jipe",Vector2(28.1,4.4),Vector2(26,3.5)],["escala-kombi",Vector2(28.5,24.1),Vector2(26,23.5)]]:
		play.cell=shot[1]
		play.surface=play.world.cell_id(floori(play.cell.x),floori(play.cell.y))
		play.elevation=play.world.support(play.cell)
		play.follower=play.cell+Vector2(.6,.1)
		play.follower_height=play.world.support(play.follower)
		play._refresh_visuals();play._update_hint()
		play.camera.position=play.world.iso(shot[2],play.elevation)-Vector2(0,30)
		play.camera.reset_smoothing()
		for i in range(8):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT+shot[0]+"-1280x720.png"))
	print("Four native prop/person scale comparisons captured; no movement or save tests.")
	quit()
