extends SceneTree
const Row=preload("res://scripts/campaign/marisol_row.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
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
 for n in 8:await process_frame
func click(text:String)->void:
 for b:Button in app.page.find_children("*","Button",true,false):
  if b.text==text:b.pressed.emit();await frames();return
 check(false,"button "+text)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 app=load("res://scripts/campaign/front_end.gd").new();app.session._store=load("res://scripts/campaign/save_store.gd").new("user://marisol-row-"+State.new_id());root.add_child(app);app.preferences.reduced_motion=true
 check(app.session.start("slot-1").status=="ok","isolated save")
 var p:Dictionary=app.session.snapshot().player
 check(not Row.eligible(p),"Blue required")
 p.flags.leagueBlue=true
 check(not Row.eligible(p),"historical Cais required")
 var district:=Rules.fresh("cais");district.completed=true;district.rewardClaimed=true;district.champion=Rules.definition("cais").stages[0].npcId;Rules.store(p,"cais",district)
 p.partners=[{"id":"r","modelId":"rabbito","xp":0}];p.equippedPartnerId="r"
 p.journey={"phase":"complete","lesson":5}
 check(Row.eligible(p),"lost championship does not revoke lesson")
 var event:Dictionary=CP.data("kronasta-cais-c").events.filter(func(e):return e.props.get("duel","")=="cais-5")[0]
 var at:=Vector2(event.u+.5,event.v+.5)
 check(app.session.checkpoint(CP.make("kronasta-cais-c",at,CP.SPACE),p).status=="ok","Marisol checkpoint")
 var lesson:=Row.new(app.session);var before:Dictionary=app.session.snapshot()
 check(not lesson.near(Vector2.INF),"nonfinite denied")
 check(lesson.finish(at).status=="wrong_step" and app.session.snapshot()==before,"cannot finish without responses")
 check(lesson.answer("rush",at).status=="try_again" and lesson.step==0 and app.session.snapshot()==before,"wrong answer explained without mutation")
 check(Row.new(app.session).step==0,"unregistered lesson restarts")
 app._show_row_lesson(lesson,at);await frames()
 for entry:Dictionary in Row.data().lessons:
  for option:Dictionary in entry.options:
   if option.id==entry.answer:await click(option.text);break
 check(lesson.step==3 and not Row.learned(app.session.snapshot().player),"UI answers do not auto-save completion")
 var store=app.session._store;app.session._store=FailedStore.new()
 check(lesson.finish(at).status=="io_error" and app.session.snapshot()==before,"failed write keeps state unchanged")
 app.session._store=store
 await click("Registrar orientação")
 var after:Dictionary=app.session.snapshot()
 check(Row.learned(after.player),"orientation registered")
 check(after.player.partners==before.player.partners and after.player.inventory==before.player.inventory and after.player.coins==before.player.coins,"no borrowed Platyx rewards costs or partner changes")
 check(not after.player.flags.get("canRemar",false),"orientation not practical permission")
 check(lesson.finish(at).status=="already_applied" and app.session.snapshot()==after,"repeat read-only")
 check(app.session.resume_slot("slot-1").status=="ok" and Row.learned(app.session.snapshot().player),"persists after reload")
 if DisplayServer.get_name()!="headless":
  app._show_row_lesson(Row.new(app.session),at);await frames();await RenderingServer.frame_post_draw
  var out:=ProjectSettings.globalize_path("res://../documentation/qa/marisol-row-v1");DirAccess.make_dir_recursive_absolute(out)
  check(root.get_texture().get_image().save_png(out.path_join("orientacao.png"))==OK,"capture")
 app._show_saved()
 for frame in 900:
  await process_frame
  if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):break
 check(is_instance_valid(app.park),"Cais adapter opens")
 if is_instance_valid(app.park):
  app._district_action("cais-5");await frames()
  await click("Assuntos do campeonato")
  for frame in 900:
   await process_frame
   if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):break
  check(is_instance_valid(app.park),"championship route restores world before accessing NPC")
 print("MARISOL ROW ",checks," checks; ",failures," failures; orientation only, no aquatic navigation")
 app.free();quit(0 if failures==0 else 1)
