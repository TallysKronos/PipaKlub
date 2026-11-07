extends RefCounted
const Ramps=preload("res://studio-generated/verification-1793991159229/ramp_rules.gd")
const PAD := 200
const MASKS := [0]
static var shapes: Dictionary={}
static var cached: Dictionary={}
static var textures: Dictionary={}
static var source: Dictionary={}
static var mask_indices: Dictionary={}
static var ground_specs: Dictionary={}
static var wall_specs: Dictionary={}
static func ground_rank(kind: String) -> int:
	return int(ground_specs[kind].priority) if ground_specs.has(kind) else 0
static func ground_background(a: Dictionary,i: int,x: int,y: int) -> String:
	var best := INF
	var kind: String=a.floors[i]
	var w := int(a.width)
	for dy: int in range(-1,2):
		for dx: int in range(-1,2):
			if dx==0 and dy==0:
				continue
			var xx := i%w+dx
			var yy := int(i/w)+dy
			if xx<0 or yy<0 or xx>=w or yy>=int(a.height):
				continue
			var k: String=a.floors[yy*w+xx]
			if a.levels[yy*w+xx]!=a.levels[i] or ground_rank(k)>=ground_rank(a.floors[i]):
				continue
			var d := float((x-(dx*32+16))**2+(y-(dy*32+16))**2)
			if d<best:
				best=d
				kind=k
	return kind

static func normalized(m: int) -> int:
	var n := m & 15
	for pair: Array in [[16,1,2],[32,2,4],[64,4,8],[128,8,1]]:
		if m & int(pair[0]) and m & int(pair[1]) and m & int(pair[2]):
			n |= int(pair[0])
	return n

static func neighbor(a: Dictionary,i: int,level: int = -1) -> int:
	var w := int(a.width)
	var x := i%w
	var y := int(i/w)
	var mask := 0
	for entry: Array in [[0,-1,1],[1,0,2],[0,1,4],[-1,0,8],[1,-1,16],[1,1,32],[-1,1,64],[-1,-1,128]]:
		var nx := x+int(entry[0])
		var ny := y+int(entry[1])
		var outside := nx<0 or ny<0 or nx>=w or ny>=int(a.height)
		var match_cell := level<0 and outside
		if not outside:
			var j := ny*w+nx
			if level<0:
				match_cell=a.floors[j]==a.floors[i]
				if (a.floors[i]=="grass" and a.floors[j] in ["water","sand"]) or (a.floors[i]=="sand" and a.floors[j]=="water"):
					match_cell=true
				# A ramp's material stops at its physical sides; do not erode adjacent grass.
				if a.floors[i]=="grass" and a.ramps[i]==null and int(entry[0])!=0 and a.ramps[j]!=null:
					match_cell=true
				if ground_specs.has(a.floors[i]) or ground_specs.has(a.floors[j]):
					match_cell=ground_rank(a.floors[j])>=ground_rank(a.floors[i])
				# Different storeys never blend their surface materials.
				if a.levels[j]!=a.levels[i]:
					match_cell=true
			else:
				match_cell=float(a.levels[j])+(1 if a.ramps[j]!=null and int(entry[1])==1 else 0)>=level
		if match_cell:
			mask |= int(entry[2])
	return normalized(mask)

static func shape(m: int) -> PackedByteArray:
	if shapes.has(m):
		return shapes[m]
	var result := PackedByteArray()
	result.resize(1024)
	var profile := [4,4,3,3,3,4,4,3,3,4,4,3,3,3,4,4]
	for y: int in range(32):
		for x: int in range(32):
			var qx := x if x<16 else 31-x
			var qy := y if y<16 else 31-y
			var horizontal := 8 if x<16 else 2
			var vertical := 1 if y<16 else 4
			var diagonal := (128 if y<16 else 64) if x<16 else (16 if y<16 else 32)
			var inside := true
			if not (m & horizontal) and qx<int(profile[y%16])+1:
				inside=false
			if not (m & vertical) and qy<int(profile[x%16])+1:
				inside=false
			if not (m & horizontal) and not (m & vertical) and qx<15 and qy<15 and (qx-14)*(qx-14)+(qy-14)*(qy-14)>100:
				inside=false
			if m & horizontal and m & vertical and not (m & diagonal) and qx*qx+qy*qy<25:
				inside=false
			result[y*32+x]=1 if inside else 0
	shapes[m]=result
	return result

