extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
const OUT="res://../documentation/overworld/professor-moderno/"
func _initialize() -> void:call_deferred("run")
func shot(file:String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+file+".png")
func run() -> void:
 root.size=Vector2i(1280,720);RenderingServer.set_default_clear_color(Color("101d2c"))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 var name:="antes"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--name="):name=arg.trim_prefix("--name=")
 if "--frontend" in OS.get_cmdline_user_args():
  var front=load("res://scripts/campaign/front_end.gd").new()
  var state=load("res://scripts/campaign/state.gd")
  front.session._store=load("res://scripts/campaign/save_store.gd").new("user://professor-preview-"+state.new_id())
  root.add_child(front)
  var saved:Dictionary=state.fresh("slot-3")
  saved.checkpoint={"kind":"world","scene":"professor-home","position":[1056,1184]}
  saved.player.partners=[{"id":"preview-rabbito","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}]
  saved.player.equippedPartnerId="preview-rabbito";saved.player.journey={"lesson":5,"phase":"complete"}
  front.session._snapshot=saved;front._show_world()
  await create_timer(1.0).timeout;await shot("frontend-hud")
  front.session.close_session();front.free();print("PROFESSOR frontend capture; isolated state, no reward commits");quit();return
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
 var room:=Room.new();root.add_child(room);room.position=Vector2(100,0);room.scale=Vector2.ONE*1.1
 room.configure(content.rooms.professor,[1056,1232],false,"*",true,true);room.set_process(false);room.opening_pose()
 await shot(name+"-geral")
 room.avatar.hide();room.mother_sprite.hide();room.companion.hide()
 await shot(name+"-sem-atores")
 if name!="antes":
  var views:Dictionary={"entrada":Vector2(322,468),"biblioteca":Vector2(465,190),"estudo":Vector2(590,240),"oficina":Vector2(716,370),"mesa":Vector2(386,277),"arquivo":Vector2(575,485),"canto-paredes":Vector2(432,80)}
  for key in views:
   room.scale=Vector2.ONE*2.0;room.position=Vector2(640,360)-views[key]*2.0
   await shot(name+"-detalhe-"+key)
  room.scale=Vector2.ONE*1.1;room.position=Vector2(100,0);room.avatar.show()
  var poses:Dictionary={"atras-mesa":Vector2(624,528),"frente-mesa":Vector2(624,816),"atras-oficina":Vector2(1200,480),"frente-oficina":Vector2(1440,672)}
  for key in poses:
   room.actor=poses[key];room.opening_pose();await shot(name+"-oclusao-"+key)
 room.free();print("PROFESSOR capture ",name);quit()
