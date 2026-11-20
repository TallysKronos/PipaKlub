extends RefCounted
const DIRS={"n":Vector2i(0,-1),"s":Vector2i(0,1),"e":Vector2i(1,0),"w":Vector2i(-1,0)}
static func neighbors(a: Dictionary,i: int,direction: String) -> Vector2i:
	var p := Vector2i(i%int(a.width),int(i/int(a.width)))
	var d: Vector2i=DIRS.get(direction,Vector2i(0,-1))
	var h := p+d
	var l := p-d
	return Vector2i(h.y*int(a.width)+h.x if h.x>=0 and h.y>=0 and h.x<int(a.width) and h.y<int(a.height) else -1,l.y*int(a.width)+l.x if l.x>=0 and l.y>=0 and l.x<int(a.width) and l.y<int(a.height) else -1)
static func rise(direction: String,x: float,y: float) -> float:
	return y/32 if direction=="s" else x/32 if direction=="e" else 1-x/32 if direction=="w" else 1-y/32
static func landing(a: Dictionary,i: int) -> bool:
	for j: int in [i-1,i+1,i-int(a.width),i+int(a.width)]:
		if j>=0 and j<a.ramps.size() and a.ramps[j]!=null:
			var n := neighbors(a,j,str(a.ramps[j]))
			if (n.x==i and int(a.levels[i])==int(a.levels[j])+1) or (n.y==i and int(a.levels[i])==int(a.levels[j])):
				return true
	return false
static func point(a: Dictionary,i: int,p: Vector2) -> Vector2:
	var row := int(i/int(a.width))*32
	var h := float(a.levels[i])
	var d: String=a.ramps[i]
	if d in ["e","w"]:
		return Vector2(p.x,p.y+(h+rise(d,fposmod(p.x,32),0))*16)
	return Vector2(p.x,row+(p.y-row+h*16+(16 if d=="n" else 0))/(1.5 if d=="n" else 0.5))
