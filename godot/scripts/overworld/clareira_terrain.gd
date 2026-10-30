extends RefCounted
## Approved Clareira materials. Contours are baked offline; gameplay cells stay unchanged.
const BASE := "res://assets/overworld/kits/parque/manga-terrain/"
var AREA := Rect2i()
const DENSITY := 16
var origin := Vector2i.ZERO
var extent := Vector2i.ZERO
var mask: Texture2D
var material: ShaderMaterial
var rings: Array[PackedVector2Array] = []

func setup(model, kit: Dictionary, bake: bool = false, map_id: String = "clareira-do-papel") -> void:
	var contour_path := BASE+("clareira-contour.png" if map_id=="clareira-do-papel" else map_id+"-contour.png")
	var manifest_path := BASE+("manifest.json" if map_id=="clareira-do-papel" else map_id+"-manifest.json")
	AREA=Rect2i(0,0,int(model.data.w),int(model.data.h))
	origin=AREA.position-Vector2i(3,3)
	extent=AREA.size+Vector2i(6,6)
	var image: Image
	if bake:
		# Treat the square as part of the path's underlay, then overlay its exact,
		# constructed footprint. This avoids a grassy hairline at road/plaza joins.
		var occupied: Dictionary={}
		for v in range(origin.y,origin.y+extent.y):
			for u in range(origin.x,origin.x+extent.x):
				var at:=Vector2i(u,v)
				var cell: Dictionary=model.cell_at(at)
				if cell.get("material","") in ["terra","piso"]: occupied[at]=true
		var edges: Dictionary={}
		for at: Vector2i in occupied:
			var corners: Array[Vector2i]=[at,at+Vector2i.RIGHT,at+Vector2i.ONE,at+Vector2i.DOWN]
			var neighbors: Array[Vector2i]=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
			for i in 4:
				if occupied.has(at+neighbors[i]): continue
				if not edges.has(corners[i]): edges[corners[i]]=[]
				edges[corners[i]].append(corners[(i+1)%4])
		while not edges.is_empty():
			var first: Vector2i=edges.keys()[0]
			var current:=first
			var previous:=first-Vector2i.RIGHT
			var ring:=PackedVector2Array()
			for count in 3000:
				ring.append(Vector2(current))
				if not edges.has(current): break
				var options: Array=edges[current]
				var next: Vector2i=options[0]
				var best:=-INF
				for candidate: Vector2i in options:
					var a:=Vector2(current-previous)
					var b:=Vector2(candidate-current)
					var score:=a.cross(b)*2+a.dot(b)
					if score>best: best=score; next=candidate
				options.erase(next)
				if options.is_empty(): edges.erase(current)
				previous=current; current=next
				if current==first: break
			if ring.size()>=3: rings.append(_roughen(_smooth(_simplify_closed(ring,.65))))
		image=Image.create(extent.x*DENSITY,extent.y*DENSITY,false,Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var point:=Vector2(origin)+(Vector2(x,y)+Vector2.ONE*.5)/DENSITY
				var inside:=false
				for ring in rings:
					if Geometry2D.is_point_in_polygon(point,ring): inside=not inside
				var cell: Dictionary=model.cell_at(Vector2i(point.floor()))
				# A decorative cutout must never turn the actual ramp into a grass gap.
				if cell.get("ramp")!=null and cell.get("material","")=="terra": inside=true
				if cell.get("material","")=="terra":
					for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
						if model.cell_at(Vector2i(point.floor())+delta).get("material","")=="ponte": inside=true; break
				var paving:=1.0 if cell.get("material","")=="piso" else 0.0
				if paving>0.0 and map_id=="veredas-do-encanamento":
					# Only the exposed perimeter wears away; internal cell seams stay solid.
					var at:=Vector2i(point.floor())
					var local:=point-Vector2(at)
					var distance:=1.0
					var neighbors:=[Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
					var distances:=[local.x,1.0-local.x,local.y,1.0-local.y]
					for side in 4:
						if model.cell_at(at+neighbors[side]).get("material","")!="piso": distance=minf(distance,distances[side])
					var erosion:=.09+.045*sin(point.x*8.7+point.y*5.3)+.025*sin(point.y*27.1)
					paving=smoothstep(erosion,erosion+.10,distance)
				image.set_pixel(x,y,Color(1.0 if inside else 0.0,paving,1.0 if cell.get("material","")=="mato" else 0.0,1))
		image.save_png(contour_path)
	else:
		var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if contract.get("mapSha256","")!=FileAccess.get_sha256("res://assets/overworld/maps/"+map_id+".json"):
			push_warning(map_id+" contour is stale; run bake_clareira_terrain.gd")
			return
		mask=load(contour_path)
		if mask==null: push_error("Missing baked Clareira contour"); return
	if bake: mask=ImageTexture.create_from_image(image)
	material=ShaderMaterial.new()
	material.shader=load("res://scripts/overworld/clareira_terrain.gdshader")
	if map_id=="veredas-do-encanamento":
		material.set_shader_parameter("paving_period",320.0)
		material.set_shader_parameter("repeat_paving",true)
	material.set_shader_parameter("grass_details",load("res://assets/overworld/kits/parque/manga-terrain/grama.png"))
	material.set_shader_parameter("dirt_details",load("res://assets/overworld/kits/parque/manga-terrain/terra.png"))
	material.set_shader_parameter("mask_origin",Vector2(origin))
	material.set_shader_parameter("mask_extent",Vector2(extent))
	material.set_shader_parameter("pilot_min",Vector2(AREA.position))
	material.set_shader_parameter("pilot_max",Vector2(AREA.end))
	for entry in [["grass_paint","grama"],["dirt_paint","terra"],["square_paint","piso"]]:
		material.set_shader_parameter(entry[0],load(kit.root+kit.paintSurfaces[entry[1]]))

func supports(at: Vector2i, cell: Dictionary) -> bool:
	return material!=null and AREA.has_point(at) and cell.material in ["grama","terra","piso","mato"]

func tile(at: Vector2i, view) -> void:
	var cell: Dictionary=view.model.cell_at(at)
	var root: Node2D=view._floor_node(at,float(cell.level))
	root.name="PisoClareiraContinuo"
	var surface:=Polygon2D.new()
	var quad:=PackedVector2Array()
	for offset in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
		quad.append(view.model.project(Vector2(at)+offset,false)-Vector2(0,view.model.surface_height(cell,offset)*64)-root.position)
	surface.polygon=quad
	surface.texture=mask
	surface.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var uv:=PackedVector2Array()
	for offset in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]: uv.append((Vector2(at-origin)+offset)*DENSITY)
	surface.uv=uv
	surface.material=material
	# Steep ramps stretch the ground projection: retain faint dirt wear there,
	# keeping readable stone clusters on the connected flat landings.
	if cell.get("ramp")!=null:
		surface.material=material.duplicate()
		surface.material.set_shader_parameter("details_strength",0.12)
	root.add_child(surface)

func _simplify_open(points: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	if points.size()<3: return points
	var distance:=0.0
	var pivot:=0
	for i in range(1,points.size()-1):
		var gap:=points[i].distance_to(Geometry2D.get_closest_point_to_segment(points[i],points[0],points[-1]))
		if gap>distance: distance=gap; pivot=i
	if distance<=tolerance: return PackedVector2Array([points[0],points[-1]])
	var left:=_simplify_open(points.slice(0,pivot+1),tolerance)
	var right:=_simplify_open(points.slice(pivot),tolerance)
	left.resize(left.size()-1)
	left.append_array(right)
	return left

func _simplify_closed(points: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	var split:=1
	for i in range(2,points.size()):
		if points[i].distance_squared_to(points[0])>points[split].distance_squared_to(points[0]): split=i
	var a:=_simplify_open(points.slice(0,split+1),tolerance)
	var b:=points.slice(split)
	b.append(points[0]); b=_simplify_open(b,tolerance)
	a.resize(a.size()-1); a.append_array(b); a.resize(a.size()-1)
	return a

func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	for pass_index in 2:
		var next:=PackedVector2Array()
		for i in points.size():
			var a:=points[i]
			var b:=points[(i+1)%points.size()]
			next.append(a.lerp(b,.18)); next.append(a.lerp(b,.82))
		points=next
	return points

func _roughen(points: PackedVector2Array) -> PackedVector2Array:
	# Tiny, sparse bites on the already continuous boundary. The period is not
	# tied to cells; amplitude stays below 0.04 cell (~1.3 native screen pixels).
	var result:=PackedVector2Array()
	for i in points.size():
		var a:=points[i]
		var b:=points[(i+1)%points.size()]
		var tangent:=(b-a).normalized()
		var normal:=Vector2(-tangent.y,tangent.x)
		var samples:=maxi(1,ceili(a.distance_to(b)/.11))
		for sample in samples:
			var point:=a.lerp(b,float(sample)/samples)
			var cluster:=sin(point.x*5.37+point.y*3.13)
			var bite:=pow(maxf(0,cluster-.45)/.55,2)*sin(point.x*29.1-point.y*17.7)*.035
			result.append(point+normal*bite)
	return result
