extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
const D=preload("res://scripts/campaign/shop_data.gd")
const OUT="res://../documentation/overworld/loja-tcg/"
func _initialize()->void:call_deferred("run")
func shot(file:String)->void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+file+".png")
func run()->void:
 root.size=Vector2i(1280,720);RenderingServer.set_default_clear_color(Color("101d2c"))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 var name:="geometria"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--name="):name=arg.trim_prefix("--name=")
 var room:=Room.new();root.add_child(room);room.position=Vector2(120,15);room.scale=Vector2.ONE*1.1
 room.configure(D.room(),[D.ENTRY.x,D.ENTRY.y],false,"*",false,true);room.set_process(false);room.opening_pose()
 await shot(name+"-geral")
 room.avatar.hide();room.companion.hide();room.get_node("ShopOwner").hide();await shot(name+"-sem-atores")
 var views:Dictionary={"balcao":Vector2(515,235),"estantes":Vector2(430,180),"mesas":Vector2(470,430),"expositores":Vector2(200,290),"entrada":Vector2(290,440),"canto":Vector2(380,90)}
 for id in views:
  room.scale=Vector2.ONE*2;room.position=Vector2(640,360)-views[id]*2
  await shot(name+"-detalhe-"+id)
 room.position=Vector2(640,360)-Vector2(550,280)*2;room.get_node("ShopOwner").show()
 await shot(name+"-dono-balcao")
 room.get_node("ShopOwner").hide();room.avatar.show();room.scale=Vector2.ONE*1.1;room.position=Vector2(120,15)
 for pose in [["atras-balcao",D.point(8,.8)],["frente-balcao",D.point(8,4.5)],["atras-mesa",D.point(9,6)],["frente-mesa",D.point(12,9.5)]]:
  room.actor=pose[1];room.opening_pose();await shot(name+"-oclusao-"+str(pose[0]))
 room.free();print("SHOP capture ",name);quit()
