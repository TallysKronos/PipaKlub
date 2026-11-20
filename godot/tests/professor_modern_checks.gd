extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
const Lab = preload("res://scripts/campaign/professor_interior_v2.gd")
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
 check(room.data.layout.floor==original.layout.floor and room.data.layout.blocking.kaelEntry==original.layout.blocking.kaelEntry,"save coordinate envelope and entry preserved")
 check(room.get_meta("professor_art","")=="interior-v2","professor receives its new presentation")
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
 var staging=preload("res://scripts/campaign/tutorial_staging.gd")
 for hotspot in room.data.hotspots:
  var entry:=Vector2(1056,1232)
  var end:=Vector2(hotspot.x,hotspot.y)
  room.actor=entry
  var outbound:Array=staging.route(room,end)
  check(not outbound.is_empty() and outbound.back()==end,"collision-free path to "+str(hotspot.id))
  room.actor=end
  var inbound:Array=staging.route(room,entry)
  check(not inbound.is_empty() and inbound.back()==entry,"collision-free return from "+str(hotspot.id))
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
 var shell := room.get_node("LaboratorioInteriorV2")
 check(shell.get_child_count()==10 and room.avatar.scale==Vector2.ONE,"native atlas architecture and Kael")
 for id in Lab.PROPS:
  var node:Node2D=room.get_node(id)
  for art:Sprite2D in node.get_children():
   check(art.scale==Vector2.ONE and node.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"native pixel density: "+id)
   check(art.texture is AtlasTexture and art.texture.region.end.x<=art.texture.atlas.get_width() and art.texture.region.end.y<=art.texture.atlas.get_height(),"atlas region fits: "+id)
 for pose in [
  {"at":Lab.point_at(5.3,6.15),"id":"bancada-pesquisa","behind":true},
  {"at":Lab.point_at(5.3,3.85),"id":"bancada-pesquisa","behind":false},
  {"at":Lab.point_at(11.6,2.7),"id":"mesa-maleta","behind":true},
  {"at":Lab.point_at(11.6,.42),"id":"mesa-maleta","behind":false},
 ]:
  check(room._safe(pose.at),"occlusion pose stands on walkable ground")
  room.actor=pose.at;room.opening_pose()
  var prop:Node2D=room.get_node(pose.id)
  check((room.avatar.z_index<prop.z_index) if pose.behind else (room.avatar.z_index>prop.z_index),"actor depth ordering: "+str(pose.id))
 var stock := Lab.point_at(11.80,6.48)
 room.actor=Vector2(1056,1232)
 check(not staging.route(room,stock).is_empty(),"public stockroom reached through its door")
 var old_position := Lab.point_at(5.8,4.9)
 var resumed := Lab.resume_point(old_position,room.data.blocked)
 check(room._safe(resumed) and resumed.distance_to(old_position)<200,"old save inside furniture resumes close by on the floor")
 check(Lab.walkable(preload("res://scripts/campaign/retalho_care.gd").APPROACH),"Retalho approach reachable")
 check(Lab.walkable(Vector2(1152,864)),"tutorial and exam approach preserved")
 var controls=preload("res://scripts/campaign/controls.gd")
 controls.install(controls.DEFAULTS)
 controls.use_keyboard()
 room.actor=Lab.point_at(4.8,1.7)
 var screen_before:=room.project(room.actor)
 Input.action_press("campaign_right")
 for tick in range(6):room._process(.025)
 Input.action_release("campaign_right")
 var keyboard_delta:=room.project(room.actor)-screen_before
 check(keyboard_delta.x>8 and absf(keyboard_delta.y)<=1,"right input stays horizontal after room recalibration")
 Engine.time_scale = 30.0
 room.actor=Vector2(1056,1232)
 room.opening_pose()
 for hotspot in room.data.hotspots:
  var target:=Vector2(hotspot.x,hotspot.y)
  check(await staging.approach(room,target),"Kael walks to "+str(hotspot.id))
  check(room.actor.distance_to(target)<2.0,"Kael reaches "+str(hotspot.id))
  check(await staging.approach(room,Vector2(1056,1232)),"Kael walks back from "+str(hotspot.id))
 check(await staging.approach(room,stock) and room.actor.distance_to(stock)<2.0,"Kael crosses the visible stockroom threshold")
 check(await staging.approach(room,Vector2(1056,1232)),"Kael returns from the stockroom")
 Engine.time_scale = 1.0
 room.free()
 print("PROFESSOR MODERNO ",checks," checks; ",visited.size()," reachable samples; ",unreachable," unreachable walkable samples; ",failures," failures; no save access")
 quit(0 if failures==0 else 1)
