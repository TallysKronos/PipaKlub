extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
const Travel=preload("res://scripts/campaign/bosque_campaign.gd")
const Explore=preload("res://scripts/campaign/exploration.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures.append(text);printerr("FAIL "+text)
func _initialize()->void:
	var session:=Session.new();session._store=Store.new("user://nina-order-"+State.new_id())
	check(session.start("slot-1").status=="ok","new local slot")
	var p:Dictionary=session.snapshot().player;p.partners=[{"id":"r","modelId":"rabbito","xp":0}];p.equippedPartnerId="r";p.journey={"phase":"complete","lesson":5}
	var at:=CP.target("park-trail","nina")
	check(session.checkpoint(CP.make("park-trail",at,CP.SPACE),p).status=="ok","at Nina before Mikka")
	check(Story.current_beat(p).id=="mikka" and Explore.new(session).accept_nina(at).status=="wrong_step","Mikka precedes new Nina quest")
	p.morro=preload("res://scripts/campaign/morro_rules.gd").defaults();p.morro.stars["morro-5"]=3
	check(session.checkpoint(CP.make("park-trail",at,CP.SPACE),p).status=="ok","Mikka victory fixture")
	check(Explore.new(session).accept_nina(at).status=="ok","Nina request after Mikka")
	p=session.snapshot().player
	check(p.flags.ninaAccepted and p.flags.ninaBambuzalOrder,"quest records new chronology")
	check(session.resume_slot("slot-1").status=="ok" and session.snapshot().player.flags.ninaBambuzalOrder,"chronology survives reload")
	check(Story.current_beat(p).id=="bosque","Bosque follows the request")
	p.flags.bosqueClareiraDescoberta=true
	check(Story.current_beat(p).id=="lohan","then Lohan")
	check(Travel.new(session).travel("park-clearing").status=="wrong_step","fast travel cannot bypass champion")
	for event:Dictionary in CP.data("park-trail").events:
		if event.type!="saida" or event.props.get("destino","")!="park-clearing":continue
		var cp:Dictionary=CP.make("park-trail",Vector2(event.u+.5,event.v+.5),CP.SPACE)
		check(CP.exit_target(cp,str(int(event.id)),p).status=="story_gate","walking exit cannot bypass Lohan")
	var old:Dictionary=p.duplicate(true);old.flags.erase("ninaBambuzalOrder")
	check(Story.park_access(old,"park-clearing") and Story.park_access(old,"park-veredas"),"existing accepted quest retains all old access")
	for stage:Dictionary in Rules.definition("bambuzal").stages:
		var planned:=Rules.prepare(p,"bambuzal",stage.id);p=Rules.settle(p,planned.context,"won").player
	check(Story.park_access(p,"park-clearing") and Story.park_access(p,"park-veredas"),"Lohan opens real park connections")
	check(Story.current_beat(p).id=="tyler","Tyler introduction follows Lohan")
	p.flags.tylerClareiraMet=true
	check(Story.current_beat(p).id=="lacertubo","recovery follows Tyler")
	p.flags.guardianDefeated=true
	check(Story.current_beat(p).id=="nina-devolvida","then the handoff")
	p.flags.ninaReturned=true
	check(Story.current_beat(p).id=="promocao-verde","recognize first category exam after handoff")
	preload("res://scripts/campaign/league_promotion.gd").award_into(p)
	check(Story.current_beat(p).id=="planar-nina","promotion introduces borrowed glide tutorial")
	p.flags.ninaGlideTutorialDone=true
	check(Story.current_beat(p).id=="canal-pipeiros","after Planar the third district follows")
	session.free();print("NINA ORDER: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
