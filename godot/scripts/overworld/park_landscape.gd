extends Node2D
## Three campaign landscapes. Coordinates remain in the existing save domain.
## Every top, bank, prop and actor uses the same height/projection contract.
var scene_id := "park-trail"
var source: Dictionary = {}
var geometry_only := false
var show_props := true
var ground_paint: ShaderMaterial
var patches: Array[Dictionary] = []
var prop_nodes: Array[Node2D] = []
var static_blockers: Array[Dictionary] = []
var wall_texture: Texture2D
var water: Polygon2D
const STEP := 16.0
const BASE := "res://assets/overworld/kits/"
const VALLEY_HEIGHT := -48.0
const RIVER_HEIGHT := -72.0
const ISLAND_BOTTOM := -112.0
var valley_footprint := PackedVector2Array()
var river_footprint := PackedVector2Array()
var valley_surface_count := 0

static func valley_outline() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-45,1010),Vector2(-55,790),Vector2(-48,550),Vector2(30,380),Vector2(115,265),Vector2(120,110),Vector2(220,30),Vector2(390,38),Vector2(505,105),Vector2(650,30),Vector2(820,40),Vector2(980,100),Vector2(1140,-35),Vector2(1320,-25),Vector2(1510,30),Vector2(1590,210),Vector2(1570,420),Vector2(1560,570),Vector2(1450,680),Vector2(1200,815),Vector2(970,910),Vector2(800,930),Vector2(600,880),Vector2(360,800),Vector2(240,850),Vector2(70,990)])

static func river_outline() -> PackedVector2Array:
	return PackedVector2Array([Vector2(600,400),Vector2(755,420),Vector2(785,535),Vector2(830,590),Vector2(880,645),Vector2(950,700),Vector2(910,760),Vector2(820,800),Vector2(810,850),Vector2(665,827),Vector2(665,775),Vector2(640,736),Vector2(620,703),Vector2(600,650),Vector2(572,610),Vector2(540,600),Vector2(500,570),Vector2(505,520),Vector2(540,490),Vector2(600,480)])

func planar(p: Vector2) -> Vector2:
	return p if scene_id=="park-veredas" else Vector2((p.x-p.y)*.82+930,(p.x+p.y)*.41+20)

func height_at(p: Vector2) -> float:
	if scene_id=="park-veredas":return 80.0*clampf((440.0-p.y)/190.0,0,1)+32.0*clampf((200.0-p.y)/120.0,0,1)
	var high := 64.0 if scene_id=="park-clearing" else 48.0
	if p.x<704:return 0.0
	if p.y<448.0:return high
	var ramp_x := 1088.0 if scene_id=="park-clearing" else 832.0
	if p.x>=ramp_x and p.x<=ramp_x+192 and p.y<=640:return high*clampf((640.0-p.y)/192.0,0,1)
	return 0.0

func patch_height(s: Dictionary,p: Vector2) -> float:
	if scene_id=="park-veredas":return height_at(p)
	var high := 64.0 if scene_id=="park-clearing" else 48.0
	if s.center.x<704:return 0.0
	if s.center.y<448:return high
	var ramp_x := 1088.0 if scene_id=="park-clearing" else 832.0
	if s.center.x>=ramp_x and s.center.x<ramp_x+192 and s.center.y<640:return high*clampf((640.0-p.y)/192.0,0,1)
	return 0.0

func project(p: Vector2) -> Vector2:return planar(p)-Vector2(0,height_at(p))
func depth(p: Vector2) -> int:return clampi(roundi(planar(p).y),-4000,4000)

func unproject(screen: Vector2) -> Vector2:
	if scene_id!="park-veredas":return Vector2.ZERO
	# Monotone y-height(y): inverse is unique even on a slope.
	var lo := screen.y-1.0
	var hi := screen.y+114.0
	for i in 24:
		var y := (lo+hi)*.5
		if y-height_at(Vector2(screen.x,y))<screen.y:lo=y
		else:hi=y
	return Vector2(screen.x,(lo+hi)*.5)

