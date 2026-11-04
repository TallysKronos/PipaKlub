extends Node2D
## Soulgen's global rest-pivots: parent pose * local pose * artwork transform.
var project:Dictionary={}
var textures:Dictionary={}
var behind:=false
var clock:=0.0
var pose_override:Dictionary={}

func _process(delta:float) -> void:
	if not is_visible_in_tree():return
	clock+=delta;queue_redraw()

func channel(id:String) -> Dictionary:
	if pose_override.has(id):return pose_override[id]
	var clip:Dictionary=project.get("clips",{}).get("idle",{})
	if clip.is_empty():return {}
	var t:=fmod(clock,float(clip.seconds)) if clip.loop else minf(clock,float(clip.seconds))
	var frames:Array=clip.frames
	var a:Dictionary=frames[0]
	var b:Dictionary=frames[-1]
	for index in range(1,frames.size()):
		if t<=float(frames[index].t):
			a=frames[index-1];b=frames[index];break
	var u:=clampf((t-float(a.t))/maxf(.00001,float(b.t)-float(a.t)),0,1)
	if a.get("ease","linear")=="smooth":u=u*u*(3-2*u)
	var av:Dictionary=a.values.get(id,{})
	var bv:Dictionary=b.values.get(id,{})
	var result:Dictionary={}
	for key in ["x","y","rotation","scaleX","scaleY"]:
		var rest:=1.0 if key in ["scaleX","scaleY"] else 0.0
		result[key]=lerpf(float(av.get(key,rest)),float(bv.get(key,rest)),u)
	return result

func pose_transform(value:Dictionary,pivot:Array) -> Transform2D:
	var p:=Vector2(pivot[0],pivot[1])
	var basis:=Transform2D(deg_to_rad(float(value.get("rotation",0))),Vector2.ZERO)
	basis.x*=float(value.get("scaleX",1));basis.y*=float(value.get("scaleY",1))
	basis.origin=p+Vector2(value.get("x",0),value.get("y",0))-basis*p
	return basis

func part_matrix(part:Dictionary,cache:Dictionary,parts:Dictionary) -> Transform2D:
	if cache.has(part.id):return cache[part.id]
	var parent:Transform2D=part_matrix(parts[part.parent],cache,parts) if part.get("parent") else pose_transform(channel("root"),project.rootPivot)
	var result:=parent*pose_transform(channel(part.id),part.pivot)
	cache[part.id]=result
	return result

func _draw() -> void:
	if project.is_empty():return
	var ordered:Array=project.parts.duplicate()
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.z<b.z)
	var parts:Dictionary={}
	for part in ordered:parts[part.id]=part
	var cache:Dictionary={}
	var origin:=Transform2D(0,-Vector2(project.rootPivot[0],project.rootPivot[1]))
	for part in ordered:
		if not part.get("visible",true) or (float(part.z)<0)!=behind:continue
		var art:Dictionary=part.get("artTransform",{})
		var factor:=float(art.get("scale",1))
		var values:Dictionary={"rotation":art.get("rotation",0),"scaleX":factor*(-1 if art.get("flipX",false) else 1),"scaleY":factor*(-1 if art.get("flipY",false) else 1)}
		draw_set_transform_matrix(origin*part_matrix(part,cache,parts)*pose_transform(values,part.pivot))
		var r:Array=part.rect
		var s:Array=part.source
		draw_texture_rect_region(textures[part.asset],Rect2(r[0],r[1],r[2],r[3]),Rect2(s[0],s[1],s[2],s[3]))
	draw_set_transform_matrix(Transform2D.IDENTITY)
