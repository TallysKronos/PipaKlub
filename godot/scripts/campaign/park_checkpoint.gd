extends RefCounted
## Explicit coordinate version: legacy illustrated pixels never become map cells by guesswork.
const SPACE := "parque-overworld-v1"
const MAPS := {"park-trail":"jardim-das-pipas","park-clearing":"clareira-do-papel","park-veredas":"veredas-do-encanamento","kronasta-bosque-a":"kronasta-bosque-a","kronasta-bosque-b":"kronasta-bosque-b","kronasta-bosque-c":"kronasta-bosque-c"}
const Model = preload("res://scripts/overworld/map_model.gd")
const Legacy = preload("res://scripts/campaign/park_data.gd")
static var _maps: Dictionary = {}
static var _models: Dictionary = {}

static func is_bosque(scene: String) -> bool:
	return scene in ["kronasta-bosque-a","kronasta-bosque-b","kronasta-bosque-c"]

static func data(scene: String) -> Dictionary:
	if not MAPS.has(scene): return {}
	if not _maps.has(scene):
		_maps[scene] = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/"+MAPS[scene]+".json"))
		# The incoming layout is a preview. Preserve the live Nina quest in the
		# campaign adapter, with an ID distinct from its entrance event 43.
		if scene=="park-trail" and _maps[scene].get("forest",{}).get("nativeProps",false):
			_maps[scene].events.append({"id":8243,"type":"npc","name":"Nina","u":10,"v":32,"props":{"fala":"nina-jardim-proposta","missao":"nina","bloqueia":false}})
		if scene=="park-veredas" and _maps[scene].get("forest",{}).get("nativeProps",false):
			_maps[scene].events.append({"id":1100,"type":"saida","name":"Atalho para o Jardim das Pipas","u":43,"v":33,"props":{"destino":"park-trail","requer":"ninaTail"}})
	return _maps[scene]

static func model_for(scene: String):
	if not _models.has(scene):
		var model := Model.new()
		model.setup(data(scene))
		_models[scene] = model
	return _models[scene]

static func valid_position(scene: String, point: Vector2) -> bool:
	var map := data(scene)
	return not map.is_empty() and point.is_finite() and point.x>=0 and point.y>=0 and point.x<float(map.w) and point.y<float(map.h)

static func loadable_position(scene: String, point: Vector2) -> bool:
	# Earlier native park layouts were 64x48. Accept their saved coordinates for
	# loading only; resolve()/make() move them onto supported current terrain.
	if valid_position(scene,point): return true
	return scene in ["park-trail","park-clearing","park-veredas"] and point.is_finite() and point.x>=0 and point.y>=0 and point.x<64 and point.y<48

static func safe(scene: String, point: Vector2) -> Vector2:
	var model = model_for(scene)
	if valid_position(scene,point) and model.point_walkable(point): return point
	if not point.is_finite(): point = spawn(scene)
	var id: int = model.graph.get_closest_point(point)
	return model.graph.get_point_position(id)

static func spawn(scene: String, entrance: String = "") -> Vector2:
	var map := data(scene)
	if not entrance.is_empty():
		for event in map.events:
			if event.type=="entrada" and event.props.get("entrada","")==entrance: return Vector2(event.u+.5,event.v+.5)
	return Vector2(map.spawn.u+.5,map.spawn.v+.5)

static func target(scene: String, key: String) -> Vector2:
	var map := data(scene)
	if map.is_empty(): return Vector2.INF
	if key.begins_with("chest:"):
		for piece in map.pieces:
			if piece.props.get("bau","")==key.trim_prefix("chest:"): return Vector2(piece.u+.5,piece.v+.5)
	for event in map.events:
		if (key=="nina" and event.name=="Nina") or (key=="boss" and event.props.get("acao","")=="parkBoss") or (key=="tail" and event.props.get("acao","")=="veredasTail"):
			return Vector2(event.u+.5,event.v+.5)
	return Vector2.INF

static func migrate(scene: String, point: Vector2) -> Vector2:
	var anchors: Array = [[Vector2(208,816),spawn(scene)]]
	if scene=="park-veredas":
		anchors.append([Legacy.NINA,target(scene,"nina")])
		anchors.append([Legacy.BOSS,target(scene,"boss")])
		anchors.append([Legacy.TAIL,target(scene,"tail")])
		for id in Legacy.CHESTS: anchors.append([Legacy.CHESTS[id].point,target(scene,"chest:"+id)])
	else:
		var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))[scene]
		for place in old.places:
			for event in data(scene).events:
				if event.name==place.name: anchors.append([Vector2(place.point[0],place.point[1]),Vector2(event.u+.5,event.v+.5)])
	var best := spawn(scene)
	var distance := INF
	for anchor in anchors:
		var gap: float = point.distance_squared_to(anchor[0])
		if gap<distance and Vector2(anchor[1]).is_finite(): distance=gap; best=anchor[1]
	return safe(scene,best)

