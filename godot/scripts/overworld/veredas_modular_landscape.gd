extends Node2D
## Native terrain and individual props. The concept image is never loaded.
const KIT := "res://assets/overworld/kits/"
const Warp = preload("res://scripts/overworld/legacy_map_warp.gd")
var warp := Warp.new()
var layout: Dictionary
var prop_nodes: Array[Node2D]=[]
var geometry_only := false
var show_props := true
var water_material: ShaderMaterial
var terrain: ShaderMaterial
var water: Polygon2D
var raised: Array[Dictionary]=[]
var raised_outlines: Array[PackedVector2Array]=[]

func elevation(p: Vector2) -> float:
	for region in raised:
		if Geometry2D.is_point_in_polygon(p,region.points):return _region_height(region,p)
	return 0.0

func _region_height(region: Dictionary,p: Vector2) -> float:
	if region.get("ramp",false):return region.height*clampf((region.bottom-p.y)/(region.bottom-region.top),0,1)
	return region.height

func surface(p: Vector2) -> Vector2:return p-Vector2(0,elevation(p))
func project(p: Vector2) -> Vector2:return surface(warp.transform(p))
func depth(p: Vector2) -> int:return clampi(roundi(warp.transform(p).y),-4000,4000)

func jump_links() -> Array:
	# Measured stretches on the front faces, away from ramps, props and water.
	# All coordinates are derived on the terrain plane, then converted to save space.
	var result: Array = []
	for entry in [
		{"id":"mirante", "edge":Vector2(503,199), "out":Vector2(14,47).normalized(), "drop":48.0},
		{"id":"patio", "edge":Vector2(1235,290), "out":Vector2(-21,91).normalized(), "drop":80.0}
	]:
		var start: Vector2 = entry.edge - entry.out * 20
		var finish: Vector2 = entry.edge + entry.out * 36
		result.append({"id":entry.id, "from":warp.transform(start,true), "to":warp.transform(finish,true), "drop":entry.drop})
	return result
func unproject(p: Vector2) -> Vector2:
	for region in raised:
		var y: float=p.y+region.height
		if region.get("ramp",false):
			var slope: float=region.height/(region.bottom-region.top)
			y=(p.y+slope*region.bottom)/(1.0+slope)
		var candidate := Vector2(p.x,y)
		if Geometry2D.is_point_in_polygon(candidate,region.points):return warp.transform(candidate,true)
	return warp.transform(p,true)