func connected(a: Vector2,b: Vector2) -> bool:
	var count := maxi(1,ceili(a.distance_to(b)/2.0))
	var last := height_at(a)
	for i in range(1,count+1):
		var next := height_at(a.lerp(b,float(i)/count))
		if absf(next-last)>2.0:return false
		last=next
	return true

func build(id: String,data: Dictionary) -> void:
	scene_id=id;source=data
	var backdrop := CanvasLayer.new();backdrop.layer=-100
	var void_color := ColorRect.new();void_color.color=Color("0c1624")
	void_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	void_color.mouse_filter=Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(void_color);add_child(backdrop)
	wall_texture=load(BASE+("cais-v1/surfaces/rocha.png" if id=="park-veredas" else "bairro-inicial-v2/surfaces/terra-fundacao.png"))
	ground_paint=ShaderMaterial.new()
	ground_paint.shader=load("res://shaders/overworld/park_landscape.gdshader")
	ground_paint.set_shader_parameter("grass_texture",load(BASE+"planicie-v1/surfaces/grama.png"))
	ground_paint.set_shader_parameter("earth_texture",load(BASE+"planicie-v1/surfaces/terra.png"))
	ground_paint.set_shader_parameter("geometry_only",geometry_only)
	ground_paint.set_shader_parameter("veredas",id=="park-veredas")
	var paths := PackedVector4Array()
	var habitats := PackedVector4Array()
	if id!="park-veredas":
		for rect: Dictionary in data.walkable:
			var r := Vector4(rect.x+rect.w*.5,rect.y+rect.h*.5,rect.w*.5,rect.h*.5)
			if rect.properties.get("ground_frame","") in ["dirt","sidewalk"]:paths.append(r)
			if rect.properties.has("encounter_zone"):habitats.append(r)
		# The lower and upper landings share the exact ramp footprint.
		paths.append(Vector4(1184 if id=="park-clearing" else 928,544,72,112))
	else:
		for r in [[210,810,62,48],[300,115,65,30],[485,454,130,25],[900,466,112,30],[1110,579,110,30],[1040,775,90,32],[1270,167,116,45],[770,203,155,23]]:paths.append(Vector4(r[0],r[1],r[2],r[3]))
		for rect: Rect2 in preload("res://scripts/campaign/park_data.gd").GRASS:habitats.append(Vector4(rect.get_center().x,rect.get_center().y,rect.size.x*.5,rect.size.y*.5))
	ground_paint.set_shader_parameter("path_count",paths.size())
	paths.resize(32);ground_paint.set_shader_parameter("paths",paths)
	ground_paint.set_shader_parameter("habitat_count",habitats.size())
	habitats.resize(16);ground_paint.set_shader_parameter("habitats",habitats)
	if id=="park-veredas":_veredas()
	else:_park()
	if show_props and not geometry_only:_dress()

func _mesh(points: PackedVector2Array,uv: PackedVector2Array,paint: Material,tint: Color,z: int,texture: Texture2D=null) -> void:
	var indices := Geometry2D.triangulate_polygon(points)
	if indices.is_empty():return
	var arrays := [];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := MeshInstance2D.new();node.mesh=mesh;node.material=paint;node.modulate=tint;node.texture=texture
	node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	node.z_index=z;add_child(node)

func _wall(a: Vector2,b: Vector2,ha: float,hb: float,la: float,lb: float) -> void:
	if maxf(ha-la,hb-lb)<.01:return
	var points := PackedVector2Array();var uv := PackedVector2Array()
	var samples := [Vector3(a.x,a.y,ha),Vector3(b.x,b.y,hb),Vector3(b.x,b.y,lb),Vector3(a.x,a.y,la)]
	for p: Vector3 in samples:
		var q := planar(Vector2(p.x,p.y))-Vector2(0,p.z)
		if points.has(q):continue
		points.append(q);uv.append(Vector2((p.x+p.y)/150.0,p.z/96.0))
	if points.size()<3:return
	var tint := Color.WHITE if scene_id!="park-veredas" else Color("c1c8b0")
	if b.x<a.x:tint=tint.darkened(.13)
	_mesh(points,uv,null,tint,depth((a+b)*.5)-1,null if geometry_only else wall_texture)

