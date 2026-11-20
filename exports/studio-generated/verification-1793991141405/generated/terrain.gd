extends RefCounted
const RISE := 16.0
const Autotile = preload("res://autotile.gd")

static func allowed(a: Dictionary,from: Vector2,to: Vector2) -> bool:
	return absf(height_at(a,to)-height_at(a,from))<0.22 and (not Autotile.water_at(a,to) or Autotile.water_at(a,from))

static func height_at(a: Dictionary, p: Vector2) -> float:
	return Autotile.support(a,p)

static func project(a: Dictionary, p: Vector2) -> Vector2:
	return p - Vector2(0, height_at(a,p)*RISE)

static func top(a: Dictionary,i: int) -> Rect2:
	var d: Variant=a.ramps[i]
	return Rect2(i%int(a.width)*32,int(i/int(a.width))*32-(float(a.levels[i])+(1 if d!=null and d!="s" else 0))*16,32,16 if d=="s" else 48 if d!=null else 32)

static func face(a: Dictionary, i: int) -> Rect2:
	var j := i+int(a.width)
	var low := float(a.levels[j])+(1 if a.ramps[j]!=null else 0) if j<a.levels.size() else 0.0
	var high := float(a.levels[i])
	if high<=low:
		return Rect2()
	return Rect2(i%int(a.width)*32,(int(i/int(a.width))+1)*32-high*RISE,32,(high-low)*RISE)

static func surface(a: Dictionary, p: Vector2, support: int = -1) -> Vector2:
	if support>=0:
		var flat := p+Vector2(0,support*16)
		if flat.x>=0 and flat.y>=0 and flat.x<float(a.width)*32 and flat.y<float(a.height)*32 and absf(height_at(a,flat)-support)<0.001:
			return flat
		for i: int in range(a.ramps.size()):
			if a.ramps[i]!=null and int(a.levels[i])==support:
				var r := top(a,i)
				if r.has_point(p):
					return Autotile.Ramps.point(a,i,p)
		return Vector2.INF
	var raster := Autotile.plan(a)
	var x := int(floor(p.x))
	var y := int(floor(p.y))+Autotile.PAD
	if x<0 or x>=int(raster.width) or y<0 or y>=int(raster.height):
		return p
	var n := y*int(raster.width)+x
	var i := int(raster.owners[n])
	if i<0:
		return p
	if raster.kinds[n]:
		return Vector2(p.x,float(raster.depth[n])-0.01)
	if a.ramps[i]!=null:
		var r := top(a,i)
		return Autotile.Ramps.point(a,i,p)
	return p+Vector2(0,float(raster.zmap[n])*16)

static func move(a: Dictionary, p: Vector2, delta: Vector2) -> Vector2:
	var steps := maxi(1,int(ceil(delta.length()/2.0)))
	var step := delta/steps
	var result := p
	for i: int in range(steps):
		var q := bounded(a,result+step)
		if allowed(a,result,q):
			result=q
		else:
			q=bounded(a,result+Vector2(step.x,0))
			if allowed(a,result,q):
				result=q
			q=bounded(a,result+Vector2(0,step.y))
			if allowed(a,result,q):
				result=q
	return result

static func bounded(a: Dictionary, p: Vector2) -> Vector2:
	return p.clamp(Vector2.ONE,Vector2(float(a.width)*32-1,float(a.height)*32-1))

static func occluders(a: Dictionary, p: Vector2,asset: String = "") -> Array[Rect2]:
	var result: Array[Rect2]=[]
	var raster := Autotile.plan(a)
	var z := height_at(a,p)
	var root := project(a,p)
	var x0 := maxi(0,int(floor(root.x))-40)
	var x1 := mini(int(raster.width),int(ceil(root.x))+40)
	var y0 := maxi(-Autotile.PAD,int(floor(root.y))-(80 if asset.begins_with("arvore-") else 65))
	var y1 := mini(int(raster.height)-Autotile.PAD,int(ceil(root.y))+16)
	for spec: Dictionary in a.get("customAssets",[]):
		if str(spec.id)==asset:
			x0=maxi(0,int(floor(root.x-float(spec.anchor[0]))))
			x1=mini(int(raster.width),int(ceil(root.x-float(spec.anchor[0])+float(spec.frameWidth))))
			y0=maxi(-Autotile.PAD,int(floor(root.y-float(spec.anchor[1]))))
			y1=mini(int(raster.height)-Autotile.PAD,int(ceil(root.y-float(spec.anchor[1])+float(spec.frameHeight))))
	var previous: Dictionary={}
	for y: int in range(y0,y1):
		var start := -1
		var next: Dictionary={}
		for x: int in range(x0,x1+1):
			var n := (y+Autotile.PAD)*int(raster.width)+x
			var hidden_pixel: bool = x<x1 and float(raster.depth[n])>p.y+0.01 and float(raster.zmap[n])>z+0.001
			if hidden_pixel and start<0:
				start=x
			if not hidden_pixel and start>=0:
				var key := str(start)+":"+str(x-start)
				if previous.has(key):
					var index: int=previous[key]
					result[index].size.y+=1
					next[key]=index
				else:
					next[key]=result.size()
					result.append(Rect2(start,y,x-start,1))
				start=-1
		previous=next
	return result

static func valid_ramp(a: Dictionary,i: int) -> bool:
	if i<0 or i>=a.levels.size():
		return false
	var n := Autotile.Ramps.neighbors(a,i,str(a.ramps[i]) if a.ramps[i]!=null else "n")
	return n.x>=0 and n.y>=0 and int(a.levels[n.x])==int(a.levels[i])+1 and a.levels[n.y]==a.levels[i] and a.ramps[n.x]==null and a.ramps[n.y]==null

static func clean(a: Dictionary) -> void:
	for i: int in range(a.ramps.size()):
		if a.ramps[i]!=null and not valid_ramp(a,i):
			a.ramps[i]=null


static func face_cell(a: Dictionary,p: Vector2) -> int:
	var raster := Autotile.plan(a)
	var x := int(floor(p.x))
	var y := int(floor(p.y))+Autotile.PAD
	if x<0 or x>=int(raster.width) or y<0 or y>=int(raster.height):
		return -1
	var n := y*int(raster.width)+x
	return int(raster.owners[n]) if raster.kinds[n] else -1
