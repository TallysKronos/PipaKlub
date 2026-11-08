extends RefCounted
## Facades use the same projected corners as the blocking footprint.
const S = preload("res://scripts/overworld/forest_structures.gd")

static func build(node:Node2D, feet:PackedVector2Array, style:String, height:float, variant:int=0) -> void:
	var colors:Dictionary = {
		"lajes":["ddd2bb","496b74","72b6bc"],
		"porto":["78949a","506d77","d5ae58"],
		"palafitas":["a97751","a34f40","68a8a3"],
	}
	var palette:Array = colors[style]
	var wall := Color(palette[0])
	var roof := Color(palette[1])
	var glass := Color(palette[2])
	if style == "palafitas":
		wall=Color(["b78759","7eaaa0","cfaa78"][variant%3])
		roof=Color(["a34f40","446b72","8d6548"][variant%3])
	var top := PackedVector2Array()
	for foot in feet:
		top.append(foot - Vector2(0,height))
	for edge in [[1,2],[2,3]]:
		var a:Vector2 = feet[edge[0]]
		var b:Vector2 = feet[edge[1]]
		var upper_a:Vector2 = top[edge[0]]
		var upper_b:Vector2 = top[edge[1]]
		var raised := 32.0+variant*4.0 if style == "palafitas" else 0.0
		var sill := Vector2(0,raised)
		var face := wall if edge[0] == 2 else wall.darkened(.21)
		if raised > 0:
			for t in [0.0,.5,1.0]:
				var foot := a.lerp(b,t)
				S.line(node,PackedVector2Array([foot,foot-sill]),7,face.darkened(.36))
			S.line(node,PackedVector2Array([a.lerp(b,.18),a.lerp(b,.52)-sill]),3,face.darkened(.35))
			S.line(node,PackedVector2Array([a.lerp(b,.82),a.lerp(b,.49)-sill]),3,face.darkened(.35))
		S.quad(node,PackedVector2Array([upper_a,upper_b,b-sill,a-sill]),face)
		S.line(node,PackedVector2Array([a-sill,b-sill]),3,face.darkened(.32))
		for floor_id in (2 if style == "lajes" else 1):
			var row := Vector2(0,26+floor_id*44)
			for bay in 3:
				var left := upper_a.lerp(upper_b,.12+bay*.27)+row
				var right := upper_a.lerp(upper_b,.28+bay*.27)+row
				var depth := Vector2(0,24)
				S.quad(node,PackedVector2Array([left,right,right+depth,left+depth]),glass.darkened(.22))
				S.line(node,PackedVector2Array([left+depth,right+depth]),2,face.lightened(.26))
				S.line(node,PackedVector2Array([left.lerp(right,.5),left.lerp(right,.5)+depth]),1.5,face.darkened(.35))
		if edge[0] == 2:
			var threshold:=sill+Vector2(0,14 if style=="palafitas" else 0)
			var door_left := a.lerp(b,.39)-threshold
			var door_right := a.lerp(b,.63)-threshold
			var door_height := Vector2(0,36)
			S.quad(node,PackedVector2Array([door_left-door_height,door_right-door_height,door_right,door_left]),roof.darkened(.3))
			S.line(node,PackedVector2Array([door_left-door_height,door_right-door_height]),3,wall.lightened(.22))
		if style == "lajes":
			var balcony := Vector2(0,58)
			for t in [.16,.43,.70]:
				var left := upper_a.lerp(upper_b,t)+balcony
				var right := upper_a.lerp(upper_b,t+.19)+balcony
				S.line(node,PackedVector2Array([left,right]),4,wall.lightened(.3))
		if style == "porto":
			for t in [.06,.33,.66,.94]:
				var anchor := upper_a.lerp(upper_b,t)
				S.line(node,PackedVector2Array([anchor,anchor+Vector2(0,height)]),3,face.darkened(.27))
			if edge[0]==2 and variant!=0:
				panel(node,upper_a,upper_b,.14,.86,75,94,Color("dbc181") if variant==1 else Color("bf744e"))
				panel(node,upper_a,upper_b,.31,.71,103,height-8,Color("30444d"))
				for rail in range(110,int(height)-8,8):
					panel(node,upper_a,upper_b,.32,.70,rail,rail+2,Color("6f898b"))
		if style=="palafitas":
			for row in range(14,int(height-raised)-6,14):
				if row<24 or row>52:
					panel(node,upper_a,upper_b,.06,.94,row,row+1,face.darkened(.18))
	S.quad(node,top,roof)
	for row in 6:
		var t := float(row+1)/7.0
		S.line(node,PackedVector2Array([top[0].lerp(top[3],t),top[1].lerp(top[2],t)]),1.5,roof.lightened(.16))
	var outline := top.duplicate()
	outline.append(top[0])
	S.line(node,outline,2.5,roof.darkened(.34))
	if style=="palafitas" and variant!=0:
		var ridge_a:=top[0].lerp(top[3],.5)-Vector2(0,18+variant*9)
		var ridge_b:=top[1].lerp(top[2],.5)-Vector2(0,18+variant*9)
		S.quad(node,PackedVector2Array([top[0],top[1],ridge_b,ridge_a]),roof.lightened(.15))
		S.quad(node,PackedVector2Array([ridge_a,ridge_b,top[2],top[3]]),roof)
		S.quad(node,PackedVector2Array([top[1],ridge_b,top[2]]),wall.darkened(.23))
		for strip in [.2,.4,.6,.8]:
			S.line(node,PackedVector2Array([top[3].lerp(top[2],strip),ridge_a.lerp(ridge_b,strip),top[0].lerp(top[1],strip)]),1.5,roof.darkened(.26))
		S.line(node,PackedVector2Array([ridge_a,ridge_b]),3,roof.lightened(.26))
	if style=="porto" and variant==2:
		porto_crane(node,top)
	if style=="lajes":
		for t in [.27,.72]:
			var garden:Vector2=top[3].lerp(top[2],t).lerp(top[0].lerp(top[1],t),.34)
			S.quad(node,PackedVector2Array([garden+Vector2(-24,0),garden+Vector2(0,-12),garden+Vector2(24,0),garden+Vector2(0,12)]),Color("d1b385"))
			for offset in [-12,0,12]:
				S.line(node,PackedVector2Array([garden+Vector2(offset,1),garden+Vector2(offset,-10)]),8,Color("587457") if offset else Color("91a767"))


