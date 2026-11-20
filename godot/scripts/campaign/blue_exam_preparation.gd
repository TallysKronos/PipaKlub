extends RefCounted
## Orientation only. The playable patio exam is independent of Retalho's rescue.
const Rules=preload("res://scripts/campaign/district_rules.gd")
const AT=Vector2(1152,864)
const SPACE="professor-home"
## Sr. Assis in the workshop room (content.json rooms.professor hotspot "professor").
const PROFESSOR=Vector2(960,768)
static func data()->Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/retalho-care-v1/blue-preparation.json"))
static func eligible(player:Dictionary)->bool:
 return player.get("flags",{}).get("leagueGreen",false) and Rules.completed(player,"cais") and Rules.completed(player,"industrial")
static func prepared(player:Dictionary)->bool:
 return player.get("flags",{}).get("exameAzulOrientadoV2",false)
static func near(session:Node,point:Vector2)->bool:
 var saved:Dictionary=session.snapshot()
 # F16: next to Sr. Assis himself (the room's "professor" hotspot) as well as the old
 # spot by the workbench; talking to him used to do nothing when Kael faced him.
 return saved.checkpoint.get("kind")=="world" and saved.checkpoint.get("scene")==SPACE and point.is_finite() and (point.distance_to(AT)<=110 or point.distance_to(PROFESSOR)<=110) and preload("res://scripts/campaign/retalho_care.gd").walkable(point)
static func confirm(session:Node,point:Vector2)->Dictionary:
 var saved:Dictionary=session.snapshot()
 if not eligible(saved.player) or not near(session,point):return {"status":"wrong_step"}
 if prepared(saved.player):return {"status":"already_applied"}
 saved.player.flags.exameAzulOrientadoV2=true
 return session.commit_operation(data().id,{"kind":"world","scene":SPACE,"position":[point.x,point.y]},saved.player)
