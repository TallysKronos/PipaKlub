extends RefCounted
## Optional Kronasta region; authored map rewards use the campaign's atomic receipts.
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const NAMES={"moedas":"moedas","papel-seda":"papel de seda","vareta-bambu":"vareta de bambu","cola-reparo":"cola de reparo","linha-encerada":"linha encerada","pista-caderno-heleana-1":"página do caderno"}
var session: Node
func _init(local_session: Node) -> void: session=local_session

static func available(player: Dictionary) -> bool:
	return not player.get("partners",[]).is_empty() and player.get("journey",{}).get("phase","")=="complete"

func travel(destination: String) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	var source: String=saved.get("checkpoint",{}).get("scene","")
	if saved.get("checkpoint",{}).get("kind","")!="world" or not available(saved.player): return {"status":"wrong_step"}
	if source!="quintal" and not Checkpoint.MAPS.has(source): return {"status":"wrong_step"}
	var target: Dictionary
	if destination=="kronasta-bosque-a":
		target=Checkpoint.make(destination,Checkpoint.spawn(destination),Checkpoint.SPACE)
	elif destination=="quintal":
		target=preload("res://scripts/campaign/neighborhood_checkpoint.gd").make(Vector2(1792,1808),saved.player)
	else: return {"status":"wrong_step"}
	return session.checkpoint(target,saved.player)

func arrive() -> Dictionary:
	var saved: Dictionary=session.snapshot()
	if not Checkpoint.is_bosque(saved.checkpoint.get("scene","")) or saved.checkpoint.get("space","")!=Checkpoint.SPACE or not available(saved.player): return {"status":"wrong_step"}
	var point:=Vector2(saved.checkpoint.position[0],saved.checkpoint.position[1])
	if not Checkpoint.model_for(saved.checkpoint.scene).point_walkable(point): return {"status":"wrong_step"}
	var part: String=saved.checkpoint.scene.trim_prefix("kronasta-bosque-")
	var receipt: String="bosque-discovered-"+part+"-v1"
	if receipt in saved.player.completedOperations: return {"status":"already_applied"}
	saved.player.flags["bosqueParte"+part.to_upper()+"Descoberta"]=true
	if part=="c": saved.player.flags.bosqueClareiraDescoberta=true
	return session.commit_operation(receipt,saved.checkpoint,saved.player)

func collect(id: String, point: Vector2) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	var scene: String=saved.checkpoint.get("scene","")
	if not Checkpoint.is_bosque(scene) or saved.checkpoint.get("space","")!=Checkpoint.SPACE or not available(saved.player): return {"status":"wrong_step"}
	var model=Checkpoint.model_for(scene)
	if not point.is_finite() or not model.point_walkable(point): return {"status":"wrong_step"}
	for event in model.data.events:
		if str(int(event.id))!=id or event.type!="item": continue
		var receipt: String="park-item-"+scene+"-"+id
		if receipt in saved.player.completedOperations: return {"status":"already_applied"}
		var target:=Vector2(event.u+.5,event.v+.5)
		if point.distance_to(target)>1.8 or absf(model.height_at(point)-model.height_at(target))>=.25 or not Checkpoint.allowed(event,saved.player,scene): return {"status":"wrong_step"}
		var item: String=event.props.get("item","")
		var count: int=int(event.props.get("quantidade",0))
		if not NAMES.has(item) or count<1 or count>30: return {"status":"wrong_step"}
		if item=="moedas": saved.player.coins+=count
		else: saved.player.inventory[item]=saved.player.inventory.get(item,0)+count
		# Preserve the existing clue without inventing its text or a new revelation.
		if item=="pista-caderno-heleana-1": saved.player.flags.bosquePaginaEncontrada=true
		var result: Dictionary=session.commit_operation(receipt,saved.checkpoint,saved.player)
		if result.status=="ok": result.reward="%d %s"%[count,NAMES[item]]
		return result
	return {"status":"wrong_step"}

static func rest_events(area: String, model) -> Array:
	if area!="kronasta-bosque-c": return []
	var result: Array=[]
	for piece in model.data.pieces:
		if piece.asset!="banco": continue
		# Bench origins are blocked. Use a reachable adjacent cell at its own height.
		for delta in [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT]:
			var at: Vector2i=Vector2i(piece.u,piece.v)+delta
			if not model.walkable(at) or int(model.cell_at(at).level)!=int(model.cell_at(Vector2i(piece.u,piece.v)).level): continue
			result.append({"id":9700+int(piece.id),"type":"interacao","name":"Descansar no banco","u":at.x,"v":at.y,"props":{"acao":"wildRest"}})
			break
	return result

static func objective(player: Dictionary, scene: String) -> String:
	if preload("res://scripts/campaign/park_training.gd").needs_rest(player): return "Seu parceiro precisa descansar. Há bancos na Clareira do Marco."
	return {"kronasta-bosque-a":"Exploração opcional · siga a trilha ou procure os desvios dos platôs.","kronasta-bosque-b":"Atravesse o riacho pela ponte e siga até a Clareira do Marco.","kronasta-bosque-c":"Clareira descoberta · explore o mirante, descanse ou use o atalho de volta."}.get(scene,"")
