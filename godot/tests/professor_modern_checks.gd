extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
 var original:Dictionary=content.rooms.professor.duplicate(true)
 var room:=Room.new();root.add_child(room);room.configure(content.rooms.professor,[1056,1232],true,"*",true,true);room.set_process(false)
 check(room.data==original,"all canonical dimensions, camera, blocking and hotspots preserved")
 check(room.get_meta("professor_art","")=="modern-v1","professor receives its new presentation")
 check(content.rooms.professor==original,"shared content not mutated")
 var visited:Dictionary={};var queue:Array[Vector2i]=[Vector2i(1056,1232)];visited[queue[0]]=true;var n:=0
 while n<queue.size():
  var at:Vector2i=queue[n];n+=1
  for d in [Vector2i(16,0),Vector2i(-16,0),Vector2i(0,16),Vector2i(0,-16)]:
   var p:Vector2i=at+d
   if not visited.has(p) and room._safe(Vector2(p)):visited[p]=true;queue.append(p)
 for hotspot in room.data.hotspots:
  var found:=false
  for p:Vector2i in visited:if Vector2(p).distance_to(Vector2(hotspot.x,hotspot.y))<24:found=true;break
  check(found,"reachable canonical interaction: "+str(hotspot.id))
 for blocked in room.data.blocked:
  check(not room._safe(Vector2(blocked[0]+blocked[2]/2.,blocked[1]+blocked[3]/2.)),"furniture remains solid")
 var walk_samples:=0
 var unreachable:=0
 var f:Dictionary=room.data.layout.floor
 for x in range(int(f.x+16),int(f.x+f.w),16):
  for y in range(int(f.y+16),int(f.y+f.h),16):
   var p:=Vector2i(x,y)
   if room._safe(Vector2(p)):
    walk_samples+=1
    if not visited.has(p):unreachable+=1
 check(unreachable==0,"no isolated walkable pockets")
 for id in ["library","study","workbench","desk","chest"]:
  var node:Node2D=room.get_node("Professor_"+id)
  var art:Sprite2D=node.get_node_or_null("Art")
  check(art!=null,"new art present: "+id)
  if art:
   check(is_equal_approx(art.scale.x,art.scale.y),"uniform scaling: "+id)
   check(art.region_rect.end.x<=art.texture.get_width() and art.region_rect.end.y<=art.texture.get_height(),"crop inside original PNG: "+id)
 for pose in [{"at":Vector2(624,528),"id":"desk","behind":true},{"at":Vector2(624,816),"id":"desk","behind":false},{"at":Vector2(1200,480),"id":"workbench","behind":true},{"at":Vector2(1440,672),"id":"workbench","behind":false}]:
  check(room._safe(pose.at),"occlusion pose stands on walkable ground")
  room.actor=pose.at;room.opening_pose()
  var prop:Node2D=room.get_node("Professor_"+str(pose.id))
  check((room.avatar.z_index<prop.z_index) if pose.behind else (room.avatar.z_index>prop.z_index),"actor depth ordering: "+str(pose.id))
 room.free()
 print("PROFESSOR MODERNO ",checks," checks; ",visited.size()," reachable samples; ",unreachable," unreachable walkable samples; ",failures," failures; no save access")
 quit(0 if failures==0 else 1)
