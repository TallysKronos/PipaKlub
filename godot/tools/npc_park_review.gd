extends SceneTree
## Actual Veredas consumer, no campaign/session/save access.
func _initialize() -> void:call_deferred("review")
func review() -> void:
	root.size=Vector2i(1280,720)
	var view=load("res://scripts/campaign/park_view.gd").new()
	view.saved_player={"name":"Kael","partners":[],"flags":{},"openedChests":[],"coins":0,"inventory":{}}
	root.add_child(view);view.set_physics_process(false)
	var point: Vector2=load("res://scripts/campaign/park_data.gd").NINA
	view.player=point+Vector2(25,15);view.follower=point+Vector2(40,35)
	view._refresh_positions();view.camera.position=view.landscape.project(view.player)
	view.camera.position_smoothing_enabled=false
	await create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	var path: String=ProjectSettings.globalize_path("res://../documentation/pixelgen/npc-in-game-v1/park.png")
	root.get_texture().get_image().save_png(path)
	var okay: bool=view._near_action().get("id","")=="nina" and view.nina.texture.resource_path=="res://assets/npc-ds/nina.png"
	print("Nina real park: correct texture and interaction range; pass=",okay)
	view.free();quit(0 if okay else 1)
