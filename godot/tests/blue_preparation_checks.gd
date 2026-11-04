extends SceneTree
const Prep=preload("res://scripts/campaign/blue_exam_preparation.gd")
const Care=preload("res://scripts/campaign/retalho_care.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
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
func capture(name:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames();await RenderingServer.frame_post_draw
 var folder:=ProjectSettings.globalize_path("res://../documentation/qa/blue-preparation-v1")
 DirAccess.make_dir_recursive_absolute(folder)
 check(root.get_texture().get_image().save_png(folder.path_join(name+".png"))==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 app=load("res://scripts/campaign/front_end.gd").new()
 app.session._store=Store.new("user://blue-preparation-"+preload("res://scripts/campaign/state.gd").new_id())
 root.add_child(app);app.preferences.reduced_motion=true
 check(app.session.start("slot-1").status=="ok","isolated save")
 var p:Dictionary=app.session.snapshot().player
 check(not Prep.eligible(p),"league prerequisites required")
 p.partners=[{"id":"r","modelId":"rabbito","xp":4000}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
 # Historical records, including a lost title, must not undo narrative guidance.
 for id in ["morro","bambuzal","beira-canal","feira","cais","industrial"]:
  var district:=Rules.fresh(id);district.completed=true;district.rewardClaimed=true
  for stage in Rules.definition(id).stages:
   district.wonDuels.append(stage.id)
   if stage.role=="lieutenant":district.qualification.append(stage.id)
  Rules.store(p,id,district)
 for flag in ["ninaAccepted","guardianDefeated","ninaReturned","bosqueClareiraDescoberta","tylerClareiraMet","leagueGreen","ninaGlideTutorialDone","comportaVeredasAberta","feiraApitoComprado","feiraApitoFalsoTestado","feiraApitoVerdadeiro","muralPrimeiroLaco","retalhoBosqueVencido","fotoExpedicaoLida","golliaCarretelVencida","pipaDragaoDesatadaVencida","retalhoAtelieAproximacao","retalhoAtelieCuidado","assisReconheceuNoRetalho","exameAzulPreparacao"]:p.flags[flag]=true
 check(Prep.eligible(p),"orientation eligible")
 var independent:Dictionary=p.duplicate(true)
 for flag in ["retalhoBosqueVencido","pipaDragaoDesatadaVencida","retalhoAtelieAproximacao","retalhoAtelieCuidado","assisReconheceuNoRetalho","exameAzulPreparacao"]:independent.flags.erase(flag)
 check(Prep.eligible(independent),"league orientation independent of Retalho arc")
 independent.flags.exameAzulOrientado=true
 check(not Prep.prepared(independent),"legacy orientation must receive corrected briefing")
 independent.flags.erase("leagueGreen")
 check(not Prep.eligible(independent),"previous category still required")
 for beat in ["galpao-gollia","galpao-retalho","bruno-emblema","retalho-atelie"]:check(Story.beat_done(p,beat),"journal reads "+beat)
 check(Story.current_beat(p).id=="azul-preparacao","journal guides to orientation")
 var cp:={"kind":"world","scene":Care.SPACE,"position":[Care.APPROACH.x,Care.APPROACH.y]}
 check(app.session.checkpoint(cp,p).status=="ok","fixture persisted")
 check(Prep.confirm(app.session,Vector2.ZERO).status=="wrong_step","remote refused")
 var wrong_scene:Dictionary=cp.duplicate(true);wrong_scene.scene="quintal"
 check(app.session.checkpoint(wrong_scene,p).status=="ok" and Prep.confirm(app.session,Care.APPROACH).status=="wrong_step","wrong scene refused")
 check(app.session.checkpoint(cp,p).status=="ok","return to atelier")
 var baseline:Dictionary=app.session.snapshot();var working=app.session._store
 app.session._store=FailedStore.new()
 check(Prep.confirm(app.session,Care.APPROACH).status=="io_error","write failure")
 check(app.session.snapshot()==baseline,"failure preserves progress")
 app.session._store=working
 app._show_world();await frames();app._world_interact("professor");await frames()
 var dialog:Control=app.get_node_or_null("BlueExamPreparationDialogue")
 check(is_instance_valid(dialog) and app.flow_busy and not app.room.can_walk,"orientation captures input")
 if not is_instance_valid(dialog):app.free();quit(1);return
 dialog.canceled.emit();await frames()
 check(not Prep.prepared(app.session.snapshot().player) and app.room.can_walk and not app.flow_busy,"cancel restores exploration")
 app._world_interact("professor");await frames();dialog=app.get_node("BlueExamPreparationDialogue")
 while dialog.page_index<dialog.pages.size()-2:dialog.next_page()
 await capture("01-orientacao")
 while dialog.page_index<dialog.pages.size()-1:dialog.next_page()
 dialog.get_ok_button().pressed.emit();await frames()
 check(Prep.prepared(app.session.snapshot().player) and app.room.can_walk and not app.flow_busy,"confirmation restores exploration")
 check(app.session.resume_slot("slot-1").status=="ok" and Prep.prepared(app.session.snapshot().player),"reload persists preparation")
 var after:Dictionary=app.session.snapshot()
 check(not after.player.flags.get("leagueBlue",false) and Story.category(after.player)=="Rabiola Verde","no blue promotion")
 check(Story.current_beat(after.player).id=="exame-azul" and Story.act(after.player)==3,"journal continues personal arc after orientation")
 check("Pátio" in Prep.data().prepared,"unfinished league exam explicit")
 var original:Dictionary=JSON.parse_string(JSON.stringify(baseline.player))
 var current:Dictionary=JSON.parse_string(JSON.stringify(after.player))
 check(current.partners==original.partners and current.inventory==original.inventory and current.coins==original.coins,"no creature, coin or item reward")
 check(Prep.confirm(app.session,Care.APPROACH).status=="already_applied" and app.session.snapshot()==after,"replay read only")
 app._show_world();await frames();await capture("02-preparacao-registrada")
 independent.flags.leagueGreen=true
 check(app.session.start("slot-2").status=="ok" and app.session.commit_operation("blue-exam.orientation-v1",cp,independent).status=="ok","legacy candidate without Retalho saved separately")
 check(Prep.confirm(app.session,Care.APPROACH).status=="ok","candidate without Retalho receives orientation")
 check(not app.session.snapshot().player.flags.get("assisReconheceuNoRetalho",false) and app.session.snapshot().player.flags.get("exameAzulOrientado",false) and Prep.prepared(app.session.snapshot().player),"legacy progress preserved without inventing care")
 print("BLUE PREPARATION ",checks," checks; ",failures," failures")
 app.free();quit(0 if failures==0 else 1)
