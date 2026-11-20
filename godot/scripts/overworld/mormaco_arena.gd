extends RefCounted
## Shared deck and cast marks. Coordinates are in the lake's 2:1 map grid.
const DECK_ORIGIN := Vector2(29.62,7.96)
const DECK_SIZE := Vector2(4.98,2.92)
const DECK_Z := 94.0
const CAST_POINT := Vector2(32.58,10.53)
const HAND := Vector2(-15,-33)
const METAL := Color("#24435b")
const EDGE := Color("#426e82")
const LIGHT := Color("#9dc1bd")

static func cast_foot(model)->Vector2:
 if model.data.has("celLake"):
  var mark:Array=model.data.celLake.caster
  return Vector2(mark[0],mark[1])
 return model.project(CAST_POINT,false)-Vector2(0,DECK_Z)

static func build(view,make_node:Callable,quad:Callable,line:Callable,platform:Callable,depth:float):
 var deck:Node2D=make_node.call(view,DECK_ORIGIN+DECK_SIZE)
 deck.name="PlataformaMormaco"
 var catwalk:=Rect2(DECK_ORIGIN+Vector2(DECK_SIZE.x,1.22),Vector2(3.14,1.34))
 for slab in [Rect2(DECK_ORIGIN,DECK_SIZE),catwalk]:
  var at:Vector2=slab.position
  var size:Vector2=slab.size
  var supports:=[at+Vector2(.29,size.y-.24),at+size-Vector2(.28,.24),at+Vector2(size.x-.28,.23)]
  for foot:Vector2 in supports:
   var water:bool=view.model.cell_at(Vector2i(foot)).get("material")=="agua"
   var ground:float=depth-6.0 if water else view.model.height_at(foot)*64.0
   var base:=depth+10.0 if water else ground+12.0
   platform.call(deck,foot-Vector2(.24,.22),Vector2(.48,.44),base-4,ground,Color("#757f70"),Color("#535f59"),Color("#42545a"))
   platform.call(deck,foot-Vector2(.20,.18),Vector2(.40,.36),base,base-4,Color("#a1a693"),Color("#747e76"),Color("#586860"))
   platform.call(deck,foot-Vector2(.075,.075),Vector2(.15,.15),DECK_Z-6,base,LIGHT,METAL,Color("#20304a"))
   line.call(deck,[[foot,DECK_Z-12],[foot+Vector2(.24,-.40),DECK_Z-34]],EDGE,3)
  platform.call(deck,at,size,DECK_Z,DECK_Z-8,Color("#acaa99"),METAL,Color("#1e3044"))
  for index in range(1,ceili(size.x/.27)):
   var cut:=at+Vector2(index*.27,0)
   line.call(deck,[[cut,DECK_Z],[cut+Vector2(0,size.y),DECK_Z]],Color("#7f857f"),1)
   line.call(deck,[[cut+Vector2(.043,0),DECK_Z],[cut+Vector2(.043,size.y),DECK_Z]],Color("#c7c3af"),1)
  var lip:=at+Vector2(0,size.y)
  line.call(deck,[[lip,DECK_Z],[lip+Vector2(size.x,0),DECK_Z]],LIGHT,2)
  for index in range(0,ceili(size.x/.37)):
   var mark:=lip+Vector2(.08+index*.37,-.16)
   line.call(deck,[[mark,DECK_Z],[mark+Vector2(.16,.088),DECK_Z]],Color("#d4ac51"),2)
 var a:=DECK_ORIGIN
 var b:=a+Vector2(DECK_SIZE.x,0)
 var c:=a+DECK_SIZE
 var d:=a+Vector2(0,DECK_SIZE.y)
 _rail(deck,a,b,line)
 _rail(deck,a,d,line)
 _rail(deck,b,b+Vector2(0,1.22),line)
 _rail(deck,c,c-Vector2(0,.36),line)
 _rail(deck,d,d+Vector2(1.47,0),line)
 _rail(deck,d+Vector2(3.90,0),c,line)
 _rail(deck,catwalk.position,catwalk.position+Vector2(catwalk.size.x,0),line)
 _rail(deck,catwalk.position+Vector2(0,catwalk.size.y),catwalk.end,line)
 _instruments(deck,a+Vector2(.55,.50),quad,line,platform)
 _seep(view,make_node,quad,line,depth)
 _floating_plants(view,make_node,quad,line,depth)
 _resting_shelf(view,make_node,quad,line,depth)

