extends RefCounted
## Legacy street coordinates and native city cells are different save spaces.
const SPACE := "bairro-inicial-v2"
const HOME := Vector2(4.4,17.4)
const PROFESSOR := Vector2(5.9,-.65)
const PARK := Vector2(30.5,20)
const MORRO := Vector2(30.5,.2)

static func is_cell(point: Vector2) -> bool:
	return point.is_finite() and point.x>=0 and point.x<32 and point.y>=-7 and point.y<28

static func resolve(point: Vector2,player: Dictionary) -> Vector2:
	if is_cell(point):return point
	# Preserve the exact last city position when returning from an interior/map.
	var previous: Variant=player.get("cityPosition",[])
	if previous is Array and previous.size()==2:
		var candidate:=Vector2(float(previous[0]),float(previous[1]))
		if is_cell(candidate):return candidate
	if point.x>=2400:return MORRO
	if point.x>=1800:return PARK
	if point.x>=1000:return PROFESSOR
	return HOME

static func make(point: Vector2,player: Dictionary) -> Dictionary:
	var cell:=resolve(point,player)
	player.cityPosition=[cell.x,cell.y]
	return {"kind":"world","scene":"quintal","position":[cell.x,cell.y],"space":SPACE}
