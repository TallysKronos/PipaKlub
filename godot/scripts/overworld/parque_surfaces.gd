extends RefCounted
## Visual-only surfaces. Navigation, heights and bridge cells remain model-owned.
var model: RefCounted
var actors: Node2D
var kit: Dictionary
var decks: Dictionary = {}
var water_material: ShaderMaterial

func _init(source: RefCounted, parent: Node2D, art: Dictionary) -> void:
	model = source
	actors = parent
	kit = art
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://shaders/overworld/water_surface.gdshader")
	water_material.set_shader_parameter("surface_texture",load("res://assets/overworld/kits/aguas-v1/surfaces/rio-claro.png"))
	var mask := Image.create(1,1,false,Image.FORMAT_RGBA8)
	mask.fill(Color(0,0,0,1))
	water_material.set_shader_parameter("shore_texture",ImageTexture.create_from_image(mask))
	water_material.set_shader_parameter("flow_direction",Vector2(1,0))
	water_material.set_shader_parameter("cycle_seconds",4.0)

func polygon(parent: Node2D, points: PackedVector2Array, color: Color) -> Polygon2D:
	var item := Polygon2D.new()
	item.polygon = points
	item.color = color
	parent.add_child(item)
	return item

func line(parent: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	var item := Line2D.new()
	item.points = points
	item.default_color = color
	item.width = width
	item.begin_cap_mode = Line2D.LINE_CAP_ROUND
	item.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(item)

func draw_water(at: Vector2i, cell: Dictionary, beneath_bridge: bool = false) -> void:
	var depth := float(kit.mangaWater.depthPx)
	var root := Node2D.new()
	root.name = "AguaRebaixada"
	root.position = model.project(Vector2(at),false)-Vector2(0,float(cell.level)*64)
	root.z_index = -3
	actors.add_child(root)
	var offsets := [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]
	var edges := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	var corners := PackedVector2Array()
	for point in offsets: corners.append(model.project(point,false))
	var water_points := PackedVector2Array()
	for point in corners: water_points.append(point+Vector2(0,depth))
	var water := polygon(root,water_points,Color.WHITE)
	water.material = water_material
	# Tiny same-colour overlap removes raster seams without changing the shore.
	if beneath_bridge: return
	var shore := Node2D.new()
	shore.name = "MargemDoLeito"
	shore.position = root.position
	shore.z_index = -2
	actors.add_child(shore)
	for i in 4:
		var neighbor: Dictionary = model.cell_at(at+edges[i])
		if neighbor.is_empty() or neighbor.get("material","") in ["agua","ponte"]: continue
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i+1)%4]
		var down := Vector2(0,depth)
		polygon(shore,PackedVector2Array([a,b,b+down,a+down]),Color("8B744B") if i in [0,3] else Color("AE905A"))
		line(shore,PackedVector2Array([a+down,b+down]),Color("205563"),2.0)
		line(shore,PackedVector2Array([a,b]),Color("456B43"),2.4)
		# Short ink hatching on exposed earth, drawn at a fixed native scale.
		var middle := a.lerp(b,.45)
		line(shore,PackedVector2Array([middle+Vector2(1,3),middle+Vector2(2,7)]),Color("75633E"),1.2)

func draw_bridge(at: Vector2i, cell: Dictionary) -> bool:
	if decks.has(at): return true
	var pending: Array[Vector2i] = [at]
	var component: Dictionary = {}
	var low := at
	var high := at
	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		if component.has(point): continue
		component[point] = true
		low = low.min(point)
		high = high.max(point)
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = point+offset
			if not component.has(next) and model.cell_at(next).get("material","") == "ponte": pending.append(next)
	var size := high-low+Vector2i.ONE
	# Native drawing has this exact footprint; other bridge shapes use their kit.
	var recipe: Dictionary = kit.continuousBridge
	var footprint := Vector2i(recipe.footprint[0],recipe.footprint[1])
	if size != footprint or component.size()!=footprint.x*footprint.y: return false
	for point in component:
		decks[point] = true
		draw_water(point,cell,true)
	var origin: Vector2 = model.project(Vector2(low),false)-Vector2(0,float(cell.level)*64)
	var deck := Sprite2D.new()
	deck.name = "PonteInteira"
	deck.centered = false
	deck.texture = load(kit.root+recipe.file)
	deck.position = origin-Vector2(recipe.origin[0],recipe.origin[1])
	deck.z_index = -1
	actors.add_child(deck)
	for side in ["fundo","frente"]:
		var rail := Node2D.new()
		rail.name = "CordaDaPonte_"+side
		rail.position = model.project(Vector2(low)+Vector2(0 if side=="fundo" else footprint.x,float(footprint.y)*.5),false)
		actors.add_child(rail)
		var art := Sprite2D.new()
		art.centered = false
		art.texture = load(kit.root+recipe.rails[side])
		art.position = origin-rail.position-Vector2(recipe.origin[0],recipe.origin[1])
		rail.add_child(art)
	return true