func build(_id: String,_source: Dictionary) -> void:
	layout=JSON.parse_string(FileAccess.get_file_as_string(KIT+"veredas-modular-v5/layout.json"))
	warp.setup(layout.anchors)
	for region: Dictionary in layout.raised:
		var r := region.duplicate();r.points=polygon(r.points);raised.append(r)
		raised_outlines.append(r.points)
	var merging := true
	while merging:
		merging=false
		for i in raised_outlines.size():
			for j in range(i+1,raised_outlines.size()):
				var merged := Geometry2D.merge_polygons(raised_outlines[i],raised_outlines[j])
				if merged.size()==1:
					raised_outlines[i]=merged[0];raised_outlines.remove_at(j);merging=true;break
			if merging:break
	var backdrop := CanvasLayer.new();backdrop.layer=-100
	var bg := ColorRect.new();bg.color=Color("0c1624")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(bg);add_child(backdrop)
	terrain=ShaderMaterial.new();terrain.shader=load("res://shaders/overworld/veredas_modular.gdshader")
	terrain.set_shader_parameter("grass_texture",load(KIT+"planicie-v1/surfaces/grama.png"))
	terrain.set_shader_parameter("earth_texture",load(KIT+"planicie-v1/surfaces/terra.png"))
	terrain.set_shader_parameter("geometry_only",geometry_only)
	var segments := PackedVector4Array()
	for path: Array in layout.paths:
		for i in range(path.size()-1):segments.append(Vector4(path[i][0],path[i][1],path[i+1][0],path[i+1][1]))
	terrain.set_shader_parameter("path_count",segments.size());segments.resize(64)
	terrain.set_shader_parameter("paths",segments)
	_build_water()
	var outlines: Array[PackedVector2Array]=[polygon(layout.landmass)]
	var changed := true
	while changed:
		changed=false
		for i in outlines.size():
			for j in range(i+1,outlines.size()):
				var merged := Geometry2D.merge_polygons(outlines[i],outlines[j])
				if merged.size()==1:
					outlines[i]=merged[0];outlines.remove_at(j);changed=true;break
			if changed:break
	for outline in outlines:
		_ground(outline)
		var area := 0.0
		for i in outline.size():area+=outline[i].cross(outline[(i+1)%outline.size()])
		for i in outline.size():
			var a := outline[i];var b := outline[(i+1)%outline.size()]
			if ((b-a).x*signf(area))<=0:continue
			var cuts: Array[float]=[0.0,1.0]
			if absf(b.y-a.y)>.01:
				for y in [180.0,230.0,330.0]:
					var t: float=(y-a.y)/(b.y-a.y)
					if t>0 and t<1:cuts.append(t)
			cuts.sort()
			for k in range(cuts.size()-1):_bank(a.lerp(b,cuts[k]),a.lerp(b,cuts[k+1]))
	for region in raised:_ground(region.points,region)
	for outline in raised_outlines:
		var area := 0.0
		for i in outline.size():area+=outline[i].cross(outline[(i+1)%outline.size()])
		for i in outline.size():
			var a := outline[i];var b := outline[(i+1)%outline.size()]
			var outward := Vector2((b-a).y,-(b-a).x).normalized()*signf(area)
			if outward.y<=.001:continue
			var ha := 0.0;var hb := 0.0
			for region in raised:
				if Geometry2D.is_point_in_polygon((a+b)*.5-outward*.15,region.points):
					ha=_region_height(region,a);hb=_region_height(region,b);break
			if maxf(ha,hb)<.01:continue
			_mesh(PackedVector2Array([a-Vector2(0,ha),b-Vector2(0,hb),b,a]),PackedVector2Array([Vector2(a.x/180,ha/100),Vector2(b.x/180,hb/100),Vector2(b.x/180,0),Vector2(a.x/180,0)]),null if geometry_only else load(KIT+"cais-v1/surfaces/rocha.png"),null,roundi((a.y+b.y)*.5)-1,Color("a5ac87"))
	for bridge: Dictionary in layout.bridges:_bridge(polygon(bridge.points))
	# The stream uses the same cut as collision and the same bank vertices.
	var creek := polygon(layout.water)
	for i in creek.size():
		var a := creek[i];var b := creek[(i+1)%creek.size()]
		var midpoint := (a+b)*.5
		var on_bridge := false
		for bridge: Dictionary in layout.bridges:
			if Geometry2D.is_point_in_polygon(midpoint,polygon(bridge.points)):on_bridge=true
		if not on_bridge:
			_mesh(PackedVector2Array([surface(a),surface(b),b+Vector2(0,24),a+Vector2(0,24)]),PackedVector2Array([Vector2(a.x/180,0),Vector2(b.x/180,0),Vector2(b.x/180,.24),Vector2(a.x/180,.24)]),null if geometry_only else load(KIT+"cais-v1/surfaces/rocha.png"),null,-2001,Color("92977c"))
	_stairs()
	if show_props and not geometry_only:_dress_modular()

func _mesh(points: PackedVector2Array,uv: PackedVector2Array,texture: Texture2D,material: Material,z: int,tint: Color=Color.WHITE) -> void:
	var ids := Geometry2D.triangulate_polygon(points)
	if ids.is_empty():return
	var arrays := [];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=ids
	var mesh := ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := MeshInstance2D.new();node.mesh=mesh;node.texture=texture;node.material=material
	node.modulate=tint;node.z_index=z;node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;add_child(node)

