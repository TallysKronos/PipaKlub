extends "res://scripts/campaign/care_creature.gd"
## One-shot performance of the approved Lacertubo cutout; no new anatomy.
var performance:=0.0
func local_transform(id:String) -> Transform2D:
	var base:=super.local_transform(id)
	if reduced_motion:return base
	var tension:=smoothstep(2.0,3.1,performance)*(1-smoothstep(6.5,7.4,performance))
	var angle:=0.0
	var offset:=Vector2.ZERO
	if id=="sail":angle=-.16*tension
	if id=="head":angle=-.10*tension;offset=Vector2(-2,-2)*tension
	if id=="tail":angle=sin(performance*3)*.08*tension
	if id=="body":offset=Vector2(0,-3)*tension
	var pivot:=Vector2(parts[id].pivot[0],parts[id].pivot[1])
	var t:=Transform2D(angle,pivot+offset);t.origin-=t.basis_xform(pivot)
	return base*t
func perform(time:float) -> void:
	performance=time
	if parts.has("head"):
		var head:Dictionary=parts.head
		if not head.has("rest_source"):head.rest_source=head.source.duplicate()
		head.source=head.faces.fierce.source if time>=3.0 and time<6.8 else head.rest_source
		head.asset="expressions" if time>=3.0 and time<6.8 else "parts"
	animate(0)
