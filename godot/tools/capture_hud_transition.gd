extends SceneTree
## Actual animated scene reveal with an in-memory fixture, no campaign writes.
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var front := Front.new()
	root.add_child(front)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	front.preferences.fullscreen = false
	front.preferences.reduced_motion = false
	for frame in 4: await process_frame
	var saved := State.fresh("slot-1")
	saved.player.partners = [{"id": "transition-review", "modelId": "rabbito", "xp": 0}]
	saved.player.equippedPartnerId = "transition-review"
	saved.player.journey = {"phase": "complete", "lesson": 5}
	saved.checkpoint = {"kind": "world", "scene": "morro", "position": [528, 752]}
	front.session._snapshot = saved
	front._show_saved()
	await create_timer(.19).timeout
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://").path_join("../tmp/campaign-review").simplify_path()
	root.get_texture().get_image().save_png(folder.path_join("ink-transition-middle.png"))
	await create_timer(.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("ink-transition-finished.png"))
	print("Transition captured at middle and after 450ms.")
	quit()
