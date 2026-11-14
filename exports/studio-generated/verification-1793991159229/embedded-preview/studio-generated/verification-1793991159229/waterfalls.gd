extends RefCounted
const Terrain=preload("res://studio-generated/verification-1793991159229/autotile.gd")
const WIDTHS={"cachoeira-fina":32,"cachoeira-dupla":64,"cachoeira-ampla":96}
static func geometry(a: Dictionary,point: Vector2,asset: String) -> Dictionary:
	if not WIDTHS.has(asset):
		return {}
	var left := roundi(point.x-float(WIDTHS[asset])/2)
	var columns: Array=[]
	var valid := 0
	var top := INF
	var bottom := -INF
	for x: int in range(left,left+int(WIDTHS[asset])):
		var best: Dictionary={}
		for y: int in range(maxi(1,roundi(point.y)-20),mini(int(a.height)*32-1,roundi(point.y)+21)):
			if x<0 or x>=int(a.width)*32:
				continue
			var high := Terrain.support(a,Vector2(x+0.5,y-0.5))
			var low := Terrain.support(a,Vector2(x+0.5,y+0.5))
			if high-low<0.99 or not Terrain.water_at(a,Vector2(x+0.5,y-1)) or not Terrain.water_at(a,Vector2(x+0.5,y+1)):
				continue
			if best.is_empty() or absf(y-point.y)<absf(float(best.front)-point.y):
				best={"x":x,"front":y,"high":high,"low":low,"top":y-high*16,"bottom":y-low*16}
		columns.append(best)
		if not best.is_empty():
			valid+=1
			top=minf(top,best.top)
			bottom=maxf(bottom,best.bottom)
	if valid<float(WIDTHS[asset])*0.75:
		return {}
	var yy := floori(top)-20
	return {"x":left-8,"y":yy,"width":int(WIDTHS[asset])+16,"height":ceili(bottom)+12-yy,"left":left,"columns":columns}

static func render(a: Dictionary,point: Vector2,asset: String,atlas: Image,phase: int) -> Dictionary:
	var g := geometry(a,point,asset)
	if g.is_empty():
		return {}
	var r := Terrain.plan(a)
	var image := Image.create(g.width,g.height,false,Image.FORMAT_RGBA8)
	for yy: int in range(g.height):
		for xx: int in range(g.width):
			var x: int=g.x+xx
			var y: int=g.y+yy
			var column: Dictionary=g.columns[clampi(x-int(g.left),0,g.columns.size()-1)]
			if column.is_empty() or x<0 or x>=int(r.width) or y+Terrain.PAD<0 or y+Terrain.PAD>=int(r.height):
				continue
			var n: int=(y+Terrain.PAD)*int(r.width)+x
			if r.owners[n]<0:
				continue
			var local: int=x-g.left
			var inside: bool=local>=0 and local<g.columns.size()
			var sx := -1
			var sy := -1
			var opacity := 1.0
			if inside and y>=column.top and y<column.bottom and r.kinds[n] and absf(float(r.depth[n])-float(column.front))<1.1:
				sx=8+local%32
				sy=16+posmod(y-int(column.top),64)
			elif local>=-4 and local<g.columns.size()+4 and y<column.top+6 and not r.kinds[n] and absf(float(r.zmap[n])-float(column.high))<0.01 and a.floors[r.owners[n]]=="water":
				var reach: int=12+[0,2,4,3,5,2,4,1][posmod(floori(float(local)/4),8)]
				var distance: int=y-(int(column.top)-reach)
				if distance<0:
					continue
				sx=8+local if local<0 else (40+local-g.columns.size() if local>=g.columns.size() else 8+local%32)
				sy=12+(y-int(column.top)+3)*2 if y>=column.top-3 else 20+mini(45,distance*3)
				opacity=minf(1,minf(float(distance+1)/6,minf(float(local+5)/5,float(g.columns.size()+4-local)/5)))*(0.65 if y<column.top-3 else 1.0)
			elif y>=column.bottom-4 and y<column.bottom+12 and not r.kinds[n] and absf(float(r.zmap[n])-float(column.low))<0.01 and a.floors[r.owners[n]]=="water":
				sx=local+8 if local<8 else (48-(g.columns.size()+8-local) if local>=g.columns.size()-8 else 16+local%16)
				sy=80+y-int(column.bottom)+4
			if sx>=0 and sx<48 and sy>=0 and sy<96:
				var color := atlas.get_pixel(phase%4*48+sx,sy)
				color.a=float(roundi(roundi(color.a*255)*opacity))/255
				image.set_pixel(xx,yy,color)
	g["image"]=image
	return g
