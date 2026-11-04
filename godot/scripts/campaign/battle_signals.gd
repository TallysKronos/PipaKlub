extends RefCounted
## Reads the authoritative contact/quality contract; never calculates damage.
const T = preload("res://scripts/campaign/ui_tokens.gd")

static func state(model: RefCounted, rival: Dictionary) -> Dictionary:
	var crossing: Dictionary = model.contact(model.p,rival)
	var hint: Dictionary = model.contact_hint(model.p,rival)
	return {"hint":hint,"contact":crossing,"quality":model.cut_quality(model.p,crossing) if not crossing.is_empty() else {},
		"danger":rival.get("signatureWindup",0)>0,"evade":model.attack_notice(rival).active}

static func diamond(canvas: CanvasItem, p: Vector2, radius: float, color: Color, dashed: bool = false) -> void:
	var points := PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius,0),p+Vector2(0,radius),p+Vector2(-radius,0),p+Vector2(0,-radius)])
	canvas.draw_polyline(points,T.NANQUIM,6,true)
	if dashed:
		for i in 4: canvas.draw_dashed_line(points[i],points[i+1],color,2,4,true)
	else: canvas.draw_polyline(points,color,2,true)

static func text(canvas: CanvasItem, at: Vector2, value: String, color: Color, size: int = 18) -> void:
	var font := T.label()
	var w := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	canvas.draw_string_outline(font,at-Vector2(w/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,5,T.NANQUIM)
	canvas.draw_string(font,at-Vector2(w/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

static func safe(point: Vector2, others: Array, radius: float = 0) -> bool:
	for other: Vector2 in others:
		if point.distance_to(other)<40+radius: return false
	return true

static func label_rect(at:Vector2,value:String,font_size:int) -> Rect2:
	var width := T.label().get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	return Rect2(at-Vector2(width/2+5,font_size+5),Vector2(width+10,font_size*1.35+10))

static func safe_rect(rect:Rect2,others:Array) -> bool:
	for point:Vector2 in others:
		var closest := point.clamp(rect.position,rect.end)
		if closest.distance_to(point)<40:return false
	return true

static func safe_text(canvas:CanvasItem,at:Vector2,value:String,color:Color,font_size:int,others:Array) -> bool:
	var rect := label_rect(at,value,font_size)
	var viewport := canvas.get_viewport_rect().grow(-6)
	if not viewport.encloses(rect) or not safe_rect(rect,others): return false
	text(canvas,at,value,color,font_size)
	return true

static func projected_ring(project:Callable,center:Vector2,radius:float,steps:int=64) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in steps+1: result.append(project.call(center+Vector2.from_angle(TAU*i/steps)*radius))
	return result

static func safe_segment(a:Vector2,b:Vector2,others:Array) -> bool:
	for point:Vector2 in others:
		if Geometry2D.get_closest_point_to_segment(point,a,b).distance_to(point)<40:return false
	return true

static func draw_on(canvas: CanvasItem, model: RefCounted, project: Callable, age: float, reduced: bool) -> void:
	var p: Dictionary = model.p
	var own: Vector2 = project.call(Vector2(p.x,p.y))
	var rivals: Array = model.actors.slice(1) if model.get("actors") != null else [model.q]
	var others: Array = []
	for rival: Dictionary in rivals: others.append(project.call(Vector2(rival.x,rival.y)))
	var marker := own+Vector2(0,42)
	if safe(marker,others):
		diamond(canvas,marker,7,T.CEU)
		if age<3 and (model.get("round_number")==null or model.round_number==1): safe_text(canvas,marker+Vector2(0,24),"VOCÊ",T.PAPEL,18,others)
	if p.get("counter",0)>0 and safe(own+Vector2(0,-62),others):
		safe_text(canvas,own+Vector2(0,-62),"CONTRA!",T.CEU,24,others)
		canvas.draw_line(own+Vector2(-26,-54),own+Vector2(-26+52*p.counter/2,-54),T.CEU,4)
	var warning_present := rivals.any(func(actor:Dictionary):return actor.get("signatureWindup",0)>0)
	var evade_present := rivals.any(func(actor:Dictionary):return model.attack_notice(actor).active)
	for rival: Dictionary in rivals:
		if rival.hp<=0 or rival.hull<=0: continue
		var rival_point: Vector2 = project.call(Vector2(rival.x,rival.y))
		var status := state(model,rival)
		# Alert is first in priority. Suppress lower signals when it is present.
		if status.danger:
			var profile: Dictionary = model.signature_profile(rival)
			var aim_world: Vector2 = rival.signatureAim
			var ring := projected_ring(project,aim_world,profile.radius)
			var progress := clampf(1-rival.signatureWindup/profile.windup,0,1)
			# Project the real world radius through both axes: ellipse under nonuniform framing.
			for i in ring.size()-1:
				if not safe_segment(ring[i],ring[i+1],others):continue
				if i%4<2:
					canvas.draw_line(ring[i],ring[i+1],T.NANQUIM,7,true)
					canvas.draw_line(ring[i],ring[i+1],T.RABIOLA,3,true)
				if not reduced and i<progress*(ring.size()-1): canvas.draw_line(ring[i],ring[i+1],T.RABIOLA,5,true)
			var alert := rival_point+Vector2(0,-65)
			var nonowners: Array = [own]
			for point:Vector2 in others:
				if point!=rival_point:nonowners.append(point)
			if safe(alert,nonowners,16):
				diamond(canvas,alert,15,T.RABIOLA)
				safe_text(canvas,alert+Vector2(0,7),"!",T.PAPEL,24,nonowners)
			continue
		if status.evade:
			var progress := float(model.attack_notice(rival).progress)
			var radius := 38.0 if reduced else lerpf(76,38,progress)
			if safe(own,others,radius+2):
				canvas.draw_circle(own,radius,T.CEU,false,3,true)
			continue
		if warning_present or evade_present:continue
		var c: Dictionary = status.hint
		if own.distance_to(rival_point)<160:
			var start: Vector2 = project.call(Vector2(rival.anchor,585))
			canvas.draw_line(start.lerp(rival_point,.52),start.lerp(rival_point,.68),T.alpha(T.SOL,.5),7,true)
		if c.is_empty(): continue
		var at: Vector2 = project.call(c.point)
		if not safe(at,others,30) or at.distance_to(own)<40: continue
		var color := T.SOL if c.valid and c.perfect else T.PAPEL if c.valid else T.TINTA_3
		diamond(canvas,at,14,color,not c.valid)
		var quality: Dictionary = model.cut_quality(p,c)
		for i in 3:
			var lit: bool = [quality.angle,quality.moving,quality.center][i]
			var center := at+Vector2((i-1)*28,33)
			if safe(center,others,10): diamond(canvas,center,4,T.SOL if quality.critical and c.valid and lit else T.PAPEL if lit else T.TINTA_3)
		safe_text(canvas,at+Vector2(0,56),"ÂNGULO · RELADA · CENTRO",T.PAPEL,13,others+[own])
	# Per-kite halos are lowest priority among the persistent signals.
	for actor: Dictionary in [p]+rivals:
		var center: Vector2 = project.call(Vector2(actor.x,actor.y))
		var nonowners: Array = []
		for other: Dictionary in [p]+rivals:
			if not is_same(other,actor): nonowners.append(project.call(Vector2(other.x,other.y)))
		if not safe(center,nonowners,32): continue
		if actor.get("guardTime",0)>0: canvas.draw_circle(center,32,T.alpha(T.CEU,.5),false,4,true)
		if actor.get("shield",0)>0: canvas.draw_circle(center,36,T.alpha(T.PAPEL,.3),false,5,true)
		if not actor.get("lineMove",{}).is_empty(): canvas.draw_arc(center,36,-PI/2,-PI/2+TAU*clampf(actor.lineMove.elapsed/1.05,0,1),40,T.CEU,3,true)
