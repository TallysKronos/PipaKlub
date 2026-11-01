extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
 root.size=Vector2i(1280,720);RenderingServer.set_default_clear_color(Color("101d2c"))
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
 var room_key:="bedroom"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--room="):room_key=arg.trim_prefix("--room=")
 var room:=Room.new();root.add_child(room);room.position=Vector2(108,10);room.scale=Vector2.ONE*1.1
 room.configure(content.rooms[room_key],[1030,610] if room_key=="bedroom" else [1040,912],false,"",true,true)
 room.set_process(false);room.opening_pose()
 var out:="res://../documentation/overworld/casa-kael-moderna"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 var file:="antes"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--name="):file=arg.trim_prefix("--name=")
 for shot in ["geral","sem-atores"]:
  if shot=="sem-atores":room.avatar.hide();room.mother_sprite.hide();room.companion.hide()
  await process_frame;await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png(out.path_join(file+"-"+shot+".png"))!=OK:quit(1);return
 if not file.ends_with("antes"):
  var focuses:Dictionary={"cama":Vector2(480,260),"mesa":Vector2(730,370),"escada":Vector2(225,380),"canto-paredes":Vector2(441,80)}
  if room_key=="home":focuses={"sofa":Vector2(300,280),"jantar":Vector2(550,320),"cozinha":Vector2(770,330),"escada-topo":Vector2(630,305),"escada-base":Vector2(540,510),"porta":Vector2(160,260)}
  for key in focuses:
   room.scale=Vector2.ONE*2.0;room.position=Vector2(640,360)-focuses[key]*2.0
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out.path_join(file+"-detalhe-"+key+".png"))
  room.scale=Vector2.ONE*1.1;room.position=Vector2(108,10);room.avatar.show()
  var poses:Dictionary={"atras-cama":Vector2(480,352),"frente-cama":Vector2(480,800),"atras-mesa":Vector2(1008,432),"frente-mesa":Vector2(1200,528)}
  if room_key=="home":poses={"atras-sofa":Vector2(480,544),"frente-sofa":Vector2(480,912),"atras-jantar":Vector2(736,480),"frente-jantar":Vector2(1104,624)}
  for key in poses:
   room.actor=poses[key];room.opening_pose()
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out.path_join(file+"-oclusao-"+key+".png"))
 print("QUARTO capture ",file);room.free();quit()
