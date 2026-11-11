extends RefCounted
## Distances are native map cells; grace counts active walking, never idle time.
const Training=preload("res://scripts/campaign/park_training.gd")
const BOSS_LEVEL := 8
const MIN_WALK_SECONDS := 4.0
const Rewards=preload("res://scripts/campaign/opponent_rewards.gd")

static func reward_xp(species: String, level: int) -> int:
	return Rewards.xp(species,level)

static func distance_range(scene: String) -> Vector2:
	return {"park-trail":Vector2(18,26),"park-clearing":Vector2(14,22),"park-veredas":Vector2(12,19)}.get(scene,Vector2(18,26))

static func walking_grace(player: Dictionary) -> float:
	var result: String=player.get("lastEncounter",{}).get("outcome","")
	return 12.0 if result=="lost" else 8.0 if result=="fled" else 6.0

static func weight(model, point: Vector2) -> float:
	if not model.point_walkable(point): return 0.0
	var cell: Dictionary=model.cell_at(Vector2i(point.floor()))
	if (str(model.data.get("id",""))=="kronasta-bosque-d" or str(model.data.get("id","")).begins_with("kronasta-bambuzal-") or str(model.data.get("id","")).begins_with("kronasta-beira-canal-") or str(model.data.get("id","")).begins_with("kronasta-feira-")) and cell.material!="mato":return 0.0
	if cell.material not in ["grama","terra","mato"] or cell.get("ramp")!=null: return 0.0
	for event in model.data.events:
		var action: String=event.props.get("acao","")
		if event.type not in ["npc","saida","entrada","item"] and action not in ["parkBoss","wildRest","parkMap","wildGuide"]: continue
		var radius:=8.0 if action=="parkBoss" else 3.0
		if point.distance_to(Vector2(event.u+.5,event.v+.5))<radius: return 0.0
	for event in Training.events(str(model.data.get("id","")),model):
		if point.distance_to(Vector2(event.u+.5,event.v+.5))<3.0: return 0.0
	for piece in model.data.pieces:
		if piece.asset in ["bau","banco"] and point.distance_to(Vector2(piece.u+.5,piece.v+.5))<2.5: return 0.0
	return 1.6 if cell.material=="mato" else 1.0

static func wild_level(scene: String, roll: int) -> int:
	if scene=="kronasta-bosque-d":return 20+roll%3
	if scene.begins_with("kronasta-feira-"):return 15+roll%3
	if scene.begins_with("kronasta-beira-canal-"):return 12+roll%3
	if scene.begins_with("kronasta-bambuzal-"):return 7+roll%3
	# Planícies (Nv.10–14) e Gruta do Moinho (Nv.12–16): região lateral depois do Lacertubo.
	if scene in ["planicie-a","planicie-b","planicie-c"]:return 10+"abc".find(scene.right(1))+roll%3
	if scene in ["caverna-a","caverna-b","caverna-c"]:return 12+"abc".find(scene.right(1))+roll%3
	if scene.begins_with("kronasta-bosque-"):
		return {"kronasta-bosque-a":1,"kronasta-bosque-b":2,"kronasta-bosque-c":3}[scene]+roll%3
	# Every campaign region follows its story band (BIBLIA §3 and §8); wild ones
	# at Lv.1-7 next to a Lv.20-40 story only interrupted the walk (campaign walker).
	var band := {"cais":17,"industrial":20,"pantano":23,"palafitas":24,"montanha":26,"alto-da-serra":27,"aracati":30,"centro":30,"lajes":33,"porto":36,"coracao":40,"mirante":40}
	for region in band:
		if scene.begins_with("kronasta-"+region+"-"):
			return int(band[region])+maxi(0,"abcd".find(scene.right(1)))+roll%3
	return 5+roll%3 if scene=="park-veredas" else 2+roll%3 if scene=="park-clearing" else 1+roll%3

static func level_penalty(gap: int) -> float:
	# Interpolate the 3/5/10-level anchors; penalties stop at 50%.
	if gap<=0: return 0.0
	if gap<=3: return .1*gap/3.0
	if gap<=5: return lerpf(.1,.25,(gap-3)/2.0)
	return lerpf(.25,.5,clampf((gap-5)/5.0,0,1))
