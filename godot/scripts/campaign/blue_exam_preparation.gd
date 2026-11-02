extends RefCounted
## Orientation only. Cida's exam and its rescue events are separate future content.
const Care=preload("res://scripts/campaign/retalho_care.gd")
static func data()->Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/retalho-care-v1/blue-preparation.json"))
static func eligible(player:Dictionary)->bool:
 return Care.available(player) and player.get("flags",{}).get("assisReconheceuNoRetalho",false) and player.get("flags",{}).get("exameAzulPreparacao",false)
static func prepared(player:Dictionary)->bool:
 return player.get("flags",{}).get("exameAzulOrientado",false)
static func confirm(session:Node,point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if not eligible(saved.player) or not Care.new(session).near(point):return {"status":"wrong_step"}
 if prepared(saved.player):return {"status":"already_applied"}
 saved.player.flags.exameAzulOrientado=true
 return session.commit_operation(data().id,{"kind":"world","scene":Care.SPACE,"position":[point.x,point.y]},saved.player)
