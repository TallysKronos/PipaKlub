extends RefCounted
## Kronasta regions (Bosque, Distrito Industrial, Pântano, Montanha): travel, discovery
## and authored map rewards, using the campaign's atomic receipts.
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Story=preload("res://scripts/campaign/kronasta_story.gd")
const NAMES={"kit-remendo":"Kit de Remendo","moedas":"moedas","papel-seda":"papel de seda","vareta-bambu":"vareta de bambu","cola-reparo":"cola de reparo","linha-encerada":"linha encerada","pista-caderno-heleana-1":"página do caderno","pa-do-moinho":"pá do moinho"}
var session: Node
func _init(local_session: Node) -> void: session=local_session

static func available(player: Dictionary) -> bool:
	return not player.get("partners",[]).is_empty() and player.get("journey",{}).get("phase","")=="complete"

static func authored_materials(scene: String) -> bool:
	return Checkpoint.region_of(scene)=="bambuzal" or Checkpoint.is_bosque(scene) or (Checkpoint.MAPS.has(scene) and Checkpoint.data(scene).get("forest",{}).get("nativeProps",false))

func travel(destination: String) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	var source: String=saved.get("checkpoint",{}).get("scene","")
	if saved.get("checkpoint",{}).get("kind","")!="world" or not available(saved.player): return {"status":"wrong_step"}
	# The Câmara do Elo closes behind Kael until the Eremor falls (no city map either).
	if source=="kronasta-coracao-d" and not saved.player.get("flags",{}).get("enamorDerrotado",false): return {"status":"wrong_step"}
	# The pause map opens indoors too (ateliê, loja, casa): those rooms are in the Vila.
	if source not in ["quintal","professor-home","kite-shop","kael-home"] and not Checkpoint.MAPS.has(source) and not preload("res://scripts/campaign/morro.gd").maps().has(source): return {"status":"wrong_step"}
	if not preload("res://scripts/campaign/kronasta_atlas.gd").can_travel(destination,saved.player):return {"status":"wrong_step"}
	if destination in ["park-trail","park-clearing","park-veredas"] and not Story.park_access(saved.player,destination):return {"status":"wrong_step"}
	if destination=="parque-patio-liga" and not load("res://scripts/campaign/blue_exam_preparation.gd").eligible(saved.player):return {"status":"wrong_step"}
	var target: Dictionary
	var region:=Checkpoint.region_of(destination)
	# Regions are entered by part A, and only while the story keeps them open.
	if not region.is_empty() and destination.ends_with("-a") and Story.can_travel(saved.player,region):
		target=Checkpoint.make(destination,Checkpoint.spawn(destination),Checkpoint.SPACE)
	elif region.is_empty() and Checkpoint.MAPS.has(destination):
		target=Checkpoint.make(destination,Checkpoint.spawn(destination),Checkpoint.SPACE)
	elif destination=="morro":
		target={"kind":"world","scene":"morro","position":preload("res://scripts/campaign/morro.gd").maps().morro.spawn}
	elif destination=="quintal":
		target=preload("res://scripts/campaign/neighborhood_checkpoint.gd").make(Vector2(1792,1808),saved.player)
	else: return {"status":"wrong_step"}
	return session.checkpoint(target,saved.player)

func arrive() -> Dictionary:
	var saved: Dictionary=session.snapshot()
	var region:=Checkpoint.region_of(saved.checkpoint.get("scene",""))
	if region.is_empty() or saved.checkpoint.get("space","")!=Checkpoint.SPACE or not available(saved.player): return {"status":"wrong_step"}
	var point:=Vector2(saved.checkpoint.position[0],saved.checkpoint.position[1])
	if not Checkpoint.model_for(saved.checkpoint.scene).point_walkable(point): return {"status":"wrong_step"}
	var part: String=saved.checkpoint.scene.right(1) if region=="caverna" else saved.checkpoint.scene.trim_prefix("kronasta-"+region+"-")
	var receipt: String=region+"-discovered-"+part+"-v1"
	if receipt in saved.player.completedOperations: return {"status":"already_applied"}
	saved.player.flags[region+"Parte"+part.to_upper()+"Descoberta"]=true
	if region=="bosque" and part=="c": saved.player.flags.bosqueClareiraDescoberta=true
	return session.commit_operation(receipt,saved.checkpoint,saved.player)