static func porto_crane(node:Node2D,top:PackedVector2Array)->void:
	var base:=top[0].lerp(top[2],.44)
	var arm_end:=top[1].lerp(top[2],.32)-Vector2(0,113)
	var mast:=base-Vector2(0,145)
	var ink:=Color("42494b")
	var ochre:=Color("d69c4f")
	S.quad(node,roof_inset(top,.37),ink)
	S.line(node,PackedVector2Array([base,mast,arm_end]),10,ink)
	S.line(node,PackedVector2Array([base,mast,arm_end]),6,ochre)
	var brace:=base-Vector2(0,70)
	S.line(node,PackedVector2Array([brace,arm_end]),4,ochre)
	for t in [.24,.48,.72]:
		S.line(node,PackedVector2Array([mast.lerp(arm_end,t),brace.lerp(arm_end,t+.18)]),3,ochre.darkened(.2))
	var cab:=brace+Vector2(-16,-20)
	S.quad(node,PackedVector2Array([cab,cab+Vector2(24,-12),cab+Vector2(24,9),cab+Vector2(0,21)]),ink)
	S.quad(node,PackedVector2Array([cab+Vector2(3,2),cab+Vector2(20,-7),cab+Vector2(20,5),cab+Vector2(3,13)]),Color("a0b8aa"))
	var hook:=arm_end+Vector2(0,58)
	S.line(node,PackedVector2Array([arm_end,hook,hook+Vector2(5,4),hook+Vector2(10,0)]),2,ink)

