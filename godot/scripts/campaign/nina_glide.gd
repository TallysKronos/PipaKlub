extends RefCounted
## Loan permission is permanent. The borrowed Carcará is never a party/bank asset.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const State=preload("res://scripts/campaign/state.gd")
static var _data:Dictionary={}
var session:Node
func _init(active:Node)->void:session=active
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/glide-nina-v1/links.json"))
	return _data
static func link(id:String)->Dictionary:
	for entry:Dictionary in data().links:
		if entry.id==id:return entry.duplicate(true)
	return {}
static func point(raw:Array)->Vector2:return Vector2(raw[0],raw[1])
static func scene_for(entry:Dictionary)->String:return str(entry.get("scene",data().scene))
static func allowed(player:Dictionary)->bool:return player.get("flags",{}).get("leagueGreen",false) and player.get("flags",{}).get("ninaGlideLoanAvailable",false)
static func valid_link(entry:Dictionary)->bool:
	if entry.is_empty():return false
	var model=CP.model_for(scene_for(entry))
	var a:=point(entry.from);var b:=point(entry.to)
	if not a.is_finite() or not b.is_finite() or a.distance_to(b)<3 or a.distance_to(b)>9:return false
	if not is_equal_approx(a.x,b.x) or model.clear_segment(a,b):return false
	for end in [a,b]:
		if not model.point_walkable(end) or model.cell_at(Vector2i(end.floor())).get("ramp")!=null:return false
		for side in [Vector2.LEFT,Vector2.RIGHT]:
			if not model.clear_segment(end,end+side):return false
	if not is_equal_approx(model.height_at(a),model.height_at(b)):return false
	var water:=false
	for i in range(1,32):
		var p:=a.lerp(b,i/32.0);var c:Dictionary=model.cell_at(Vector2i(p.floor()))
		if c.is_empty() or c.material in ["bosque","rocha","construcao"] or model.solid.has(model.key(Vector2i(p.floor()))):return false
		if c.material=="agua":water=true
		if model.height_at(p)>model.height_at(a)+.01:return false
	return water
static func events(scene:String="park-veredas")->Array:
	var result:Array=[]
	for i in data().links.size():
		var e:Dictionary=data().links[i]
		if scene_for(e)!=scene:continue
		result.append({"id":10800+i,"type":"interacao","name":"Planar com o Carcará da Nina","u":int(e.from[0]),"v":int(e.from[1]),"props":{"acao":"ninaGlide","glideLink":e.id}})
	return result
func begin(id:String,at:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint;var entry:=link(id)
	if cp.kind!="world" or entry.is_empty() or cp.get("scene")!=scene_for(entry) or cp.get("space")!=CP.SPACE or not allowed(saved.player) or not valid_link(entry) or not at.is_finite():return {"status":"wrong_step"}
	if saved.player.has("ninaGlideFlight"):return {"status":"wrong_step"}
	var model=CP.model_for(cp.scene);var origin:=point(entry.from)
	# Same reach as the interact prompt (1.8): the flight starts from the arrow anyway.
	if at.distance_to(origin)>1.8 or not model.clear_segment(at,origin):return {"status":"wrong_step"}
	saved.player.ninaGlideFlight={"version":1,"id":State.new_id(),"link":id,"scene":cp.scene}
	return session.checkpoint(CP.make(cp.scene,origin,CP.SPACE),saved.player)
func finish(token:String)->Dictionary:
	var saved:Dictionary=session.snapshot();var flight:Dictionary=saved.player.get("ninaGlideFlight",{})
	if flight.is_empty() or flight.id!=token or saved.checkpoint.kind!="world" or saved.checkpoint.get("scene")!=flight.scene:return {"status":"wrong_step"}
	var entry:=link(flight.link)
	if not valid_link(entry):return {"status":"invalid"}
	saved.player.erase("ninaGlideFlight");saved.player.flags.ninaGlideTutorialDone=true
	return session.commit_operation("nina-glide-"+token,CP.make(scene_for(entry),point(entry.to),CP.SPACE),saved.player)
func recover()->Dictionary:
	var saved:Dictionary=session.snapshot();var flight:Dictionary=saved.player.get("ninaGlideFlight",{})
	if flight.is_empty():return {"status":"already_applied"}
	var entry:=link(str(flight.get("link","")))
	if entry.is_empty():return {"status":"invalid"}
	saved.player.erase("ninaGlideFlight")
	return session.checkpoint(CP.make(scene_for(entry),point(entry.from),CP.SPACE),saved.player)
static func valid_flight(value:Variant)->bool:
	return value is Dictionary and value.get("version")==1 and value.get("id") is String and not value.id.is_empty() and value.id.length()<=64 and not link(str(value.get("link",""))).is_empty() and value.get("scene")==scene_for(link(value.link))