static func _rail(deck:Node2D,a:Vector2,b:Vector2,line:Callable):
 var count:=maxi(1,ceili(a.distance_to(b)/.90))
 for index in count+1:
  var foot:=a.lerp(b,float(index)/count)
  line.call(deck,[[foot,DECK_Z],[foot,DECK_Z+24]],METAL,4)
  line.call(deck,[[foot+Vector2(-.035,0),DECK_Z+3],[foot+Vector2(-.035,0),DECK_Z+22]],LIGHT,1)
 for z in [DECK_Z+11,DECK_Z+24]:
  line.call(deck,[[a,z],[b,z]],METAL,4)
  line.call(deck,[[a,z+1],[b,z+1]],EDGE,2)

static func _instruments(deck:Node2D,at:Vector2,quad:Callable,line:Callable,platform:Callable):
 var cabinet:=Vector2(1.0,.74)
 platform.call(deck,at,cabinet,DECK_Z+34,DECK_Z,Color("#e2d9bb"),Color("#bdb7a0"),Color("#8e998e"))
 var face:=at+Vector2(.08,cabinet.y+.01)
 for index in 4:
  var z:=DECK_Z+8+index*4.0
  line.call(deck,[[face,z],[face+Vector2(.27,0),z]],Color("#687b7c"),1)
 line.call(deck,[[face+Vector2(.65,0),DECK_Z+14],[face+Vector2(.65,0),DECK_Z+25]],METAL,2)
 var screen:=at+Vector2(1.16,.19)
 platform.call(deck,screen,Vector2(1.25,.40),DECK_Z+57,DECK_Z+15,Color("#718681"),METAL,Color("#192e43"))
 var p:=screen+Vector2(.10,.41)
 var q:=p+Vector2(1.05,0)
 quad.call(deck,[[p,DECK_Z+51],[q,DECK_Z+51],[q,DECK_Z+25],[p,DECK_Z+25]],Color("#163746"))
 line.call(deck,[[p,DECK_Z+50],[q,DECK_Z+50]],Color("#75bab1"),1)
 var scope:=[]
 for index in 8:scope.append([p+Vector2(.10+index*.121,0),DECK_Z+34+[0,4,-1,8,1,5,2,9][index]])
 line.call(deck,scope,Color("#79e2d5"),2)
 for index in 3:line.call(deck,[[p+Vector2(.12+index*.14,0),DECK_Z+28],[p+Vector2(.17+index*.14,0),DECK_Z+28]],LIGHT,1)
 var pole:=at+Vector2(.34,.10)
 line.call(deck,[[pole,DECK_Z+34],[pole,DECK_Z+82]],METAL,4)
 line.call(deck,[[pole+Vector2(-.035,0),DECK_Z+34],[pole+Vector2(-.035,0),DECK_Z+81]],LIGHT,1)
 for index in 5:
  platform.call(deck,pole-Vector2(.15,.15),Vector2(.30,.30),DECK_Z+48+index*3,DECK_Z+46+index*3,Color("#e4dfc8"),LIGHT,EDGE)
 var solar:=at+Vector2(2.08,-.17)
 line.call(deck,[[solar,DECK_Z],[solar,DECK_Z+86]],METAL,4)
 var q1:=solar-Vector2(.57,.29)
 var q2:=solar+Vector2(.57,-.29)
 var q3:=solar+Vector2(.57,.43)
 var q4:=solar+Vector2(-.57,.43)
 quad.call(deck,[[q1,DECK_Z+90],[q2,DECK_Z+90],[q3,DECK_Z+79],[q4,DECK_Z+79]],Color("#294e77"))
 line.call(deck,[[q1,DECK_Z+90],[q2,DECK_Z+90],[q3,DECK_Z+79],[q4,DECK_Z+79],[q1,DECK_Z+90]],LIGHT,2)
 for index in range(1,4):
  line.call(deck,[[q1.lerp(q2,index*.25),DECK_Z+90],[q4.lerp(q3,index*.25),DECK_Z+79]],Color("#799ba3"),1)