func _park() -> void:
	var lookup := {}
	for y in range(192,944,16):
		for x in range(80,1456,16):
			var s := {"origin":Vector2(x,y),"center":Vector2(x+8,y+8)}
			patches.append(s);lookup[Vector2i(x,y)]=s
	for s in patches:
		var a: Vector2=s.origin
		var cells := PackedVector2Array([a,a+Vector2(16,0),a+Vector2(16,16),a+Vector2(0,16)])
		var points := PackedVector2Array()
		for p in cells:points.append(planar(p)-Vector2(0,patch_height(s,p)))
		_mesh(points,cells,ground_paint,Color.WHITE,depth(s.center)-2)
		for edge in [[0,1,Vector2i(0,-16)],[1,2,Vector2i(16,0)],[2,3,Vector2i(0,16)],[3,0,Vector2i(-16,0)]]:
			var p := cells[edge[0]];var q := cells[edge[1]]
			var neighbor: Dictionary=lookup.get(Vector2i(a)+edge[2],{})
			var bottom_a := -44.0 if neighbor.is_empty() else patch_height(neighbor,p)
			var bottom_b := -44.0 if neighbor.is_empty() else patch_height(neighbor,q)
			_wall(p,q,patch_height(s,p),patch_height(s,q),bottom_a,bottom_b)

func _subdivide(a: Vector2,b: Vector2,c: Vector2,wood: bool,level: int=0) -> void:
	if level<6 and maxf(a.distance_to(b),maxf(b.distance_to(c),c.distance_to(a)))>42:
		var ab := (a+b)*.5;var bc := (b+c)*.5;var ca := (c+a)*.5
		_subdivide(a,ab,ca,wood,level+1);_subdivide(ab,b,bc,wood,level+1)
		_subdivide(ca,bc,c,wood,level+1);_subdivide(ab,bc,ca,wood,level+1);return
	var cells := PackedVector2Array([a,b,c]);var points := PackedVector2Array()
	for p in cells:points.append(project(p))
	if wood:
		_mesh(points,PackedVector2Array([a/128,b/128,c/128]),null,Color("c9a06a"),depth((a+b+c)/3)-2,load(BASE+"cais-v1/surfaces/madeira.png") if ResourceLoader.exists(BASE+"cais-v1/surfaces/madeira.png") else wall_texture)
	else:_mesh(points,cells,ground_paint,Color.WHITE,depth((a+b+c)/3)-2)

