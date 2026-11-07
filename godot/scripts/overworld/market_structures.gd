extends RefCounted
## Barracas derivadas da pegada 3x2; projeção e ordenação seguem o piso.
const S=preload("res://scripts/overworld/forest_structures.gd")
const CENTRO_KIT="res://assets/overworld/kits/centro-studio-v1/"
const CENTRO_ART={
 "centro-fonte":["fonte-de-terracota",Vector2(42,80)],
 "centro-jardineira":["bromelia-no-banco",Vector2(22,57)],
 "centro-poste":["poste-de-rua",Vector2(26,85)],
 "centro-bancada":["bancada-de-pipas",Vector2(47,83)],
}
static func build(view)->void:
 for piece:Dictionary in view.model.data.pieces:
  if CENTRO_ART.has(piece.asset):
   centro_piece(view,piece)
   continue
  if piece.asset!="feira-banca":continue
  var node:=Node2D.new()
  node.position=view.model.project(Vector2(piece.u+3,piece.v+2),false)
  node.set_meta("scenery",true);view.actors.add_child(node)
  var feet:=PackedVector2Array()
  for uv:Vector2 in [Vector2(piece.u,piece.v),Vector2(piece.u+3,piece.v),Vector2(piece.u+3,piece.v+2),Vector2(piece.u,piece.v+2)]:feet.append(view.model.project(uv)-node.position)
  var district := str(view.model.data.id)
  if district.begins_with("kronasta-centro-") and not S.geometry():
   preload("res://scripts/overworld/district_architecture.gd").centro_kiosk(node,feet,int(piece.u+piece.v)%2)
   continue
  if district.begins_with("kronasta-centro-") or district.begins_with("kronasta-lajes-"):
   civic_kiosk(node,feet,district.begins_with("kronasta-lajes-"))
   continue
  var roof:=PackedVector2Array()
  var counter:=PackedVector2Array()
  for foot:Vector2 in feet:
   S.line(node,PackedVector2Array([foot,foot-Vector2(0,92)]),5,Color("4b3c36"))
   roof.append(foot-Vector2(0,92));counter.append(foot-Vector2(0,33))
  S.quad(node,PackedVector2Array([counter[1],counter[2],feet[2],feet[1]]),Color("825d42"))
  S.quad(node,PackedVector2Array([counter[2],counter[3],feet[3],feet[2]]),Color("624a3c"))
  S.quad(node,counter,Color("cca170"))
  if not S.geometry():
   for i in 4:
    var c:Vector2=counter[3].lerp(counter[2],.15+i*.2)-Vector2(0,5)
    S.quad(node,PackedVector2Array([c+Vector2(-8,0),c+Vector2(0,-5),c+Vector2(8,0),c+Vector2(0,5)]),Color("e5bd62") if i%2==0 else Color("87a979"))
  var accent:=Color("c9795c")
  if piece.props.get("variante")=="teal":accent=Color("559c9b")
  elif piece.props.get("variante")=="ochre":accent=Color("d3ad57")
  if S.geometry():accent=Color("73868b")
  S.quad(node,roof,accent)
  for i in 6:
   var a:Vector2=roof[0].lerp(roof[1],float(i)/6)
   var b:Vector2=roof[0].lerp(roof[1],float(i+1)/6)
   var c:Vector2=roof[3].lerp(roof[2],float(i+1)/6)
   var d:Vector2=roof[3].lerp(roof[2],float(i)/6)
   if i%2==0:S.quad(node,PackedVector2Array([a,b,c,d]),Color("efe1ba") if not S.geometry() else accent.lightened(.1))
  var edge:=PackedVector2Array([roof[3],roof[2],roof[1]])
  S.line(node,edge,2,Color("443b36"))
  S.quad(node,PackedVector2Array([roof[3],roof[2],roof[2]+Vector2(0,12),roof[3]+Vector2(0,12)]),accent.darkened(.15))

static func centro_piece(view,piece:Dictionary)->void:
 var origin:=Vector2(piece.u,piece.v)
 var footprint:=Vector2(piece.fu,piece.fv)
 var point:=origin+footprint*.5
 var node:=Node2D.new()
 node.position=view.model.project(origin+footprint,false)
 node.set_meta("scenery",true)
 view.actors.add_child(node)
 var foot:Vector2=view.model.project(point)-node.position
 if S.geometry():
  var outline:=PackedVector2Array()
  for corner:Vector2 in [origin,origin+Vector2(footprint.x,0),origin+footprint,origin+Vector2(0,footprint.y)]:
   outline.append(view.model.project(corner)-node.position)
  S.quad(node,outline,Color("658c8b"))
  return
 var spec:Array=CENTRO_ART[piece.asset]
 var texture:Texture2D=load(CENTRO_KIT+spec[0]+".png")
 if texture==null:return
 var shadow:=PackedVector2Array()
 var radius:=Vector2(21,7) if piece.asset=="centro-fonte" else Vector2(11,4)
 for i in 12:
  var angle:=TAU*float(i)/12.0
  shadow.append(foot+Vector2(cos(angle),sin(angle))*radius)
 S.quad(node,shadow,Color(.13,.18,.17,.25))
 var art:=Sprite2D.new()
 art.texture=texture
 art.centered=false
 art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 art.position=foot-spec[1]
 node.add_child(art)

# The kiosk stands inside the same collision footprint as the former stall.
static func civic_kiosk(node:Node2D,feet:PackedVector2Array,residential:bool)->void:
 var top:=PackedVector2Array()
 var height:=82.0 if residential else 104.0
 var wall:=Color("ddd0ad") if residential else Color("d7af87")
 var roof:=Color("537a7b") if residential else Color("885c53")
 if S.geometry():
  wall=Color("899e9f")
  roof=Color("a5b8b4")
 for foot in feet:top.append(foot-Vector2(0,height))
 S.quad(node,PackedVector2Array([top[1],top[2],feet[2],feet[1]]),wall.darkened(.2))
 S.quad(node,PackedVector2Array([top[2],top[3],feet[3],feet[2]]),wall)
 S.quad(node,top,roof)
 for edge in [[1,2],[2,3]]:
  var a:Vector2=top[edge[0]]
  var b:Vector2=top[edge[1]]
  S.line(node,PackedVector2Array([a,b]),3,roof.darkened(.3))
  if S.geometry():continue
  var left:=a.lerp(b,.18)+Vector2(0,22)
  var right:=a.lerp(b,.82)+Vector2(0,22)
  S.quad(node,PackedVector2Array([left,right,right+Vector2(0,32),left+Vector2(0,32)]),Color("355761"))
  S.line(node,PackedVector2Array([left+Vector2(0,32),right+Vector2(0,32)]),3,Color("f1d4aa"))