## The frontage is drawn in elevation against the exact blocking footprint.
static func centro(node:Node2D, feet:PackedVector2Array, role:String, height:float) -> void:
	var palettes := {
		"matriz":["e5c699","ab6950","614938"],
		"tv":["699297","345664","bce6de"],
		"liga":["c4ab86","354e65","e9be67"],
		"sobrado":["c49370","8d5045","e4c69b"],
	}
	var palette:Array=palettes[role]
	var wall:=Color(palette[0])
	var roof:=Color(palette[1])
	var trim:=Color(palette[2])
	var top:=PackedVector2Array()
	for foot in feet:
		top.append(foot-Vector2(0,height))
	for index in [1,2]:
		var left:Vector2=top[index]
		var right:Vector2=top[index+1]
		var face:=wall.darkened(.24) if index==1 else wall
		panel(node,left,right,0,1,0,height,face)
		panel(node,left,right,0,1,height-14,height,face.darkened(.30))
		panel(node,left,right,0,1,8,17,face.lightened(.21))
		for side in [0.0,.92]:
			panel(node,left,right,side,side+.08,17,height-14,face.lightened(.15))
		if role=="matriz":
			for x in [.15,.43,.71] if index==1 else [.14,.70]:
				window(node,left,right,x,x+.16,57,124,trim)
			if index==2:
				window(node,left,right,.37,.63,89,height-14,trim)
				window(node,left,right,.43,.57,33,61,trim)
		elif role=="tv":
			window(node,left,right,.10,.90,43,102,Color("29434d"))
			for x in [.25,.50,.75]:
				panel(node,left,right,x,x+.018,43,102,Color("95b1ab"))
			if index==2:
				panel(node,left,right,.16,.48,106,145,Color("263c49"))
				panel(node,left,right,.19,.45,110,141,trim)
				var screen:=left.lerp(right,.32)+Vector2(0,126)
				S.quad(node,PackedVector2Array([screen+Vector2(-14,0),screen+Vector2(0,-9),screen+Vector2(14,0),screen+Vector2(0,9)]),Color("345664"))
				window(node,left,right,.56,.85,117,height-14,trim)
		else:
			for x in [.15,.41,.67]:
				window(node,left,right,x,x+.17,36,78,trim)
			panel(node,left,right,.08,.92,88,95,face.darkened(.21))
			window(node,left,right,.17,.34,108,144,trim)
			window(node,left,right,.51,.82,103,height-14,trim)
			if index==2 and role=="liga":
				panel(node,left,right,.11,.88,82,100,roof)
				for x in [.20,.47,.74]:
					panel(node,left,right,x,x+.045,101,height-14,trim)
		var outline:=PackedVector2Array([left,left+Vector2(0,height),right+Vector2(0,height)])
		S.line(node,outline,2,face.darkened(.35))
	S.quad(node,top,roof)
	for row in 9:
		var t:=float(row+1)/10.0
		S.line(node,PackedVector2Array([top[0].lerp(top[3],t),top[1].lerp(top[2],t)]),2,roof.lightened(.18))
	S.line(node,PackedVector2Array([top[0],top[1],top[2],top[3],top[0]]),3,roof.darkened(.35))
	if role=="matriz":
		bell_tower(node,feet,height)
	elif role=="tv":
		var base:Vector2=(top[0]+top[2])*.5
		var mast:=base-Vector2(0,69)
		S.line(node,PackedVector2Array([base,mast]),6,Color("334a52"))
		for offset in [8,20,32]:
			var beam:=mast+Vector2(0,offset)
			S.line(node,PackedVector2Array([beam-Vector2(27,13.5),beam+Vector2(27,13.5)]),3,trim)

## Portaria e clube reaproveitam o perímetro bloqueado do prédio original.
static func lajes_landmark(node:Node2D,feet:PackedVector2Array,pool:bool)->void:
	var height:=62.0 if pool else 93.0
	var top:=PackedVector2Array()
	for foot in feet:
		top.append(foot-Vector2(0,height))
	for index in [1,2]:
		var a:Vector2=top[index]
		var b:Vector2=top[index+1]
		var wall:=Color("c5c0a7") if index==1 else Color("e1d8bb")
		panel(node,a,b,0,1,0,height,wall)
		panel(node,a,b,0,1,0,9,Color("57747a"))
		panel(node,a,b,0,1,height-9,height,wall.darkened(.23))
		if not pool:
			window(node,a,b,.12,.64,23,60,Color("4d686c"))
			window(node,a,b,.72,.89,23,height-9,Color("4d686c"))
			panel(node,a,b,.11,.90,10,19,Color("b78850"))
	S.quad(node,top,Color("cec7ab"))
	if pool:
		S.quad(node,roof_inset(top,.14),Color("f0e7c9"))
		S.quad(node,roof_inset(top,.20),Color("316b83"))
		var water:=roof_inset(top,.23)
		S.quad(node,water,Color("529da7"))
		for row in [.19,.47,.73]:
			var start:Vector2=water[0].lerp(water[3],row)
			var end:Vector2=water[1].lerp(water[2],row)
			S.line(node,PackedVector2Array([start.lerp(end,.12),start.lerp(end,.43),start.lerp(end,.51)]),2,Color("8dc6c0"))
		var ladder:Vector2=water[2].lerp(water[3],.36)
		for offset in [-5.0,5.0]:
			var rail:=ladder+Vector2(offset,offset*.5)
			S.line(node,PackedVector2Array([rail+Vector2(-3,5),rail-Vector2(0,15),rail+Vector2(5,-16)]),2,Color("e9e2cb"))
		S.line(node,PackedVector2Array([ladder+Vector2(-5,-5),ladder+Vector2(5,0)]),2,Color("e9e2cb"))
	else:
		S.quad(node,roof_inset(top,.08),Color("647f83"))
		S.quad(node,roof_inset(top,.15),Color("a9b1a4"))
	var outline:=top.duplicate()
	outline.append(top[0])
	S.line(node,outline,3,Color("818779"))

