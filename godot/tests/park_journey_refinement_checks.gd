extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Training=preload("res://scripts/campaign/park_training.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Encounter=preload("res://scripts/campaign/encounter_model.gd")
const Encounters=preload("res://scripts/campaign/encounters.gd")
const Exploration=preload("res://scripts/campaign/exploration.gd")
const Pacing=preload("res://scripts/campaign/park_pacing.gd")
class MemorySession extends Node:
	var data: Dictionary=State.fresh("slot-1")
	func snapshot() -> Dictionary: return data.duplicate(true)
	func checkpoint(cp: Dictionary,player: Dictionary) -> Dictionary:
		var next:=data.duplicate(true);next.checkpoint=cp.duplicate(true);next.player=player.duplicate(true)
		var status: String=State.inspect(next,"slot-1")
		if status=="ok": data=next
		else: printerr("INVALID TEST STATE ",status," checkpoint ",cp)
		return {"status":status}
	func commit_operation(id: String,cp: Dictionary,player: Dictionary) -> Dictionary:
		if id in data.player.completedOperations: return {"status":"already_applied"}
		player.completedOperations.append(id)
		return checkpoint(cp,player)
var checks:=0
var failures:=0
var stages: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL ",label)
func _initialize() -> void: call_deferred("run")
func rest_point(scene: String) -> Vector2:
	var model=Checkpoint.model_for(scene)
	for event in model.data.events:
		if event.props.get("acao","")!="wildRest": continue
		var center:=Vector2(event.u+.5,event.v+.5)
		for offset in [Vector2.ZERO,Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
			var at: Vector2=center+offset
			if model.walkable(Vector2i(at.floor())) and absf(model.height_at(at)-model.height_at(center))<.25: return at
	return Vector2.INF
func fight(model) -> void:
	for tick in 9500:
		if not model.outcome.is_empty(): return
		var p: Dictionary=model.p;var q: Dictionary=model.q
		var crossing:=Vector2(q.anchor,585).lerp(Vector2(q.x,q.y),.6)
		var aim:=Vector2(clampf(p.anchor+(crossing.x-p.anchor)/.7,55,945),clampf(585+(crossing.y-585)/.7,70,480))
		var direction: Vector2=(aim-Vector2(p.x,p.y)).limit_length()
		model.tick(1.0/60.0,{"x":direction.x,"y":direction.y,"cut":model.contact(p,q).get("valid",false) and q.charge<=0,"guard":q.signatureWindup>0 and q.signatureWindup<.3 and p.guardCooldown<=0,"line":p.lineCooldown<=0 and p.energy>60,"signature":p.energy>=100})
func run() -> void:
	seed(20261029)
	var session:=MemorySession.new()
	var partner: Dictionary={"id":"journey-partner","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}
	session.data.player.partners=[partner]
	session.data.player.equippedPartnerId=partner.id
	session.data.player.journey={"lesson":5,"phase":"complete"}
	var encounters:=Encounters.new(session)
	var exploration:=Exploration.new(session)
	var nina_start:=Checkpoint.target("park-trail","nina")
	session.data.checkpoint=Checkpoint.make("park-trail",nina_start,Checkpoint.SPACE)
	check(exploration.accept_nina(nina_start).status=="ok","quest starts by speaking to Nina in the actual Jardim")
	var wild_count:=0
	var wild_per_stop:=0 if "--no-random" in OS.get_cmdline_user_args() else 2
	var authored_xp:=0
	for raw in Training.DUELS: authored_xp+=Training.duel(raw.id).xp
	check(authored_xp==174 and Encounter.level_for_xp(authored_xp)==3,"trainer XP matches species/level and does not bypass progression")
	for raw in Training.DUELS:
		var entry:=Training.duel(raw.id)
		var map=Checkpoint.model_for(entry.scene)
		var at:=Training.point(entry.id,map)
		var preparation_bench:=rest_point(entry.scene)
		session.data.checkpoint=Checkpoint.make(entry.scene,preparation_bench,Checkpoint.SPACE)
		check(exploration.rest(preparation_bench).status=="ok","rest before the next authored challenge")
		check(at.is_finite() and map.walkable(Vector2i(at.floor())),entry.name+" stands on walkable terrain")
		check(not map.path_to(Checkpoint.spawn(entry.scene),at).is_empty(),entry.name+" is reachable from the area entrance")
		session.data.checkpoint=Checkpoint.make(entry.scene,at,Checkpoint.SPACE)
		check(Pacing.weight(map,at)==0,entry.name+" has a safe conversation area")
		check(encounters.start_training(entry.id,at+Vector2(12,12)).status=="wrong_step","cannot start remote duel")
		var started:Dictionary=encounters.start_training(entry.id,at)
		check(started.status=="ok",entry.name+" duel starts")
		if started.status!="ok":
			session.free();quit(1);return
		var battle: Dictionary=session.snapshot().player.encounter
		var model:=Encounter.new();model.restore(battle.state)
		check(model.q.trainingRank==Training.DUELS.find(raw)+1,"trainer combat rank survives reward derivation")
		check(battle.rewardXp==Encounters.reward_amount(false,entry.scene,entry.species,entry.level),"trainer creature XP equals wild opponent of same species/level")
		var old_battle:Dictionary=battle.duplicate(true)
		old_battle.rewardXp=Training.LEGACY_XP[entry.id]
		check(State.valid_encounter(old_battle),"suspended legacy trainer remains loadable")
		check(Encounters.reward_for(old_battle,old_battle.state)==entry.xp,"legacy trainer does not retain inflated creature payout")
		fight(model)
		if model.outcome!="won":
			check(model.outcome=="lost" and model.p.level<entry.level,"underprepared route can lose and needs more exploration")
			var defeated_before:Dictionary=session.data.player.duplicate(true)
			check(encounters.save_battle(model.snapshot()).status=="ok" and encounters.settle().status=="ok","underlevel defeat returns to exploration")
			check(Training.active(session.data.player).xp==Training.active(defeated_before).xp and session.data.player.coins==defeated_before.coins and session.data.player.tamerXp==defeated_before.tamerXp,"defeat awards no creature XP, money or tamer XP")
			check(not Training.completed(session.data.player,entry.id),"defeat does not consume first-clear reward")
			print("PARK JOURNEY: ",checks," checks; ",failures," failures; preparation required before ",entry.name,"; stages=",JSON.stringify(stages),"; wildWins=",wild_count)
			session.free();quit(1 if failures else 0);return
		check(encounters.save_battle(model.snapshot()).status=="ok","suspended duel remains valid")
		var before: int=Training.active(session.data.player).xp
		var coins_before:int=session.data.player.coins
		var tamer_before:int=session.data.player.get("tamerXp",0)
		var preview:Dictionary=load("res://scripts/campaign/hud_rewards.gd").preview(session.data.player,battle,model)
		check(encounters.settle().status=="ok","duel settles atomically")
		check(Training.active(session.data.player).xp==before+entry.xp,"first clear grants declared XP")
		check(session.data.player.coins==coins_before+entry.coins and preview.coins==entry.coins,"trainer pays money shown in preview")
		check(session.data.player.tamerXp==tamer_before+int(floor(entry.xp/5.0))+entry.tamerXp and preview.tamer.after==session.data.player.tamerXp,"trainer tamer bonus matches committed preview")
		for outcome in ["lost","fled"]:
			var failed_state:Dictionary=model.snapshot();failed_state.outcome=outcome
			check(Encounters.owner_bonus(battle,failed_state)=={"coins":0,"tamerXp":0},"no trainer bonus for "+outcome)
		check(Training.completed(session.data.player,entry.id),"duel receipt is persisted")
		check(session.data.player.inventory.is_empty(),"friendly duels do not drop wild rabiolas")
		var state_before: String=JSON.stringify(session.data)
		check(encounters.start_training(entry.id,at).status=="already_applied" and JSON.stringify(session.data)==state_before,"first-clear reward cannot be repeated")
		# Two ordinary encounters per stop, normal species/level XP and actual combat.
		for i in wild_per_stop:
			var level:=Pacing.wild_level(entry.scene,wild_count)
			var species: String=["basica","mata","raio"][wild_count%3]
			var wild:=Encounter.new(Training.active(session.data.player),{"modelId":species,"level":level})
			# Recover at the nearby bench before continuing the route.
			var bench:=rest_point(entry.scene)
			check(bench.is_finite() and exploration.rest(bench).status=="ok","regional bench restores the team")
			wild=Encounter.new(Training.active(session.data.player),{"modelId":species,"level":level})
			fight(wild)
			check(wild.outcome=="won","normal encounter can be won at earned level")
			if wild.outcome!="won": break
			var amount:=Encounters.reward_amount(false,entry.scene,species,level)
			preload("res://scripts/campaign/progression.gd").award(session.data.player,Training.active(session.data.player),amount)
			wild_count+=1
		stages.append({"trainer":entry.id,"xp":Training.active(session.data.player).xp,"level":Training.level(session.data.player)})
	check(Training.level(session.data.player)<8,"six duels do not grant the recommended boss level")
	var boss_at:=Checkpoint.target("park-veredas","boss")
	session.data.checkpoint=Checkpoint.make("park-veredas",boss_at,Checkpoint.SPACE)
	check(exploration.rest(rest_point("park-veredas")).status=="ok","prepare at final bench")
	check(encounters.start_boss(boss_at).status=="ok","earned route reaches actual boss service")
	var boss:=Encounter.new();boss.restore(session.data.player.encounter.state);fight(boss)
	check(boss.outcome=="won","perfect-command controller can still win below recommendation")
	check(encounters.save_battle(boss.snapshot()).status=="ok" and encounters.settle().status=="ok","boss victory persists")
	var tail_at:=Checkpoint.target("park-veredas","tail")
	check(exploration.collect_tail(tail_at).status=="ok","tail is collected separately")
	var nina_at:=Checkpoint.target("park-trail","nina")
	session.data.checkpoint=Checkpoint.make("park-trail",nina_at,Checkpoint.SPACE)
	check(exploration.return_tail(nina_at).status=="ok" and session.data.player.flags.ninaReturned,"return to Nina completes the quest")
	check(exploration.rest(nina_at+Vector2(15,15)).status=="wrong_step","rest requires an actual nearby bench")
	var store=load("res://scripts/campaign/save_store.gd").new(ProjectSettings.globalize_path("res://../tmp/trainer-roundtrip-"+State.new_id()))
	var fresh: Dictionary=store.create_slot("slot-1")
	check(fresh.status=="ok","isolated disk slot is created")
	session.data.revision=fresh.data.revision
	check(store.save_slot(session.data).status=="ok","completed route is saved to disk")
	var restored: Dictionary=store.load_slot("slot-1")
	check(restored.status=="ok" and restored.data.player.completedOperations==session.data.player.completedOperations and restored.data.player.flags.ninaReturned,"reload preserves all first-clear receipts and rescue")
	print("PARK JOURNEY: ",checks," checks; ",failures," failures; stages=",JSON.stringify(stages),"; wildWins=",wild_count)
	session.free()
	quit(1 if failures else 0)
