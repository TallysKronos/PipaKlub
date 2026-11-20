extends Node2D

const MINT := Color("#83d9cc")
const FOAM := Color("#d5eee0")
const INK := Color("#241c3d")
const VIOLET := Color("#b36dce")

var mode := "still"
var sprite_has_wake := false
var cast_origin := Vector2(510,-160)
var surfacing_width := 0.0
var body_depth := 0.0
var bank := Vector2.ZERO
var pipeiro := Vector2.ZERO
var progress := 0.0:
 set(value):
  progress=value
  queue_redraw()

func _draw() -> void:
 match mode:
  "reveal":
   var wake:=smoothstep(.04,.65,progress)
   for index in 3:
    var crest:=clampf((progress-.08-index*.065)/.62,0,1)
    if crest>0:
     _ring(9+crest*(145-index*11),MINT,(1.0-crest)*.74,index)
   var murk:=smoothstep(.12,.24,progress)*(1.0-smoothstep(.51,.75,progress))
   draw_set_transform(Vector2(2,18),0,Vector2(1,.21))
   draw_circle(Vector2.ZERO,18+94*wake,Color("#142f32")*Color(1,1,1,murk*.34))
   draw_set_transform(Vector2.ZERO)
   if surfacing_width>0:
    _foam_line()
   _surface_spray(clampf((progress-.49)/.33,0,1),FOAM)
   _ring(102+18*wake,MINT,smoothstep(.5,.82,progress)*.45,0)
  "underwater":
   var position:=Vector2(-92,-19).lerp(Vector2(8,8),progress)
   draw_set_transform(position.round(),.12,Vector2(1,.35))
   draw_circle(Vector2.ZERO,69.0+progress*26.0,Color("#102a31"))
   for index in 4:
    var x:float=-37.0+index*21.0
    draw_colored_polygon(PackedVector2Array([Vector2(x-13,1),Vector2(x,-32),Vector2(x+17,-6),Vector2(x+5,24)]),Color("#24474b"))
   _ring(78+progress*49,MINT,.56*(1.0-progress*.43),1)
  "shore":
   _breaking_wave()
  "breath":
   _breath()
  "ribbon":
   _ribbon()
  "ambush":
   var pressure:=smoothstep(.18,.60,progress)
   _ring(91+36*pressure,VIOLET,.48*(1.0-smoothstep(.87,1.0,progress)),1)
   _surface_spray(clampf((progress-.40)/.42,0,1),Color("#dfa5ef"))
   if progress>.02 and progress<.94:
    _carretel(pressure)
   if progress>=.388 and progress<.64:
    _surviving_jet()
  "settled":
   if not sprite_has_wake:_ring(108+progress*28,MINT,(1.0-progress)*.28,3)
  _:
   _ring(14+progress*48,MINT,(1.0-progress)*.35,4)

func _ring(radius:float,ink:Color,opacity:float,phase:int)->void:
 if opacity<=0:return
 var color:=Color(ink,opacity)
 for index in 24:
  if (index+phase)%5 in [0,1]:continue
  var a:=Vector2.from_angle(TAU*index/24.0)*Vector2(radius,radius*.25)
  var b:=Vector2.from_angle(TAU*(index+1)/24.0)*Vector2(radius,radius*.25)
  draw_line(a.round(),b.round(),color,2 if index in [4,5,6,7,8] else 1)

func _surface_spray(t:float,ink:Color)->void:
 if t<=0 or t>=1:return
 for index in 22:
  var seed:=float((index*37)%19)/18.0
  var facing:=-1.0 if index%2==0 else 1.0
  var x:=facing*(23+seed*48+t*76)
  var y:=8.0-(17+seed*38)*sin(t*PI)
  var point:=Vector2(roundf(x),roundf(y))
  var opacity:=(1.0-t)*(.45+seed*.54)
  draw_rect(Rect2(point,Vector2(2+index%3,1+index%2*2)),Color(ink,opacity))

func _foam_line()->void:
 var width:=surfacing_width
 for index in 17:
  var t:=index/16.0
  var x:=(t*2.0-1.0)*width
  var y:=12.0-roundf(sin(x*.1)*2.0)
  var opacity:=sin(t*PI)*.65*(1.0-smoothstep(.58,.68,progress))
  draw_rect(Rect2(Vector2(roundf(x),y),Vector2(maxf(4,width*.12),3 if index%4==0 else 1)),Color(FOAM,opacity))

func _breaking_wave()->void:
 if progress<=0 or progress>=1:return
 var direction:=bank.normalized()
 var span:=Vector2(-direction.y,direction.x)
 var crest:=bank.lerp(pipeiro,.24)
 var head:=direction*65.0
 var splash:=smoothstep(.55,.74,progress)
 var fade:=1.0-smoothstep(.79,1.0,progress)
 for ring in 3:
  var travel:=clampf((progress-ring*.085)/.67,0,1)
  if travel==0:continue
  var center:=head.lerp(crest,travel)
  var width:=lerpf(29,77,travel)-ring*9
  var ridge:=PackedVector2Array()
  for index in 13:
   var u:=(index-6)/6.0
   ridge.append((center+span*u*width-direction*(u*u*19.0+ring*9.0+3.0*sin(index*2.0))).round())
  var wash:=ridge.duplicate()
  for index in range(11,0,-1):
   var thickness:=sin(PI*index/12.0)*(19.0-ring*3.0)
   wash.append((ridge[index]-direction*thickness).round())
  draw_colored_polygon(wash,Color("#429b8f",fade*(.55 if ring==0 else .35)))
  draw_polyline(ridge,Color("#1d6462",fade*.82),7-ring)
  draw_polyline(ridge,Color(MINT,fade*.94 if ring==0 else fade*.55),3 if ring==0 else 2)
  if ring==0:
   for index in range(1,12,2):
    draw_line(ridge[index],ridge[index+1],Color(FOAM,fade),2)
 if splash>0:
  var wet:=crest.lerp(pipeiro,.53)
  draw_set_transform(wet.round(),0,Vector2(1,.25))
  draw_circle(Vector2.ZERO,41+12*splash,Color("#4f6759",.60*fade))
  draw_set_transform(Vector2.ZERO)
  for index in 20:
   var seed:float=float((index*37)%23)/22.0
   var offset:=span*(seed-.50)*(70.0+splash*98)
   offset+=direction*splash*(11+index%5*5)
   offset.y-=sin(splash*PI)*(12+index%6*4)
   draw_rect(Rect2((crest+offset).round(),Vector2(2+index%3,2)),Color(FOAM,fade))