static func support(a: Dictionary,p: Vector2) -> float:
	var x := clampf(p.x,0,float(a.width)*32-0.001)
	var y := clampf(p.y,0,float(a.height)*32-0.001)
	var w := int(a.width)
	var i := int(y/32)*w+int(x/32)
	var h := int(a.levels[i])
	if a.ramps[i]!=null:
		return h+Ramps.rise(str(a.ramps[i]),fposmod(x,32),fposmod(y,32))
	var landing: bool = Ramps.landing(a,i)
	if not a.get("autotiling",true) or landing:
		return h
	var gx := int(floor(x/32-0.5))
	var gy := int(floor(y/32-0.5))
	var fx := x/32-0.5-gx
	var fy := y/32-0.5-gy
	var maximum := h
	for dy: int in range(2):
		for dx: int in range(2):
			var cx := clampi(gx+dx,0,w-1)
			var cy := clampi(gy+dy,0,int(a.height)-1)
			maximum=maxi(maximum,int(a.levels[cy*w+cx]))
	for level: int in range(maximum,0,-1):
		var density := 0.0
		for dy: int in range(2):
			for dx: int in range(2):
				var cx := clampi(gx+dx,0,w-1)
				var cy := clampi(gy+dy,0,int(a.height)-1)
				var j := cy*w+cx
				var value := float(a.levels[j])
				if a.ramps[j]!=null:
					value+=clampf(Ramps.rise(str(a.ramps[j]),clampf(x-cx*32,0,31.999),clampf(y-cy*32,0,31.999)),0,1)
				if value>=level-0.0001:
					density+=(fx if dx else 1-fx)*(fy if dy else 1-fy)
		if density>=0.5:
			return level
	return 0

static func surface_support(a: Dictionary,x: float,y: float,z: float) -> int:
	var w := int(a.width)
	var i := mini(a.levels.size()-1,int(y/32)*w+int(x/32))
	if a.ramps[i]!=null or absf(float(a.levels[i])-z)<0.001:
		return i
	var gx := x/32-0.5
	var gy := y/32-0.5
	var cx := int(floor(gx))
	var cy := int(floor(gy))
	var fx := gx-cx
	var fy := gy-cy
	var best := -1.0
	var source_cell := i
	for dy: int in range(2):
		for dx: int in range(2):
			var xx := clampi(cx+dx,0,w-1)
			var yy := clampi(cy+dy,0,int(a.height)-1)
			var j := yy*w+xx
			var weight := (fx if dx else 1-fx)*(fy if dy else 1-fy)
			if a.ramps[j]==null and absf(float(a.levels[j])-z)<0.001 and weight>best:
				best=weight
				source_cell=j
	return source_cell

static func wall_support(a: Dictionary,x: float,y: float,z: float) -> int:
	var w := int(a.width)
	var i := mini(a.levels.size()-1,int(y/32)*w+int(x/32))
	if float(a.levels[i])>=z-0.001 or a.ramps[i]!=null:
		return i
	var gx := x/32-0.5
	var gy := y/32-0.5
	var cx := int(floor(gx))
	var cy := int(floor(gy))
	var fx := gx-cx
	var fy := gy-cy
	var best := -1.0
	var source_cell := i
	for dy: int in range(2):
		for dx: int in range(2):
			var xx := clampi(cx+dx,0,w-1)
			var yy := clampi(cy+dy,0,int(a.height)-1)
			var j := yy*w+xx
			var weight := (fx if dx else 1-fx)*(fy if dy else 1-fy)
			if float(a.levels[j])>=z-0.001 and weight>best:
				best=weight
				source_cell=j
	return source_cell

static func init_assets() -> void:
	if not textures.is_empty():
		return
	source=JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991159229/autotile/source.json"))
	for g: Dictionary in source.get("grounds",[]):
		ground_specs[str(g.id)]=g
		textures[str(g.id)]=(load("res://studio-generated/verification-1793991159229/autotile/"+str(g.id)+".png") as Texture2D).get_image()
	for w: Dictionary in source.get("walls",[]):
		wall_specs[str(w.id)]=w
		textures[str(w.id)]=(load("res://studio-generated/verification-1793991159229/autotile/"+str(w.id)+".png") as Texture2D).get_image()
	for name: String in ["grass","stone","sand","water","dirt","earth","rock"]:
		textures[name]=(load("res://studio-generated/verification-1793991159229/autotile/"+name+".png") as Texture2D).get_image()
	source=JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991159229/autotile/source.json"))
	for i: int in range(source.masks.size()):
		mask_indices[int(source.masks[i])]=i

