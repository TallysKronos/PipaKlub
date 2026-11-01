extends RefCounted
const ENTRY=Vector2(1104,1584)
const OWNER=Vector2(1152,460.8)
const CITY_ENTRY=Vector2(26.35,-.55)
static func point(u:float,v:float)->Vector2:return Vector2(384+u*96,288+v*96)
static func project(p:Vector2)->Vector2:return (Vector2((p.x-p.y)/3,(p.x+p.y)/6)+Vector2(432,90))*.82
static func room()->Dictionary:
 var data:Dictionary={"id":"kite-shop","floorImage":"shop-modern","camera":{"x":-432,"y":-90,"scale":.82,"isometric":true},"layout":{"floor":{"x":384,"y":288,"w":1728,"h":1344},"blocking":{"kaelEntry":[ENTRY.x,ENTRY.y]}},"props":[],"walkable":[[384,288,1728,1344]],"blocked":[],"hotspots":[]}
 for item in [["rug",6.5,5,7,8,0],["shelf-a",0,0,6,1,150],["shelf-b",12,0,6,1,150],["counter",5,2,6,1.5,90],["display",0,7,1.5,3,135],["gondola",3,6,3,2,95],["table-a",8,6,4,3,58],["table-b",9,10,4,3,58],["showcase",14,5,3,2,95],["exit",6.5,13,2,1,0]]:
  var p:Vector2=point(item[1],item[2]);var w:float=item[3]*96;var h:float=item[4]*96
  var a:=project(p);var c:=project(p+Vector2(w,h));var left:=project(p+Vector2(0,h));var right:=project(p+Vector2(w,0))
  data.props.append({"id":item[0],"kind":"flat" if item[0] in ["rug","exit"] else "floor","footprint":{"u0":item[1],"v0":item[2],"u1":item[1]+item[3],"v1":item[2]+item[4]},"rect":[left.x,a.y-item[5]*.82,right.x-left.x,c.y-a.y+item[5]*.82]})
  if item[0] not in ["rug","exit"]:data.blocked.append([p.x,p.y,w,h])
 data.blocked.append([OWNER.x-24,OWNER.y-24,48,48])
 data.props.append({"id":"window","kind":"wallLeft","footprint":null,"rect":[270,85,92,112]})
 for entry in [["exit","Sair para a rua",7.5,13.5],["counter","Conversar com o dono",8,4.5],["showcase","Ver os mostruários",15.5,8],["table-a","Mesas da comunidade",7,7.5],["table-b","Espaço de jogadores",8,11.5],["gondola","Kits e acessórios",4.5,9]]:
  var at:=point(entry[2],entry[3]);data.hotspots.append({"id":entry[0],"name":entry[1],"x":at.x,"y":at.y})
 return data
static func safe(p:Vector2)->bool:
 var data:=room()
 for d in [Vector2(-14,-14),Vector2(-14,14),Vector2(14,-14),Vector2(14,14)]:
  if not Rect2(384,288,1728,1344).has_point(p+d):return false
 for r in data.blocked:
  if Rect2(r[0]-14,r[1]-14,r[2]+28,r[3]+28).has_point(p):return false
 return p.is_finite()
