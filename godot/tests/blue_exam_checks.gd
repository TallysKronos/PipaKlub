extends SceneTree
const Exam=preload("res://scripts/campaign/blue_exam.gd")
const Escort=preload("res://scripts/campaign/blue_escort_model.gd")
const ControlModel=preload("res://scripts/campaign/blue_control_model.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
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
func world()->void:
 for i in 900:
  if not is_instance_valid(app.scene_loading):break
  await process_frame
 app._show_world()
 for i in 900:
  await process_frame
  if is_instance_valid(app.park) and app.park.get_meta("campaign_scene","")==Exam.SCENE and not is_instance_valid(app.scene_loading):
   app.park.set_physics_process(false);app.park.blue_guide.set_process(false);return
 check(false,"yard loads")
func at(point:Vector2)->void:
 check(app.session.checkpoint(CP.make(Exam.SCENE,point,CP.SPACE),app.session.snapshot().player).status=="ok","checkpoint")
func shot(name:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames();await RenderingServer.frame_post_draw
 var path:=ProjectSettings.globalize_path("res://../documentation/qa/blue-exam-v1/fluxo")
 DirAccess.make_dir_recursive_absolute(path)
 check(root.get_texture().get_image().save_png(path.path_join(name+".png"))==OK,"capture "+name)
func completed_control()->RefCounted:
 var m:=ControlModel.new()
 for i in 300:
  m.tick(.05,{"pointer":ControlModel.TARGET.get_center()})
  if m.phase==1:break
 check(m.phase==1,"hold within target")
 m.tick(.05,{"line":true});m.tick(.05,{"line":false})
 check(not m.armed,"cannot preempt the signal by tapping line")
 for i in 30:m.tick(.05,{"line":true})
 for i in 100:
  m.tick(.05,{"line":false})
  if m.phase==2:break
 check(m.phase==2 and m.energy>=60,"release after wind recovers energy")
 for i in 3:
  for tick in 24:m.tick(.05,{"guard":false})
  m.tick(.05,{"guard":true});m.tick(.05,{"guard":false})
 check(m.complete and m.signals==3,"three deliberate defenses complete control")
 return m
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 var idle:=ControlModel.new()
 for i in 500:idle.tick(.05,{})
 check(not idle.complete and idle.phase==0,"idling does not pass")
 var escort:=Escort.new()
 for i in 200:escort.tick(.05,Escort.ROUTE[2])
 check(escort.checkpoint==0 and not escort.evidence(),"standing at final marker cannot pass")
 var malformed:=Exam.fresh();malformed.escort=4
 check(not Exam.valid(malformed),"invalid progress refused")
 malformed=Exam.fresh();malformed.control=true
 check(not Exam.valid(malformed),"control cannot precede care and escort")
 var control:RefCounted=completed_control()
 app=load("res://scripts/campaign/front_end.gd").new();app.session._store=load("res://scripts/campaign/save_store.gd").new("user://blue-exam-"+State.new_id());root.add_child(app);app.preferences.reduced_motion=true
 check(app.session.start("slot-1").status=="ok","isolated save")
 service=Exam.new(app.session)
 var p:Dictionary=app.session.snapshot().player
 for id in ["cais","industrial"]:
  var value:=Rules.fresh(id);value.completed=true;value.rewardClaimed=true;value.champion=Rules.definition(id).stages[0].npcId;Rules.store(p,id,value)
 p.flags.leagueGreen=true;p.flags.leagueGreenSeen=true;p.journey={"phase":"complete","lesson":5};p.coins=17;p.inventory={"papel-seda":2}
 for i in 30:p.partners.append({"id":"partner-"+str(i),"modelId":"rabbito","xp":0,"condition":{"line":0,"structure":0}})
 p.equippedPartnerId="partner-0"
 load("res://scripts/campaign/pipeiro_identity.gd").issue_into(p);p.flags.pipeiroDocumentsSeen=true
 check(Exam.Prep.eligible(p) and not p.flags.get("assisReconheceuNoRetalho",false),"candidate independent of Retalho")
 var unqualified:=p.duplicate(true);unqualified.flags.leagueGreen=false;unqualified.flags.retalhoAcolhido=true
 check(not Exam.Prep.eligible(unqualified),"owning Retalho never qualifies candidate")
 var entry:Dictionary=CP.data("park-trail").events.filter(func(e):return int(e.id)==19100)[0]
 check(CP.allowed(entry,p) and not CP.allowed(entry,unqualified),"physical entrance eligibility")
 var inbound:Dictionary=CP.exit_target(CP.make("park-trail",Vector2(34.5,31.5),CP.SPACE),"19100",p)
 check(inbound.get("status")=="ok","physical entrance leads to supported patio")
 check(CP.model_for("park-trail").height_at(Vector2(34.5,31.5))==CP.model_for(Exam.SCENE).height_at(CP.spawn(Exam.SCENE)),"entrance ground level matches")
 var exit_event:Dictionary=CP.data(Exam.SCENE).events.filter(func(e):return e.type=="saida")[0]
 var outbound:Dictionary=CP.exit_target(CP.make(Exam.SCENE,Vector2(20.5,31.5),CP.SPACE),str(int(exit_event.id)),p)
 check(outbound.get("status")=="ok" and outbound.get("point")==Vector2(34.5,31.5),"return reaches the same Garden entrance")
 check(CP.model_for("park-trail").cell_at(Vector2i(34,31)).material==CP.model_for(Exam.SCENE).cell_at(Vector2i(20,31)).material,"connection material matches")
 check(app.session.checkpoint(CP.make(Exam.SCENE,Exam.OBSERVE,CP.SPACE),p).status=="ok","fixture")
 var before:Dictionary=app.session.snapshot()
 check(service.care("rest",Exam.OBSERVE).status=="wrong_step","must observe first")
 check(service.claim(Exam.CIDA).status=="wrong_step","no award for merely visiting")
 check(service.observe(Vector2.INF).status=="wrong_step","nonfinite refused")
 var working=app.session._store;app.session._store=FailedStore.new()
 check(service.observe(Exam.OBSERVE).status=="io_error" and app.session.snapshot()==before,"failed observation unchanged")
 app.session._store=working
 await world();await shot("01-bancada")
 app._blue_station("observe");await frames();await shot("02-observacao")
 check(Exam.record(app.session.snapshot().player).observed,"examining persists observation")
 var choices:Array=app.page.find_children("*","Button",true,false)
 choices.filter(func(b):return b.text=="Trocar a linha")[0].pressed.emit();await frames()
 check(not Exam.record(app.session.snapshot().player).care,"wrong care cannot pass")
 choices.filter(func(b):return b.text.begins_with("Oferecer descanso"))[0].pressed.emit();await frames()
 check(Exam.record(app.session.snapshot().player).care,"correct care passed")
 check(service.control(control,Exam.CONTROL).status=="wrong_step","control cannot bypass escort")
 at(Escort.START);await world()
 check(not app.park.follower_root.visible and not app.park.exploration_hud.partner_panel.visible,"borrowed partner not personal team")
 app._blue_station("escort")
 var guide:Node2D=app.park.blue_guide
 check(guide.running,"escort begins at real station")
 var resumed_partial:=false
 for tick in 1600:
  if guide.course.complete:break
  if guide.course.checkpoint==1 and not resumed_partial:
   check(app.session.resume_slot("slot-1").status=="ok","partial escort reload")
   app.park.saved_player=app.session.snapshot().player;guide.begin();resumed_partial=true
   check(guide.course.checkpoint==1 and guide.course.position==Escort.ROUTE[0],"resume from passed marker, not from start")
  if tick%4==0:app.park.walk_to(guide.course.position+Vector2(0,1))
  app.park._physics_process(.05);guide._process(.05)
 check(guide.course.complete and int(Exam.record(app.session.snapshot().player).escort)==3,"real controller accompanies three markers")
 await shot("03-conducao")
 check(app.session.resume_slot("slot-1").status=="ok" and int(Exam.record(app.session.snapshot().player).escort)==3,"escort reload")
 var rogue:=Escort.new();rogue.ready=true;rogue.position=Escort.ROUTE[0]
 check(service.escort_checkpoint(rogue,rogue.position).status=="wrong_step","fake marker without walking refused")
 at(Exam.CONTROL);await world();app._blue_station("control");await frames()
 var view:Control=app.get_node_or_null("BlueControlView")
 check(is_instance_valid(view),"control UI opens")
 if not is_instance_valid(view):app.free();quit(1);return
 await create_timer(.5).timeout
 var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=view.field().get_center()
 root.push_input(click,true);await frames()
 check(view.pointer.distance_to(Vector2(.5,.5))<.001,"flight field receives mouse through layout")
 click=click.duplicate();click.pressed=false;root.push_input(click,true)
 view.toggle_pause();var frozen:float=view.model.held_time;await frames()
 check(view.model.held_time==frozen,"pause freezes evaluation")
 view.toggle_pause();await shot("04-controle")
 view.left.emit();await frames()
 check(not Exam.record(app.session.snapshot().player).control and int(Exam.record(app.session.snapshot().player).escort)==3,"leaving retains only passed competencies")
 await world();app._blue_station("control");await frames();view=app.get_node("BlueControlView")
 view.model=control;await frames();view.finish.pressed.emit();await frames()
 check(Exam.record(app.session.snapshot().player).control and not Exam.promoted(app.session.snapshot().player),"control pass not promotion")
 at(Exam.CIDA);await world()
 working=app.session._store;before=app.session.snapshot();app.session._store=FailedStore.new()
 check(service.claim(Exam.CIDA).status=="io_error" and app.session.snapshot()==before,"failed promotion remains pending")
 app.session._store=working
 app._blue_station("register");await frames()
 for d in app.get_children():
  if d.has_method("get_ok_button"):
   while d.page_index<d.pages.size()-1:d.next_page()
   d.get_ok_button().pressed.emit();break
 await frames()
 var after:Dictionary=app.session.snapshot()
 check(Exam.promoted(after.player) and after.player.inventory.get("certificado-rabiola-azul",0)==1,"Cida grants one certificate")
 check(load("res://scripts/campaign/kronasta_story.gd").category(after.player)=="Rabiola Azul","category visible")
 var original:Dictionary=JSON.parse_string(JSON.stringify(p));var current:Dictionary=JSON.parse_string(JSON.stringify(after.player))
 check(current.partners==original.partners and current.coins==original.coins and current.inventory["papel-seda"]==2,"full exhausted bank and materials untouched")
 check(not after.player.flags.get("retalhoAcolhido",false),"exam never grants Retalho")
 check(service.claim(Exam.CIDA).status=="already_applied" and app.session.snapshot()==after,"promotion not farmable")
 check(app.session.resume_slot("slot-1").status=="ok" and Exam.promoted(app.session.snapshot().player),"promotion reload")
 await shot("05-aprovacao")
 print("BLUE EXAM ",checks," checks; ",failures," failures; scripted inputs, no physical controller")
 app.free();quit(0 if failures==0 else 1)
