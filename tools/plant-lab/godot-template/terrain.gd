extends RefCounted
const RISE := 16.0

static func height_at(a: Dictionary, p: Vector2) -> float:
	var x := clampi(int(floor(p.x / 32)), 0, int(a.width)-1)
	var y := clampi(int(floor(p.y / 32)), 0, int(a.height)-1)
	var i := y * int(a.width) + x
	return float(a.levels[i]) + (1.0-fposmod(p.y,32.0)/32.0 if a.ramps[i] != null else 0.0)

static func project(a: Dictionary, p: Vector2) -> Vector2:
	return p - Vector2(0, height_at(a,p)*RISE)

static func top(a: Dictionary, i: int) -> Rect2:
	var ramp := a.ramps[i] != null
	return Rect2(i % int(a.width)*32, int(i/int(a.width))*32-(float(a.levels[i])+(1 if ramp else 0))*RISE,32,48 if ramp else 32)

static func face(a: Dictionary, i: int) -> Rect2:
	var j := i+int(a.width)
	var low := float(a.levels[j])+(1 if a.ramps[j]!=null else 0) if j<a.levels.size() else 0.0
	var high := float(a.levels[i])
	if high<=low:
		return Rect2()
	return Rect2(i%int(a.width)*32,(int(i/int(a.width))+1)*32-high*RISE,32,(high-low)*RISE)

static func surface(a: Dictionary, p: Vector2, support: int = -1) -> Vector2:
	for i: int in range(a.levels.size()-1,-1,-1):
		if support>=0 and int(a.levels[i])!=support:
			continue
		var f := face(a,i)
		if support<0 and f.has_area() and f.has_point(p):
			return Vector2(p.x,(int(i/int(a.width))+1)*32-0.01)
		var r := top(a,i)
		if r.has_point(p):
			return Vector2(p.x,int(i/int(a.width))*32+(p.y-r.position.y)/(1.5 if a.ramps[i]!=null else 1.0))
	return p if support<0 else Vector2.INF

static func move(a: Dictionary, p: Vector2, delta: Vector2) -> Vector2:
	var steps := maxi(1,int(ceil(delta.length()/2.0)))
	var step := delta/steps
	var result := p
	for i: int in range(steps):
		var q := bounded(a,result+step)
		if absf(height_at(a,q)-height_at(a,result))<0.22:
			result=q
		else:
			q=bounded(a,result+Vector2(step.x,0))
			if absf(height_at(a,q)-height_at(a,result))<0.22:
				result=q
			q=bounded(a,result+Vector2(0,step.y))
			if absf(height_at(a,q)-height_at(a,result))<0.22:
				result=q
	return result

static func bounded(a: Dictionary, p: Vector2) -> Vector2:
	return p.clamp(Vector2.ONE,Vector2(float(a.width)*32-1,float(a.height)*32-1))

static func occluders(a: Dictionary, p: Vector2) -> Array[Rect2]:
	var result: Array[Rect2]=[]
	var z := height_at(a,p)
	var own := int(p.y/32)*int(a.width)+int(p.x/32)
	for i: int in range(a.levels.size()):
		if i==own or (int(i/int(a.width))+1)*32<=p.y+0.01:
			continue
		var high := float(a.levels[i])+(1 if a.ramps[i]!=null else 0)
		if high>z+0.001:
			var r := top(a,i)
			if a.ramps[i]!=null:
				r.size.y=clampf(high-z,0,1)*48
			result.append(r)
		var f := face(a,i)
		if f.has_area() and float(a.levels[i])>z+0.001:
			result.append(f)
	return result

static func valid_ramp(a: Dictionary, i: int) -> bool:
	var w := int(a.width)
	return i>=w and i<a.levels.size()-w and a.levels[i-w]==a.levels[i]+1 and a.levels[i+w]==a.levels[i] and a.ramps[i-w]==null and a.ramps[i+w]==null

static func clean(a: Dictionary) -> void:
	for i: int in range(a.ramps.size()):
		if a.ramps[i]!=null and not valid_ramp(a,i):
			a.ramps[i]=null

