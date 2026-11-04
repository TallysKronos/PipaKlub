extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Session=preload("res://scripts/campaign/session.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Exam=preload("res://scripts/campaign/league_promotion.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
const Exploration=preload("res://scripts/campaign/exploration.gd")
class FailedStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot:Dictionary)->Dictionary:return {"status":"io_error"}
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL "+text)
func eligible_player()->Dictionary:
	var p:Dictionary=State.fresh("slot-1").player
	p.partners=[{"id":"r","modelId":"rabbito","xp":0}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	for stage:Dictionary in Rules.definition("bambuzal").stages:
		var plan:=Rules.prepare(p,"bambuzal",stage.id);p=Rules.settle(p,plan.context,"won").player
	p.flags.merge({"tylerClareiraMet":true,"ninaAccepted":true,"ninaBambuzalOrder":true,"guardianDefeated":true,"ninaTail":true})
	p.inventory["quest-nina-tail"]=1
	return p
func _initialize()->void:
	var p:=eligible_player()
	check(not Exam.eligible(p) and not Exam.award_into(p),"tail must actually be returned")
	var returned:=p.duplicate(true);returned.flags.ninaReturned=true
	for flag in ["tylerClareiraMet","guardianDefeated","ninaReturned"]:
		var missing:=returned.duplicate(true);missing.flags[flag]=false
		check(not Exam.eligible(missing),"required milestone "+flag)
	var missing:=returned.duplicate(true);missing.erase("morro")
	check(not Exam.eligible(missing),"first district required")
	missing=returned.duplicate(true);missing.championship.districts.bambuzal.completed=false;missing.championship.districts.bambuzal.rewardClaimed=false
	check(not Exam.eligible(missing),"second district required")
	var session:=Session.new();session._store=Store.new("user://green-exam-"+State.new_id());check(session.start("slot-1").status=="ok","isolated slot")
	var at:=CP.target("park-trail","nina")
	check(session.checkpoint(CP.make("park-trail",at,CP.SPACE),p).status=="ok","Nina delivery fixture")
	var disk:RefCounted=session._store;session._store=FailedStore.new()
	check(Exploration.new(session).return_tail(at).status=="io_error" and session.snapshot().player.inventory.has("quest-nina-tail") and not Exam.promoted(session.snapshot().player),"failed write preserves tail and rank")
	session._store=disk
	check(Exploration.new(session).return_tail(at).status=="ok","handoff and promotion together")
	var current:Dictionary=session.snapshot()
	check(Story.category(current.player)=="Rabiola Verde" and not current.player.inventory.has("quest-nina-tail"),"rank and consumed quest item commit together")
	check(current.player.inventory["certificado-rabiola-verde"]==1 and current.player.inventory["emprestimo-carcara-nina"]==1 and current.player.flags.ninaGlideLoanAvailable,"unique certificate and loan permission")
	check(Exam.pending(current) and session.resume_slot("slot-1").status=="ok" and Exam.pending(session.snapshot()),"presentation resumes after reload")
	check(Exploration.new(session).return_tail(at).status=="already_applied" and Exam.claim(session,at).status=="already_applied","delivery and exam cannot duplicate")
	check(Exam.acknowledge(session).status=="ok" and not Exam.pending(session.snapshot()),"presentation acknowledged separately")
	current=session.snapshot();var title:Dictionary=Rules.entry(current.player,"bambuzal");title.champion="bambu-1";title.qualification=[];Rules.store(current.player,"bambuzal",title)
	check(session.checkpoint(current.checkpoint,current.player).status=="ok" and Story.category(session.snapshot().player)=="Rabiola Verde","title loss never demotes category")
	check(Exam.claim(session,at+Vector2(10,10)).status=="wrong_step","remote claim rejected")
	# An old completed Nina quest can be recognized after the new prerequisites are met.
	p=eligible_player();p.flags.ninaReturned=true;p.inventory.erase("quest-nina-tail")
	check(session.checkpoint(CP.make("park-trail",at,CP.SPACE),p).status=="ok" and Exam.claim(session,at).status=="ok","legacy return can claim without replaying mission")
	check(session.snapshot().player.inventory["certificado-rabiola-verde"]==1,"legacy certificate unique")
	session.free();print("GREEN EXAM: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
