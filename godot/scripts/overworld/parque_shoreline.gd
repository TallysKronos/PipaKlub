extends RefCounted
## One measured shore owns the soil lip, exposed bank and lower water surface.
## Small lip insets stay inside blocked water cells; bridge landings stay dry.
var wet: Dictionary = {}
var outlines: Array[PackedVector2Array] = []

func build(model, actors: Node2D, kit: Dictionary, material: ShaderMaterial, paint: Callable) -> bool:
	for v in int(model.data.h):
		for u in int(model.data.w):
			var at := Vector2i(u,v)
			var cell: Dictionary = model.cell_at(at)
			if cell.material == "agua":
				if int(cell.level) != 0: return false
				wet[at] = true
	# A bridge only has water beneath it where its flanks actually meet the bed.
	for v in int(model.data.h):
		for u in int(model.data.w):
			var at := Vector2i(u,v)
			if model.cell_at(at).material != "ponte": continue
			var found := false
			for direction in [Vector2i.LEFT,Vector2i.RIGHT]:
				for distance in range(1,5):
					var cell: Dictionary = model.cell_at(at+direction*distance)
					if cell.get("material","") == "agua": found = true; break
					if cell.get("material","") != "ponte": break
			if found: wet[at] = true
	if wet.is_empty(): return false
	var edges: Dictionary = {}
	var corners := [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.ONE,Vector2i.DOWN]
	var neighbors := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	for at: Vector2i in wet:
		for side in 4:
			if wet.has(at+neighbors[side]): continue
			var a: Vector2i = at+corners[side]
			# Ambiguous diagonal contacts require the cell fallback, not a bad polygon.
			if edges.has(a): return false
			edges[a] = at+corners[(side+1)%4]
	var loops: Array = []
	while not edges.is_empty():
		var start: Vector2i = edges.keys()[0]
		var at := start
		var loop: Array[Vector2i] = []
		while edges.has(at):
			loop.append(at)
			var next: Vector2i = edges[at]
			edges.erase(at)
			at = next
		if at != start: return false
		loops.append(loop)
	var depth := float(kit.mangaWater.depthPx)
	for loop: Array in loops:
		var contour := PackedVector2Array()
		var old_points := PackedVector2Array()
		var soil_types: Array[String] = []
		for i in loop.size():
			var a := Vector2(loop[i])
			var b := Vector2(loop[(i+1)%loop.size()])
			var before := Vector2(loop[posmod(i-1,loop.size())])
			var after := Vector2(loop[(i+2)%loop.size()])
			var direction := (b-a).normalized()
			var inward := Vector2(-direction.y,direction.x)
			var prior := (a-before).normalized()
			var following := (after-b).normalized()
			var na := (inward+Vector2(-prior.y,prior.x))*.5
			var nb := (inward+Vector2(-following.y,following.x))*.5
			var middle := (a+b)*.5
			var outside: Dictionary = model.cell_at(Vector2i((middle-inward*.5).floor()))
			var soil := str(outside.get("material","grama"))
			if not kit.paintSurfaces.has(soil): soil = "grama"
			# Anchor the landing edge rather than curling grass over bridge planks.
			var landing: bool = outside.get("material","") == "ponte"
			var inset := 0.0 if landing else .14+.07*sin(a.x*.83+a.y*.41)
			for step in 4:
				var t := float(step)/4.0
				var original := a.lerp(b,t)
				var offset := na.lerp(nb,t)*inset+inward*sin(t*PI)*inset*.28
				var point := original+offset
				# Numerical/concave corners must never expand water onto dry ground.
				if not wet.has(Vector2i((point+inward*.0001).floor())): point = original+inward*.001
				old_points.append(original)
				contour.append(point)
				soil_types.append(soil)
		outlines.append(contour)
		var lower := PackedVector2Array()
		var aperture := PackedVector2Array()
		for p in contour:
			aperture.append(model.project(p,false))
			lower.append(model.project(p,false)+Vector2(0,depth))
		# Projecting a lower plane moves it towards the camera. Its hidden front
		# edge must be clipped by the upper opening, including at nearby cliffs.
		# Keep the full measured bed as metadata; only its visible part is drawn.
		for visible: PackedVector2Array in Geometry2D.intersect_polygons(lower,aperture):
			var water := Polygon2D.new()
			water.name = "AguaRebaixadaContinua"
			water.z_index = -3
			water.polygon = visible
			water.material = material
			water.set_meta("shore_top",contour)
			water.set_meta("full_bed",lower)
			water.set_meta("aperture",aperture)
			actors.add_child(water)
		for i in contour.size():
			var j := (i+1)%contour.size()
			var a: Vector2 = model.project(contour[i],false)
			var b: Vector2 = model.project(contour[j],false)
			var oa: Vector2 = model.project(old_points[i],false)
			var ob: Vector2 = model.project(old_points[j],false)
			var shore := Node2D.new()
			shore.name = "MargemContinua"
			shore.position = (oa+ob)*.5
			# Banks render above the lower water and below *all* upper floor cells.
			# Sorting narrow bank slices among the floor diamonds creates sawteeth.
			shore.z_index = -3
			actors.add_child(shore)
			var lip := Polygon2D.new()
			lip.z_index = 1
			lip.color = Color(kit.surfaceTreatment.colors[soil_types[i]])
			lip.polygon = Transform2D(0,-shore.position)*PackedVector2Array([oa,ob,b,a])
			lip.material = paint.call(soil_types[i])
			shore.add_child(lip)
			var wall := Polygon2D.new()
			wall.polygon = Transform2D(0,-shore.position)*PackedVector2Array([a,b,b+Vector2(0,depth),a+Vector2(0,depth)])
			wall.texture = load(kit.root+kit.wallSurfaces.pedra.file)
			wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			var phase_a := (contour[i].x+contour[i].y)*48.0
			var phase_b := (contour[j].x+contour[j].y)*48.0
			var tex_depth := depth*96.0/64.0
			wall.uv = PackedVector2Array([Vector2(phase_a,0),Vector2(phase_b,0),Vector2(phase_b,tex_depth),Vector2(phase_a,tex_depth)])
			wall.color = Color(.91,.87,.79) if b.x>a.x else Color(.75,.78,.73)
			shore.add_child(wall)
			var contact := Line2D.new()
			contact.points = Transform2D(0,-shore.position)*PackedVector2Array([a+Vector2(0,depth),b+Vector2(0,depth)])
			contact.width = 1.3
			contact.default_color = Color("34545a")
			shore.add_child(contact)
	return true
