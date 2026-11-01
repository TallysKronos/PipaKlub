extends SceneTree
const Pacing=preload("res://scripts/campaign/park_pacing.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Encounter=preload("res://scripts/campaign/encounter_model.gd")
const Encounters=preload("res://scripts/campaign/encounters.gd")
var checks:=0
var failures:=0

func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; printerr("FAIL ",message)

func _initialize() -> void:
	for scene in Checkpoint.MAPS:
		var model=Checkpoint.model_for(scene)
		var outside:=0
		var grass:=0
		for id in model.graph.get_point_ids():
			var point: Vector2=model.graph.get_point_position(id)
			var cell: Dictionary=model.cell_at(Vector2i(point.floor()))
			var weight:=Pacing.weight(model,point)
			if weight>0 and cell.material=="mato": grass+=1
			elif weight>0: outside+=1
			if cell.material in ["ponte","piso"] or cell.get("ramp")!=null: check(weight==0,"bridge, square and ramp safe: "+scene)
		check(outside>30,scene+" has encounters beyond grass")
		# Original park maps promise encounter grass. Bosque B's authored grass
		# surrounds protected interactions; ordinary terrain still hosts encounters.
		if scene in ["park-clearing","park-veredas"]: check(grass>0,scene+" retains high-grass encounters")
		for event in model.data.events:
			if event.type in ["npc","saida","entrada"] or event.props.get("acao","")=="parkBoss":
				check(Pacing.weight(model,Vector2(event.u+.5,event.v+.5))==0,"interaction remains safe: "+event.name)
		print(scene,": eligible ordinary ground=",outside,"; tall grass=",grass)
	var xp:=0
	var wins:=0
	while Encounter.level_for_xp(xp)<8 and wins<100:
		var scene: String="park-trail" if wins<8 else "park-clearing" if wins<20 else "park-veredas"
		var species: String="basica" if wins%10<5 else "mata" if wins%10<8 else "raio"
		xp+=Encounters.reward_amount(false,scene,species,Pacing.wild_level(scene,wins%3))
		wins+=1
	check(wins>=40 and wins<=55,"mixed progression prepares boss in 40-55 victories")
	print("Mixed route to Lv.8: ",wins," victories, ",xp," XP")
	check(Encounters.reward_amount(false,"park-trail","mata",3)>Encounters.reward_amount(false,"park-trail","basica",3),"same-area species have distinct rewards")
	check(Encounters.reward_amount(false,"park-trail","basica",3)>Encounters.reward_amount(false,"park-veredas","basica",1),"enemy strength, not regional label, determines reward")
	for anchor in [[3,.1],[5,.25],[10,.5],[20,.5]]: check(is_equal_approx(Pacing.level_penalty(anchor[0]),anchor[1]),"level penalty anchor "+str(anchor[0]))
	for result in ["won","fled","lost"]:
		check(Pacing.walking_grace({"lastEncounter":{"outcome":result}})=={"won":6.0,"fled":8.0,"lost":12.0}[result],"walking pause after "+result)
	var low:=Encounter.new({"xp":0})
	var equal:=Encounter.new({"xp":Encounter.xp_for_level(8)})
	check(low.enemy_level==8 and equal.p.level==8,"boss level matches progression")
	var hp: float=low.p.hp
	low._apply_hit({"target":low.p,"body":false,"damage":20.0})
	check(is_equal_approx(hp-low.p.hp,27.0),"seven levels below takes 35 percent extra damage")
	hp=low.q.hull
	low._apply_hit({"target":low.q,"body":true,"damage":20.0})
	check(is_equal_approx(hp-low.q.hull,13.0),"lower-level body attack loses 35 percent damage")
	var restored:=Encounter.new()
	restored.restore(low.snapshot())
	check(restored.p.level==1 and restored.q.level==8,"combat levels survive suspend and resume")
	for pair in [[0,1],[Encounter.xp_for_level(8),8]]:
		var model:=Encounter.new({"id":"pacing-rabbito","modelId":"rabbito","xp":pair[0]})
		for tick in 9000:
			if not model.outcome.is_empty(): break
			var p: Dictionary=model.p
			var q: Dictionary=model.q
			var crossing:=Vector2(q.anchor,585).lerp(Vector2(q.x,q.y),.6)
			var aim:=Vector2(clampf(p.anchor+(crossing.x-p.anchor)/.7,55,945),clampf(585+(crossing.y-585)/.7,70,480))
			var direction: Vector2=(aim-Vector2(p.x,p.y)).limit_length()
			model.tick(1.0/60.0,{"x":direction.x,"y":direction.y,"cut":model.contact(p,q).get("valid",false) and q.charge<=0,"guard":q.signatureWindup>0 and q.signatureWindup<.3 and p.guardCooldown<=0,"line":p.lineCooldown<=0 and p.energy>60,"signature":p.energy>=100})
		print("Simulated boss, partner Lv.",pair[1],": ",model.outcome,"; elapsed=",snappedf(model.time,.1),"; line=",snappedf(model.p.hp,.1),"; structure=",snappedf(model.p.hull,.1))
		check(not model.outcome.is_empty(),"boss battle terminates within time budget")
		if pair[1]==8: check(model.outcome=="won","prepared partner can win with timed commands")
	print("PARK PACING: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