func _ground(outline: PackedVector2Array,region: Dictionary={}) -> void:
	# Small cells share exact height breaks and UV phase, including ramp joints.
	var rows: Array[float]=[]
	for y in range(96,944,24):rows.append(float(y))
	for y in [206.0,250.0,296.0,330.0]:rows.append(y)
	rows.sort()
	for row in range(rows.size()-1):
		if rows[row+1]-rows[row]<.001:continue
		for x in range(96,1488,24):
			var cell := PackedVector2Array([Vector2(x,rows[row]),Vector2(x+24,rows[row]),Vector2(x+24,rows[row+1]),Vector2(x,rows[row+1])])
			for section in Geometry2D.intersect_polygons(cell,outline):
				var parts: Array[PackedVector2Array]=[section]
				var cutters: Array[PackedVector2Array]=[]
				if region.is_empty():
					cutters.append(polygon(layout.water));cutters.append_array(raised_outlines)
				for cutter in cutters:
					var next: Array[PackedVector2Array]=[]
					for part in parts:next.append_array(Geometry2D.clip_polygons(part,cutter))
					parts=next
				for part in parts:
					var top := PackedVector2Array()
					for p in part:top.append(p-Vector2(0,0 if region.is_empty() else _region_height(region,p)))
					_mesh(top,part,null,terrain,-2000 if region.is_empty() else roundi((rows[row]+rows[row+1])*.5)-2)

func _bank(a: Vector2,b: Vector2) -> void:
	var bottom := -42.0
	var points := PackedVector2Array([a,b,b-Vector2(0,bottom),a-Vector2(0,bottom)])
	var uv := PackedVector2Array([Vector2(a.x/180,0),Vector2(b.x/180,0),Vector2(b.x/180,bottom/100),Vector2(a.x/180,bottom/100)])
	_mesh(points,uv,null if geometry_only else load(KIT+"cais-v1/surfaces/rocha.png"),null,-2001,Color("889a88") if not geometry_only else Color("52695f"))

func legacy_layout(original: Dictionary) -> Dictionary:
	var adapted := original.duplicate(true)
	adapted.floors=[];adapted.obstacles=[];adapted.separated_trees=[];adapted.foreground=[]
	for part in warp.legacy_polygons(polygon(layout.landmass)):
		adapted.floors.append({"name":"Vale continuo","points":as_array(part),"height":0})
	var creek_parts: Array[PackedVector2Array]=[polygon(layout.water)]
	for bridge: Dictionary in layout.bridges:
		var next: Array[PackedVector2Array]=[]
		for part in creek_parts:next.append_array(Geometry2D.clip_polygons(part,polygon(bridge.points)))
		creek_parts=next
	for part in creek_parts:
		for piece in warp.legacy_polygons(part):adapted.obstacles.append({"name":"Agua rebaixada","points":as_array(piece)})
	# A terrace edge is solid on both sides; only the zero-height ramp mouth opens.
	for outline in raised_outlines:
		var area := 0.0
		for i in outline.size():area+=outline[i].cross(outline[(i+1)%outline.size()])
		for i in outline.size():
			var a := outline[i];var b := outline[(i+1)%outline.size()]
			var normal := Vector2((b-a).y,-(b-a).x).normalized()*signf(area)
			if elevation((a+b)*.5-normal*.2)<4:continue
			var barrier := PackedVector2Array([a+normal*2,b+normal*2,b-normal*2,a-normal*2])
			for part in warp.legacy_polygons(barrier):adapted.obstacles.append({"name":"Borda do patamar","points":as_array(part)})
	for obstacle: Dictionary in layout.obstacles:
		var p := PackedVector2Array()
		if obstacle.has("points"):p=polygon(obstacle.points)
		else:
			for i in 24:p.append(Vector2(obstacle.center[0],obstacle.center[1])+Vector2(cos(TAU*i/24)*obstacle.radius[0],sin(TAU*i/24)*obstacle.radius[1]))
		for piece in warp.legacy_polygons(p):adapted.obstacles.append({"name":obstacle.name,"points":as_array(piece)})
	return adapted

