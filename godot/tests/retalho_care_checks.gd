extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Care=preload("res://scripts/campaign/retalho_care.gd")
const Dialogue=preload("res://scripts/campaign/hud_dialogue.gd")
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
func dialog()->Control:return app.get_node_or_null("RetalhoCareDialogue")
func capture(name:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames();await RenderingServer.frame_post_draw
 var folder:=ProjectSettings.globalize_path("res://../documentation/qa/retalho-atelie-v1")
 DirAccess.make_dir_recursive_absolute(folder)
 check(root.get_texture().get_image().save_png(folder.path_join(name+".png"))==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 app=load("res://scripts/campaign/front_end.gd").new();app.session._store=Store.new("user://retalho-care-"+State.new_id());root.add_child(app);app.preferences.reduced_motion=true
 check(app.session.start("slot-1").status=="ok","isolated session")
 var p:Dictionary=app.session.snapshot().player
 p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":73,"structure":61}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5};p.inventory={"papel-seda":2};p.coins=17
 check(not Care.available(p),"locked before warehouse")
 p.flags.pipaDragaoDesatadaVencida=true
 check(not Care.available(p),"warehouse alone cannot skip Bruno")
 var district:=Rules.fresh("industrial");district.completed=true;district.rewardClaimed=true;district.champion="vasken";Rules.store(p,"industrial",district)
 check(Care.available(p),"historical victory sufficient even after losing title")
 var data:Dictionary=app.content.rooms.professor
 check(Care.room_data(data,p).hotspots.size()==data.hotspots.size()+1 and not data.hotspots.any(func(h):return h.id=="retalho-care"),"room data not mutated")
 check(Care.room_data(Care.room_data(data,p),p).hotspots.size()==data.hotspots.size()+1,"no duplicate hotspot")
 check(Care.walkable(Care.APPROACH),"approach walkable")
 check(not Care.walkable(Vector2.INF) and not Care.walkable(Vector2.ZERO),"unsafe points refused")
 var cp:={"kind":"world","scene":"professor-home","position":[Care.APPROACH.x,Care.APPROACH.y]}
 var fixture:Dictionary=app.session.checkpoint(cp,p)
 check(fixture.status=="ok","story fixture")
 if fixture.status!="ok":app.free();quit(1);return
 var service:=Care.new(app.session)
 check(service.advance(Care.nodes()[0].id,Vector2.INF).status=="wrong_step","nonfinite interaction")
 check(service.advance(Care.nodes()[0].id,Vector2(1056,1232)).status=="wrong_step","remote interaction")
 check(service.advance(Care.nodes()[1].id,Care.APPROACH).status=="wrong_step","cannot skip approach")
 var before:Dictionary=app.session.snapshot();var working=app.session._store
 app.session._store=FailedStore.new()
 check(service.advance(Care.nodes()[0].id,Care.APPROACH).status=="io_error","write failure reported")
 check(app.session.snapshot()==before,"failed write grants no progress")
 app.session._store=working
 app._show_world();await frames()
 check(app.room.get_node_or_null("RetalhoAtelie")!=null,"Retalho present in atelier")
 check(app.room._safe(Care.APPROACH) and app.room.data.hotspots.any(func(h):return h.id=="retalho-care"),"approach and hotspot in real room")
 await capture("01-retalho-no-atelie")
 app._world_interact("retalho-care");await frames()
 check(is_instance_valid(dialog()) and not app.room.can_walk and app.flow_busy and app.room.story_paused,"scene captures input")
 dialog().canceled.emit();await frames()
 check(Care.step(app.session.snapshot().player)==0 and app.room.can_walk and not app.flow_busy and not app.room.story_paused,"cancel restores exploration without progress")
 for i in 3:
  app._world_interact("retalho-care");await frames()
  check(is_instance_valid(dialog()),"dialogue opens at step "+str(i))
  if not is_instance_valid(dialog()):app.free();quit(1);return
  while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
  await capture("02-etapa-"+str(i))
  if i==2:
   root.size=Vector2i(1920,1080);await frames();await capture("03-reconhecimento-1080p")
   root.size=Vector2i(1280,720);await frames()
  dialog().get_ok_button().pressed.emit();await frames()
  check(Care.step(app.session.snapshot().player)==i+1,"beat persisted "+str(i))
  check(service.advance(Care.nodes()[i].id,Care.APPROACH).status==("already_applied" if i==2 else "wrong_step"),"stale confirmation safe")
  if is_instance_valid(dialog()):dialog().canceled.emit();await frames()
  else:
   for child:Node in app.get_children():
    if child.get_script()==Dialogue:child.confirmed.emit()
   await frames()
  check(app.session.resume_slot("slot-1").status=="ok" and Care.step(app.session.snapshot().player)==i+1,"resume at next unread beat")
  app._show_world();await frames()
 var after:Dictionary=app.session.snapshot()
 check(after.player.flags.get("assisReconheceuNoRetalho",false) and after.player.flags.get("exameAzulPreparacao",false),"recognition and preparation stored")
 check(not after.player.flags.get("leagueBlue",false),"no automatic blue promotion")
 var original:Dictionary=JSON.parse_string(JSON.stringify(before.player))
 var current:Dictionary=JSON.parse_string(JSON.stringify(after.player))
 check(current.inventory==original.inventory and current.partners==original.partners and current.coins==original.coins,"no capture, XP, healing, loot or material charge")
 check(after.player.completedOperations.filter(func(id):return id.begins_with("retalho-care.")).size()==3,"three unique narrative receipts")
 check(service.advance(Care.nodes()[2].id,Care.APPROACH).status=="already_applied" and app.session.snapshot()==after,"completion replay is read-only")
 await capture("04-descanso")
 print("RETALHO CARE ",checks," checks; ",failures," failures")
 app.free();quit(0 if failures==0 else 1)
