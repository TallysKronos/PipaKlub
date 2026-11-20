extends RefCounted
## Dados persistidos mantêm a unidade lógica de 96 por célula.
const ENTRY := Vector2(1104,1584)
const OWNER := Vector2(1132.8,499.2)
const CITY_ENTRY := Vector2(26.35,-.55)
const FLOOR := Rect2(384,288,1728,1344)
# Pegadas calibradas pela base dos móveis pintados.
const FURNITURE := {
	"prateleira-a":[.4,.2,7.1,1.9],
	"prateleira-b":[10.6,.2,17.8,2.1],
	"expositor-pipas":[.1,6.9,1.9,11.5],
	"gondola":[3.5,7.1,6.8,9.9],
	"balcao":[4.8,2.5,11.5,5.0],
	"mesa-fundo":[10.2,6.1,15.8,9.4],
	"mesa-frente":[10.2,10.5,15.8,13.9],
}
static func point(u:float,v:float)->Vector2:
	return FLOOR.position+Vector2(u,v)*96

static func project(p:Vector2)->Vector2:
	var cells := (p-FLOOR.position)/96
	return (Vector2(500,245)+Vector2((cells.x-cells.y)*32,(cells.x+cells.y)*16)).round()

static func room()->Dictionary:
	var data:Dictionary={
		"id":"kite-shop","floorImage":"shop-modern",
		"camera":{"x":0,"y":0,"scale":1.0,"isometric":true},
		"layout":{"floor":{"x":384,"y":288,"w":1728,"h":1344},"blocking":{"kaelEntry":[ENTRY.x,ENTRY.y]}},
		"props":[],"walkable":[[384,288,1728,1344]],"blocked":[],"hotspots":[],
	}
	for id in FURNITURE:
		var bounds:Array=FURNITURE[id]
		data.props.append({"id":id,"kind":"solid","footprint":{"u0":bounds[0],"v0":bounds[1],"u1":bounds[2],"v1":bounds[3]}})
		var origin:=point(bounds[0],bounds[1])
		data.blocked.append([origin.x,origin.y,(bounds[2]-bounds[0])*96,(bounds[3]-bounds[1])*96])
	data.props.append({"id":"porta-vidro","kind":"solid","footprint":{"u0":6.0,"v0":13.8,"u1":8.3,"v1":14.3}})
	data.blocked.append([OWNER.x-24,OWNER.y-24,48,48])
	for entry in [
		["exit","Sair para a rua",7.5,13.5],
		["counter","Conversar com o dono",8,5.7],
		["showcase","Ver os mostruários",15,2.9],
		["table-a","Mesas da comunidade",9.1,7.5],
		["table-b","Espaço de jogadores",9.1,11.7],
		["gondola","Kits e acessórios",5.3,10.7],
	]:
		var at:=point(entry[2],entry[3])
		data.hotspots.append({"id":entry[0],"name":entry[1],"x":at.x,"y":at.y})
	return data

static func safe(p:Vector2)->bool:
	if not p.is_finite() or not FLOOR.grow(-14).has_point(p):
		return false
	for bounds in room().blocked:
		if Rect2(bounds[0]-14,bounds[1]-14,bounds[2]+28,bounds[3]+28).has_point(p):
			return false
	return true

static func inside_floor(p:Vector2)->bool:
	return p.is_finite() and FLOOR.grow(-14).has_point(p)

static func resume_point(p:Vector2)->Vector2:
	if safe(p):
		return p
	if not p.is_finite():
		return ENTRY
	var nearest:=ENTRY
	var distance:=nearest.distance_squared_to(p)
	for x in range(408,2112,24):
		for y in range(312,1632,24):
			var candidate:=Vector2(x,y)
			var cost:=candidate.distance_squared_to(p)
			if cost<distance and safe(candidate):
				nearest=candidate
				distance=cost
	return nearest
