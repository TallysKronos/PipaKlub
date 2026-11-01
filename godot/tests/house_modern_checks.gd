extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
const Art=preload("res://scripts/campaign/house_modern.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
 var source:Dictionary=content.rooms.bedroom.duplicate(true)
 var room:=Room.new();root.add_child(room);room.configure(source,[528,816],true,"desk",true,true);room.set_process(false)
 check(room.data==content.rooms.bedroom,"presentation preserves all room data")
 check(room.get_meta("house_art","")=="modern-v1","native bedroom style applies")
 check(room.props.size()==source.props.size()+3,"all separate props and actors retain ordering entries")
 var seen:Dictionary={};var q:Array[Vector2i]=[Vector2i(528,816)];seen[q[0]]=true;var n:=0
 while n<q.size():
  var at:Vector2i=q[n];n+=1
  for d in [Vector2i(16,0),Vector2i(-16,0),Vector2i(0,16),Vector2i(0,-16)]:
   var p:Vector2i=at+d
   if not seen.has(p) and room._safe(Vector2(p)):seen[p]=true;q.append(p)
 for name in ["kaelTV","kaelDesk","motherEntry","mother","kaelTalk","kaelBirth","rabbito","rabbitoNear"]:
  var raw:Array=source.layout.blocking[name];var target:=Vector2(raw[0],raw[1]);var found:=false
  for p:Vector2i in seen:if Vector2(p).distance_to(target)<24:found=true;break
  check(room._safe(target) and found,"reachable story position "+name)
 for spot in source.hotspots:
  var found:=false
  for p:Vector2i in seen:if Vector2(p).distance_to(Vector2(spot.x,spot.y))<50:found=true;break
  check(found,"reachable interaction "+str(spot.id))
 for r in source.blocked:
  check(not room._safe(Vector2(r[0]+r[2]*.5,r[1]+r[3]*.5)),"furniture and stair void remain blocked")
 for item in room.props:
  var art:Sprite2D=item.node.get_node_or_null("Art")
  if art:
   check(is_equal_approx(art.scale.x,art.scale.y),"uniform art scale "+str(item.node.name))
   check(art.region_rect.size.x>0 and art.region_rect.size.y>0,"valid art crop")
 for id in ["cama","mesa","estante","guarda-roupa","tv","janela"]:
  check(room.get_node("Modern_"+id).has_node("Art"),"bedroom art is present: "+id)
 var bed:Node2D=room.get_node("Modern_cama")
 room.actor=Vector2(480,352);room.opening_pose();check(room.avatar.z_index<bed.z_index,"actor behind bed uses back ordering")
 room.actor=Vector2(480,800);room.opening_pose();check(room.avatar.z_index>bed.z_index,"actor in front of bed uses front ordering")
 var desk:Node2D=room.get_node("Modern_mesa")
 room.actor=Vector2(1008,432);room.opening_pose();check(room.avatar.z_index<desk.z_index,"actor behind desk")
 room.actor=Vector2(1200,528);room.opening_pose();check(room.avatar.z_index>desk.z_index,"actor in front of desk")
 room.free()
 var home:=Room.new();root.add_child(home);home.configure(content.rooms.home,content.rooms.home.entry,false,"",true,true);home.set_process(false)
 check(home.data==content.rooms.home,"downstairs preserves all navigation data")
 check(home.get_meta("house_art","")=="modern-v1","downstairs uses matching house art")
 var visited:Dictionary={};var queue:Array[Vector2i]=[Vector2i(1424,1104)];visited[queue[0]]=true;var index:=0
 while index<queue.size():
  var at:Vector2i=queue[index];index+=1
  for d in [Vector2i(16,0),Vector2i(-16,0),Vector2i(0,16),Vector2i(0,-16)]:
   var p:Vector2i=at+d
   if not visited.has(p) and home._safe(Vector2(p)):visited[p]=true;queue.append(p)
 for spot in home.data.hotspots:
  var found:=false
  for p:Vector2i in visited:if Vector2(p).distance_to(Vector2(spot.x,spot.y))<50:found=true;break
  check(found,"downstairs reachable interaction "+str(spot.id))
 for item in home.props:
  var art:Sprite2D=item.node.get_node_or_null("Art")
  if art:
   check(is_equal_approx(art.scale.x,art.scale.y),"downstairs uniform scale "+str(item.node.name))
   check(art.region_rect.size.x>0 and art.region_rect.size.y>0,"downstairs alpha crop")
 for id in ["sofa","mesa-centro","mesa-jantar","banco-jantar","banco-fundo","cozinha","janela"]:
  check(home.get_node("Modern_"+id).has_node("Art"),"downstairs art is present: "+id)
 var sofa:Node2D=home.get_node("Modern_sofa")
 home.actor=Vector2(480,544);home.opening_pose();check(home.avatar.z_index<sofa.z_index,"actor behind sofa")
 home.actor=Vector2(480,912);home.opening_pose();check(home.avatar.z_index>sofa.z_index,"actor in front of sofa")
 home.free()
 check(not Art.applies(content.rooms.professor),"other interiors keep original art")
 print("CASA MODERNA ",checks," checks; bedroom ",seen.size(),", home ",visited.size()," reachable samples; ",failures," failures; no save access")
 quit(0 if failures==0 else 1)