func _veredas() -> void:
	valley_footprint=valley_outline();river_footprint=river_outline()
	_valley_floor()
	# Water is below the measured banks. No blue overlay on walkable ground.
	water=Polygon2D.new();water.color=Color("417e8a");water.z_index=-3900
	var water_points := PackedVector2Array()
	for p in river_footprint:water_points.append(p-Vector2(0,RIVER_HEIGHT))
	water.polygon=water_points
	if not geometry_only:
		var flow := ShaderMaterial.new()
		flow.shader=load("res://shaders/overworld/water_surface.gdshader")
		flow.set_shader_parameter("surface_texture",load(BASE+"cavernas-v3/surfaces/agua-linhas.png"))
		var mask := Image.create(1,1,false,Image.FORMAT_RGBA8)
		mask.fill(Color(0,0,0,1))
		flow.set_shader_parameter("shore_texture",ImageTexture.create_from_image(mask))
		var preferences=preload("res://scripts/campaign/preferences.gd").new()
		preferences.load_settings()
		flow.set_shader_parameter("preview_time",0.0 if preferences.reduced_motion else -1.0)
		flow.set_shader_parameter("ripple_strength",.006)
		water.material=flow;water.color=Color.WHITE
	add_child(water)
	var outlines: Array[PackedVector2Array]=[]
	for floor_data: Dictionary in source.floors:
		var p := PackedVector2Array()
		for xy in floor_data.points:p.append(Vector2(xy[0],xy[1]))
		var wood := str(floor_data.name).begins_with("Ponte ")
		# Cut at the actual changes of height gradient. A triangle spanning
		# two ramps would approximate their join and open a slit at its bank.
		var bands := [-1000.0,80.0,200.0,250.0,440.0,2000.0]
		for band in range(bands.size()-1):
			var strip := PackedVector2Array([Vector2(-1000,bands[band]),Vector2(3000,bands[band]),Vector2(3000,bands[band+1]),Vector2(-1000,bands[band+1])])
			for section in Geometry2D.intersect_polygons(p,strip):
				var triangles := Geometry2D.triangulate_polygon(section)
				for i in range(0,triangles.size(),3):_subdivide(section[triangles[i]],section[triangles[i+1]],section[triangles[i+2]],wood)
		if wood:_bridge_details(p)
		if not wood:outlines.append(p)
	# Merge support first: ground_paint boundaries never generate internal walls.
	var changed := true
	while changed:
		changed=false
		for i in outlines.size():
			for j in range(i+1,outlines.size()):
				var merged := Geometry2D.merge_polygons(outlines[i],outlines[j])
				if merged.size()==1:
					outlines[i]=merged[0];outlines.remove_at(j);changed=true;break
			if changed:break
	for p in outlines:
		var area := 0.0
		for i in p.size():area+=p[i].cross(p[(i+1)%p.size()])
		for i in p.size():
			var a := p[i];var b := p[(i+1)%p.size()]
			var outward := Vector2((b-a).y,-(b-a).x)*signf(area)
			# An extrusion on a back-facing shore lies behind the top. Drawing
			# it over that top creates the triangular tears seen in review.
			if outward.y<=.001:continue
			var fractions: Array[float]=[0.0,1.0]
			if absf(b.y-a.y)>.001:
				for cut in [80.0,200.0,250.0,440.0]:
					var fraction: float=(cut-a.y)/(b.y-a.y)
					if fraction>.00001 and fraction<.99999:fractions.append(fraction)
			fractions.sort()
			for k in range(fractions.size()-1):
				var start := a.lerp(b,fractions[k]);var end := a.lerp(b,fractions[k+1])
				# The elevated routes now stand on the lower valley, not in void.
				var midpoint := (start+end)*.5
				if midpoint.y>250 and midpoint.y<440:
					_talus(start,end,outward.normalized())
				else:_wall(start,end,height_at(start),height_at(end),VALLEY_HEIGHT,VALLEY_HEIGHT)

func _talus(a: Vector2,b: Vector2,outward: Vector2) -> void:
	var foot_a := a+outward*36.0;var foot_b := b+outward*36.0
	var points := PackedVector2Array([project(a),project(b),foot_b-Vector2(0,VALLEY_HEIGHT),foot_a-Vector2(0,VALLEY_HEIGHT)])
	# Rock UV follows height, rather than stretching painted grass blades down
	# the bank. The upper and lower vertices still use their real support.
	var uv := PackedVector2Array([Vector2((a.x+a.y)/150,height_at(a)/96),Vector2((b.x+b.y)/150,height_at(b)/96),Vector2((foot_b.x+foot_b.y)/150,VALLEY_HEIGHT/96),Vector2((foot_a.x+foot_a.y)/150,VALLEY_HEIGHT/96)])
	_mesh(points,uv,null,Color("a6b092"),depth((a+b)*.5)-1,null if geometry_only else wall_texture)

func _valley_floor() -> void:
	var vertices := PackedVector2Array();var uv := PackedVector2Array();var indices := PackedInt32Array()
	# Clip small cells rather than filling the inner ring returned by a whole
	# polygon difference. The long river cannot be enclosed by a 32px cell.
	for y in range(-64,1024,32):
		for x in range(-64,1600,32):
			var cell := PackedVector2Array([Vector2(x,y),Vector2(x+32,y),Vector2(x+32,y+32),Vector2(x,y+32)])
			for clipped in Geometry2D.intersect_polygons(cell,valley_footprint):
				for p in Geometry2D.clip_polygons(clipped,river_footprint):
					var triangulation := Geometry2D.triangulate_polygon(p)
					if triangulation.is_empty():continue
					var offset := vertices.size()
					for point in p:vertices.append(point-Vector2(0,VALLEY_HEIGHT));uv.append(point)
					for index in triangulation:indices.append(offset+index)
					valley_surface_count+=1
	var arrays := [];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var floor_node := MeshInstance2D.new();floor_node.name="ValleyContinuousFloor";floor_node.mesh=mesh
	var paint := ground_paint.duplicate() as ShaderMaterial
	paint.set_shader_parameter("path_count",0);paint.set_shader_parameter("habitat_count",0)
	floor_node.material=paint;floor_node.modulate=Color("a5bab0");floor_node.z_index=-3500
	add_child(floor_node)
	_lower_faces(valley_footprint,VALLEY_HEIGHT,ISLAND_BOTTOM,-3600,false)
	_lower_faces(river_footprint,VALLEY_HEIGHT,RIVER_HEIGHT,-3400,true)

