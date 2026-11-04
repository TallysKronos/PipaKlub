extends Node2D
## World-space chevrons, flight shadows and landing rings; no clickable hotspots.
var view:Node2D
func _draw() -> void:
	if view==null:return
	for entry:Dictionary in view.model.data.mobility.links:
		var a:Vector2=view.model.project(Vector2(entry.from[0],entry.from[1]))
		var b:Vector2=view.model.project(Vector2(entry.to[0],entry.to[1]))
		var dir:Vector2=(b-a).normalized()
		var side:=dir.orthogonal()
		var strength:float=.85 if view.player.distance_to(Vector2(entry.from[0],entry.from[1]))<1.2 else .45
		var color:=Color(.35,.85,1,strength)
		for n in 2:
			var at:Vector2=a+dir*(3+n*8)
			draw_polyline(PackedVector2Array([at-dir*6+side*5,at,at-dir*6-side*5]),Color(.06,.17,.23,strength),4,true)
			draw_polyline(PackedVector2Array([at-dir*6+side*5,at,at-dir*6-side*5]),color,2,true)
	for event:Dictionary in view.model.data.events:
		if event.type!="item":continue
		var point:=Vector2(event.u+.5,event.v+.5)
		if event.props.get("visibilidade","")=="escondido" and view.player.distance_to(point)>2:continue
		var at:Vector2=view.model.project(point)-Vector2(0,8)
		var points:=PackedVector2Array()
		for n in 8:
			var angle:float=PI*n/4
			points.append(at+Vector2(cos(angle),sin(angle))*(7 if n%2==0 else 2))
		draw_colored_polygon(points,Color("f5dc8a"))
	if view.traversal.active:
		for partner in [false,true]:
			var pose:Dictionary=view.traversal.sample(partner)
			var at:Vector2=view.model.project(pose.point)
			draw_set_transform(at,0,Vector2(1,.4))
			draw_circle(Vector2.ZERO,11 if partner else 15,Color(0,0,0,.23))
			if pose.landed:
				var age:float=(pose.local-view.Traversal.WINDUP-view.Traversal.FLIGHT)/view.Traversal.LANDING
				if age<1:draw_arc(Vector2.ZERO,12+age*20,0,TAU,24,Color(.9,.85,.65,(1-age)*.65),2,true)
			draw_set_transform(Vector2.ZERO)
