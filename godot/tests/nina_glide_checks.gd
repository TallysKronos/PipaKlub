extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Session=preload("res://scripts/campaign/session.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Glide=preload("res://scripts/campaign/nina_glide.gd")
class FailedStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL "+text)
func _initialize()->void:
	var session:=Session.new();session._store=Store.new("user://glide-"+State.new_id());check(session.start("slot-1").status=="ok","isolated slot")
	var p:Dictionary=session.snapshot().player;p.partners=[{"id":"r","modelId":"rabbito","xp":0}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	var service:=Glide.new(session);var entry:Dictionary=Glide.data().links[0];var a:=Glide.point(entry.from);var b:=Glide.point(entry.to)
	var model=CP.model_for("park-veredas")
	for e:Dictionary in Glide.data().links:
		model=CP.model_for(Glide.scene_for(e))
		check(Glide.valid_link(e),"audited link "+e.id)
		check(not model.path_to(CP.spawn(Glide.scene_for(e)),Glide.point(e.from)).is_empty(),"both banks reachable by ordinary route "+e.id)
		check(not model.clear_segment(Glide.point(e.from),Glide.point(e.to)),"water is not walkable")
	check(session.checkpoint(CP.make("park-veredas",a,CP.SPACE),p).status=="ok","takeoff fixture")
	check(service.begin(entry.id,a).status=="wrong_step","loan permission required")
	p.flags.leagueGreen=true;p.flags.ninaGlideLoanAvailable=true
	check(session.checkpoint(CP.make("park-veredas",a,CP.SPACE),p).status=="ok","permission")
	check(service.begin(entry.id,Vector2.INF).status=="wrong_step" and service.begin(entry.id,a+Vector2(6,0)).status=="wrong_step","remote/invalid takeoff rejected")
	# Wherever the interact prompt reaches (up to 1.8 cells, clear line), Planar starts.
	var reach:Vector2=Vector2.INF
	for offset in [Vector2(1.5,0),Vector2(-1.5,0),Vector2(0,1.5),Vector2(0,-1.5),Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
		var spot:Vector2=a+offset
		if model.point_walkable(spot) and model.clear_segment(spot,a):reach=spot;break
	check(reach.is_finite(),"walkable spot within the prompt reach")
	if reach.is_finite():
		check(service.begin(entry.id,reach).status=="ok" and session.snapshot().player.has("ninaGlideFlight"),"Planar starts from the prompt reach, not only on the arrow")
		var undo:Dictionary=session.snapshot().player
		undo.erase("ninaGlideFlight")
		check(session.checkpoint(CP.make("park-veredas",a,CP.SPACE),undo).status=="ok","back to the arrow")
	var disk:RefCounted=session._store;session._store=FailedStore.new()
	check(service.begin(entry.id,a).status=="io_error" and not session.snapshot().player.has("ninaGlideFlight"),"failed takeoff save never starts")
	session._store=disk
	check(service.begin(entry.id,a).status=="ok","persist takeoff before animation")
	var flight:Dictionary=session.snapshot().player.ninaGlideFlight
	check(service.begin(entry.id,a).status=="wrong_step","one flight at a time")
	check(session.resume_slot("slot-1").status=="ok" and service.recover().status=="ok","interrupted flight recovers")
	check(session.snapshot().checkpoint.position==[a.x,a.y] and not session.snapshot().player.flags.get("ninaGlideTutorialDone",false),"recovery uses ground and grants nothing")
	check(service.finish(flight.id).status=="wrong_step","abandoned token cannot land")
	check(service.begin(entry.id,a).status=="ok","retry takeoff")
	flight=session.snapshot().player.ninaGlideFlight
	session._store=FailedStore.new()
	check(service.finish(flight.id).status=="io_error" and session.snapshot().player.has("ninaGlideFlight"),"failed landing keeps pending safe checkpoint")
	session._store=disk
	var before:Dictionary=session.snapshot().player
	check(service.finish(flight.id).status=="ok","retry landing saves")
	check(session.snapshot().checkpoint.position==[b.x,b.y] and session.snapshot().player.flags.ninaGlideTutorialDone,"landing commits stable arrival and tutorial")
	check(session.snapshot().player.partners==before.partners and session.snapshot().player.inventory==before.inventory and session.snapshot().player.coins==before.coins,"loan never grants party member, item or repeatable reward")
	check(service.finish(flight.id).status=="wrong_step","landing receipt cannot repeat")
	var reverse:Dictionary=Glide.data().links[1]
	check(service.begin(reverse.id,b).status=="ok","return direction")
	check(service.finish(session.snapshot().player.ninaGlideFlight.id).status=="ok" and session.snapshot().checkpoint.position==[a.x,a.y],"return lands at original bank")
	check(session.resume_slot("slot-1").status=="ok" and not session.snapshot().player.has("ninaGlideFlight"),"completed trip reloads")
	session.free();print("NINA GLIDE: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
