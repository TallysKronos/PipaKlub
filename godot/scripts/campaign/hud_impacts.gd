extends RefCounted
const T = preload("res://scripts/campaign/ui_tokens.gd")
const Paint = preload("res://scripts/campaign/recorte_ink.gd")
const Signals = preload("res://scripts/campaign/battle_signals.gd")
## Confirmed events only; temporary paint and lettering never modify combat state.
var bursts: Array[Dictionary] = []
var reduced_motion := false
var protected_points: Array[Vector2] = []
var suppress_secondary := false
var visible_rect := Rect2()
var serial := 0
var last_labels: Array[Rect2] = []
func add(event:Dictionary) -> void:
	if event.get("amount",0)<=0 and event.get("kind","") not in ["evade","block"]:return
	var burst := event.duplicate()
	burst.age=0.0;burst.serial=serial;serial+=1
	bursts.append(burst)
	if bursts.size()>3:bursts.pop_front()
func step(delta:float) -> void:
	for burst in bursts:burst.age+=delta
	bursts=bursts.filter(func(burst:Dictionary):return burst.age<(.08 if reduced_motion else .6))
func clear_paint(point:Vector2,diameter:float) -> bool:
	for kite in protected_points:
		if kite.distance_to(point)<40+diameter/2:return false
	return true
func place_label(point:Vector2,value:String,font:Font,font_size:int,viewport:Rect2,occupied:Array[Rect2]) -> Dictionary:
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var offsets := [Vector2.ZERO,Vector2(0,70),Vector2(0,-70),Vector2(120,0),Vector2(-120,0),Vector2(0,140)]
	for offset:Vector2 in offsets:
		var at := point+offset
		var rect := Rect2(at-Vector2(width/2+10,font_size+10),Vector2(width+20,font_size*1.35+20))
		if not viewport.encloses(rect) or not Signals.safe_rect(rect,protected_points):continue
		var overlaps := occupied.any(func(other:Rect2):return other.grow(6).intersects(rect))
		if not overlaps:return {"at":at-Vector2(width/2,0),"rect":rect}
	return {}
func draw_label(canvas:CanvasItem,placement:Dictionary,value:String,font:Font,font_size:int,color:Color,stroke:int) -> void:
	if placement.is_empty():return
	canvas.draw_string_outline(font,placement.at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,stroke,T.alpha(T.NANQUIM,color.a))
	canvas.draw_string(font,placement.at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
	last_labels.append(placement.rect)
func draw_on(canvas:CanvasItem,project:Callable=Callable()) -> void:
	last_labels.clear()
	if suppress_secondary:return
	var viewport := visible_rect if visible_rect.has_area() else canvas.get_viewport_rect().grow(-10)
	var labels: Array[Dictionary] = []
	for burst in bursts:
		var point:Vector2=project.call(burst.point) if project.is_valid() else burst.point
		var age:float=burst.age
		var opacity := clampf(1-age/(.08 if reduced_motion else .6),0,1)
		var critical:bool=burst.get("critical",false)
		var color:Color=[T.CEU,T.SOL,T.FOLHA,T.RABIOLA][int(burst.get("color",0))%4]
		if not reduced_motion:
			var extent := 125.0 if critical else 70.0 if burst.get("amount",0)>20 else 45.0
			var family := "trail" if burst.get("kind","")=="evade" else "large" if critical else "medium" if burst.get("amount",0)>20 else "small"
			var assets := Paint.family(family)
			if clear_paint(point,extent) and not assets.is_empty():
				canvas.draw_texture_rect(Paint.texture(assets[int(burst.serial)%assets.size()]),Rect2(point-Vector2.ONE*extent/2,Vector2.ONE*extent),false,T.alpha(T.CEU if family=="trail" else color,opacity*.7))
			for i in 5:
				var direction:=Vector2.from_angle(i*TAU/5+.3)
				var drop:=point+direction*(12+age*70)
				if clear_paint(drop,8):canvas.draw_circle(drop,3*(1-age/.6),T.alpha(color,opacity))
			if critical and age<.25:
				for i in 8:
					var direction:=Vector2.from_angle(TAU*i/8)
					var a:=point+direction*70
					var b:=point+direction*105
					if Signals.safe_segment(a,b,protected_points):canvas.draw_line(a,b,T.alpha(T.SOL,opacity),2,true)
		var word := "CRAAC!" if burst.get("cut_line",false) else "VUPT!" if burst.get("kind","")=="evade" else "TOC!" if burst.get("kind","")=="block" or burst.get("body",false) else "TCHAC!" if critical else ""
		if age<.25 and not word.is_empty():
			labels.append({"point":point+Vector2(0,55),"text":word,"size":120 if critical else 38,"font":T.lettering(),"color":T.alpha(T.SOL if critical else T.CEU,opacity),"priority":2})
		if age<.5 and burst.get("amount",0)>0:
			labels.append({"point":point+Vector2(0,-28 if reduced_motion else -28-24*minf(1,age/.5)),"text":"−%d"%roundi(burst.amount),"size":40 if critical else 28,"font":T.label(),"color":T.alpha(T.SOL if critical else T.PAPEL,opacity),"priority":1})
	labels.sort_custom(func(a:Dictionary,b:Dictionary):return a.priority>b.priority)
	for label:Dictionary in labels:
		var placement:=place_label(label.point,label.text,label.font,label.size,viewport,last_labels)
		draw_label(canvas,placement,label.text,label.font,label.size,label.color,10 if label.priority==2 else 5)