static func roof_inset(top:PackedVector2Array,inset:float)->PackedVector2Array:
	var center:Vector2=(top[0]+top[2])*.5
	var inner:=PackedVector2Array()
	for point in top:
		inner.append(point.lerp(center,inset*2.0))
	return inner

static func centro_kiosk(node:Node2D,feet:PackedVector2Array,variant:int)->void:
	var canopy:=Color("80524b") if variant==0 else Color("436d70")
	var top:=PackedVector2Array()
	for foot in feet:
		top.append(foot-Vector2(0,84))
	for index in [1,2]:
		var left:Vector2=top[index]
		var right:Vector2=top[index+1]
		var wall:=Color("c5a47f").darkened(.19) if index==1 else Color("e2bd91")
		panel(node,left,right,0,1,0,84,wall)
		panel(node,left,right,0,1,0,12,canopy)
		panel(node,left,right,0,1,75,84,wall.darkened(.25))
		if index==1:
			window(node,left,right,.2,.8,28,56,wall.lightened(.2))
		else:
			window(node,left,right,.13,.56,25,57,wall.lightened(.25))
			window(node,left,right,.63,.90,24,75,canopy)
			panel(node,left,right,.11,.59,54,61,canopy)
	S.quad(node,top,canopy.darkened(.1))
	for t in [.24,.48,.72]:
		S.line(node,PackedVector2Array([top[0].lerp(top[3],t),top[1].lerp(top[2],t)]),2,canopy.lightened(.2))

static func panel(node:Node2D,left:Vector2,right:Vector2,x0:float,x1:float,y0:float,y1:float,color:Color)->void:
	var a:=left.lerp(right,x0)
	var b:=left.lerp(right,x1)
	S.quad(node,PackedVector2Array([a+Vector2(0,y0),b+Vector2(0,y0),b+Vector2(0,y1),a+Vector2(0,y1)]),color)

static func window(node:Node2D,left:Vector2,right:Vector2,x0:float,x1:float,y0:float,y1:float,trim:Color)->void:
	panel(node,left,right,x0,x1,y0,y1,trim)
	panel(node,left,right,x0+.015,x1-.015,y0+4,y1-4,Color("253f4e"))
	panel(node,left,right,x0+.027,x1-.027,y0+6,y0+13,Color("7b9ca0"))
	var center:=(x0+x1)*.5
	panel(node,left,right,center-.006,center+.006,y0+4,y1-4,trim)

static func bell_tower(node:Node2D,feet:PackedVector2Array,height:float)->void:
	var top:=PackedVector2Array()
	for point in [feet[0].lerp(feet[1],.56),feet[1],feet[1].lerp(feet[2],.42),feet[0].lerp(feet[1],.56).lerp(feet[3].lerp(feet[2],.56),.42)]:
		top.append(point-Vector2(0,height))
	var peak:=PackedVector2Array()
	for point in top:peak.append(point-Vector2(0,73))
	S.quad(node,PackedVector2Array([peak[1],peak[2],top[2],top[1]]),Color("aa805d"))
	S.quad(node,PackedVector2Array([peak[2],peak[3],top[3],top[2]]),Color("dfbc8d"))
	var bell := peak[2].lerp(peak[3],.5)+Vector2(0,29)
	S.line(node,PackedVector2Array([bell-Vector2(0,12),bell+Vector2(0,15)]),14,Color("594034"))
	S.line(node,PackedVector2Array([bell-Vector2(0,6),bell+Vector2(0,10)]),7,Color("daa559"))
	var tip:Vector2=(peak[0]+peak[2])*.5-Vector2(0,46)
	S.quad(node,PackedVector2Array([peak[0],peak[1],peak[2],peak[3]]),Color("a76453"))
	for index in 4:
		S.quad(node,PackedVector2Array([peak[index],peak[(index+1)%4],tip]),Color("bd7457") if index==2 else Color("925147"))
	S.line(node,PackedVector2Array([tip,tip-Vector2(0,18)]),3,Color("55443f"))
	S.line(node,PackedVector2Array([tip+Vector2(-6,-12),tip+Vector2(6,-12)]),3,Color("55443f"))
