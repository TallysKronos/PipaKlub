extends SceneTree
const Story=preload("res://scripts/campaign/mormaco_story.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Arena=preload("res://scripts/overworld/mormaco_arena.gd")
const REVEAL_SHOTS="art/overworld/pantano-mormaco-v2/aparicao"
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
func wait_until(predicate:Callable)->void:
 for tick in 420:
  if predicate.call():return
  await physics_frame
func at(scene:String,point:Vector2)->void:check(app.session.checkpoint(CP.make(scene,point,CP.SPACE),app.session.snapshot().player).status=="ok","checkpoint "+scene)
func world()->void:
 for i in 900:
  if not is_instance_valid(app.scene_loading):break
  await process_frame
 app._show_world()
 for i in 900:
  await process_frame
  if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading):app.park.set_physics_process(false);return
 check(false,"world loads")
func approve()->void:
 for d in app.get_children():
  if d.has_method("get_ok_button"):
   while d.page_index<d.pages.size()-1:d.next_page()
   d.get_ok_button().pressed.emit();await frames();return
 check(false,"dialogue exists")
func walk_to_event(point:Vector2)->bool:
 var view:Node2D=app.park
 if not view.walk_to(point):return false
 for tick in 6000:
  view._physics_process(1.0/60.0)
  if view.path.is_empty():return view.player.distance_to(point)<.25 and not view.nearby.is_empty()
 return false
func follow_exit(destination:String)->bool:
 for e:Dictionary in app.park.interaction_events:
  if e.props.get("destino")!=destination:continue
  if not walk_to_event(Vector2(e.u+.5,e.v+.5)) or app.park.nearby.id!=e.id:return false
  app.park.interact()
  for tick in 900:
   await process_frame
   if is_instance_valid(app.park) and app.park.saved_checkpoint.scene==destination and not is_instance_valid(app.scene_loading):
    app.park.set_physics_process(false)
    return true
 return false
