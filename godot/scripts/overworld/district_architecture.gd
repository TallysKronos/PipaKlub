extends RefCounted
## Facades use the same projected corners as the blocking footprint.
const S = preload("res://scripts/overworld/forest_structures.gd")

static func build(node:Node2D, feet:PackedVector2Array, style:String, height:float) -> void:
	var colors:Dictionary = {
		"centro":["d4aa79","8b554c","497477"],
		"lajes":["ddd2bb","496b74","72b6bc"],
		"porto":["78949a","506d77","d5ae58"],
		"palafitas":["a97751","a34f40","68a8a3"],
	}
	var palette:Array = colors[style]
	var wall := Color(palette[0])
	var roof := Color(palette[1])
	var glass := Color(palette[2])
	var top := PackedVector2Array()
	for foot in feet:
		top.append(foot - Vector2(0,height))
	for edge in [[1,2],[2,3]]:
		var a:Vector2 = feet[edge[0]]
		var b:Vector2 = feet[edge[1]]
		var upper_a:Vector2 = top[edge[0]]
		var upper_b:Vector2 = top[edge[1]]
		var raised := 38.0 if style == "palafitas" else 0.0
		var sill := Vector2(0,raised)
		var face := wall if edge[0] == 2 else wall.darkened(.21)
		if raised > 0:
			for t in [0.0,.5,1.0]:
				var foot := a.lerp(b,t)
				S.line(node,PackedVector2Array([foot,foot-sill]),7,face.darkened(.36))
		S.quad(node,PackedVector2Array([upper_a,upper_b,b-sill,a-sill]),face)
		S.line(node,PackedVector2Array([a-sill,b-sill]),3,face.darkened(.32))
		for floor_id in (2 if style == "lajes" or style == "centro" else 1):
			var row := Vector2(0,26+floor_id*44)
			for bay in 3:
				var left := upper_a.lerp(upper_b,.12+bay*.27)+row
				var right := upper_a.lerp(upper_b,.28+bay*.27)+row
				var depth := Vector2(0,24)
				S.quad(node,PackedVector2Array([left,right,right+depth,left+depth]),glass.darkened(.22))
				S.line(node,PackedVector2Array([left+depth,right+depth]),2,face.lightened(.26))
				S.line(node,PackedVector2Array([left.lerp(right,.5),left.lerp(right,.5)+depth]),1.5,face.darkened(.35))
		if edge[0] == 2:
			var door_left := a.lerp(b,.39)-sill
			var door_right := a.lerp(b,.63)-sill
			var door_height := Vector2(0,36)
			S.quad(node,PackedVector2Array([door_left-door_height,door_right-door_height,door_right,door_left]),roof.darkened(.3))
			S.line(node,PackedVector2Array([door_left-door_height,door_right-door_height]),3,wall.lightened(.22))
		if style == "lajes":
			var balcony := Vector2(0,58)
			for t in [.16,.43,.70]:
				var left := upper_a.lerp(upper_b,t)+balcony
				var right := upper_a.lerp(upper_b,t+.19)+balcony
				S.line(node,PackedVector2Array([left,right]),4,wall.lightened(.3))
		if style == "centro":
			var cornice := Vector2(0,16)
			S.line(node,PackedVector2Array([upper_a+cornice,upper_b+cornice]),4,wall.lightened(.23))
		if style == "porto":
			for t in [.06,.33,.66,.94]:
				var anchor := upper_a.lerp(upper_b,t)
				S.line(node,PackedVector2Array([anchor,anchor+Vector2(0,height)]),3,face.darkened(.27))
	S.quad(node,top,roof)
	for row in 6:
		var t := float(row+1)/7.0
		S.line(node,PackedVector2Array([top[0].lerp(top[3],t),top[1].lerp(top[2],t)]),1.5,roof.lightened(.16))
	var outline := top.duplicate()
	outline.append(top[0])
	S.line(node,outline,2.5,roof.darkened(.34))

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
