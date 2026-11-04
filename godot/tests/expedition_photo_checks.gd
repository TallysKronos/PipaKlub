extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Photo=preload("res://scripts/campaign/expedition_photo.gd")
const Dialogue=preload("res://scripts/campaign/hud_dialogue.gd")
var checks:=0
var failures:=0
var app:Control
class FailedStore extends "res://scripts/campaign/save_store.gd":
 func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,text:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",text)
func frames()->void:
 for i in 8:await process_frame
func dialog()->Control:return app.get_node_or_null("ExpeditionPhotoDialogue")
func capture(name:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames();await RenderingServer.frame_post_draw
 var folder:=ProjectSettings.globalize_path("res://../documentation/qa/foto-expedicao-v2")
 DirAccess.make_dir_recursive_absolute(folder)
 check(root.get_texture().get_image().save_png(folder.path_join(name+".png"))==OK,"capture "+name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1280,720)
 app=load("res://tests/fixtures/park_frontend_fixture.gd").new();app.session._store=Store.new("user://photo-flow-"+State.new_id());root.add_child(app)
 check(app.session.start("slot-1").status=="ok","isolated slot")
 var p:Dictionary=app.session.snapshot().player
 p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
 var at:=Vector2(912,560);var cp:={"kind":"world","scene":"professor-home","position":[at.x,at.y]}
 check(app.session.checkpoint(cp,p).status=="ok","archive fixture")
 var service:=Photo.new(app.session)
 check(service.read(at).status=="wrong_step","locked before Retalho")
 p.flags.retalhoBosqueVencido=true;check(app.session.checkpoint(cp,p).status=="ok","after Retalho")
 check(service.read(Vector2.INF).status=="wrong_step","invalid point")
 check(service.read(Vector2(1056,1296)).status=="wrong_step","remote reading rejected")
 app._show_world();await frames()
 check(is_instance_valid(app.room) and app.room._safe(at),"archive approach is walkable")
 app._world_interact("study");await frames()
 check(is_instance_valid(dialog()) and is_instance_valid(app.get_node_or_null("ExpeditionPhotograph")),"photo and dialogue visible")
 check(not app.room.can_walk and app.flow_busy,"exploration suspended")
 check(app.get_node("ExpeditionPhotograph").z_index==70 and dialog().z_index>70,"photograph overlays room but stays below dialogue")
 await capture("01-foto")
 dialog().canceled.emit();await frames()
 check(not app.session.snapshot().player.flags.get(Photo.FLAG,false),"closing does not complete story")
 check(app.room.can_walk and not app.flow_busy and not is_instance_valid(app.get_node_or_null("ExpeditionPhotograph")),"cancel restores room")
 app._world_interact("study");await frames()
 while dialog().page_index<dialog().pages.size()-1:dialog().next_page()
 await capture("02-pista")
 var before:Dictionary=app.session.snapshot()
 dialog().get_ok_button().pressed.emit();await frames()
 check(app.session.snapshot().player.flags.get(Photo.FLAG,false),"reading committed")
 check(app.session.snapshot().player.inventory==before.player.inventory and app.session.snapshot().player.partners==before.player.partners,"no loot or partner grants")
 check(app.session.resume_slot("slot-1").status=="ok" and app.session.snapshot().player.flags.get(Photo.FLAG,false),"memory survives reload")
 var copy:Dictionary=app.session.snapshot();check(service.read(at).status=="already_applied" and app.session.snapshot()==copy,"repeat read is idempotent")
 var bad:Node=Session.new();bad._store=FailedStore.new("user://photo-fail");bad._snapshot=app.session.snapshot();bad._snapshot.player.flags.erase(Photo.FLAG);bad._snapshot.player.completedOperations.erase("foto-expedicao-v1")
 copy=bad.snapshot();check(Photo.new(bad).read(at).status=="io_error" and bad.snapshot()==copy,"write failure keeps memory pending")
 bad.free();app.free();await process_frame;print("EXPEDITION PHOTO: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