func shot(name:String,folder:="documentation/qa/mormaco-story-v1")->void:
 if DisplayServer.get_name()=="headless":return
 await frames();await RenderingServer.frame_post_draw
 var out:=ProjectSettings.globalize_path("res://../"+folder);DirAccess.make_dir_recursive_absolute(out)
 check(root.get_texture().get_image().save_png(out.path_join(name+".png"))==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 app=load("res://scripts/campaign/front_end.gd").new();app.session._store=Store.new("user://mormaco-"+State.new_id());root.add_child(app);app.preferences.reduced_motion=true
 check(app.session.start("slot-1").status=="ok","isolated save")
 var p:Dictionary=app.session.snapshot().player
 check(not Story.available(p),"Blue and practical Remar required")
 p.flags.leagueBlue=true;p.flags.canRemar=true;p.journey={"phase":"complete","lesson":5}
 p.partners=[{"id":"r","modelId":"rabbito","xp":Model.xp_for_level(27),"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r"
 check(app.session.checkpoint(CP.make(Story.A,Story.SIGNAL,CP.SPACE),p).status=="ok","fixture")
 var service:=Story.new(app.session);var before:Dictionary=app.session.snapshot()
 check(service.observe(Vector2.INF).status=="wrong_step","invalid observation rejected")
 var store=app.session._store;app.session._store=FailedStore.new()
 check(service.observe(Story.SIGNAL).status=="io_error" and app.session.snapshot()==before,"failed intro atomic")
 app.session._store=store
 at(Story.C,Story.AT)
 check(service.begin(Story.AT).status=="wrong_step","observe signs before battle")
 at(Story.A,Story.SIGNAL);await world();app._request_mormaco("mormacoSignals");await frames();await shot("01-vento-parou");await approve()
 check(app.session.snapshot().player.flags.get("mormacoVentosPararam",false),"actual intro persists")
 check(await follow_exit("kronasta-pantano-b"),"walk to the exit from A and enter B")
 check(await follow_exit(Story.C),"walk through B and enter the lake")
 check(walk_to_event(Story.AT) and app.park.nearby.props.get("acao")=="mormacoStory","walk to the guardian with the equipped partner")
 check(is_instance_valid(app.park.mormaco) and not app.park.mormaco.sprite.visible,"guardian starts submerged in actual pond")
 var cinematic:bool="--mormaco-cinematic" in OS.get_cmdline_user_args()
 if cinematic:
  app.preferences.reduced_motion=false
  app.park.reduced_motion=false
 for point in [Story.AT,Story.REST]:check(not CP.model_for(Story.C).path_to(CP.spawn(Story.C),point).is_empty(),"walkable station")
 await shot("02-possuido")
 check(service.release(Story.AT).status=="wrong_step","no release without victory")
 check(service.begin(Story.AT+Vector2(5,0)).status=="wrong_step","remote battle rejected")
 var guardian:Node2D=app.park.mormaco
 check(app.park.actors.has_node("MargemDoMormaco") and app.park.model.data.has("celLake"),"the approved lakeside renders in the campaign")
 check(not is_instance_valid(guardian.caster),"the caster is hidden before the ambush")
 var camera:Camera2D=app.park.camera
 var original_position:=camera.position
 var original_zoom:=camera.zoom
 app._request_mormaco("mormacoStory")
 if cinematic:
  await wait_until(func():return guardian.reveal_phase=="surface")
  check(app.park.paused and not app.park.exploration_hud.get_parent().visible,"reveal holds movement and clears the HUD")
  for i in 6:await physics_frame
  await shot("01-superficie",REVEAL_SHOTS)
  await wait_until(func():return guardian.reveal_phase=="geysers")
  for i in 14:await physics_frame
  await shot("02-geiseres",REVEAL_SHOTS)
  for i in 30:await physics_frame
  await shot("02b-onda-na-margem",REVEAL_SHOTS)
 await wait_until(func():return guardian.revealed and not app.flow_busy)
 check(guardian.sprite.visible and not camera.position.is_equal_approx(original_position) and app.park.paused,"guardian and framing stay through the dialogue")
 if cinematic:await shot("03-desafio",REVEAL_SHOTS)
 var offer:Node=app.get_tree().get_first_node_in_group("manga_dialogue")
 check(is_instance_valid(offer),"the challenge offers a choice")
 if is_instance_valid(offer):offer.get_cancel_button().pressed.emit()
 await frames()
 check(camera.position.is_equal_approx(original_position) and camera.zoom.is_equal_approx(original_zoom) and not app.park.paused and not guardian.shore_effect.visible,"declining restores the camera, input and shore")
 app._request_mormaco("mormacoStory")
 await frames()
 await approve()
 for i in 900:
  await process_frame
  if is_instance_valid(app.battle):break
 check(is_instance_valid(app.battle),"actual duel opens")
 if not is_instance_valid(app.battle):app.free();quit(1);return
 app.battle.set_process(false);app.battle.set_physics_process(false)
 check(app.battle.art_ids==["rabbito","mormaco-normal"] and app.battle.boss_intro.title=="Mormaço","Kael fights with his partner against Soulgen Mormaço")
 await shot("03-duelo")
 var battle:RefCounted=app.battle.model
 check(battle.enemy_level==27 and battle.q.boss and battle.q.phase==1 and battle.wind_strength()==0,"authored boss level and still air")
 check(battle.signature_profile(battle.q).windup>=2,"clear geyser warning")
 check(app.session.resume_slot("slot-1").status=="ok","battle can reload")
 for i in 10000:
  if not battle.outcome.is_empty():break
  var towards:=Vector2(battle.q.x-battle.p.x,battle.q.y-battle.p.y).normalized()
  battle.tick(.05,{"x":towards.x,"y":towards.y,"cut":true,"signature":true})
 check(battle.mormaco_ambush() and is_equal_approx(battle.q.hp,battle.q.stats.line*.7),"at 70% the first duel stops for the ambush")
 check(app.encounters.save_battle(battle.snapshot()).status=="ok" and app.session.resume_slot("slot-1").status=="ok","interruption survives reload")
 app._show_saved()
 for i in 900:
  if is_instance_valid(app.park) and not is_instance_valid(app.scene_loading) and is_instance_valid(app.park.mormaco):break
  await process_frame
 await frames()
 check(app.session.snapshot().checkpoint.kind=="world" and not Story.won(app.session.snapshot().player),"threshold returns to the pond without boss victory")
 if cinematic:
  check(app.park.mormaco.sprite.texture.resource_path.ends_with("submerged.png"),"the ambush starts with the normal guardian")
  await wait_until(func():return app.park.mormaco.effect.mode=="ambush" and app.park.mormaco.effect.progress>.51)
  check(is_instance_valid(app.park.mormaco.rai) and app.park.mormaco.sprite.texture.resource_path.ends_with("submerged.png"),"Rai reaches the shore before the possession completes")
  var ambush:Node2D=app.park.mormaco
  check(is_instance_valid(ambush.caster) and ambush.caster.position.is_equal_approx(Arena.cast_foot(app.park.model)) and (ambush.effect.cast_origin+ambush.root.position).is_equal_approx(ambush.caster.position+Arena.HAND),"the caster stands on the deck and the thread starts at her reel")
  await shot("04-carretel",REVEAL_SHOTS)
 for i in 360:
  if is_instance_valid(app.park.mormaco.tyler) and not app.flow_busy:break
  await physics_frame
 check(is_instance_valid(app.park.mormaco.tyler) and app.session.snapshot().player.flags.get("mormacoTylerChegou",false),"overworld animation ends with Tyler's arrival")
 check(app.park.mormaco.sprite.texture.resource_path.ends_with("submerged-possession.png"),"possession uses the dedicated overworld atlas")
 var rai_overworld := false
 for actor in app.park.actors.get_children():
  if actor is Sprite2D and actor.is_visible_in_tree() and actor.texture != null and actor.texture.resource_path.ends_with("/rai-overworld-idle-eight.png"):
   rai_overworld = actor.region_rect.size == Vector2(64, 96)
 check(rai_overworld,"Rai joins Tyler in the overworld with his directional sprite")
 await shot("pantano-mormaco-tyler-rai","documentation/campaign/overworld-sprites/capturas")
 await approve()
 for i in 300:
  if is_instance_valid(app.battle):break
  await process_frame
 check(is_instance_valid(app.battle),"second duel opens")
 if not is_instance_valid(app.battle):app.free();quit(1);return
 battle=app.battle.model
 check(battle.q.get("tylerAlly",false) and app.battle.rai_ally!=null and app.battle.art_ids[1]=="mormaco-possuido","Tyler and Rai join Kael against possessed Mormaço")
 check(is_equal_approx(battle.q.hp,battle.q.stats.line*.7),"second duel retains 70% HP")
 var assistance:=Model.new()
 assistance.restore(battle.snapshot())
 assistance.intro=0
 assistance.q.tylerCooldown=.01
 assistance.tick(.05,{})
 check(assistance.q.hp<battle.q.hp and assistance.q.tylerCooldown==5.0,"Rai's assist deals real damage")
 for i in 10000:
  if not battle.outcome.is_empty():break
  var towards:=Vector2(battle.q.x-battle.p.x,battle.q.y-battle.p.y).normalized()
  var defending:bool=battle.q.signatureWindup>0 and battle.q.signatureWindup<.35
  battle.tick(.05,{"x":towards.x,"y":towards.y,"cut":not defending,"signature":true,"guard":defending})
 print("SCRIPTED BATTLE ",battle.outcome," player ",battle.p.hp," boss ",battle.q.hp)
 check(battle.outcome=="won","scripted controller wins full battle")
 if battle.outcome!="won":app.free();quit(1);return
 check(app.encounters.save_battle(battle.snapshot()).status=="ok","terminal result saved")
 before=app.session.snapshot();app.session._store=FailedStore.new()
 check(service.settle().status=="io_error" and app.session.snapshot()==before,"failed settlement keeps encounter")
 app.session._store=store
 check(service.settle().status=="ok" and Story.won(app.session.snapshot().player) and not Story.freed(app.session.snapshot().player),"victory breaks control, talk pending")
 check(service.settle().status=="wrong_step","settlement not duplicated")
 await world();app._request_mormaco("mormacoStory");await frames();await shot("04-libertacao")
 before=app.session.snapshot();app.session._store=FailedStore.new()
 check(service.release(Story.AT).status=="io_error" and app.session.snapshot()==before,"failed liberation stays pending")
 app.session._store=store;await approve()
 check(Story.freed(app.session.snapshot().player),"release and clue persist")
 check(app.park.mormaco.sprite.texture.resource_path.ends_with("submerged.png"),"approved free colors restored")
 check(service.begin(Story.AT).status=="already_applied" and service.release(Story.AT).status=="already_applied","no replay rewards")
 check(app.session.snapshot().player.partners.size()==before.player.partners.size() and app.session.snapshot().player.inventory==before.player.inventory and app.session.snapshot().player.coins==before.player.coins,"guardian not captured or duplicated")
 check(app.session.resume_slot("slot-1").status=="ok" and Story.freed(app.session.snapshot().player),"liberation reload")
 await shot("05-livre")
 # Independent failure paths retain eligibility and keep the same guardian.
 p=app.session.snapshot().player;p.flags.erase("mormacoLacosDesfeitos");p.flags.erase("mormacoLiberto")
 p.partners[0].condition={"line":100,"structure":100}
 check(app.session.checkpoint(CP.make(Story.C,Story.AT,CP.SPACE),p).status=="ok","failure fixture")
 for outcome in ["lost","fled"]:
  check(service.begin(Story.AT).status=="ok","begin "+outcome)
  var snapshot:Dictionary=app.session.snapshot();snapshot.player.encounter.state.outcome=outcome
  if outcome=="lost":snapshot.player.encounter.state.p.hp=0
  check(app.session.checkpoint(snapshot.checkpoint,snapshot.player).status=="ok" and service.settle().status=="ok","settle "+outcome)
  check(not Story.won(app.session.snapshot().player),"failure does not free guardian")
  at(Story.C,Story.REST);check(service.rest(Story.REST).status in ["ok","already_applied"],"rest recovery")
  at(Story.C,Story.AT)
 print("MORMACO STORY ",checks," checks; ",failures," failures; full win via scripted combat; loss/flee terminal fixtures")
 app.free();quit(0 if failures==0 else 1)
