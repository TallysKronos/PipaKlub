extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Story=preload("res://scripts/campaign/warehouse_story.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
var checks:=0
var failures:=0
var session:Node
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func visit(scene:String,point:Vector2)->void:
 var saved:Dictionary=session.snapshot()
 for p:Dictionary in saved.player.partners:p.condition={"line":100,"structure":100}
 check(session.checkpoint(CP.make(scene,point,CP.SPACE),saved.player).status=="ok","visit "+scene)
func finish(outcome:String)->void:
 var saved:Dictionary=session.snapshot();var model:=Model.new();model.restore(saved.player.encounter.state);model.outcome=outcome
 saved.player.encounter.state=model.snapshot()
 check(session.checkpoint(saved.checkpoint,saved.player).status=="ok","persist terminal "+outcome)
func _initialize()->void:call_deferred("run")
func run()->void:
 session=Session.new();session._store=Store.new("user://warehouse-"+State.new_id())
 check(session.start("slot-1").status=="ok","isolated fixture")
 var p:Dictionary=session.snapshot().player
 p.partners=[{"id":"r","modelId":"rabbito","xp":4000,"condition":{"line":100,"structure":100}}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
 var prior:=Rules.fresh("cais");prior.completed=true;prior.rewardClaimed=true;prior.champion="player";Rules.store(p,"cais",prior)
 check(not Story.available(p),"previous story is required")
 p.flags.retalhoBosqueVencido=true;p.flags.fotoExpedicaoLida=true
 check(Story.available(p),"canon prerequisites")
 check(session.checkpoint(CP.make(Story.B,Story.GOLLIA,CP.SPACE),p).status=="ok","fixture persisted")
 var story:=Story.new(session)
 var before_gollia:Dictionary=session.snapshot();before_gollia.player.partners[0].condition={"line":0,"structure":0}
 check(session.checkpoint(CP.make(Story.B,Vector2(21.5,25.5),CP.SPACE),before_gollia.player).status=="ok","injured before Gollia")
 check(story.rest(Vector2(21.5,25.5)).status=="ok" and not session.snapshot().player.flags.get("golliaCarretelVencida",false),"B bank recovers before locked warehouse")
 visit(Story.B,Story.GOLLIA)
 check(story.begin("gollia",Vector2.INF).status=="wrong_step","nonfinite point")
 check(story.begin("gollia",Story.GOLLIA+Vector2(4,0)).status=="wrong_step","remote challenge")
 var door:Dictionary=CP.data(Story.B).events.filter(func(e):return e.type=="saida" and e.props.destino==Story.D)[0]
 check(not CP.allowed(door,p),"door locked")
 for outcome:String in ["fled","lost","won"]:
  visit(Story.B,Story.GOLLIA)
  check(story.begin("gollia",Story.GOLLIA).status=="ok","Gollia begin "+outcome)
  check(session.resume_slot("slot-1").status=="ok","Gollia resume")
  finish(outcome)
  check(session.resume_slot("slot-1").status=="ok" and session.snapshot().player.encounter.state.outcome==outcome,"terminal Gollia state resumes")
  var bad:Dictionary=session.snapshot().player.encounter.duplicate(true);bad.state.enemyLevel=24
  check(not State.valid_encounter(bad),"reject opponent level alteration")
  check(story.settle().status=="ok","Gollia settle "+outcome)
  check(bool(session.snapshot().player.flags.get("golliaCarretelVencida",false))==(outcome=="won"),"win alone opens door")
  var before:Dictionary=session.snapshot();check(story.settle().status=="wrong_step" and session.snapshot()==before,"duplicate settlement")
 visit(Story.B,Vector2(26.5,11.5))
 var target:=CP.exit_target(session.snapshot().checkpoint,str(int(door.id)),session.snapshot().player)
 check(target.status=="ok" and target.scene==Story.D,"B to D")
 check(is_equal_approx(CP.model_for(Story.B).height_at(Vector2(26.5,11.5)),CP.model_for(Story.D).height_at(target.point)),"door elevation matches")
 visit(Story.D,Story.AT)
 check(story.begin("dragon",Story.AT).status=="wrong_step","cannot skip protection and untying")
 check(story.advance(1,Story.AT).status=="wrong_step","out of order beat")
 for i in 3:
  check(story.advance(i,Story.AT+Vector2(5,0)).status=="wrong_step","remote beat")
  check(story.advance(i,Story.AT).status=="ok","persist beat "+str(i))
  check(session.resume_slot("slot-1").status=="ok" and Story.step(session.snapshot().player)==i+1,"resume after beat")
  check(story.advance(i,Story.AT).status=="wrong_step","stale beat rejected")
 for outcome:String in ["fled","lost","won"]:
  visit(Story.D,Story.AT)
  check(story.begin("dragon",Story.AT).status=="ok","dragon begin "+outcome)
  check(session.resume_slot("slot-1").status=="ok","dragon suspend/resume")
  finish(outcome)
  check(session.resume_slot("slot-1").status=="ok" and session.snapshot().player.encounter.state.outcome==outcome,"terminal dragon state resumes")
  var model:=Model.new();model.restore(session.snapshot().player.encounter.state)
  var preview:Dictionary=preload("res://scripts/campaign/hud_rewards.gd").preview(session.snapshot().player,session.snapshot().player.encounter,model)
  # A won story duel pays the uniform win XP (BIBLIA §8), shown before and credited after.
  var xp_before:int=int(session.snapshot().player.partners[0].xp)
  check(not preview.items.any(func(item):return str(item).begins_with("Rabiola")),"no phantom capture")
  check((preview.xp>0)==(outcome=="won"),"XP only for a win")
  check(story.settle().status=="ok","dragon settle "+outcome)
  check(int(session.snapshot().player.partners[0].xp)-xp_before==preview.xp,"result card XP is what the settlement credits")
  check(bool(session.snapshot().player.flags.get("pipaDragaoDesatadaVencida",false))==(outcome=="won"),"win alone unlocks Bruno")
  check(Story.step(session.snapshot().player)==3,"failure preserves intervention")
 check(session.snapshot().player.inventory.get("agulha-desatar",0)==1,"one needle")
 check(story.begin("dragon",Story.AT).status=="wrong_step","no farming after victory")
 check(story.settle().status=="wrong_step" and session.snapshot().player.inventory.get("agulha-desatar",0)==1,"no duplicate needle")
 check(session.resume_slot("slot-1").status=="ok" and session.snapshot().player.flags.pipaDragaoDesatadaVencida,"persist victory")
 var injured:Dictionary=session.snapshot();injured.player.partners[0].condition={"line":0,"structure":0}
 check(session.checkpoint(CP.make(Story.D,Vector2(14.5,30.5),CP.SPACE),injured.player).status=="ok","injured checkpoint")
 check(story.rest(Story.AT).status=="wrong_step","remote healing refused")
 check(story.rest(Vector2(14.5,30.5)).status=="ok","recover without coins or kits")
 check(session.snapshot().player.partners[0].condition.line==100 and session.snapshot().player.partners[0].condition.structure==100,"full recovery")
 check(story.rest(Vector2(14.5,30.5)).status=="already_applied","healthy rest is no-op")
 check(load("res://scripts/campaign/front_end.gd")!=null,"front end parses")
 check(load("res://scripts/campaign/warehouse_tableau.gd")!=null,"tableau parses")
 check(preload("res://scripts/campaign/battle_ink.gd").facing_flip("pipa-dragao-desatada",0,1) and not preload("res://scripts/campaign/battle_ink.gd").facing_flip("pipa-dragao-desatada",1,0),"authored left sprite faces its opponent")
 print("WAREHOUSE ",checks," checks; ",failures," failures; terminal outcomes are fixtures, not combat balance")
 session.free();quit(0 if failures==0 else 1)