static func floor_color(a: Dictionary,i: int,x: int,y: int) -> Color:
	var kind: String=a.floors[i]
	var cx := i%int(a.width)
	var cy := int(i/int(a.width))
	var variant := posmod(cx*cx*17+cy*cy*29+cx*cy*13+cx*7+cy*11,65521)%3
	if a.get("variants",[]).size()>i and a.variants[i]!=null:
		variant=int(a.variants[i])
	var m := neighbor(a,i) if a.get("autotiling",true) else 255
	if ground_specs.has(kind):
		if a.ramps[i]!=null:
			m=255
		elif a.get("autotiling",true) and not bool(shape(m)[y*32+x]):
			kind=ground_background(a,i,x,y)
			m=255
	if kind=="water" and a.get("autotiling",true) and not bool(shape(m)[y*32+x]) and shore_sand(a,i):
		kind="sand"
		m=255
	if kind=="dirt":
		return (textures.dirt as Image).get_pixel(x,y+variant*32)
	var index: int=mask_indices[m]
	var color: Color=(textures[kind] as Image).get_pixel(index%8*32+x,(int(index/8)+variant*6)*32+y)
	if kind=="water" and a.has("waterDepth") and i<a.waterDepth.size() and (not a.get("autotiling",true) or bool(shape(m)[y*32+x])):
		var depth: int=a.waterDepth[i]
		color=Color(float(roundi(roundi(color.r*255)*(1-depth*0.09)))/255,float(roundi(roundi(color.g*255)*(1-depth*0.09)))/255,float(roundi(roundi(color.b*255)*(1-depth*0.035)))/255,color.a)
	return color

static func shore_sand(a: Dictionary,i: int) -> bool:
	var w := int(a.width)
	for dy: int in range(-1,2):
		for dx: int in range(-1,2):
			var x := i%w+dx
			var y := int(i/w)+dy
			if x>=0 and y>=0 and x<w and y<int(a.height) and a.floors[y*w+x]=="sand":
				return true
	return false

static func water_at(a: Dictionary,p: Vector2) -> bool:
	var x := int(floor(p.x))
	var y := int(floor(p.y))
	if x<0 or y<0 or x>=int(a.width)*32 or y>=int(a.height)*32:
		return false
	var i := int(y/32)*int(a.width)+int(x/32)
	if ground_specs.has(a.floors[i]) and a.get("autotiling",true) and not bool(shape(neighbor(a,i))[y%32*32+x%32]):
		return ground_background(a,i,x%32,y%32)=="water"
	return a.floors[i]=="water" and (not a.get("autotiling",true) or bool(shape(neighbor(a,i))[y%32*32+x%32]))

static func ripple_points(a: Dictionary,phase: int) -> Array[Vector2]:
	var result: Array[Vector2]=[]
	for i: int in range(a.floors.size()):
		if a.floors[i]!="water":
			continue
		for k: int in range(4):
			var direction: Variant=a.flow[i] if a.has("flow") and i<a.flow.size() else null
			var x := i%int(a.width)*32+posmod(k*11+i*7+(-phase if direction=="w" else phase),27)+2
			var y := int(i/int(a.width))*32+posmod(k*7+i*3+(phase if direction=="s" else -phase if direction=="n" else 0),25)+3
			for dx: int in range(3):
				var p := Vector2(x+dx,y)
				if water_at(a,p) and water_at(a,p-Vector2(3,3)) and water_at(a,p+Vector2(3,3)):
					result.append(p)
	return result

static func relief_rim(heights: PackedFloat32Array,w: int,h: int,x: int,y: int) -> int:
	var z := heights[y*w+x]
	if z<=0:
		return 0
	for distance: int in [1,2]:
		for d: Vector2i in [Vector2i(-distance,0),Vector2i(distance,0),Vector2i(0,-distance),Vector2i(0,distance)]:
			var xx := x+d.x
			var yy := y+d.y
			if xx>=0 and yy>=0 and xx<w and yy<h and z-heights[yy*w+xx]>0.22:
				return distance
	return 0