func collect(id: String, point: Vector2) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	var scene: String=saved.checkpoint.get("scene","")
	if not authored_materials(scene) or saved.checkpoint.get("space","")!=Checkpoint.SPACE or not available(saved.player): return {"status":"wrong_step"}
	var model=Checkpoint.model_for(scene)
	if not point.is_finite() or not model.point_walkable(point): return {"status":"wrong_step"}
	# Baús dos mapas novos (peça "bau" com item e quantidade): abrem uma vez e ficam abertos.
	if id.begins_with("piece-"):
		for piece in model.data.pieces:
			if str(int(piece.id))!=id.trim_prefix("piece-") or piece.asset!="bau" or not piece.props.has("item"): continue
			var chest_id: String="parque:"+Checkpoint.MAPS[scene]+":"+str(int(piece.id))
			if chest_id in saved.player.get("openedChests",[]): return {"status":"already_applied"}
			var spot:=Vector2(piece.u+.5,piece.v+.5)
			if point.distance_to(spot)>1.9 or absf(model.height_at(point)-model.height_at(spot))>=.25: return {"status":"wrong_step"}
			var item: String=str(piece.props.item)
			var count: int=int(str(piece.props.get("quantidade","1")))
			if not NAMES.has(item) or count<1 or count>100: return {"status":"wrong_step"}
			if item=="moedas": saved.player.coins+=count
			else: saved.player.inventory[item]=saved.player.inventory.get(item,0)+count
			var opened: Array=saved.player.get("openedChests",[])
			opened.append(chest_id)
			saved.player.openedChests=opened
			var stored: Dictionary=session.commit_operation("park-chest-"+Checkpoint.MAPS[scene]+"-"+id,saved.checkpoint,saved.player)
			if stored.status=="ok": stored.reward="%d %s"%[count,NAMES[item]]
			return stored
		return {"status":"wrong_step"}
	for event in model.data.events:
		if str(int(event.id))!=id or event.type!="item": continue
		var receipt: String="park-item-"+Checkpoint.MAPS[scene]+"-"+id
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
	if Checkpoint.region_of(scene)=="palafitas" and preload("res://scripts/campaign/district_rules.gd").unlocked(player,"palafitas"):return preload("res://scripts/campaign/district_campaign.gd").objective(player,"palafitas")
	if scene.begins_with("kronasta-pantano-") and load("res://scripts/campaign/retalho_trust.gd").swamp_open(player) or scene.begins_with("kronasta-palafitas-"):return load("res://scripts/campaign/retalho_trust.gd").objective(player)
	if scene=="kronasta-industrial-d" and Story.current_beat(player).get("id","") in ["galpao","gollia-bando"]:return Story.objective(player)
	if scene=="kronasta-industrial-d":return preload("res://scripts/campaign/warehouse_story.gd").objective(player)
	if scene=="kronasta-bosque-d":return "Retalho recuou. Guarde a pista do nó de expedição e volte pela trilha." if player.get("flags",{}).get("retalhoBosqueVencido",false) else "Procure Retalho na clareira elevada · Nv.22. O mato dos desvios é opcional."
	# A conquered place with the story elsewhere points to the next step (F25/F33).
	var beat:Dictionary=Story.current_beat(player)
	var away:bool=not beat.is_empty() and str(beat.get("place",""))!=Checkpoint.region_of(scene) and not (Checkpoint.is_bosque(scene) and beat.get("place","")=="bosque")
	# The Bosque keeps its exploration hints in the early acts; a conquered district always
	# points onwards (after Dona Zulmira, the Caverna do Mural).
	var conquered:bool=Checkpoint.region_of(scene) in ["bambuzal","beira-canal","feira","cais","industrial"] and preload("res://scripts/campaign/district_rules.gd").completed(player,Checkpoint.region_of(scene))
	var clareira:bool=player.get("flags",{}).get("bosqueClareiraDescoberta",false)
	if away and (conquered or (Checkpoint.is_bosque(scene) and (clareira or int(beat.get("act",0))>=4))):
		return "Próximo passo · "+Story.objective(player)+" Use o mapa de Kronasta (M)."
	if Checkpoint.region_of(scene) in ["bambuzal","beira-canal","feira","cais","industrial"]:return preload("res://scripts/campaign/district_campaign.gd").objective(player,Checkpoint.region_of(scene))
	if not Checkpoint.is_bosque(scene):
		var local:String=Story.region_objective(player,scene)
		# Nothing to do here and the story is elsewhere: show the next step (F25).
		if local.strip_edges().is_empty() and away and int(beat.get("act",0))>=4:return "Próximo passo · "+Story.objective(player)+" Use o mapa de Kronasta (M)."
		return local
	# The Trovareta storm (act 4) overrides the Bosque's exploration hints.
	if Story.current_beat(player).get("id","")=="trovareta": return Story.current_beat(player).text
	if preload("res://scripts/campaign/park_training.gd").needs_rest(player): return "Seu parceiro precisa descansar. Há bancos na Clareira do Marco."
	return {"kronasta-bosque-a":"Exploração opcional · siga a trilha ou procure os desvios dos platôs.","kronasta-bosque-b":"Atravesse o riacho pela ponte e siga até a Clareira do Marco.","kronasta-bosque-c":"Clareira descoberta · explore o mirante, descanse ou use o atalho de volta."}.get(scene,"")
