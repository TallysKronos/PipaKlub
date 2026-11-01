extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
const D=preload("res://scripts/campaign/shop_data.gd")
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Journey=preload("res://scripts/campaign/journey.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var data:=D.room();var room:=Room.new();root.add_child(room);room.configure(data,[D.ENTRY.x,D.ENTRY.y],true,"*",false,true);room.set_process(false)
 check(data.layout.floor.w*data.layout.floor.h>14*11*96*96*1.6,"shop is at least 60 percent larger than legacy layout")
 var seen:Dictionary={};var queue:Array[Vector2i]=[Vector2i(D.ENTRY)];seen[queue[0]]=true;var n:=0
 while n<queue.size():
  var at:Vector2i=queue[n];n+=1
  for delta in [Vector2i(16,0),Vector2i(-16,0),Vector2i(0,16),Vector2i(0,-16)]:
   var p:Vector2i=at+delta
   if not seen.has(p) and room._safe(Vector2(p)):seen[p]=true;queue.append(p)
 for spot in data.hotspots:
  var reachable:=false
  for p:Vector2i in seen:if Vector2(p).distance_to(Vector2(spot.x,spot.y))<24:reachable=true;break
  check(reachable and room._safe(Vector2(spot.x,spot.y)),"reachable interaction "+str(spot.id))
 var unreachable:=0
 for x in range(400,2112,16):
  for y in range(304,1632,16):
   var p:=Vector2i(x,y)
   if room._safe(Vector2(p)) and not seen.has(p):unreachable+=1
 check(unreachable==0,"no isolated walkable pockets")
 for item in room.props:
  var art:Sprite2D=item.node.get_node_or_null("Art")
  if art:
   check(is_equal_approx(art.scale.x,art.scale.y),"uniform art scale "+str(item.node.name))
   check(art.region_rect.end.x<=art.texture.get_width() and art.region_rect.end.y<=art.texture.get_height(),"crop inside PNG")
 var owner:=room.get_node("ShopOwner")
 check(owner.has_node("Art"),"new owner uses his own chibi asset")
 check(owner.z_index<room.get_node("Shop_counter").z_index,"owner is drawn behind the counter")
 check(not room._safe(D.OWNER),"owner has a physical foot collision")
 room.actor=D.point(8,4.5);room.opening_pose();check(room.avatar.z_index>room.get_node("Shop_counter").z_index,"customer stands in front of counter")
 for pose in [[D.point(8,.8),"counter",true],[D.point(7,6),"table-a",true],[D.point(10,9.5),"table-a",false]]:
  check(room._safe(pose[0]),"occlusion pose is on walkable floor")
  room.actor=pose[0];room.opening_pose()
  var prop:Node2D=room.get_node("Shop_"+str(pose[1]))
  check(room.avatar.z_index<prop.z_index if pose[2] else room.avatar.z_index>prop.z_index,"depth order around "+str(pose[1]))
 var session:=Session.new();session._store=Store.new("user://shop-checks-"+State.new_id());root.add_child(session)
 check(session.start("slot-1").status=="ok","isolated slot created")
 var saved:Dictionary=session.snapshot();saved.player.partners=[{"id":State.new_id(),"modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}];saved.player.equippedPartnerId=saved.player.partners[0].id
 check(session.checkpoint({"kind":"world","scene":"quintal","position":[D.CITY_ENTRY.x,D.CITY_ENTRY.y],"space":"bairro-inicial-v2"},saved.player).status=="ok","old city scene remains valid")
 var journey:=Journey.new(session)
 check(journey.enter_world("kite-shop",D.ENTRY).status=="ok","shop checkpoint is accepted")
 var stored:Dictionary=session.snapshot()
 check(State.inspect(stored,"slot-1")=="ok","shop snapshot validates")
 check(journey.enter_world("kite-shop",D.point(1,12)).status=="ok","walked position can be saved")
 session.close_session();check(session.resume_slot("slot-1").status=="ok","shop save reloads")
 check(session.snapshot().checkpoint.scene=="kite-shop" and session.snapshot().checkpoint.position==[480.0,1440.0],"reload preserves shop position")
 check(journey.enter_world("kite-shop",Vector2.ZERO).status!="ok","invalid shop spawn cannot be saved")
 check(journey.enter_world("quintal",D.CITY_ENTRY).status=="ok","return to city is valid")
 session.close_session();session.free();room.free()
 print("SHOP MODERNO ",checks," checks; ",seen.size()," reachable samples; ",unreachable," isolated walkable samples; ",failures," failures; isolated save directory")
 quit(0 if failures==0 else 1)
