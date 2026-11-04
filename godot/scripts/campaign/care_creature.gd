extends Node2D
## Approved Soulgen cutouts, animated around the original hierarchy/pivots.
var rig:Dictionary={}
var textures:Dictionary={}
var parts:Dictionary={}
var ordered:Array=[]
var foot:=Vector2.ZERO
var native_height:=150.0
var pose:="idle"
var clock:=0.0
var left:=false
var reduced_motion:=false
var atlas:Sprite2D
var atlas_frames:Array=[]
func configure(model_id:String) -> void:
	var registry:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/care-room-v1/rigs.json"))
	if registry.has(model_id):
		rig=JSON.parse_string(FileAccess.get_file_as_string(registry[model_id]))
		var bounds:=Rect2()
		for part in rig.parts:
			parts[part.id]=part;ordered.append(part)
			var r:Array=part.rect;var rect:=Rect2(r[0],r[1],r[2],r[3])
			bounds=rect if bounds.size==Vector2.ZERO else bounds.merge(rect)
		for id in rig.assets:textures[id]=load(rig.assets[id].src)
		ordered.sort_custom(func(a,b):return a.z<b.z)
		foot=Vector2(bounds.get_center().x,bounds.end.y);native_height=bounds.size.y
	else:
		var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
		var id:String={"basica":"basic-carcara"}.get(model_id,model_id)
		var art:Dictionary=catalog.combat.get(id,catalog.combat.rabbito)
		atlas=Sprite2D.new();atlas.region_enabled=true;atlas.texture=load("res://assets/campaign/"+art.image)
		atlas_frames=art.animations.idle;var frame:Dictionary=atlas_frames[0]
		atlas.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
		var bounds:=atlas.texture.get_image().get_region(Rect2i(atlas.region_rect)).get_used_rect()
		atlas.offset=Vector2(frame.w*.5-bounds.get_center().x,frame.h*.5-bounds.end.y)
		native_height=bounds.size.y;add_child(atlas)
func animate(delta:float) -> void:
	clock+=delta
	if atlas!=null:
		var frame:Dictionary=atlas_frames[int(clock*8)%atlas_frames.size()]
		atlas.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h);atlas.flip_h=left
	queue_redraw()
func local_transform(id:String) -> Transform2D:
	var pivot:Array=parts[id].pivot
	var angle:=0.0;var shift:=Vector2.ZERO;var stretch:=Vector2.ONE
	if not reduced_motion:
		var wave:=sin(clock*(9.0 if pose=="walk" else 2.2))
		if id=="head":angle=wave*(.08 if pose=="pet" else .018)
		if id.to_lower().contains("ear"):angle=sin(clock*4.0+float(parts[id].z))*(.11 if pose=="pet" else .025)
		if id.to_lower().contains("tail"):angle=sin(clock*3.0)*.06
		if pose=="walk" and id.to_lower().contains("arm"):angle=wave*.1
		if id.to_lower().contains("wing"):angle=sin(clock*(6 if pose=="walk" else 2.2))*(.12 if pose=="walk" else .025)
	var t:=Transform2D(angle,stretch,0,Vector2(pivot[0],pivot[1])+shift)
	t.origin-=t*Vector2(pivot[0],pivot[1])-t.origin
	return t
func matrix(id:String,cache:Dictionary) -> Transform2D:
	if cache.has(id):return cache[id]
	var p:Dictionary=parts[id]
	var parent:=Transform2D.IDENTITY
	if p.get("parent")!=null and parts.has(p.parent):parent=matrix(p.parent,cache)
	cache[id]=parent*local_transform(id)
	return cache[id]
func _draw() -> void:
	if rig.is_empty():return
	var hop:=maxf(0,sin(clock*9))*6 if pose=="walk" and not reduced_motion else 0.0
	var breath:=sin(clock*2.2)*.7 if not reduced_motion else 0.0
	var origin:=Transform2D(0,Vector2(-1 if left else 1,.94 if pose=="rest" else 1),0,Vector2(0,-hop+breath))
	origin.origin-=origin*foot-origin.origin
	var cache:Dictionary={}
	for p in ordered:
		if not p.get("visible",true):continue
		var t:Transform2D=origin*matrix(p.id,cache)
		var art:Dictionary=p.get("artTransform",{})
		if not art.is_empty():
			var pivot:=Vector2(p.pivot[0],p.pivot[1]);var s:float=art.get("scale",1.0)
			var a:=Transform2D(deg_to_rad(art.get("rotation",0)),Vector2(s*(-1 if art.get("flipX",false) else 1),s*(-1 if art.get("flipY",false) else 1)),0,pivot)
			a.origin-=a*pivot-a.origin;t=t*a
		draw_set_transform_matrix(t)
		var r:Array=p.rect;var source:Array=p.source
		draw_texture_rect_region(textures[p.asset],Rect2(r[0],r[1],r[2],r[3]),Rect2(source[0],source[1],source[2],source[3]))
	draw_set_transform_matrix(Transform2D.IDENTITY)
