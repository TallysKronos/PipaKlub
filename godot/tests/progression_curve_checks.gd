extends SceneTree
const Levels=preload("res://scripts/campaign/partner_levels.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const Encounters=preload("res://scripts/campaign/encounters.gd")
const Rewards=preload("res://scripts/campaign/hud_rewards.gd")
const Progression=preload("res://scripts/campaign/progression.gd")
var checks:=0
var failures:=0

func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; printerr("FAIL ",message)

func _initialize() -> void: call_deferred("run")

func write(path: String, value: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value))

func run() -> void:
	for level in range(1,50):
		var before:=Levels.xp_for_level(level)
		var after:=Levels.xp_for_level(level+1)
		check(after-before==20+15*level+5*level*level,"increasing cost at level "+str(level))
		check(Levels.level_for_xp(after-1)==level and Levels.level_for_xp(after)==level+1,"level boundary "+str(level))
		var n:=level-1
		var old_base:=40*n+10*n*n
		var old_next:=40*level+10*level*level
		for fraction in [0.0,.37,.99]:
			var old_xp:=old_base+floori((old_next-old_base)*fraction)
			var migrated:=Levels.from_legacy(old_xp)
			check(Levels.level_for_xp(migrated)==level,"legacy level preserved "+str(level))
			check(absf(float(migrated-before)/(after-before)-float(old_xp-old_base)/(old_next-old_base))<=1.0/(after-before),"legacy bar proportion preserved "+str(level))
	check(Levels.from_legacy(25970)==Levels.xp_for_level(50),"legacy maximum remains level 50")
	var capped:={"xp":Levels.xp_for_level(50)-3}
	check(Progression.credit_for(capped,500)==3,"rewards obey new maximum")
	var folder:=ProjectSettings.globalize_path("res://../tmp/progression-v2-"+State.new_id())
	DirAccess.make_dir_recursive_absolute(folder)
	var old:=State.fresh("slot-1")
	old.rulesVersion="demo-1"
	old.player.partners=[{"id":"legacy-partner","modelId":"rabbito","xp":855,"condition":{"line":67,"structure":81}}]
	old.player.inventory={"linha":3}
	old.player.flags={"ninaAccepted":true}
	old.player.completedOperations=["old-reward"]
	old.revision=4
	old=JSON.parse_string(JSON.stringify(old))
	write(folder.path_join("slot-1.json"),old)
	var store:=Store.new(folder)
	var loaded:=store.load_slot("slot-1")
	check(loaded.status=="ok" and loaded.data.rulesVersion==State.RULES_VERSION,"old disk save migrates")
	check(Levels.level_for_xp(loaded.data.player.partners[0].xp)==8,"disk migration preserves level")
	check(loaded.data.player.inventory==old.player.inventory and loaded.data.player.flags==old.player.flags and loaded.data.player.completedOperations==old.player.completedOperations and loaded.data.player.partners[0].condition==old.player.partners[0].condition,"migration preserves possessions, flags, receipts and wear")
	check(JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("slot-1.json"))).rulesVersion=="demo-1","loading alone never rewrites source save")
	check(store.save_slot(loaded.data).status=="ok","converted save commits atomically")
	var reloaded:=Store.new(folder).load_slot("slot-1")
	check(reloaded.data.player.partners[0].xp==loaded.data.player.partners[0].xp and State.migrate_progression(reloaded.data)==reloaded.data,"conversion cannot run twice")
	# Suspended old combat keeps its fighter snapshot; only partner XP is converted.
	old=State.fresh("slot-2")
	old.rulesVersion="demo-1"
	old.player.partners=[{"id":"legacy-fighter","modelId":"rabbito","xp":770}]
	var model:=Model.new({"id":"legacy-fighter","modelId":"rabbito","xp":Levels.xp_for_level(8)})
	old.player.encounter={"id":State.new_id(),"kind":"lacertubo","returnPoint":[1300,154],"state":model.snapshot()}
	old.checkpoint={"kind":"encounter"}
	write(folder.path_join("slot-2.json"),old)
	var session:=Session.new()
	session._store=Store.new(folder)
	check(session.resume_slot("slot-2").status=="ok","suspended old fight resumes")
	check(session.snapshot().player.encounter.state==JSON.parse_string(JSON.stringify(old.player.encounter.state)),"migration leaves battle snapshot untouched")
	model.restore(session.snapshot().player.encounter.state)
	model.outcome="won" # Transaction fixture, not a simulated skill victory.
	var preview:=Rewards.preview(session.snapshot().player,session.snapshot().player.encounter,model)
	var service:=Encounters.new(session)
	check(service.save_battle(model.snapshot()).status=="ok" and service.settle().status=="ok","legacy combat settles after curve migration")
	check(session.snapshot().player.lastEncounter.partnerXp==preview.xp and preview.xp==160,"legacy preview equals committed historical reward")
	check(service.settle().status=="wrong_step","settlement cannot repeat")
	session.free()
	for species in ["basica","mata","raio"]:
		for level in [1,3,6]:
			model=Model.new({"id":"new-fighter","xp":0},{"modelId":species,"level":level})
			model.outcome="won"
			var xp:=Encounters.reward_amount(false,"park-trail",species,level)
			var partner:={"id":"new-fighter","xp":0}
			var battle:={"kind":"wild","rewardXp":xp,"scene":"park-trail"}
			preview=Rewards.preview({"partners":[partner],"inventory":{}},battle,model)
			check(preview.xp==Encounters.reward_for(battle,model.snapshot()),"new reward preview uses frozen species/level payout")
			check(Progression.award({},partner,xp)==preview.xp and partner.xp==preview.after,"reward preview matches credited XP")
	print("PROGRESSION CURVE: ",checks," checks; ",failures," failures; ",folder)
	quit(1 if failures else 0)