static func sample_floor(a: Dictionary,i: int,x: int,y: int,rim: int = 0) -> Color:
	var c := floor_color(a,i,x,y)
	if a.ramps[i]!=null:
		var left := i
		var right := i
		var w := int(a.width)
		var horizontal: bool=a.ramps[i] in ["e","w"]
		var step := w if horizontal else 1
		var limit := int(a.height) if horizontal else w
		while (int(left/w) if horizontal else left%w)>0 and a.ramps[left-step]==a.ramps[i] and a.levels[left-step]==a.levels[i]:
			left-=step
		while (int(right/w) if horizontal else right%w)<limit-1 and a.ramps[right+step]==a.ramps[i] and a.levels[right+step]==a.levels[i]:
			right+=step
		var span := (int((right-left)/step)+1)*32
		var px := (int((i-left)/step)*32+y) if horizontal else (i-left)*32+x
		var along: int=y if a.ramps[i]=="n" else 31-y if a.ramps[i]=="s" else 31-x if a.ramps[i]=="e" else x
		if a.has("stairs") and a.stairs[i] and along%6==0:
			return Color("665641")
		var t := (along+0.5)/32
		var blend := minf(1,minf((along+1)/5.0,(32-along)/5.0))
		var edge := mini(px,span-1-px)
		var factor := 1-blend*(0.13+0.12*t)
		if edge<3:
			factor=1-blend*[0.48,0.27,0.08][edge]
		elif edge==3:
			factor=1+blend*0.12
		elif along%8==4 and px>7 and px<span-8 and (px+int(along/8)*7)%23<11:
			factor-=0.065*blend
		return Color(minf(255,roundi(roundi(c.r*255)*factor))/255,minf(255,roundi(roundi(c.g*255)*factor))/255,minf(255,roundi(roundi(c.b*255)*factor))/255,1)
	if rim>0:
		var kind: String=a.floors[i]
		if ground_specs.has(kind):
			if a.get("autotiling",true) and not bool(shape(neighbor(a,i))[y*32+x]):
				kind=ground_background(a,i,x,y)
		elif kind=="dirt" or (a.get("autotiling",true) and not bool(shape(neighbor(a,i))[y*32+x])):
			kind="dirt"
		if ground_specs.has(kind):
			return Color(ground_specs[kind].dark if rim==1 else ground_specs[kind].light)
		var colors := {"grass":[Color("526d38"),Color("b2c777")],"dirt":[Color("886b42"),Color("d9b57a")],"stone":[Color("58675b"),Color("c0c7a4")],"sand":[Color("aa905e"),Color("ead29a")],"water":[Color("315e58"),Color("67b9b1")]}
		return colors[kind][rim-1]
	return c

