extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
 root.size=Vector2i(1280,720)
 var view=load("res://scripts/overworld/view.gd").new()
 view.area_id="kronasta-bosque-a"
 view.art_preview=true
 root.add_child(view)
 view.set_physics_process(false)
 view.interface.hide()
 view.camera.position_smoothing_enabled=false
 view.player=Vector2(24.5,24.5)
 view.follower=view.player+Vector2(1,0)
 view._refresh_positions()
 view.camera.zoom=Vector2.ONE
 view.camera.position=view.model.project(view.player)-Vector2(0,40)
 for frame in 5: await process_frame
 await RenderingServer.frame_post_draw
 var output=ProjectSettings.globalize_path("res://../art/ui/soulmonsters-v2/pip-128/contexto/exploracao.png")
 var err=root.get_texture().get_image().save_png(output)
 print("HUD128_CONTEXT ",err)
 view.free()
 quit(err)
