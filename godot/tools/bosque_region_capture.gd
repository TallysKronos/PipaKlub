extends SceneTree
## Captura determinística de TODAS as juntas enumeradas no manifesto da área. Sem atores ou HUD.
const View = preload("res://scripts/overworld/view.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
 root.size=Vector2i(1280,720)
 var area:="kronasta-bosque-a"
 var output:=""
 var terrain_only:=false
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--area="):area=arg.trim_prefix("--area=")
  if arg=="--terrain-only":terrain_only=true
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
 if output.is_empty():output=ProjectSettings.globalize_path("res://../documentation/overworld/kronasta/captures/"+area+"/"+("geometria" if OS.get_environment("KRONASTA_GEOMETRIA")=="1" else "arte"))
 DirAccess.make_dir_recursive_absolute(output)
 var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../documentation/overworld/kronasta/planos/"+area+".json"))
 var view:=View.new()
 view.area_id=area
 view.art_preview=true
 root.add_child(view)
 if view.camera==null:quit(1);return
 view.set_physics_process(false)
 view.interface.hide()
 view.player_root.hide()
 view.follower_root.hide()
 for npc in view.npc_nodes:npc.root.hide()
 for occluder in view.occluders:
  var art:CanvasItem=occluder.get_node_or_null("Art")
  if art:art.modulate.a=1
 view.camera.position_smoothing_enabled=false
 if terrain_only:
  for node in view.actors.get_children():
   if node.get_meta("scenery",false):node.hide()
 for shot in plan.shots:
  view.camera.zoom=Vector2.ONE*float(shot.zoom)
  view.camera.position=view.model.project(Vector2(shot.u,shot.v))-Vector2(0,35)
  await process_frame
  await RenderingServer.frame_post_draw
  var error:int=root.get_texture().get_image().save_png(output.path_join(str(shot.name)+".png"))
  if error!=OK:printerr("CAPTURE FAILED ",shot.name);quit(1);return
 print(area,": ",plan.shots.size()," capturas em ",output)
 view.free()
 quit()