func _lower_faces(outline: PackedVector2Array,top: float,bottom: float,z: int,inside: bool) -> void:
	var area := 0.0
	for i in outline.size():area+=outline[i].cross(outline[(i+1)%outline.size()])
	for i in outline.size():
		var a := outline[i];var b := outline[(i+1)%outline.size()]
		var normal := Vector2((b-a).y,-(b-a).x)*signf(area)*(-1.0 if inside else 1.0)
		if normal.y<=.001:continue
		var points := PackedVector2Array([a-Vector2(0,top),b-Vector2(0,top),b-Vector2(0,bottom),a-Vector2(0,bottom)])
		var uv := PackedVector2Array([Vector2((a.x+a.y)/150,top/96),Vector2((b.x+b.y)/150,top/96),Vector2((b.x+b.y)/150,bottom/96),Vector2((a.x+a.y)/150,bottom/96)])
		_mesh(points,uv,null,Color("819889"),z,null if geometry_only else wall_texture)

func _on_route(p: Vector2) -> bool:
	for f: Dictionary in source.floors:
		var polygon := PackedVector2Array()
		for xy in f.points:polygon.append(Vector2(xy[0],xy[1]))
		if Geometry2D.is_point_in_polygon(p,polygon):return true
	return false

func _valley_trees(tree: Dictionary) -> void:
	# Small authored groups, with roots below the upper routes. No canopy carpet.
	for p in [Vector2(420,200),Vector2(454,218),Vector2(480,240),Vector2(875,300),Vector2(917,320),Vector2(1010,375),Vector2(1050,390),Vector2(1320,325),Vector2(1365,350),Vector2(1430,405),Vector2(355,880),Vector2(400,895),Vector2(1110,865)]:
		if _on_route(p) or Geometry2D.is_point_in_polygon(p,river_footprint):continue
		var root := Node2D.new();root.position=p-Vector2(0,VALLEY_HEIGHT);root.z_index=-3200+int(p.y/8)
		var sprite := Sprite2D.new();sprite.texture=load(BASE+"planicie-v1/"+tree.file);sprite.centered=false
		var factor := .48 if int(p.x)%2==0 else .57
		sprite.scale=Vector2.ONE*factor;sprite.position=-Vector2(tree.pivot[0],tree.pivot[1])*factor
		sprite.modulate=Color("a1b6a4")
		root.add_child(sprite);add_child(root);prop_nodes.append(root)

func _bridge_details(p: PackedVector2Array) -> void:
	for i in p.size():
		var a := p[i];var b := p[(i+1)%p.size()]
		if a.distance_to(b)<95:continue
		# Each post starts in the same deck plane; the long rails keep both
		# short ends open. Their depth follows their actual ground baseline.
		for k in 4:
			var point := a.lerp(b,float(k)/3)
			_line3(point,point,0.0 if k in [0,3] else RIVER_HEIGHT,25,Color("806345"),3.0)
		_line3(a,b,25,25,Color("bd9b68"),2.0)

func _line3(a: Vector2,b: Vector2,ha: float,hb: float,tint: Color,width: float) -> void:
	var node := Line2D.new()
	node.points=PackedVector2Array([planar(a)-Vector2(0,ha),planar(b)-Vector2(0,hb)])
	node.default_color=tint;node.width=width;node.antialiased=true
	node.z_index=depth((a+b)*.5)+1
	add_child(node)