static func _seep(view,make_node:Callable,quad:Callable,line:Callable,depth:float):
 var at:=Vector2(27.7,8.32)
 var n:Node2D=make_node.call(view,at)
 n.z_index=0
 var lip:=at+Vector2(-.16,.32)
 var foot:=at+Vector2(-.30,.52)
 var left:=Vector2(-.115,.025)
 var right:=Vector2(.11,-.015)
 var upper_left:=at+Vector2(-.31,-.07)
 var upper_right:=at+Vector2(.28,.03)
 quad.call(n,[[upper_left,53],[upper_right,53],[upper_right+Vector2(0,.16),51],[upper_left+Vector2(0,.16),51]],Color("#789264"))
 quad.call(n,[[at+left,52],[at+right,52],[lip+right,2],[lip+left,2]],Color("#649e99",.91))
 quad.call(n,[[lip+left,3],[lip+right,3],[foot+right,depth+4],[foot+left,depth+4]],Color("#83b8b1",.80))
 line.call(n,[[at,51],[at+Vector2(-.03,.16),27],[lip,2],[foot,depth+5]],Color("#c3e3d7",.89),2)
 line.call(n,[[foot+Vector2(-.25,-.03),depth+3],[foot+Vector2(.20,-.01),depth+3]],Color("#8bcabd"),2)
 line.call(n,[[foot+Vector2(-.32,.10),depth],[foot+Vector2(.34,.12),depth]],Color("#4f9690"),1)

static func _floating_plants(view,make_node:Callable,quad:Callable,line:Callable,depth:float):
 var n:Node2D=make_node.call(view,Vector2.ZERO)
 n.z_index=-4
 for origin in [Vector2(16.8,15.6),Vector2(18,12.55),Vector2(29.6,20.8),Vector2(31.45,18.7)]:
  for index in 7:
   var a:Vector2=origin+Vector2.from_angle(index*2.39)*(index*.1)
   var r:=.12+float(index%3)*.055
   var lip:=r*.54
   var p:=[a+Vector2(-r,0),a+Vector2(-lip,-r),a+Vector2(lip,-r),a+Vector2(r,0),a+Vector2(lip,r),a,a+Vector2(-lip,r)]
   var points:=[]
   for vertex in p:points.append([vertex,depth+1])
   quad.call(n,points,Color("#77894f") if index%2==0 else Color("#5d804b"))
   line.call(n,[[p[0],depth+1],[p[1],depth+1],[p[2],depth+1]],Color("#96ab5b"),1)
  line.call(n,[[origin+Vector2(.18,.32),depth+3],[origin+Vector2(.29,.25),depth+7],[origin+Vector2(.37,.37),depth+3]],Color("#d29baa"),3)

static func _resting_shelf(view,make_node:Callable,quad:Callable,line:Callable,depth:float):
 var n:Node2D=make_node.call(view,Vector2.ZERO)
 n.z_index=-4
 # Exposed blocks along the submerged ridge in the water material.
 for data in [[Vector2(21.67,17.58),.62,7.0],[Vector2(21.72,18.28),.72,9.0],[Vector2(22.1,18.97),.86,8.0],[Vector2(22.77,19.71),.8,10.0],[Vector2(23.66,19.92),.78,11.0],[Vector2(24.48,19.82),.68,7.0],[Vector2(25.33,19.66),.74,9.0],[Vector2(26.20,19.35),.54,7.0],[Vector2(26.70,18.67),.62,6.0],[Vector2(27.1,17.9),.68,5.0],[Vector2(26.7,16.8),.54,4.0],[Vector2(25.57,20.28),.31,3.0],[Vector2(23.74,20.44),.36,5.0],[Vector2(22.22,19.58),.3,4.0]]:
  var at:Vector2=data[0]
  var size:float=data[1]
  var rise:float=data[2]
  var a:=at+Vector2(-.58,-.4)*size
  var b:=at+Vector2(.37,-.55)*size
  var c:=at+Vector2(.74,.02)*size
  var d:=at+Vector2(.34,.52)*size
  var e:=at+Vector2(-.53,.43)*size
  var z:=depth+rise
  quad.call(n,[[e,z],[d,z],[c,z],[c,depth],[d,depth],[e,depth]],Color("#58665b"))
  quad.call(n,[[a,z],[b,z+2],[c,z],[d,z],[e,z]],Color("#82907a") if rise>7 else Color("#637c68"))
  line.call(n,[[a,z],[b,z+2],[c,z]],Color("#afad88"),1)
  line.call(n,[[a.lerp(e,.53),z],[at+Vector2(-.04,.05),z+1],[d.lerp(c,.27),z],[d.lerp(c,.27),z-3]],Color("#6a7a66"),1)
