extends RefCounted
## Opt-in, authored traversal. It never modifies the walking graph or account saves.
const WINDUP := .14
const FLIGHT := .56
const LANDING := .16
const PARTNER_DELAY := .22
const TOTAL := WINDUP + FLIGHT + LANDING + PARTNER_DELAY
var active := false
var elapsed := 0.0
var link: Dictionary = {}
var start := Vector2.ZERO
var finish := Vector2.ZERO
var height_from := 0.0
var height_to := 0.0

static func point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

static func valid(model, candidate: Dictionary) -> bool:
	if candidate.get("kind","") not in ["jump","drop"]:return false
	for key in ["from","to"]:
		if not candidate.get(key) is Array or candidate[key].size()!=2:return false
		for n in candidate[key]:
			if not (n is float or n is int) or not is_finite(float(n)):return false
	var a:=point(candidate.from)
	var b:=point(candidate.to)
	var d:=a.distance_to(b)
	if d<1.5 or d>3.1 or (not is_equal_approx(a.x,b.x) and not is_equal_approx(a.y,b.y)):return false
	# Flat, supported and wide landing pockets, never a slope or blocked prop.
	for p in [a,b]:
		if not model.point_walkable(p):return false
		var c:Dictionary=model.cell_at(Vector2i(floori(p.x),floori(p.y)))
		if c.get("ramp")!=null:return false
		var side:=Vector2(0,1) if is_equal_approx(a.y,b.y) else Vector2(1,0)
		if not [p+side,p-side].any(func(q):return model.clear_segment(p,q)):return false
	var delta:float=model.height_at(a)-model.height_at(b)
	if candidate.kind=="jump" and not is_zero_approx(delta):return false
	if candidate.kind=="drop" and not is_equal_approx(delta,1):return false
	for n in range(1,12):
		var t:=float(n)/12
		var p:=a.lerp(b,t)
		var c:Dictionary=model.cell_at(Vector2i(floori(p.x),floori(p.y)))
		if c.is_empty() or c.material in ["bosque","construcao","rocha"]:return false
		if model.solid.has(model.key(Vector2i(floori(p.x),floori(p.y)))):return false
		var clearance:=sin(PI*t)*(38.0/64 if candidate.kind=="drop" else 52.0/64)
		if model.height_at(p)>lerpf(model.height_at(a),model.height_at(b),t)+clearance+.01:return false
	# An authored shortcut must actually cross a break in normal walking.
	return not model.clear_segment(a,b)

func begin(model, candidate: Dictionary, at: Vector2) -> bool:
	if active or not valid(model,candidate):return false
	var origin:=point(candidate.from)
	if at.distance_to(origin)>.08:return false
	link=candidate.duplicate(true);start=origin;finish=point(candidate.to)
	height_from=model.height_at(start);height_to=model.height_at(finish)
	elapsed=0;active=true
	return true

func advance(delta: float) -> void:
	if not active:return
	elapsed=minf(TOTAL,elapsed+maxf(0,delta))
	if elapsed>=TOTAL:active=false

func sample(partner: bool=false) -> Dictionary:
	var local:=elapsed-(PARTNER_DELAY if partner else 0.0)
	var t:=clampf((local-WINDUP)/FLIGHT,0,1)
	var lift:=sin(PI*t)*(38 if link.get("kind")=="drop" else 52)
	return {"point":start.lerp(finish,t),"height":lerpf(height_from,height_to,t),"lift":lift,"t":t,"local":local,"landed":local>=WINDUP+FLIGHT}

func checkpoint() -> Vector2:
	# Never serialize a coordinate inside a gap. Until both land, use the takeoff.
	return start if active else finish

func cancel() -> Vector2:
	var safe:=checkpoint()
	active=false;elapsed=0
	return safe