func _prop(file: String,pivot: Vector2,p: Vector2,factor: float=1.0) -> void:
	if not ResourceLoader.exists(file):return
	var root := Node2D.new();root.position=planar(p);root.z_index=depth(p)
	var sprite := Sprite2D.new();sprite.texture=load(file);sprite.centered=false
	sprite.scale=Vector2.ONE*factor;sprite.position=-pivot*factor-Vector2(0,height_at(p))
	root.add_child(sprite);add_child(root);prop_nodes.append(root)

func _dress() -> void:
	var tree: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"planicie-v1/library.json")).props.arvore
	if scene_id!="park-veredas":
		for block: Dictionary in source.blocked:
			var point := Vector2(block.x+block.w*.5,block.y+block.h*.5)
			# The landscape ends at its real support. No dangling border trees.
			if point.x<90 or point.x>1440 or point.y<202 or point.y>930:continue
			if "tree" in str(block.name):_prop(BASE+"planicie-v1/"+tree.file,Vector2(tree.pivot[0],tree.pivot[1]),point,.78)
			else:_legacy_prop(block.name,point)
		if scene_id=="park-trail":
			var park_kit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"parque/kit.json"))
			var gazebo: Dictionary=park_kit.pieces.coreto.variants.default
			_gazebo(gazebo,Vector2(336,420))
		var seen := {}
		for rect: Dictionary in source.walkable:
			if not rect.properties.has("encounter_zone"):continue
			for y in range(ceili(rect.y/28)*28,int(rect.y+rect.h),28):
				for x in range(ceili(rect.x/36)*36,int(rect.x+rect.w),36):
					var hash_value := posmod(x*17+y*31,101)
					if hash_value>65:continue
					var p := Vector2(x+float(hash_value%17)-8,y+float(hash_value%9)-4)
					if seen.has(p):continue
					seen[p]=true
					_prop(BASE+"parque/decalques/capim-"+("a" if (x+y)%2==0 else "b")+".png",Vector2(26,45),p,.64)
	else:
		_valley_trees(tree)
		for obstacle: Dictionary in source.obstacles:
			if not obstacle.has("center"):continue
			var p := Vector2(obstacle.center[0],obstacle.center[1])
			if not source.floors.any(func(f: Dictionary):
				var poly := PackedVector2Array()
				for xy in f.points:poly.append(Vector2(xy[0],xy[1]))
				return Geometry2D.is_point_in_polygon(p,poly)):continue
			_prop(BASE+"planicie-v1/"+tree.file,Vector2(tree.pivot[0],tree.pivot[1]),p,.64)
		var veredas_kit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"veredas/kit.json"))
		var pipes: Dictionary=veredas_kit.pieces["canos-patio"]
		var d: Dictionary=pipes.variants[pipes.default]
		_prop(BASE+"veredas/"+d.file,Vector2(d.anchor[0],d.anchor[1]),Vector2(1400,100),.8)

func _legacy_prop(id: String,p: Vector2) -> void:
	var kit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"comum/kit.json"))
	var kind := "banco" if "bench" in id else "poste" if "lamp" in id else "placa-mapa" if "map" in id else ""
	if kind.is_empty() or not kit.pieces.has(kind):return
	var entry: Dictionary=kit.pieces[kind]
	var d: Dictionary=entry.variants[entry.default]
	_prop(BASE+"comum/"+d.file,Vector2(d.anchor[0],d.anchor[1]),p,.75)

func _gazebo(d: Dictionary,p: Vector2) -> void:
	var anchor := Vector2(d.anchor[0],d.anchor[1])
	var front := depth(p)
	for part: Dictionary in d.supportParts:
		var foot := planar(p)+(Vector2(part.foot[0],part.foot[1])-anchor)*.9
		var a := (foot.x-930.0)/.82
		var b := (foot.y-20.0)/.41
		var point := Vector2((a+b)*.5,(b-a)*.5)
		_prop(BASE+"parque/"+part.file,anchor,p,.9)
		prop_nodes.back().z_index=depth(point)
		front=maxi(front,depth(point))
		static_blockers.append({"name":"coreto-post-native","x":point.x-7,"y":point.y-7,"w":14,"h":14,"properties":{"level":0}})
	_prop(BASE+"parque/"+d.roofFile,anchor,p,.9)
	prop_nodes.back().z_index=front