func _breath()->void:
 var mouth:=Vector2(-104,-49)
 for index in 9:
  var drift:=clampf(progress*1.28-index*.044,0,1)
  if drift<=0 or drift>=1:continue
  var point:=mouth.lerp(mouth.lerp(pipeiro,.42),drift)+Vector2(0,-sin(drift*PI)*21)
  var half_width:=roundf(7+drift*13)
  var opacity:=sin(drift*PI)*.57
  draw_rect(Rect2(point.round(),Vector2(half_width,4)),Color(MINT,opacity))
  draw_rect(Rect2((point+Vector2(3,-2)).round(),Vector2(half_width*.65,2)),Color(FOAM,opacity))

func _ribbon()->void:
 var hand:=pipeiro+Vector2(5,-32)
 draw_rect(Rect2(hand-Vector2(2,1),Vector2(8,4)),Color("#cdab7c"))
 var cord:=PackedVector2Array([hand+Vector2(6,1),hand+Vector2(8,6),hand+Vector2(8,14),hand+Vector2(10,22)])
 draw_polyline(cord,Color("#473540"),3)
 draw_polyline(cord,Color("#e8b966"),1)
 for point in [hand+Vector2(8,8),hand+Vector2(9,17)]:
  draw_colored_polygon(PackedVector2Array([point+Vector2(-5,-3),point,point+Vector2(5,-3),point+Vector2(4,4),point,point+Vector2(-4,4)]),Color("#d79740"))
  draw_rect(Rect2(point-Vector2.ONE,Vector2(2,2)),Color("#fff0a7"))

func _surviving_jet()->void:
 var fall:=smoothstep(.54,.64,progress)
 var size:=1.0-fall
 draw_set_transform(Vector2(10,-108+body_depth),0.0,Vector2(1,size))
 var spray:=PackedVector2Array([Vector2(-4,0),Vector2(-5,-18),Vector2(-11,-33),Vector2(-14,-49),Vector2(-10,-59),Vector2(3,-65),Vector2(14,-60),Vector2(25,-66),Vector2(34,-58),Vector2(33,-46),Vector2(22,-38),Vector2(13,-43),Vector2(7,-28),Vector2(3,-11),Vector2(3,0)])
 draw_colored_polygon(spray,Color("#1a537b"))
 draw_colored_polygon(PackedVector2Array([Vector2(-2,-2),Vector2(-1,-24),Vector2(-9,-40),Vector2(-10,-52),Vector2(1,-59),Vector2(13,-55),Vector2(24,-61),Vector2(30,-52),Vector2(23,-43),Vector2(12,-45),Vector2(3,-29),Vector2(2,-2)]),Color("#39b5dc"))
 draw_colored_polygon(PackedVector2Array([Vector2(-7,-48),Vector2(-7,-54),Vector2(1,-59),Vector2(13,-55),Vector2(22,-60),Vector2(28,-55),Vector2(24,-49),Vector2(14,-50),Vector2(4,-46),Vector2(-2,-50)]),Color("#def6ed"))
 draw_line(Vector2(0,-7),Vector2(2,-35),Color("#9ce9e8"),2)
 draw_set_transform(Vector2.ZERO)

func _carretel(pressure:float)->void:
 var flight:=smoothstep(.02,.42,progress)
 var origin:=cast_origin
 var core:=origin.lerp(Vector2(-42,-106+body_depth),flight)+Vector2(0,-54*sin(flight*PI))
 core=core.round()
 var path:=PackedVector2Array()
 for index in 13:
  var t:=index/12.0
  path.append((origin.lerp(core,t)+Vector2(0,-sin(t*PI)*35*flight)).round())
 draw_polyline(path,Color(INK,.9),5)
 draw_polyline(path,Color(VIOLET,.64),1)
 for index in 3:
  var bind:=smoothstep(.35+index*.12,.45+index*.10,progress)
  if bind>0:
   var p:Vector2=[Vector2(-44,-112),Vector2(-88,-58),Vector2(75,-27)][index]
   p=core.lerp(p,bind)
   var curl:=PackedVector2Array([core,core.lerp(p,.58)+Vector2(-13+index*10,4),p+Vector2(-7,-8),p])
   draw_polyline(curl,INK,5)
   draw_polyline(curl,Color(VIOLET,pressure*.78),2)
 if flight>.98:
  for row in 4:
   draw_line(core+Vector2(-9,row*2-2),core+Vector2(9,row*2-3),INK,3)
   draw_line(core+Vector2(-8,row*2-3),core+Vector2(8,row*2-4),VIOLET,1)
