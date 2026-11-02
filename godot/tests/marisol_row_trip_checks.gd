extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Row=preload("res://scripts/campaign/marisol_row_trip.gd")
const Motion=preload("res://scripts/campaign/row_motion.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
var app:Control
var checks:=0
var failures:=0
class FailedStore extends "res://scripts/campaign/save_store.gd":
 func save_slot(_data:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func frames()->void:
 for i in 8:await process_frame
func world()->void:
 for frame in 900:
  if not is_instance_valid(app.scene_loading):break
  await process_frame
 app._show_world()
 for frame in 900:
  await process_frame
  if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):
   app.park.set_physics_process(false);return
 check(false,"loads row view")
func shot(name:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames();await RenderingServer.frame_post_draw
 var path:=ProjectSettings.globalize_path("res://../documentation/qa/marisol-row-trip-v1");DirAccess.make_dir_recursive_absolute(path)
 check(root.get_texture().get_image().save_png(path.path_join(name+".png"))==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 app=load("res://scripts/campaign/front_end.gd").new();app.session._store=Store.new("user://row-trip-"+State.new_id());root.add_child(app);app.preferences.reduced_motion=true
 check(app.session.start("slot-1").status=="ok","isolated save")
 var p:Dictionary=app.session.snapshot().player;p.journey={"phase":"complete","lesson":5};p.flags.leagueBlue=true
 var district:=Rules.fresh("cais");district.completed=true;district.rewardClaimed=true;Rules.store(p,"cais",district)
 p.partners=[{"id":"r","modelId":"rabbito","xp":0,"condition":{"line":0,"structure":0}}];p.equippedPartnerId="r"
 var service:=Row.new(app.session);var entry:Dictionary=Row.data().links[0];var a:=Row.point(entry.from);var b:=Row.point(entry.to)
 for link:Dictionary in Row.data().links:
  check(Row.valid_link(link),"geometric water lane "+link.id)
  var model=CP.model_for(Row.data().scene)
  for bank in [Row.point(link.from),Row.point(link.to)]:
   check(not model.path_to(CP.spawn(Row.data().scene),bank).is_empty(),"bank reachable on foot")
  check(not model.clear_segment(Row.point(link.from),Row.point(link.to)),"cannot walk on water")
 check(app.session.checkpoint(CP.make(Row.data().scene,a,CP.SPACE),p).status=="ok","fixture")
 check(service.begin(entry.id,a).status=="wrong_step","orientation required")
 p.flags.marisolRemarOrientado=true
 check(app.session.checkpoint(CP.make(Row.data().scene,a,CP.SPACE),p).status=="ok","orientation")
 var story=load("res://scripts/campaign/kronasta_story.gd");story.qa_override=0
 check(story.can_travel(p,"pantano") and load("res://scripts/campaign/kronasta_atlas.gd").can_travel(Row.data().scene,p),"ordinary player access independent of Retalho")
 story.qa_override=-1
 check(service.begin(entry.id,Vector2.INF).status=="wrong_step" and service.begin(entry.id,a+Vector2(6,0)).status=="wrong_step","remote begin denied")
 var store=app.session._store;var before:Dictionary=app.session.snapshot();app.session._store=FailedStore.new()
 check(service.begin(entry.id,a).status=="io_error" and app.session.snapshot()==before,"failed departure unchanged")
 app.session._store=store
 check(service.begin(entry.id,a).status=="ok","departure persists")
 var token:String=app.session.snapshot().player.marisolRowTrip.id
 check(service.begin(entry.id,a).status=="wrong_step","duplicate trip denied")
 var motion:=Motion.new(token,entry.id)
 check(service.finish(token,motion).status=="wrong_step","no immediate arrival")
 for tick in 300:motion.tick(.05,false)
 check(motion.progress==0,"idling never crosses")
 check(app.session.resume_slot("slot-1").status=="ok" and service.recover().status=="ok","interruption returns safe bank")
 check(not app.session.snapshot().player.has("marisolRowTrip") and app.session.snapshot().checkpoint.position==[a.x,a.y] and not app.session.snapshot().player.flags.get("marisolRemarPratica",false),"recover without practice credit")
 for tick in 101:motion.tick(.05,true)
 check(service.finish(token,motion).status=="wrong_step","old token cannot land")
 await world();await shot("01-margem")
 for goal:Vector2 in [a+Vector2(1,0),a]:
  check(app.park.walk_to(goal),"walking path to bank")
  for tick in 1200:
   if app.park.player.distance_to(goal)<.08:break
   app.park._physics_process(.016)
  check(app.park.player.distance_to(goal)<.08,"controller arrives at bank")
 app._request_marisol_row(entry.id);await frames()
 for dialog in app.get_children():
  if dialog.has_method("get_ok_button"):
   while dialog.page_index<dialog.pages.size()-1:dialog.next_page()
   dialog.get_ok_button().pressed.emit();break
 await frames()
 check(not app.park.row_record.is_empty(),"actual confirmation boards")
 if app.park.row_record.is_empty():app.free();quit(1);return
 app.park.paused=true;app.park.paddle_pointer=true;var progress:float=app.park.row_motion.progress
 app.park._physics_process(.05)
 check(app.park.row_motion.progress==progress,"pause freezes crossing")
 app.park.paused=false
 for tick in 50:app.park._physics_process(.05)
 check(app.park.row_motion.progress>0 and not app.park.row_motion.complete,"held input advances")
 await shot("02-travessia")
 app.park.paddle_pointer=false;var rested:float=app.park.row_motion.energy;progress=app.park.row_motion.progress
 for tick in 10:app.park._physics_process(.05)
 check(app.park.row_motion.energy>rested and app.park.row_motion.progress==progress,"release rests without drifting")
 app.park.paddle_pointer=true;before=app.session.snapshot();app.session._store=FailedStore.new()
 for tick in 100:app.park._physics_process(.05)
 check(app.park.row_motion.complete and app.session.snapshot()==before,"failed arrival keeps pending save")
 app.session._store=store
 for dialog in app.get_children():
  if dialog.has_method("get_ok_button"):
   while dialog.page_index<dialog.pages.size()-1:dialog.next_page()
   dialog.get_ok_button().pressed.emit();break
 await frames()
 check(not app.park.paused,"dismiss save error allows arrival retry")
 var landed_motion:RefCounted=app.park.row_motion;token=app.park.row_record.id
 app.park.interact();await frames()
 check(app.park.row_record.is_empty() and app.session.snapshot().player.flags.get("marisolRemarPratica",false) and app.session.snapshot().player.flags.get("canRemar",false),"retry arrival grants practice and Remar")
 check(app.session.snapshot().checkpoint.position==[b.x,b.y],"stable far bank checkpoint")
 var current:Dictionary=app.session.snapshot().player
 check(current.partners==before.player.partners and current.coins==before.player.coins and current.inventory==before.player.inventory,"loan is not bank transfer or resource cost")
 check(service.finish(token,landed_motion).status=="wrong_step","arrival cannot repeat")
 await shot("03-chegada")
 var reverse:Dictionary=Row.data().links[1]
 check(service.begin(reverse.id,b).status=="ok","return direction")
 var pending:Dictionary=app.session.snapshot().player.marisolRowTrip;motion=Motion.new(pending.id,reverse.id)
 for tick in 101:motion.tick(.05,true)
 check(service.finish(pending.id,motion).status=="ok" and app.session.snapshot().checkpoint.position==[a.x,a.y],"return reaches origin")
 check(app.session.resume_slot("slot-1").status=="ok" and not app.session.snapshot().player.has("marisolRowTrip"),"completed trip reloads")
 print("MARISOL ROW TRIP ",checks," checks; ",failures," failures; scripted inputs, not physical gamepad")
 app.free();quit(0 if failures==0 else 1)
