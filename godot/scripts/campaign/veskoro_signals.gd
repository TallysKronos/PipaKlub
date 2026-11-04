extends RefCounted
const Moves=preload("res://scripts/campaign/veskoro_moves.gd")
static func draw_on(canvas:CanvasItem,v:Dictionary)->void:
	if v.is_empty() or v.phase not in ["warn","active"]:return
	var target:=Vector2(v.aimX,v.aimY)
	var origin:=Vector2(v.originX,v.originY)
	var active:bool=v.phase=="active"
	var purple:=Color("a350d2")
	var edge:=Color("f4e5ff")
	if int(v.cycle)%2==0:
		canvas.draw_circle(target,Moves.RADIUS,Color(.45,.15,.65,.28 if active else .12))
		canvas.draw_arc(target,Moves.RADIUS,0,TAU,64,Color("30213d"),6,true)
		canvas.draw_arc(target,Moves.RADIUS,0,TAU,64,edge,2,true)
		if not active:canvas.draw_arc(target,Moves.RADIUS-8,-PI/2,-PI/2+TAU*clampf(v.elapsed/Moves.WARN,0,1),48,purple,5,true)
		else:
			for i in 3:
				var point:=target+Vector2(-28+i*28,16)
				canvas.draw_line(point,point+Vector2(12,-42),purple,7,true)
	else:
		var normal:Vector2=(target-origin).normalized().orthogonal()*Moves.LANE
		canvas.draw_colored_polygon(PackedVector2Array([origin+normal,target+normal,target-normal,origin-normal]),Color(.45,.15,.65,.25 if active else .10))
		for signum:float in [-1.0,1.0]:
			canvas.draw_line(origin+normal*signum,target+normal*signum,Color("30213d"),5,true)
			canvas.draw_line(origin+normal*signum,target+normal*signum,edge,2,true)
		if active:
			for i in 3:
				var offset:=normal*(i-1)*.6
				canvas.draw_line(origin+offset,target+offset,purple,6,true)
		else:canvas.draw_dashed_line(origin,target,purple,3,12,true)
	canvas.draw_line(target-Vector2(8,0),target+Vector2(8,0),edge,2,true)
	canvas.draw_line(target-Vector2(0,8),target+Vector2(0,8),edge,2,true)
