extends SceneTree
const Trust=preload("res://scripts/campaign/retalho_trust.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Care=preload("res://scripts/campaign/retalho_care.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
var app:Control
var service:RefCounted
var checks:=0
var failures:=0
class FailedStore extends "res://scripts/campaign/save_store.gd":
 func save_slot(_data:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func frames()->void:
 for i in 8:await process_frame
func ready_world()->void:
 for i in 900:
  await process_frame
  var scene:String=app.session.snapshot().checkpoint.get("scene","")
  if scene==Care.SPACE and is_instance_valid(app.room) and not is_instance_valid(app.scene_loading):return
  if is_instance_valid(app.park) and app.park.get_meta("campaign_scene","")==scene and not is_instance_valid(app.scene_loading):return
 check(false,"world loads")
func shot(name:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames();await RenderingServer.frame_post_draw
 var out:=ProjectSettings.globalize_path("res://../documentation/qa/retalho-trust-v1/fluxo")
 DirAccess.make_dir_recursive_absolute(out)
 check(root.get_texture().get_image().save_png(out.path_join(name+".png"))==OK,"capture "+name)
func checkpoint(scene:String,point:Vector2)->void:
 var cp:Dictionary={"kind":"world","scene":scene,"position":[point.x,point.y]} if scene==Care.SPACE else CP.make(scene,point,CP.SPACE)
 check(app.session.checkpoint(cp,app.session.snapshot().player).status=="ok","checkpoint "+scene)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 app=load("res://scripts/campaign/front_end.gd").new();app.session._store=Store.new("user://retalho-trust-"+State.new_id());root.add_child(app)
 app.preferences.reduced_motion=true
 check(app.session.start("slot-1").status=="ok","isolated save")
 service=Trust.new(app.session)
 check(not Trust.available(app.session.snapshot().player),"no early recruitment")
 var p:Dictionary=app.session.snapshot().player
 p.partners=[{"id":"r","modelId":"rabbito","xp":Trust.Levels.xp_for_level(24),"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
 var district:=Rules.fresh("industrial");district.completed=true;district.rewardClaimed=true;Rules.store(p,"industrial",district)
 for f in ["pipaDragaoDesatadaVencida","retalhoAtelieAproximacao","retalhoAtelieCuidado","assisReconheceuNoRetalho"]:p.flags[f]=true
 preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(p);p.flags.pipeiroDocumentsSeen=true
 check(app.session.checkpoint({"kind":"world","scene":Care.SPACE,"position":[Care.APPROACH.x,Care.APPROACH.y]},p).status=="ok","care fixture")
 check(service.advance(2,Care.APPROACH).status=="wrong_step","cannot skip escape")
 app._show_world();await ready_world();app._world_interact("retalho-care");await frames()
 var dialog:Control=app.get_node_or_null("RetalhoTrustDialogue")
 check(is_instance_valid(dialog) and app.flow_busy and not app.room.can_walk,"invitation UI locks movement")
 if not is_instance_valid(dialog):app.free();quit(1);return
 await shot("01-um-lugar-livre")
 dialog.canceled.emit();await frames()
 check(Trust.stage(app.session.snapshot().player)==0 and app.room.can_walk and not app.flow_busy,"invitation cancel")
 var baseline:Dictionary=app.session.snapshot();var working=app.session._store
 app.session._store=FailedStore.new()
 check(service.advance(0,Care.APPROACH).status=="io_error" and app.session.snapshot()==baseline,"failed invitation unchanged")
 app.session._store=working
 for i in [0,1]:
  check(service.advance(i,Care.APPROACH).status=="ok","atelier beat "+str(i))
  check(app.session.resume_slot("slot-1").status=="ok" and Trust.stage(app.session.snapshot().player)==i+1,"resume atelier beat")
 check(not Care.room_data(app.content.rooms.professor,app.session.snapshot().player).hotspots.any(func(h):return h.id=="retalho-care"),"Retalho leaves atelier")
 var qa:=Story.qa_override;Story.qa_override=0
 check(Story.can_travel(app.session.snapshot().player,"pantano") and preload("res://scripts/campaign/kronasta_atlas.gd").can_travel(Trust.A,app.session.snapshot().player),"story swamp opens in release mode")
 check(not Story.can_travel(app.session.snapshot().player,"palafitas"),"docks wait for treatment")
 for i in [2,3,4]:
  var scene:String=Trust.B if i==3 else Trust.A
  var at:Vector2=Trust.HERB if i==3 else Trust.SICK
  var model=CP.model_for(scene)
  check(model.point_walkable(at) and not model.path_to(CP.spawn(scene),at).is_empty(),"real route to swamp beat "+str(i))
  checkpoint(scene,CP.safe(scene,at+Vector2(0,1)))
  check(service.advance(i,Vector2.INF).status=="wrong_step","nonfinite refused")
  check(CP.allowed(Trust.event(scene),app.session.snapshot().player,scene),"visible quest event")
  app._show_world();await ready_world();app.park.set_physics_process(false)
  await shot("02-pantano-"+str(i))
  check(service.advance(i,at).status=="ok","swamp beat "+str(i))
  check(service.advance(i,at).status=="wrong_step","stale beat refused")
 check(Story.can_travel(app.session.snapshot().player,"palafitas"),"docks open after treatment")
 for part in ["a","b","c"]:
  var scene:String="kronasta-palafitas-"+part
  var model=CP.model_for(scene)
  for event:Dictionary in CP.data(scene).events:
   var at:=Vector2(event.u+.5,event.v+.5)
   check(model.point_walkable(at) and (at.distance_to(CP.spawn(scene))<.01 or not model.path_to(CP.spawn(scene),at).is_empty()),"reachable "+scene+" "+str(event.id))
 checkpoint(Trust.C,Trust.RESCUE+Vector2(0,1))
 for outcome in ["lost","fled","won"]:
  # Terminal states are fixtures: this verifies settlement, not combat balance.
  var current:Dictionary=app.session.snapshot().player
  current.partners[0].condition={"line":100,"structure":100}
  app.session.checkpoint(app.session.snapshot().checkpoint,current)
  check(service.begin(Trust.RESCUE).status=="ok","begin rescue "+outcome)
  var e:Dictionary=app.session.snapshot().player.encounter
  e.state.outcome=outcome
  if outcome=="won":e.state.q.hp=0
  if outcome=="lost":e.state.p.hp=0
  current=app.session.snapshot().player;current.encounter=e
  check(app.session.checkpoint({"kind":"encounter"},current).status=="ok" and State.valid_encounter(e),"valid rescue fixture")
  if outcome=="won":
   var store=app.session._store;var before_win:Dictionary=app.session.snapshot();app.session._store=FailedStore.new()
   check(service.settle().status=="io_error" and app.session.snapshot()==before_win,"failed victory settlement remains resumable")
   app.session._store=store
  check(service.settle().status=="ok","settle "+outcome)
  check(Trust.stage(app.session.snapshot().player)==(6 if outcome=="won" else 5),"only victory frees line")
  if outcome=="lost":
   checkpoint("kronasta-palafitas-b",Vector2(12.5,30.5))
   check(service.rest(Vector2(12.5,30.5)).status=="ok","free rest after defeat")
   check(service.rest(Vector2(12.5,30.5)).status=="already_applied","healthy rest is read only")
  checkpoint(Trust.C,Trust.RESCUE+Vector2(0,1))
 checkpoint(Trust.C,Trust.RESCUE)
 app.preferences.reduced_motion=DisplayServer.get_name()=="headless"
 app._show_world();await ready_world();app.park.set_physics_process(false)
 app._show_retalho_trust();await frames();dialog=app.get_node_or_null("RetalhoTrustDialogue")
 check(is_instance_valid(dialog),"choice scene opens")
 check(app.park.player.distance_to(Trust.RESCUE)>=.7,"choice stages Kael beside Retalho instead of on top")
 if not is_instance_valid(dialog):app.free();quit(1);return
 while dialog.page_index<mini(3,dialog.pages.size()-1):dialog.next_page()
 if not app.preferences.reduced_motion:await create_timer(2.0).timeout
 await shot("03-retalho-escolhe")
 dialog.canceled.emit();await frames()
 await ready_world();app.preferences.reduced_motion=true
 check(Trust.stage(app.session.snapshot().player)==6,"choice can resume")
 check(service.advance(6,Trust.RESCUE).status=="ok","choice recorded before grant")
 await current_full_bank_test()
 Story.qa_override=qa
 print("RETALHO TRUST ",checks," checks; ",failures," failures; combat outcomes are fixtures")
 app.free();quit(0 if failures==0 else 1)
func current_full_bank_test()->void:
 var p:Dictionary=app.session.snapshot().player
 while p.partners.size()<30:p.partners.append({"id":State.new_id(),"modelId":"basica","xp":0})
 app.session.checkpoint(app.session.snapshot().checkpoint,p)
 var before:Dictionary=app.session.snapshot()
 check(service.claim(Trust.RESCUE).status=="bank_full" and app.session.snapshot().player.flags.get("retalhoAceitoKael",false) and app.session.snapshot().player.partners==before.player.partners,"full bank records acceptance without replacing partners")
 app._show_retalho_bank();await frames();await shot("04-banco-cheio")
 check(app.session.resume_slot("slot-1").status=="ok" and Trust.stage(app.session.snapshot().player)==7,"pending choice survives reload")
 check(service.release("r").status=="equipped","cannot release equipped partner")
 var buttons:Array=app.page.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Liberar "))
 check(not buttons.is_empty(),"bank exposes release choices")
 if buttons.is_empty():return
 buttons[0].pressed.emit();await frames()
 var dialog:Control=app.get_node_or_null("RetalhoBankReleaseDialogue")
 check(is_instance_valid(dialog),"release requires separate confirmation")
 if not is_instance_valid(dialog):return
 dialog.canceled.emit();await frames()
 check(app.session.snapshot().player.partners.size()==30,"cancel never releases a partner")
 buttons[0].pressed.emit();await frames();dialog=app.get_node("RetalhoBankReleaseDialogue")
 while dialog.page_index<dialog.pages.size()-1:dialog.next_page()
 dialog.get_ok_button().pressed.emit();await frames()
 check(app.session.snapshot().player.partners.size()==29,"confirmed release opens one slot")
 var working=app.session._store;before=app.session.snapshot();app.session._store=FailedStore.new()
 check(service.claim(Trust.RESCUE).status=="io_error" and app.session.snapshot()==before,"failed adoption grants nothing")
 app.session._store=working
 check(service.claim(Trust.RESCUE).status=="ok","Retalho adopted")
 var after:Dictionary=app.session.snapshot()
 check(after.player.partners.size()==30 and after.player.partners.filter(func(x):return x.get("origin","")==Trust.ORIGIN).size()==1,"one Retalho in bank")
 check(not after.player.flags.get("leagueBlue",false) and not after.player.flags.get("exameAzulOrientadoV2",false),"trust never grants league progress")
 check(service.claim(Trust.RESCUE).status=="already_applied" and app.session.snapshot()==after,"no duplicate adoption")
 check(app.session.resume_slot("slot-1").status=="ok" and Trust.stage(app.session.snapshot().player)==8,"adoption reload")
 var recruited:Dictionary=after.player.partners.filter(func(x):return x.get("origin","")==Trust.ORIGIN)[0]
 var view=load("res://scripts/campaign/encounter_view.gd").new()
 view.configure(app.content,load("res://scripts/campaign/encounter_model.gd").new(recruited).snapshot())
 check(view.art_ids[0]=="retalho-original","Retalho battle art is not Rabbito")
 view.free()
 app.team_page=999;app._show_collection();await frames();await shot("05-retalho-no-banco")
