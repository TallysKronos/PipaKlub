extends RefCounted
## The archive keeps its photograph: reading gives a memory, never repeatable loot.
const State=preload("res://scripts/campaign/state.gd")
const AT=Vector2(912,480)
const FLAG="fotoExpedicaoLida"
var session:Node
func _init(active:Node)->void:session=active
static func available(p:Dictionary)->bool:return p.get("flags",{}).get("retalhoBosqueVencido",false)
static func pages()->String:
 return "Kael: Minha mãe… com uma mochila de expedição? Ela nunca me mostrou essa foto.\n\nKael: Os óculos são do professor. Então esse é o Assis jovem? Mas o rosto… a mecha… parece o Tyler.\n\nKael: Essa almática no ombro dela… e esse nó na rabiola. É igual ao que vi no Bosque. Preciso guardar isso na memória."
func read(point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot();var cp:Dictionary=saved.checkpoint
 if cp.kind!="world" or cp.get("scene")!="professor-home" or not available(saved.player) or not point.is_finite() or point.distance_to(AT)>110:return {"status":"wrong_step"}
 if saved.player.flags.get(FLAG,false):return {"status":"already_applied"}
 saved.player.flags[FLAG]=true
 return session.commit_operation("foto-expedicao-v1",{"kind":"world","scene":"professor-home","position":[point.x,point.y]},saved.player)
