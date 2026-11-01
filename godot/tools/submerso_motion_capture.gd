extends SceneTree
const View=preload("res://scripts/overworld/view.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
 root.size=Vector2i(1280,720)
 var out:="res://../documentation/overworld/submerso/motion"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 var view:=View.new();view.area_id="submerso-a";view.art_preview=true;root.add_child(view)
 view.set_physics_process(false);view.interface.hide();view.player_root.hide();view.follower_root.hide()
 for npc in view.npc_nodes:npc.root.hide()
 view.camera.position_smoothing_enabled=false;view.camera.zoom=Vector2.ONE;view.camera.position=view.model.project(Vector2(42,22))
 for n in 2:
  await process_frame;await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png(out.path_join("frame-"+str(n)+".png"))!=OK:quit(1);return
  if n==0:await create_timer(1.2).timeout
 print("SUBMERSO MOTION: 2 native frames captured 1.2s apart, geometry and camera fixed")
 view.free();quit()
