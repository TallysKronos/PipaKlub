extends RefCounted
## After district six: trust and recognition, never capture or category promotion.
const Rules=preload("res://scripts/campaign/district_rules.gd")
const AT=Vector2(1152,864)
const APPROACH=Vector2(1104,960)
const SPACE="professor-home"
static var _nodes:Array=[]
var session:Node
func _init(active:Node)->void:session=active
static func nodes()->Array:
 if _nodes.is_empty():_nodes=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/retalho-care-v1/dialogue.json")).nodes
 return _nodes.duplicate(true)
static func available(p:Dictionary)->bool:
 return p.get("flags",{}).get("pipaDragaoDesatadaVencida",false) and Rules.completed(p,"industrial")
static func step(p:Dictionary)->int:
 var entries:=nodes()
 for i in entries.size():
  if not p.get("flags",{}).get(entries[i].flag,false):return i
 return entries.size()
static func objective(p:Dictionary)->String:
 if step(p)<nodes().size():return "Aproxime-se de Retalho no tapete · respeite o espaço dela."
 return load("res://scripts/campaign/retalho_trust.gd").objective(p)
static func room_data(data:Dictionary,p:Dictionary)->Dictionary:
 var result:=data.duplicate(true)
 if available(p) and not p.flags.get("retalhoFugiuVaral",false) and not result.hotspots.any(func(h):return h.id=="retalho-care"):
  result.hotspots.append({"id":"retalho-care","name":"Verificar o Varal" if p.flags.get("retalhoVaralLivre",false) else "Cuidar de Retalho","x":AT.x,"y":AT.y})
 return result
static func walkable(point:Vector2)->bool:
 return preload("res://scripts/campaign/professor_interior_v2.gd").walkable(point)
func near(point:Vector2)->bool:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 return cp.get("kind")=="world" and cp.get("scene")==SPACE and available(saved.player) and walkable(point) and point.distance_to(AT)<=110
func advance(expected:String,point:Vector2)->Dictionary:
 if not near(point):return {"status":"wrong_step"}
 var saved:Dictionary=session.snapshot();var index:=step(saved.player);var entries:=nodes()
 if index==entries.size():return {"status":"already_applied"}
 var entry:Dictionary=entries[index]
 if expected!=entry.id:return {"status":"wrong_step"}
 saved.player.flags[entry.flag]=true
 return session.commit_operation(entry.id+"-v1",{"kind":"world","scene":SPACE,"position":[point.x,point.y]},saved.player)
static func build(room:Node2D,p:Dictionary)->void:
 if not available(p) or p.flags.get("retalhoVaralLivre",false):return
 var art:=Sprite2D.new();art.name="RetalhoAtelie"
 art.texture=load("res://assets/campaign/retalho-v1/overworld.png")
 art.scale=Vector2.ONE*76.0/art.texture.get_height()
 art.offset=Vector2(0,-art.texture.get_height()*.5)
 art.position=room.project(AT);art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 room.add_child(art)
 room.props.append({"node":art,"rect":room._foot(AT),"layer":""})
 room._update_order()
