extends RefCounted
## A linear authored scene, each acknowledgment checkpointed before presentation advances.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const District=preload("res://scripts/campaign/district_rules.gd")
static var _data:Dictionary={}
var session:Node
func _init(active:Node)->void:session=active
static func nodes()->Array:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/tyler-clareira-v1/dialogue.pt-BR.json"))
	return _data.nodes
static func unlocked(player:Dictionary)->bool:return District.completed(player,"bambuzal")
static func step(player:Dictionary)->int:return int(player.get("tylerClareiraStep",0))
static func done(player:Dictionary)->bool:return player.get("flags",{}).get("tylerClareiraMet",false)
static func point()->Vector2:return Vector2(24.5,20.5)
static func events()->Array:
	return [{"id":10601,"type":"npc","name":"Tyler","u":24,"v":20,"props":{"acao":"tylerClareira","storySprite":"tyler"}},{"id":10602,"type":"npc","name":"Rai","u":26,"v":20,"props":{"acao":"tylerRai","storySprite":"rai"}}]
func available(at:Vector2)->bool:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="world" or saved.checkpoint.get("scene")!="park-clearing" or saved.checkpoint.get("space")!=CP.SPACE or not unlocked(saved.player) or not at.is_finite():return false
	var map=CP.model_for("park-clearing")
	return map.point_walkable(at) and at.distance_to(point())<=3.5 and absf(map.height_at(at)-map.height_at(point()))<.25
func advance(expected:int,at:Vector2)->Dictionary:
	if not available(at):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if done(saved.player):return {"status":"already_applied"}
	if step(saved.player)!=expected or expected<0 or expected>=nodes().size():return {"status":"stale"}
	saved.player.tylerClareiraStep=expected+1
	if expected+1==nodes().size():saved.player.flags.tylerClareiraMet=true
	return session.commit_operation("tyler-clareira-v1-"+str(expected),saved.checkpoint,saved.player)
