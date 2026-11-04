extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Service=preload("res://scripts/campaign/retalho_story.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
var checks:=0
var failures:=0
class FailedStore extends "res://scripts/campaign/save_store.gd":
 func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
func check(ok:bool,text:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",text)
func _initialize()->void:
 var session:Node=Session.new();session._store=Store.new("user://retalho-"+State.new_id());check(session.start("slot-1").status=="ok","isolated save")
 var p:Dictionary=session.snapshot().player
 p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5};p.coins=100
 var service:=Service.new(session)
 var pacing=preload("res://scripts/campaign/park_pacing.gd")
 var map=CP.model_for("kronasta-bosque-d")
 check(pacing.weight(map,Vector2(24.5,28.5))==0,"mandatory path has no random encounters")
 check(pacing.weight(map,Vector2(7.5,24.5))>0,"optional grass has encounters")
 for roll in 6:check(pacing.wild_level("kronasta-bosque-d",roll) in [20,21,22],"D level range")
 var gate:Dictionary=CP.data("kronasta-bosque-c").events.filter(func(e):return e.props.get("destino","")=="kronasta-bosque-d")[0]
 check(not CP.allowed(gate,p),"gate locked before Cais")
 check(session.checkpoint(CP.make("kronasta-bosque-d",Service.AT,CP.SPACE),p).status=="ok","new scene validates")
 check(service.begin(Service.AT).status=="wrong_step","cannot fight before Cais")
 var prior:=Rules.fresh("cais");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(p,"cais",prior)
 check(CP.allowed(gate,p),"gate opens after Cais")
 check(session.checkpoint(CP.make("kronasta-bosque-d",Service.AT,CP.SPACE),p).status=="ok","fixture")
 check(service.begin(Vector2.INF).status=="wrong_step","invalid location")
 check(service.begin(CP.spawn("kronasta-bosque-d")).status=="wrong_step","remote start rejected")
 for outcome:String in ["fled","lost","won"]:
  var saved:Dictionary=session.snapshot();saved.player.partners[0].condition={"line":100,"structure":100}
  session.checkpoint(CP.make("kronasta-bosque-d",Service.AT,CP.SPACE),saved.player)
  check(service.begin(Service.AT).status=="ok","begin "+outcome)
  check(session.resume_slot("slot-1").status=="ok","suspended battle persists")
  saved=session.snapshot();var invalid:Dictionary=saved.duplicate(true);invalid.player.encounter.state.enemyLevel=50
  check(State.inspect(invalid,"slot-1")=="invalid","tampered boss level rejected")
  var model:=Model.new();model.restore(saved.player.encounter.state);model.outcome=outcome;saved.player.encounter.state=model.snapshot()
  check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","terminal result")
  check(service.settle().status=="ok","settle "+outcome)
  check(session.snapshot().player.flags.get("retalhoBosqueVencido",false)==(outcome=="won"),"only win reveals clue")
  var copy:Dictionary=session.snapshot();check(service.settle().status=="wrong_step" and session.snapshot()==copy,"no duplicate settlement")
  check(copy.player.coins==100 and copy.player.partners.size()==1 and copy.player.partners[0].xp==4000,"story grants no invented loot capture or XP")
 check(session.resume_slot("slot-1").status=="ok","win persists")
 session.checkpoint(CP.make("kronasta-bosque-d",Service.AT,CP.SPACE),session.snapshot().player)
 check(service.begin(Service.AT).status=="already_applied","no replay farming")
 var bad:Node=Session.new();bad._store=FailedStore.new("user://retalho-fail");bad._snapshot=session.snapshot();bad._snapshot.player.flags.erase("retalhoBosqueVencido")
 var copy:Dictionary=bad.snapshot();check(Service.new(bad).begin(Service.AT).status=="io_error" and bad.snapshot()==copy,"write failure does not enter or progress")
 bad.free();session.free();print("RETALHO CAMPAIGN: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