func _build_water() -> void:
	water=Polygon2D.new();water.name="NativeRecessedCreek"
	var points := PackedVector2Array()
	for p in polygon(layout.water):points.append(p+Vector2(0,24))
	water.polygon=points;water.z_index=-3900;water.color=Color("4b96a4")
	if not geometry_only:
		water_material=ShaderMaterial.new();water_material.shader=load("res://shaders/overworld/water_surface.gdshader")
		water_material.set_shader_parameter("surface_texture",load(KIT+"cavernas-v3/surfaces/agua-linhas.png"))
		var mask := Image.create(1,1,false,Image.FORMAT_RGBA8);mask.fill(Color.BLACK)
		water_material.set_shader_parameter("shore_texture",ImageTexture.create_from_image(mask))
		var prefs=preload("res://scripts/campaign/preferences.gd").new();prefs.load_settings()
		water_material.set_shader_parameter("preview_time",0.0 if prefs.reduced_motion else -1.0)
		water_material.set_shader_parameter("ripple_strength",.004)
		water.material=water_material;water.color=Color.WHITE
	add_child(water)

func _line(a: Vector2,b: Vector2,z: int,color: Color,width: float=2.0) -> void:
	var node := Line2D.new();node.points=PackedVector2Array([a,b]);node.z_index=z
	node.default_color=color;node.width=width;node.antialiased=true;add_child(node)

func _bridge(p: PackedVector2Array) -> void:
	var top := PackedVector2Array();var uv := PackedVector2Array()
	for v in p:top.append(surface(v));uv.append(v/128)
	_mesh(top,uv,null if geometry_only else load(KIT+"cais-v1/surfaces/madeira.png"),null,roundi((p[0].y+p[2].y)*.5)-2,Color("d1aa79"))
	# Planks and rails follow a shared deck plane; both heads stay open.
	for i in range(1,12):
		var t := i/12.0
		var a := p[0].lerp(p[1],t);var b := p[3].lerp(p[2],t)
		_line(surface(a),surface(b),roundi(maxf(a.y,b.y)),Color("896445"),1)
	for edge in [[0,1],[3,2]]:
		var a := p[edge[0]];var b := p[edge[1]]
		for i in 4:
			var q := a.lerp(b,i/3.0)
			_line(surface(q),surface(q)-Vector2(0,25),roundi(q.y)+1,Color("75573b"),4)
		_line(surface(a)-Vector2(0,24),surface(b)-Vector2(0,24),roundi((a.y+b.y)*.5)+1,Color("be9c70"),2)

func _stairs() -> void:
	for i in range(1,9):
		var t := i/9.0
		var a := Vector2(434,206).lerp(Vector2(469,296),t)
		var b := Vector2(480,206).lerp(Vector2(523,296),t)
		_line(surface(a),surface(b),roundi(a.y)+1,Color("d4c8a0"),4)
		_line(surface(a)+Vector2(0,2),surface(b)+Vector2(0,2),roundi(a.y)+1,Color("7e8067"),1)

func polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:result.append(Vector2(p[0],p[1]))
	return result

func as_array(points: PackedVector2Array) -> Array:
	var result := []
	for p in points:result.append([p.x,p.y])
	return result

func _prop(file: String,pivot: Vector2,p: Vector2,factor: float) -> void:
	var node := Sprite2D.new();node.texture=load(file);node.centered=false
	node.offset=-pivot;node.scale=Vector2.ONE*factor;node.position=surface(p);node.z_index=roundi(p.y)
	add_child(node);prop_nodes.append(node)

func _dress_modular() -> void:
	var tree: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(KIT+"planicie-v1/library.json")).props.arvore
	for o: Dictionary in layout.obstacles:
		if not o.has("center"):continue
		_prop(KIT+"planicie-v1/"+tree.file,Vector2(tree.pivot[0],tree.pivot[1]),Vector2(o.center[0],o.center[1]),.90)
	var kit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(KIT+"comum/kit.json"))
	for item in [["banco",Vector2(294,739)],["placa-mapa",Vector2(216,735)]]:
		var piece: Dictionary=kit.pieces[item[0]];var d: Dictionary=piece.variants[piece.default]
		_prop(KIT+"comum/"+d.file,Vector2(d.anchor[0],d.anchor[1]),item[1],.8)
	var pipes: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(KIT+"veredas/kit.json")).pieces["canos-patio"]
	var pipe: Dictionary=pipes.variants[pipes.default]
	_prop(KIT+"veredas/"+pipe.file,Vector2(pipe.anchor[0],pipe.anchor[1]),Vector2(1260,244),.85)