static func make(scene: String, point: Vector2, space: String = "") -> Dictionary:
	var resolved := safe(scene,point) if space==SPACE or is_bosque(scene) else migrate(scene,point)
	return {"kind":"world","scene":scene,"position":[resolved.x,resolved.y],"space":SPACE}

static func resolve(checkpoint: Dictionary) -> Vector2:
	var raw: Array = checkpoint.get("position",[208,816])
	var point := Vector2(raw[0],raw[1])
	return safe(checkpoint.scene,point) if checkpoint.get("space","")==SPACE or is_bosque(checkpoint.scene) else migrate(checkpoint.scene,point)

static func near(checkpoint: Dictionary, key: String, point: Vector2) -> bool:
	if checkpoint.get("space","")!=SPACE: return false
	var scene: String = checkpoint.get("scene","")
	if not MAPS.has(scene) or not valid_position(scene,point): return false
	var at := target(scene,key)
	return at.is_finite() and point.distance_to(at)<=1.8 and model_for(scene).walkable(Vector2i(point.floor())) and absf(model_for(scene).height_at(point)-model_for(scene).height_at(at))<.25

static func in_grass(checkpoint: Dictionary, point: Vector2) -> bool:
	var scene: String = checkpoint.get("scene","")
	if not MAPS.has(scene) or not valid_position(scene,point): return false
	return model_for(scene).walkable(Vector2i(point.floor())) and model_for(scene).cell_at(Vector2i(point.floor())).material=="mato"

static func encounter_weight(checkpoint: Dictionary, point: Vector2) -> float:
	var scene: String=checkpoint.get("scene","")
	if not MAPS.has(scene) or not valid_position(scene,point): return 0.0
	return preload("res://scripts/campaign/park_pacing.gd").weight(model_for(scene),point)

static func allowed(event: Dictionary, player: Dictionary, area: String = "") -> bool:
	var props: Dictionary = event.get("props",{})
	var flags: Dictionary = player.get("flags",{})
	if props.has("requer") and not flags.get(str(props.requer),false): return false
	if props.has("ocultar_apos") and flags.get(str(props.ocultar_apos),false): return false
	if props.get("descoberta","")=="clareira-do-marco" and not flags.get("bosqueClareiraDescoberta",false): return false
	# Lacertubo leaves the Veredas once defeated; only the quest tail remains.
	if props.get("acao","")=="parkBoss" and flags.get("guardianDefeated",false): return false
	if props.get("acao","")=="veredasTail" and (not flags.get("guardianDefeated",false) or not flags.get("ninaAccepted",false) or flags.get("ninaTail",false)): return false
	if event.get("type","")=="item" and ("park-item-"+area+"-"+str(int(event.id))) in player.get("completedOperations",[]): return false
	return true

static func exit_target(checkpoint: Dictionary, id: String, player: Dictionary) -> Dictionary:
	var source: String = checkpoint.get("scene","")
	if checkpoint.get("space","")!=SPACE or not MAPS.has(source): return {"status":"wrong_step"}
	var at := Vector2(checkpoint.position[0],checkpoint.position[1])
	for event in data(source).events:
		if str(int(event.id))!=id or event.type!="saida": continue
		if not allowed(event,player) or at.distance_to(Vector2(event.u+.5,event.v+.5))>1.8: return {"status":"wrong_step"}
		if absf(model_for(source).height_at(at)-model_for(source).height_at(Vector2(event.u+.5,event.v+.5)))>=.25: return {"status":"wrong_step"}
		var destination: String = event.props.get("destino","")
		if destination=="quintal": return {"status":"ok","scene":destination,"point":Vector2(1792,1808),"space":""}
		if not MAPS.has(destination): return {"status":"wrong_step"}
		var entrance: String = event.props.get("entrada_destino","")
		var point := spawn(destination,entrance)
		if event.props.has("chegada_u") and event.props.has("chegada_v"):
			var authored:=Vector2(float(event.props.chegada_u)+.5,float(event.props.chegada_v)+.5)
			if valid_position(destination,authored) and model_for(destination).point_walkable(authored):
				return {"status":"ok","scene":destination,"point":authored,"space":SPACE}
		if is_bosque(source) and is_bosque(destination):
			if event.props.has("chegada_u") and event.props.has("chegada_v"):
				point=safe(destination,Vector2(float(event.props.chegada_u)+.5,float(event.props.chegada_v)+.5))
			return {"status":"ok","scene":destination,"point":point,"space":SPACE}
		if entrance.is_empty() and MAPS.keys().find(destination)<MAPS.keys().find(source):
			for back in data(destination).events:
				if back.type=="saida" and back.props.get("destino","")==source and not back.props.has("entrada_destino"):
					point=safe(destination,Vector2(back.u+.5,back.v+.5)); break
		return {"status":"ok","scene":destination,"point":point,"space":SPACE}
	return {"status":"wrong_step"}
