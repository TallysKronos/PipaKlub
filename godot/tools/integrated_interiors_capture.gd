extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
const Shop=preload("res://scripts/campaign/shop_data.gd")
const OUT="res://../documentation/overworld/integracao-cenarios-2026-11-01/"
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720);RenderingServer.set_default_clear_color(Color("101d2c"))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
 var proof:Array=[]
 for key in ["bedroom","home","professor","kite-shop"]:
  var data:Dictionary=Shop.room() if key=="kite-shop" else content.rooms[key]
  var point:Array={"bedroom":[1030,610],"home":[1040,912],"professor":[1056,1008],"kite-shop":[1200,1152]}[key]
  var room:=Room.new();root.add_child(room);room.position=Vector2(108,8);room.scale=Vector2.ONE*1.1
  room.configure(data,point,false,"",key!="kite-shop",true);room.set_process(false);room.avatar.facing="se";room.opening_pose()
  if room.avatar.resting==null or room.avatar.walking==null:printerr("ERROR missing updated Kael textures");quit(1);return
  var source_image:=Image.load_from_file("res://assets/kael-video/kael-idle-eight.png");source_image.convert(Image.FORMAT_RGBA8)
  var live_image:Image=room.avatar.resting.get_image();live_image.convert(Image.FORMAT_RGBA8)
  var matches:bool=source_image.get_data()==live_image.get_data()
  if not matches:printerr("ERROR current Kael texture differs from updated source");quit(1);return
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(OUT+key+"-kael-atualizado.png")
  proof.append({"room":key,"avatarBase":room.avatar.get_script().get_base_script().resource_path,"idleSource":"res://assets/kael-video/kael-idle-eight.png","idlePixelsMatchSource":matches,"walkTextureSize":[room.avatar.walking.get_width(),room.avatar.walking.get_height()],"scale":[room.avatar.scale.x,room.avatar.scale.y]})
  room.free()
 var file:=FileAccess.open(OUT+"avatar-proof.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"  ")+"\n");file.close()
 print("INTEGRATED INTERIORS: 4 captures with current eight-direction Kael");quit()
