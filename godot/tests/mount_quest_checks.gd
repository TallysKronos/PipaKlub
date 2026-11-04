extends SceneTree
const Quest=preload("res://scripts/campaign/mount_quest.gd")
const State=preload("res://scripts/campaign/state.gd")
var failures:=0
var checks:=0
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var dir:="user://mount-quest-tests-"+State.new_id()
	var session=load("res://scripts/campaign/session.gd").new()
	session._store=load("res://scripts/campaign/save_store.gd").new(dir)
	check(session.start("slot-1").status=="ok","isolated save")
	var quest=Quest.new(session)
	check(quest.talk("zeca").status=="wrong_step","cannot start during opening")
	var player:Dictionary=session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"}
	var cp:Dictionary={"kind":"world","scene":"quintal","space":"bairro-inicial-v2","position":[22,18.5]}
	check(session.checkpoint(cp,player).status=="ok","eligible city checkpoint")
	check(quest.talk("lia").status=="wrong_step","no remote NPC grant")
	check(not Quest.owned(session.snapshot().player),"mount locked initially")
	check(quest.talk("zeca").status=="ok","accept from Zeca")
	check(Quest.stage(session.snapshot().player)==1,"active quest persists")
	check(quest.talk("zeca").status=="wrong_step","cannot skip clasp")
	cp.position=[25,-.6];session.checkpoint(cp,session.snapshot().player)
	check(quest.talk("lia").status=="ok","clasp from Lia")
	check(int(session.snapshot().player.inventory.get(Quest.CLASP,0))==1,"one clasp")
	check(quest.talk("lia").status=="wrong_step","no duplicate clasp")
	check(quest.talk("zeca").status=="wrong_step","reward requires return to Zeca")
	check(session.resume_slot("slot-1").status=="ok" and Quest.stage(session.snapshot().player)==2,"midquest reload")
	cp.position=[22,18.5];session.checkpoint(cp,session.snapshot().player)
	check(quest.talk("zeca").status=="ok","turn in and receive whistle")
	check(not session.snapshot().player.inventory.has(Quest.CLASP),"clasp consumed")
	check(int(session.snapshot().player.inventory.get(Quest.ITEM,0))==1,"persistent key item")
	check(quest.talk("zeca").status=="already_applied","reward idempotent")
	check(session.resume_slot("slot-1").status=="ok" and Quest.owned(session.snapshot().player),"mount remains unlocked after reload")
	var earned:Dictionary=session.snapshot().player
	check(earned.partners.size()==1 and earned.partners[0].modelId==Quest.MODEL,"quest grants real battle partner")
	check(Quest.eligible(earned),"healthy party mount is usable")
	var mount:Dictionary=earned.partners[0]
	mount.condition.line=0
	check(not Quest.eligible(earned),"defeated line blocks mounting")
	mount.condition.line=.5
	check(not Quest.eligible(earned),"less than one HP blocks mounting")
	mount.condition.line=1
	check(Quest.eligible(earned),"exactly one HP permits mounting at Lv1")
	mount.condition.structure=0
	check(not Quest.eligible(earned),"broken hull blocks mounting")
	mount.condition={"line":100,"structure":100}
	var combat=load("res://scripts/campaign/encounter_model.gd").new(mount)
	check(combat.model_id==Quest.MODEL and combat.p.hp==100,"mount participates in combat with real HP")
	var absent:Dictionary=earned.duplicate(true);absent.partners=[]
	check(not Quest.eligible(absent),"whistle without party mount is insufficient")
	absent=earned.duplicate(true);absent.inventory.erase(Quest.ITEM)
	check(not Quest.eligible(absent),"partner without whistle cannot mount")
	check(quest.talk("zeca").status=="already_applied" and session.snapshot().player.partners.size()==1,"partner reward cannot duplicate")
	var legacy:Dictionary=earned.duplicate(true);legacy.partners=[]
	session.checkpoint(cp,legacy)
	check(quest.talk("zeca").status=="ok" and session.snapshot().player.partners.size()==1,"legacy whistle-only reward is repaired at Zeca")
	check(session.snapshot().player.coins==0,"no economy shortcut")
	var ready:Dictionary=session.snapshot().player
	ready.equippedPartnerId=ready.partners[0].id;ready.flags.ninaAccepted=true
	var boss_point:Vector2=preload("res://scripts/campaign/park_data.gd").BOSS
	check(session.checkpoint({"kind":"world","scene":"park-veredas","position":[boss_point.x,boss_point.y]},ready).status=="ok","battle checkpoint")
	var encounters=load("res://scripts/campaign/encounters.gd").new(session)
	check(encounters.start_boss(boss_point).status=="ok","mount accepted by real encounter service")
	var battle=load("res://scripts/campaign/encounter_model.gd").new()
	battle.restore(session.snapshot().player.encounter.state);battle.p.hp=0;battle.outcome="lost"
	check(encounters.save_battle(battle.snapshot()).status=="ok","mount battle health saved")
	check(encounters.settle().status=="ok" and not Quest.eligible(session.snapshot().player),"battle defeat prevents mounting after return")
	var avatar=load("res://scripts/avatar.gd").new();root.add_child(avatar);avatar.set_mounted(true)
	check(avatar.mount_rig.animations.size()==16,"16 animated directions loaded")
	avatar.moving=true;avatar.running=false;avatar.facing="e";avatar._process(0)
	check(avatar.mount_rig.animated.visible and not avatar.mount_rig.body.visible,"walking uses corrected complete sprite")
	check(avatar.mount_rig.animation_key=="walk-e","walk direction")
	avatar.mount_rig._process(.16)
	check(avatar.mount_rig.animated.region_rect.position.x==256,"walking frames advance")
	avatar.running=true;avatar._process(0)
	check(avatar.mount_rig.animation_key=="run-e","run cycle switches")
	avatar.moving=false;avatar._process(0)
	check(not avatar.mount_rig.animated.visible and avatar.mount_rig.body.visible,"rest preserves edited original")
	avatar.free();session.free()
	print("Mount quest: ",checks," checks, ",failures," failures; isolated folder ",dir)
	quit(1 if failures else 0)
