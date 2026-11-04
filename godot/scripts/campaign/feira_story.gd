extends RefCounted
## Story transactions are atomic with the local save; no repeatable story loot.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const State=preload("res://scripts/campaign/state.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const PRICE=20
const POINTS={"lalau":{"scene":"kronasta-feira-a","at":Vector2(20.5,26.5)},"grampo":{"scene":"kronasta-feira-b","at":Vector2(34.5,17.5)},"door":{"scene":"park-veredas","at":Vector2(39.5,29.5)},"rest":{"scene":"kronasta-feira-b","at":Vector2(21.5,31.5)}}
var session:Node
func _init(active:Node)->void:session=active
static func unlocked(player:Dictionary)->bool:return Rules.completed(player,"beira-canal")
static func phase(player:Dictionary)->String:
	var f:Dictionary=player.get("flags",{})
	if f.get("feiraApitoVerdadeiro",false):return "complete"
	if f.get("feiraLalauVencido",false):return "grampo"
	if f.get("feiraApitoFalsoTestado",false):return "lalau"
	if f.get("feiraApitoComprado",false):return "door"
	return "buy"
static func objective(player:Dictionary)->String:
	return {"buy":"Encontre Seu Lalau na praça da Feira para saber do apito de vento.","door":"Leve o apito às Veredas e experimente na entrada das Ruínas, no antigo pátio do guardião.","lalau":"O apito é falso. Volte à praça e confronte Seu Lalau.","grampo":"Lalau entregou o verdadeiro ao Grampo. Procure o beco do mercado na parte B.","complete":"O apito verdadeiro está com você. Termine os desafios e procure Dona Zulmira no largo alto."}[phase(player)]
static func door_events(player:Dictionary)->Array:
	if not unlocked(player):return []
	return [{"id":11100,"type":"interacao","name":"Porta das Ruínas · apito de vento","u":39,"v":29,"props":{"acao":"feiraStory","feiraAction":"door"}}]
func near(key:String,point:Vector2)->bool:
	if not POINTS.has(key) or not point.is_finite():return false
	var saved:Dictionary=session.snapshot();var p:Dictionary=POINTS[key]
	if saved.checkpoint.kind!="world" or saved.checkpoint.get("scene")!=p.scene or saved.checkpoint.get("space")!=CP.SPACE or not unlocked(saved.player):return false
	var map=CP.model_for(p.scene)
	return map.point_walkable(point) and point.distance_to(p.at)<=1.8 and absf(map.height_at(point)-map.height_at(p.at))<.25
func buy(point:Vector2)->Dictionary:
	if not near("lalau",point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if phase(saved.player)!="buy":return {"status":"already_applied"}
	if saved.player.coins<PRICE:return {"status":"feira_no_coins"}
	saved.player.coins-=PRICE;saved.player.inventory["apito-falso"]=1;saved.player.flags.feiraApitoComprado=true
	return session.commit_operation("feira-apito-compra-v1",saved.checkpoint,saved.player)
func test_door(point:Vector2)->Dictionary:
	if not near("door",point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if phase(saved.player)!="door":return {"status":"already_applied"} if phase(saved.player) in ["lalau","grampo","complete"] else {"status":"wrong_step"}
	if saved.player.inventory.get("apito-falso",0)<1:return {"status":"wrong_step"}
	saved.player.flags.feiraApitoFalsoTestado=true
	return session.commit_operation("feira-apito-falso-testado-v1",saved.checkpoint,saved.player)
static func valid_battle(e:Dictionary)->bool:
	var who:String=e.get("feiraOpponent","")
	if who not in ["lalau","grampo"]:return false
	var s:Dictionary=e.get("state",{})
	return e.get("scene")==POINTS[who].scene and e.get("space")==CP.SPACE and s.get("enemyModelId")==("mata" if who=="lalau" else "platyx-draft") and s.get("enemyLevel")== (16 if who=="lalau" else 17)
func begin(who:String,point:Vector2)->Dictionary:
	if who not in ["lalau","grampo"] or not near(who,point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if phase(saved.player)!=who:return {"status":"already_applied"} if phase(saved.player)=="complete" else {"status":"wrong_step"}
	var active:Dictionary=preload("res://scripts/campaign/park_training.gd").active(saved.player)
	if active.is_empty() or active.get("condition",{}).get("line",100)<=0 or active.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
	var battle:=Model.new(active,{"modelId":"mata" if who=="lalau" else "platyx-draft","level":16 if who=="lalau" else 17})
	battle.q.name="Seu Lalau" if who=="lalau" else "Platyx · Grampo"
	saved.player.encounter={"id":State.new_id(),"kind":"feira-story","feiraOpponent":who,"scene":saved.checkpoint.scene,"space":CP.SPACE,"returnPoint":[point.x,point.y],"state":battle.snapshot()}
	return session.checkpoint({"kind":"encounter"},saved.player)
func settle()->Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="encounter" or saved.player.encounter.kind!="feira-story":return {"status":"wrong_step"}
	var e:Dictionary=saved.player.encounter;var s:Dictionary=e.state
	if not valid_battle(e) or s.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
	for p:Dictionary in saved.player.partners:
		if p.id==s.partnerId:p.condition={"line":clampf(s.p.hp/s.p.stats.line*100,0,100),"structure":clampf(s.p.hull/s.p.stats.line*100,0,100)}
	if s.outcome=="won":
		if e.feiraOpponent=="lalau":
			saved.player.flags.feiraLalauVencido=true;saved.player.coins+=PRICE
		else:
			saved.player.flags.feiraApitoVerdadeiro=true;saved.player.inventory["apito-de-vento"]=1
			saved.player.inventory.erase("apito-falso")
	saved.player.lastFeira={"opponent":e.feiraOpponent,"outcome":s.outcome}
	saved.player.erase("encounter")
	return session.commit_operation("encounter-"+e.id,CP.make(e.scene,CP.spawn(e.scene) if s.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1]),CP.SPACE),saved.player)
func rest(point:Vector2)->Dictionary:
	if not near("rest",point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if saved.player.partners.all(func(p):return p.get("condition",{}).get("line",100)>=100 and p.get("condition",{}).get("structure",100)>=100):return {"status":"already_applied"}
	if saved.player.coins<12:return {"status":"not_enough_coins"}
	saved.player.coins-=12
	for p:Dictionary in saved.player.partners:p.condition={"line":100,"structure":100}
	return session.checkpoint(saved.checkpoint,saved.player)