static func plan(a: Dictionary) -> Dictionary:
	init_assets()
	var key := str(a.width)+":"+str(a.height)+"|"+str(a.levels.hash())+str(a.ramps.hash())+str(a.get("stairs",[]).hash())+str(a.get("waterDepth",[]).hash())+str(a.floors.hash())+str(a.cliffs.hash())+str(a.get("autotiling",true))
	if cached.get("key","")==key:
		return cached
	var w := int(a.width)*32
	var wh := int(a.height)*32
	var h := wh+PAD
	var depth := PackedFloat32Array()
	var zmap := PackedFloat32Array()
	var owners := PackedInt32Array()
	var kinds := PackedByteArray()
	var heights := PackedFloat32Array()
	depth.resize(w*h)
	depth.fill(-1)
	zmap.resize(w*h)
	owners.resize(w*h)
	owners.fill(-1)
	kinds.resize(w*h)
	heights.resize(w*wh)
	var baked: bool = int(a.width)==int(source.get("width",a.width)) and int(a.height)==int(source.get("height",a.height)) and a.levels==source.levels and a.ramps==source.ramps and a.floors==source.floors and a.cliffs==source.cliffs and a.get("variants",[])==source.get("variants",[]) and a.get("stairs",[])==source.get("stairs",[]) and a.get("waterDepth",[])==source.get("waterDepth",[]) and a.get("autotiling",true)==source.autotiling
	var top: Image=(load("res://studio-generated/verification-1793991159229/autotile/baked-top.png") as Texture2D).get_image() if baked else Image.create(w,h,false,Image.FORMAT_RGBA8)
	var faces: Image=(load("res://studio-generated/verification-1793991159229/autotile/baked-faces.png") as Texture2D).get_image() if baked else Image.create(w,h,false,Image.FORMAT_RGBA8)
	var shadows: Image=(load("res://studio-generated/verification-1793991159229/autotile/baked-shadow.png") as Texture2D).get_image() if baked else Image.create(w,h,false,Image.FORMAT_RGBA8)
	for y: int in range(wh):
		for x: int in range(w):
			heights[y*w+x]=support(a,Vector2(x+0.5,y+0.5))
	for y: int in range(wh):
		for x: int in range(w):
			var i := surface_support(a,x+0.5,y+0.5,0)
			var n := (y+PAD)*w+x
			owners[n]=i
			depth[n]=y+0.5
			if not baked:
				top.set_pixel(x,y+PAD,sample_floor(a,i,x%32,y%32,relief_rim(heights,w,wh,x,y)))
	var contacts: Array[Vector4]=[]
	for y: int in range(wh):
		for x: int in range(w):
			var z := heights[y*w+x]
			var i := surface_support(a,x+0.5,y+0.5,z)
			var low := heights[(y+1)*w+x] if y+1<wh else 0.0
			var sy := int(floor(y-z*16))
			var falling := z-low>0.22
			var end := int(floor(y+1-z*16)) if falling else maxi(sy+1,int(floor(y+1-low*16)))
			var color := sample_floor(a,i,x%32,y%32,relief_rim(heights,w,wh,x,y)) if not baked else Color(0,0,0,0)
			for yy: int in range(sy,end):
				var n := (yy+PAD)*w+x
				owners[n]=i
				depth[n]=y+0.5
				zmap[n]=z
				kinds[n]=0
				if not baked:
					top.set_pixel(x,yy+PAD,color)
					faces.set_pixel(x,yy+PAD,Color(0,0,0,0))
			if falling:
				var wall_cell := wall_support(a,x+0.5,y+0.5,z)
				var wall_kind: String=a.cliffs[wall_cell]
				var start := int(floor(y+1-z*16))
				var bottom := int(floor(y+1-low*16))
				for yy: int in range(start,bottom):
					var n := (yy+PAD)*w+x
					owners[n]=wall_cell
					depth[n]=y+1
					zmap[n]=z
					kinds[n]=1
					if not baked:
						var wall_z := -(y+1-yy) if wall_specs.has(wall_kind) else y+1-yy
						var cc: Color=(textures[wall_kind] as Image).get_pixel(x%64,posmod(wall_z,64))
						var distance := yy-start
						if wall_specs.has(wall_kind) and distance>=2 and distance<8:
							var percent: int=[78,82,87,92,96,100][distance-2]
							cc=Color(float(int((roundi(cc.r*255)*percent+50)/100))/255,float(int((roundi(cc.g*255)*percent+50)/100))/255,float(int((roundi(cc.b*255)*percent+50)/100))/255,1)
						var grass: bool = (a.floors[i]=="grass" or (ground_specs.has(a.floors[i]) and ground_specs[a.floors[i]].family=="Gramas")) and (not a.get("autotiling",true) or bool(shape(neighbor(a,i))[y%32*32+x%32]))
						if distance<2:
							if grass:
								cc=Color("79974b" if distance else "496c35")
							elif wall_specs.has(wall_kind):
								cc=Color(wall_specs[wall_kind].light if distance else wall_specs[wall_kind].dark)
							else:
								cc=Color("c9aa73" if distance else "78613f")
						if distance==2 and grass and x%4<3:
							cc=Color("9cb85e")
						top.set_pixel(x,yy+PAD,Color(0,0,0,0))
						faces.set_pixel(x,yy+PAD,cc)
				if not baked:
					contacts.append(Vector4(x,bottom,low,y+1))
	if not baked:
		for contact: Vector4 in contacts:
			for d: int in range(3):
				var yy := int(contact.y)+d+PAD
				if yy<0 or yy>=h:
					continue
				var n := yy*w+int(contact.x)
				if owners[n]>=0 and kinds[n]==0 and depth[n]>=contact.w-0.1 and zmap[n]<=contact.z+0.1:
					shadows.set_pixel(int(contact.x),yy,Color(39.0/255,55.0/255,33.0/255,float([62,35,15][d])/255))
	cached={"key":key,"width":w,"height":h,"depth":depth,"zmap":zmap,"owners":owners,"kinds":kinds,"top":ImageTexture.create_from_image(top),"faces":ImageTexture.create_from_image(faces),"shadow":ImageTexture.create_from_image(shadows)}
	return cached

