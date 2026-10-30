extends Node2D
## Review scene. No campaign save or rules are changed until area art is approved.
const Model = preload("res://scripts/overworld/map_model.gd")
const Prop = preload("res://scripts/overworld/prop.gd")
const Avatar = preload("res://scripts/avatar.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const Forest = preload("res://scripts/overworld/kronasta_forest.gd")
signal interaction_requested(event: Dictionary)
var model := Model.new()
var area_id := "veredas-piloto"
var art_preview := false
var player := Vector2.ZERO
var follower := Vector2.ZERO
var follower_trail: Array[Vector2] = []
var path := PackedVector2Array()
var clock := 0.0
var actors: Node2D
var terrain: Node2D
var avatar: Node2D
var player_root: Node2D
var companion: Sprite2D
var follower_root: Node2D
var camera: Camera2D
var interface: CanvasLayer
var hint: Label
var title: Label
var selector: OptionButton
var art_toggle: CheckButton
var index: Dictionary
var kits: Array[Dictionary] = []
var kit_library: Dictionary = {}
var terrain_layers: Array[TileMapLayer] = []
var lots: Dictionary = {}
var grass_material: ShaderMaterial
var bairro_surface_materials: Dictionary = {}
var parque_grass_material: ShaderMaterial
var painted_floor_material: ShaderMaterial
var stair_bevels: Dictionary = {}
var hidden_pieces: Dictionary = {}
var occluders: Array[Node2D] = []
const MAX_HOUSES := 6
const MIN_HOUSES := 4
# Yards are the lawn under a soft shade. The shade is interpolated per vertex
# from the four cells around it, so the change never follows the cell grid.
const YARD_SHADE := Color(.10, .20, .10)
const YARD_SHADE_ALPHA := .30
var stairs_drawn: Dictionary = {}
var opened: Dictionary = {}
var nearby: Dictionary = {}
var interaction_events: Array = []
var piece_nodes: Dictionary = {}
var npc_nodes: Array = []
var notice := ""
var notice_until := 0.0
var grass_distance := 0.0
var _last_direction := Vector2.ZERO

func _ready() -> void:
	Controls.install()
	index = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/index.json"))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--area="): area_id = argument.trim_prefix("--area=")
		if argument == "--art-preview": art_preview = true
	for biome in ["comum", "bairro", "parque", "veredas", "morro", "frutiferas"]:
		var file: String = "res://assets/overworld/kits/" + biome + "/kit.json"
		if not FileAccess.file_exists(file): continue
		var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
		kit.root = "res://assets/overworld/kits/" + biome + "/"
		kit_library[biome] = kit
	_build_hud()
	load_area(area_id)

func load_area(id: String, arrival: Dictionary = {}) -> void:
	var source := "res://assets/overworld/maps/" + id + ".json"
	if not FileAccess.file_exists(source): return
	area_id = id
	set_meta("grass_decal_count", 0)
	for node in [terrain, camera]:
		if is_instance_valid(node): remove_child(node); node.queue_free()
	terrain_layers.clear()
	stairs_drawn.clear()
	occluders.clear()
	model.setup(JSON.parse_string(FileAccess.get_file_as_string(source)))
	kits.assign([kit_library.comum])
	if kit_library.has(model.data.biome):
		# Area overrides must never leak into the next map's shared kit.
		var biome_kit: Dictionary = kit_library[model.data.biome].duplicate(true)
		var visuals: Dictionary = biome_kit.get("areaVisuals",{}).get(id,{})
		if visuals.has("floorSurfaceFile"): biome_kit.floorSurface.file = visuals.floorSurfaceFile
		kits.append(biome_kit)
	path.clear()
	nearby.clear()
	piece_nodes.clear()
	npc_nodes.clear()
	interaction_events = model.data.events.duplicate(true)
	terrain = Node2D.new()
	terrain.y_sort_enabled = true
	add_child(terrain)
	actors = terrain
	var forest: bool = art_preview and (model.data.biome == "floresta" or bool(model.data.get("forest",{}).get("nativeProps",false)))
	if forest:
		Forest.build(self)
	else:
		_build_context()
		_build_tiles()
		_build_faces()
		_build_pieces()
		_dress_bare_lots()
		_dress_bairro_gardens()
		_dress_parque()
		_dress_veredas()
		_bairro_ground_details()
		_bairro_ground_shadows()
		_morro_canopy_shadow()
	_build_events()
	var spawn: Dictionary = model.data.spawn
	player = Vector2(spawn.u + .5, spawn.v + .5)
	# Preview exits may arrive at the matching end of the next map. Invalid
	# coordinates fall back to its declared entrance; no campaign/save is changed.
	if arrival.has("chegada_u") and arrival.has("chegada_v"):
		var au: Variant = arrival.chegada_u
		var av: Variant = arrival.chegada_v
		if (au is int or au is float) and (av is int or av is float):
			if is_finite(float(au)) and is_finite(float(av)) and float(au) == floorf(float(au)) and float(av) == floorf(float(av)):
				var target := Vector2i(int(au), int(av))
				if model.walkable(target): player = Vector2(target) + Vector2.ONE * .5
	follower = player
	follower_trail.clear()
	player_root = Node2D.new()
	avatar = Avatar.new()
	player_root.add_child(avatar)
	actors.add_child(player_root)
	follower_root = Node2D.new()
	companion = Sprite2D.new()
	companion.texture = load("res://assets/campaign/combat-rabbito.png")
	companion.region_enabled = true
	companion.region_rect = Rect2(0, 0, 256, 256)
	companion.scale = Vector2.ONE * .21
	companion.offset = Vector2(0, -100)
	follower_root.add_child(companion)
	actors.add_child(follower_root)
	camera = Camera2D.new()
	# Floresta: câmera mais aberta, para ler platôs e massas de mata (REGIOES-E-PARTES, seção 6).
	camera.zoom = Vector2.ONE * (1.0 if forest else 1.4)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	_refresh_positions()
	camera.reset_smoothing()
	for i in index.areas.size():
		if index.areas[i].id == id: selector.select(i)
	title.text = model.data.name + (" • Estudo de arte" if art_preview and kits.size()>1 else " • Kit comum / chão rascunho" if art_preview else " • Rascunho")
	art_toggle.set_pressed_no_signal(art_preview)
	message("Prévia independente • progresso da campanha preservado")

func _build_context() -> void:
	# Kit-authored background recipe. It never contributes navigation, collision,
	# events, or cells to the logical model; the source-map boundary is unchanged.
	var recipe: Dictionary = kits[1].get("context", {}) if kits.size()>1 else {}
	var radius := int(recipe.get("radius",12))
	var context := Node2D.new()
	# Only the ground plane sits under the map; trees and houses sort by depth with
	# everything else, so a tree in front of the map is drawn in front of it.
	context.name="ContextoNaoJogavel";context.y_sort_enabled=true
	actors.add_child(context)
	var floor_plane := Polygon2D.new()
	floor_plane.z_index=-100
	floor_plane.color=Color(str(recipe.get("color","476643")))
	if _soft_yards():
		# Outside the map reads as the same shaded yard, so the map edge disappears.
		floor_plane.color=_average_color(kits[1].root + kits[1].materials.grama.variants[0]).lerp(Color(YARD_SHADE,1),YARD_SHADE_ALPHA)
	floor_plane.polygon=PackedVector2Array([model.project(Vector2(-radius,-radius),false),model.project(Vector2(model.data.w+radius,-radius),false),model.project(Vector2(model.data.w+radius,model.data.h+radius),false),model.project(Vector2(-radius,model.data.h+radius),false)])
	if art_preview and model.data.biome == "bairro": floor_plane.material = _bairro_surface_material("canteiro")
	if art_preview and model.data.biome == "parque" and kits.size()>1:
		var material := ShaderMaterial.new()
		material.shader = load(kits[1].surfaceShader)
		material.set_shader_parameter("surfaces",load(kits[1].root+kits[1].surfaceAtlas))
		material.set_shader_parameter("material_id",4.0)
		material.set_shader_parameter("edge_ids",Vector4(4,4,4,4))
		material.set_shader_parameter("corner_ids",Vector4(4,4,4,4))
		floor_plane.material = material
	context.add_child(floor_plane)
	if recipe.is_empty() or not art_preview:return
	# Sparse authored background trees have trunks, height and ground-depth sort.
	# They replace neither floor pixels nor the source-map blockers.
	for i in recipe.get("authoredTrees",[]).size():
		var point: Array = recipe.authoredTrees[i]
		var at := Vector2(point[0],point[1])
		var info := _definition({"asset":"arvore","id":"background","props":{"variante":"a" if i%2==0 else "b"}})
		if info.is_empty():continue
		var tree := Prop.new()
		tree.position = model.project(at,false)
		tree.configure(info,Vector2i.ONE,0,false)
		context.add_child(tree)
	if not bool(recipe.get("automaticTrees",true)): return
	# Surroundings read as hillside woods: trees of mixed kinds on an irregular
	# lattice, and only a few houses higher up the slope, behind the map.
	var w := int(model.data.w)
	var h := int(model.data.h)
	for v in range(-radius,h+radius,4):
		for u in range(-radius,w+radius,4):
			var seed := posmod(u*137+v*71+u*v*13,29)
			var shift := Vector2(seed%3-1, (seed/3)%3-1)
			var at := Vector2(u,v)+shift
			var behind: bool = at.x+2<=0 or at.y+2<=0
			# Keep two cells clear in front, so tall crowns never hide the playable edge.
			var front: bool = at.x>=w+3 or at.y>=h+3
			if not (behind or front):continue
			var house: bool = bool(recipe.get("houses",true)) and behind and (at.x<=-6 or at.y<=-6) and seed%7==0
			if not house and seed<(13 if front else 9):continue
			var variant: String = ["telha","laje","muro-chapisco"][seed%3] if house else ["a","b","tronco-largo","a","b","a","b","florida"][seed%8]
			var info := _definition({"asset":recipe.asset if house else "arvore","id":"context","props":{"variante":variant}})
			if info.is_empty():continue
			var size := 3 if house else 2
			var node := Prop.new()
			var sort_point:=at+Vector2(size,size)
			node.configure(info,Vector2i(size,size),0,false,model.project(at+Vector2(size,size)*.5,false)-model.project(sort_point,false))
			node.position=model.project(sort_point,false)
			context.add_child(node)

func _build_tiles() -> void:
	var texture: Texture2D = load("res://assets/overworld/rascunho-atlas.png")
	var ids: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/rascunho-atlas.json"))
	var levels: Dictionary = {}
	for cell in model.data.cells: levels[int(cell.level)] = true
	hidden_pieces = _compose_houses()
	lots = _occupied_lots()
	# Inset stairs meet square masonry jambs. Clipping their terrace corners
	# would detach those jambs from the inner cheeks of the stairwell.
	stair_bevels = {}
	if _soft_yards(): _build_lawn_base()
	for level in levels:
		var tiles := TileSet.new()
		tiles.tile_size = Vector2i(64, 32)
		tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
		tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
		var atlas := TileSetAtlasSource.new()
		atlas.texture = texture
		atlas.texture_region_size = Vector2i(64, 32)
		for mat in ids:
			for n in 4: atlas.create_tile(Vector2i(n, int(ids[mat])))
		tiles.add_source(atlas, 0)
		var layer := TileMapLayer.new()
		layer.name = "ChaoNivel" + str(level)
		layer.tile_set = tiles
		layer.y_sort_enabled = true
		layer.y_sort_origin = int(level) * 64
		layer.collision_enabled = false # navigation comes from the shared footprint model
		layer.navigation_enabled = false
		layer.position = Vector2(0, 16 - int(level)*64) - layer.map_to_local(Vector2i.ZERO)
		actors.add_child(layer)
		terrain_layers.append(layer)
		for i in model.data.cells.size():
			var cell: Dictionary = model.data.cells[i]
			if int(cell.level) != int(level) or cell.material == null: continue
			var at := Vector2i(i % int(model.data.w), i / int(model.data.w))
			if cell.get("ramp") != null:
				if not _draw_kit_stairs(at, cell): _draw_ramp(at, cell)
			elif cell.material == "ponte":
				_draw_bridge(at, cell)
			elif _soft_yards() and cell.material == "construcao":
				# A blocked lot without a house reads as a yard, not as bare brick.
				_draw_art_floor(at, {"material":"grama","level":cell.level,"corners":cell.corners})
			elif art_preview and kits.size()>1 and kits[1].materials.has(cell.material):
				_draw_art_floor(at, cell)
			else: layer.set_cell(at, 0, Vector2i((at.x * 7 + at.y * 13) % 4, int(ids.get(cell.material, 0))))

func _draw_bridge(at: Vector2i, cell: Dictionary) -> void:
	if art_preview and model.data.biome == "veredas" and kits.size()>1:
		_draw_veredas_bridge(at,cell)
		return
	var along_u := false
	for offset in [Vector2i(1,0),Vector2i(-1,0)]:
		var neighbor := model.cell_at(at+offset)
		if neighbor.get("material", "") == "ponte": along_u = true
	var axis := "u" if along_u else "v"
	var root := _floor_node(at, float(cell.level))
	var water := Polygon2D.new()
	water.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
	water.position.y = -float(cell.level)*64+3
	water.color = Color("77B3AF")
	root.add_child(water)
	var deck := Sprite2D.new()
	deck.texture = load(kits[0].root + kits[0].bridges[axis].file)
	deck.position.y = -float(cell.level)*64
	root.add_child(deck)

func _floor_node(at: Vector2i, level: float) -> Node2D:
	var node := Node2D.new()
	node.z_index = 0 if model.data.biome == "veredas" else -2
	node.position = model.project(Vector2(at) + Vector2(.5, .5), false)
	actors.add_child(node)
	return node

func _draw_art_floor(at: Vector2i, cell: Dictionary) -> void:
	var kit: Dictionary = kits[1]
	if model.data.biome == "veredas" and kit.has("surfaceAtlas"):
		_draw_veredas_floor(at,cell)
		return
	if model.data.biome == "parque" and kit.has("surfaceAtlas"):
		_draw_parque_floor(at,cell)
		return
	if model.data.biome == "bairro":
		_draw_bairro_floor(at,cell)
		return
	if kit.has("floorSurface") and model.data.biome == "morro":
		var floor_root := _floor_node(at, float(cell.level))
		floor_root.add_child(_painted_floor(at, cell, true))
		if cell.material == "grama":
			floor_root.add_child(_yard_shade(at, float(cell.level)))
			_grass_decal(floor_root, at, int(cell.level))
		return
	var file := ""
	if kit.materials.has(cell.material):
		var variants: Array = kit.materials[cell.material].variants
		var choice := _grass_hash(at) if cell.material == "grama" else at.x*7+at.y*13
		file = variants[posmod(choice, variants.size())]
	if file.is_empty(): return
	var root := _floor_node(at, float(cell.level))
	if cell.material == "grama":
		root.add_child(_grass_surface(kit.root + file, float(cell.level)))
	else:
		var sprite := Sprite2D.new()
		sprite.texture = load(kit.root + file)
		sprite.position.y = -float(cell.level) * 64
		root.add_child(sprite)
	if cell.material == "grama" and _soft_yards(): root.add_child(_yard_shade(at, float(cell.level)))
	# Canonical shared vertices, including three-material junctions. A corner
	# samples the existing pair atlas only inside its own quadrant; unrelated
	# corners of that texture never overwrite the third material.
	var wedges := [PackedVector2Array([Vector2(32,0),Vector2(48,8),Vector2(32,16),Vector2(16,8)]),PackedVector2Array([Vector2(64,16),Vector2(48,24),Vector2(32,16),Vector2(48,8)]),PackedVector2Array([Vector2(32,32),Vector2(16,24),Vector2(32,16),Vector2(48,24)]),PackedVector2Array([Vector2(0,16),Vector2(16,8),Vector2(32,16),Vector2(16,24)])]
	for bit in 4:
		var material := str(cell.corners[bit])
		if material == cell.material:continue
		# Blocked lots are drawn as yards; a brick corner would reappear along every path.
		if material == "construcao" and model.data.biome == "morro":continue
		for pair in kit.transitions:
			var parts: PackedStringArray = pair.split("/")
			if material not in parts or str(cell.material) not in parts:continue
			var mask := (1<<bit) if parts[1]==material else 15^(1<<bit)
			var patch := Polygon2D.new()
			var uv: PackedVector2Array = wedges[bit]
			var poly := PackedVector2Array()
			for point in uv:poly.append(point-Vector2(32,16+float(cell.level)*64))
			patch.polygon=poly;patch.uv=uv
			patch.texture=load(kit.root+kit.transitions[pair].files[mask])
			root.add_child(patch)
			break
	if cell.material == "grama" and _soft_yards(): _grass_decal(root, at, int(cell.level))

func _veredas_material(at: Vector2i, cell: Dictionary, finish: String = "") -> ShaderMaterial:
	var kit: Dictionary = kits[1]
	var order: Array = kit.surfaceOrder
	var own := maxi(0,order.find(finish if not finish.is_empty() else str(cell.material)))
	var edges := Vector4(own,own,own,own)
	var corners := Vector4(own,own,own,own)
	if finish.is_empty():
		var offsets := [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
		for i in 4:
			var neighbor := model.cell_at(at+offsets[i])
			# A vertical height edge is not a flat material transition. Decks
			# likewise keep their wood right up to their structural edge.
			if not neighbor.is_empty() and neighbor.level == cell.level and neighbor.material != "ponte":
				edges[i] = maxi(0,order.find(str(neighbor.material)))
		if cell.get("ramp") == null:
			for i in 4:
				if str(cell.corners[i]) != "ponte": corners[i] = maxi(0,order.find(str(cell.corners[i])))
	var material := ShaderMaterial.new()
	material.shader = load(kit.surfaceShader)
	material.set_shader_parameter("surfaces",load(kit.root+kit.surfaceAtlas))
	material.set_shader_parameter("material_id",float(own))
	material.set_shader_parameter("edge_ids",edges)
	material.set_shader_parameter("corner_ids",corners)
	material.set_shader_parameter("cell_origin",Vector2(at))
	return material

func _draw_veredas_floor(at: Vector2i, cell: Dictionary) -> void:
	var floor_root := _floor_node(at,float(cell.level))
	var surface := Polygon2D.new()
	surface.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
	surface.position.y = -float(cell.level)*64
	surface.texture = load(kits[1].root+kits[1].surfaceAtlas)
	var extent: Vector2 = surface.texture.get_size()
	surface.uv = PackedVector2Array([Vector2.ZERO,Vector2(extent.x,0),extent,Vector2(0,extent.y)])
	surface.material = _veredas_material(at,cell)
	floor_root.add_child(surface)
	if cell.material == "mato": _encounter_tufts(at,cell)

func _draw_veredas_bridge(at: Vector2i, cell: Dictionary) -> void:
	# Length is measured along both connected runs, rather than assuming that
	# any u-neighbour means a u bridge (a wide v bridge has those too).
	var lengths := Vector2i.ONE
	for axis in 2:
		var delta := Vector2i.RIGHT if axis == 0 else Vector2i.DOWN
		for sign_value in [-1,1]:
			var next: Vector2i = at+delta*int(sign_value)
			while model.cell_at(next).get("material","") == "ponte":
				lengths[axis] += 1
				next += delta*sign_value
	var along_u := lengths.x >= lengths.y
	var root := _floor_node(at,float(cell.level))
	var deck := Polygon2D.new()
	deck.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
	deck.position.y = -float(cell.level)*64
	deck.texture = load(kits[1].root+kits[1].surfaceAtlas)
	var extent: Vector2 = deck.texture.get_size()
	deck.uv = PackedVector2Array([Vector2.ZERO,Vector2(extent.x,0),extent,Vector2(0,extent.y)])
	deck.material = _veredas_material(at,cell,"ponte")
	root.add_child(deck)
	# No outline around each diamond: plank seams run across the whole deck.
	for n in 4:
		var t := float(n)/4.0
		var a := Vector2(t,0) if along_u else Vector2(0,t)
		var b := Vector2(t,1) if along_u else Vector2(1,t)
		var seam := Line2D.new()
		seam.width = .7
		seam.default_color = Color(.29,.18,.10,.65)
		seam.points = PackedVector2Array([model.project(Vector2(at)+a,false)-root.position,model.project(Vector2(at)+b,false)-root.position])
		seam.position.y = -float(cell.level)*64
		root.add_child(seam)
	# Continuous exposed side beams and short end posts. Only the outside of
	# the connected deck receives supports, never a post on every tile joint.
	for side in [-1,1]:
		var offset := Vector2i(0,side) if along_u else Vector2i(side,0)
		if model.cell_at(at+offset).get("material","") == "ponte": continue
		var a := Vector2(0,0 if side<0 else 1) if along_u else Vector2(0 if side<0 else 1,0)
		var b := a+(Vector2.RIGHT if along_u else Vector2.DOWN)
		var points := PackedVector2Array([model.project(Vector2(at)+a,false)-root.position,model.project(Vector2(at)+b,false)-root.position])
		var beam := Line2D.new()
		beam.width = 5
		beam.default_color = Color("79502D")
		beam.points = points
		beam.position.y = -float(cell.level)*64+2
		root.add_child(beam)
		for end in 2:
			var neighbor := at+(Vector2i(-1 if end==0 else 1,0) if along_u else Vector2i(0,-1 if end==0 else 1))
			if model.cell_at(neighbor).get("material","") == "ponte": continue
			var post := Line2D.new()
			post.width = 5
			post.default_color = Color("9E6938")
			post.points = PackedVector2Array([points[end]+Vector2(0,8),points[end]-Vector2(0,12)])
			post.position.y = -float(cell.level)*64
			root.add_child(post)

func _dress_veredas() -> void:
	if not art_preview or model.data.biome != "veredas" or kits.size()<2: return
	var dressing: Dictionary = kits[1].get("dressing",{})
	for decoration: Dictionary in dressing.get(area_id,[]):
		var at := Vector2(decoration.point[0],decoration.point[1])
		var entry := _definition({"asset":decoration.asset,"id":"veredas-decoration","props":{}})
		if entry.is_empty(): continue
		var node := Prop.new()
		var sort_point := at+Vector2(.5,.5)
		node.position = model.project(sort_point,false)
		node.configure(entry,Vector2i.ONE,model.height_at(at),false,model.project(at,false)-model.project(sort_point,false))
		node.set_meta("art_only",true)
		actors.add_child(node)
		occluders.append(node)

func _draw_parque_floor(at: Vector2i, cell: Dictionary) -> void:
	var kit: Dictionary = kits[1]
	var order: Array = kit.surfaceOrder
	var own := maxi(0,order.find(str(cell.material)))
	var edges := Vector4(own,own,own,own)
	var offsets := [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
	for i in 4:
		var neighbor := model.cell_at(at+offsets[i])
		if not neighbor.is_empty(): edges[i] = maxi(0,order.find(str(neighbor.material)))
	var corners := Vector4(own,own,own,own)
	for i in 4: corners[i] = maxi(0,order.find(str(cell.corners[i])))
	var material := ShaderMaterial.new()
	material.shader = load(kit.surfaceShader)
	material.set_shader_parameter("surfaces",load(kit.root+kit.surfaceAtlas))
	material.set_shader_parameter("material_id",float(own))
	material.set_shader_parameter("edge_ids",edges)
	material.set_shader_parameter("corner_ids",corners)
	var surface := Polygon2D.new()
	surface.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
	surface.material = material
	var floor_root := _floor_node(at,0)
	floor_root.add_child(surface)
	if cell.material != "mato": return
	_encounter_tufts(at,cell)

func _encounter_tufts(at: Vector2i, cell: Dictionary) -> void:
	var kit: Dictionary = kits[1]
	if parque_grass_material == null:
		parque_grass_material = ShaderMaterial.new()
		parque_grass_material.shader = load(kit.encounterGrass.shader)
		var preferences = preload("res://scripts/campaign/preferences.gd").new()
		preferences.load_settings()
		parque_grass_material.set_shader_parameter("wind_strength",0.0 if preferences.reduced_motion else 1.4)
	var seed := posmod(at.x*137+at.y*71,101)
	for n in 2:
		var point := Vector2(at)+Vector2(.26 if n==0 else .74,.30+float((seed+n*17)%35)/100.0)
		var tuft := Sprite2D.new()
		tuft.texture = load(kit.root+kit.encounterGrass.files[(seed+n)%2])
		tuft.centered = false
		tuft.position = -Vector2(kit.encounterGrass.anchor[0],kit.encounterGrass.anchor[1])
		tuft.material = parque_grass_material
		var grass_root := Node2D.new()
		grass_root.position = model.project(point,false)
		tuft.position.y -= float(cell.level)*64
		grass_root.add_child(tuft)
		actors.add_child(grass_root)

func _dress_parque() -> void:
	if not art_preview or model.data.biome != "parque" or kits.size()<2: return
	# No automatic tree carpet. Authored low masses explain the woodland boundary
	# while preserving long sightlines through the centre and the entry plaza.
	var recipe: Dictionary = kits[1].get("boundaryShrubs",{})
	# Low shrubs follow the woodland edge of whatever plan is loaded: every other
	# bosque cell that touches walkable ground, skipping cells with a tree.
	var trees := {}
	for piece in model.data.pieces: trees[Vector2i(piece.u,piece.v)] = true
	var points: Array = []
	for v in int(model.data.h):
		for u in int(model.data.w):
			var cell := Vector2i(u,v)
			if model.cell_at(cell).get("material","") != "bosque" or trees.has(cell) or posmod(u+v,2) == 1: continue
			for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
				if model.walkable(cell+d):
					points.append([u+.5,v+.5])
					break
	for i in points.size():
		var uv: Array = points[i]
		var at := Vector2(float(uv[0]),float(uv[1]))
		var shrub := Sprite2D.new()
		shrub.texture = load(kits[1].root+recipe.files[i%recipe.files.size()])
		shrub.centered = false
		shrub.position = -Vector2(recipe.anchor[0],recipe.anchor[1])
		var shrub_root := Node2D.new()
		shrub_root.position = model.project(at,false)
		var contact := Sprite2D.new()
		contact.texture = load(kits[1].root+"sombras/contato.png")
		contact.scale = Vector2(1.25,.55)
		contact.position = Vector2(0,-3)
		shrub_root.add_child(contact)
		shrub_root.add_child(shrub)
		actors.add_child(shrub_root)
	if area_id == "jardim-das-pipas":
		for piece in model.data.pieces:
			if piece.asset != "arvore" or str(piece.props.get("variante","")) != "florida":continue
			var info := _definition({"asset":"flores","id":"flor","props":{"variante":"coral"}})
			var flowers := Prop.new()
			flowers.configure(info,Vector2i.ONE,0,false)
			flowers.position = model.project(Vector2(piece.u+.6,piece.v+.7),false)
			actors.add_child(flowers)
	else:
		for piece in model.data.pieces:
			if piece.asset != "arvore" or int(piece.id) not in [2,5,12]:continue
			var info := _definition({"asset":"pipa-presa","id":"papel","props":{}})
			if info.is_empty():continue
			var paper := Prop.new()
			paper.configure(info,Vector2i.ONE,0,false,Vector2(12,-105))
			paper.position = model.project(Vector2(piece.u+.5,piece.v+.5),false)
			actors.add_child(paper)

func _bairro_surface_material(material_name: String) -> ShaderMaterial:
	if bairro_surface_materials.has(material_name): return bairro_surface_materials[material_name]
	var surfaces: Dictionary = kits[1].get("surfaceMaterials",{})
	if not surfaces.has(material_name): return null
	var entry: Dictionary = surfaces[material_name]
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/bairro_surface.gdshader")
	material.set_shader_parameter("surface_tex",load(kits[1].root+entry.file))
	material.set_shader_parameter("repeat_cells",float(entry.repeatCells))
	if material_name == "construcao": material.set_shader_parameter("surface_tint",Color(.94,.90,.82))
	bairro_surface_materials[material_name] = material
	return material

func _bairro_local(uv: Vector2) -> Vector2:
	return Vector2((uv.x-uv.y)*32,(uv.x+uv.y)*16-16)

func _draw_bairro_floor(at: Vector2i, cell: Dictionary) -> void:
	# Geometry owns coverage. The opaque painting is sampled in world u/v,
	# so its scale, slab joints and worn patches never restart at tile edges.
	var root := _floor_node(at,float(cell.level))
	var surface := Polygon2D.new()
	surface.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
	surface.position.y = -float(cell.level)*64
	surface.material = _bairro_surface_material(str(cell.material))
	if surface.material == null: surface.color = Color("8FAF65")
	root.add_child(surface)
	if cell.material != "calcada": return
	var edges := [
		[Vector2i.LEFT,Vector2(0,0),Vector2(0,1),Vector2(.20,0),false],
		[Vector2i.RIGHT,Vector2(1,0),Vector2(1,1),Vector2(-.20,0),false],
		[Vector2i.UP,Vector2(0,0),Vector2(1,0),Vector2(0,.20),true],
		[Vector2i.DOWN,Vector2(0,1),Vector2(1,1),Vector2(0,-.20),true]
	]
	for edge in edges:
		var neighbour := model.cell_at(at+edge[0])
		if neighbour.get("material","") != "asfalto": continue
		var a: Vector2 = edge[1]
		var b: Vector2 = edge[2]
		var inward: Vector2 = edge[3]
		var gutter := Polygon2D.new()
		gutter.polygon = PackedVector2Array([_bairro_local(a),_bairro_local(b),_bairro_local(b-inward*.65),_bairro_local(a-inward*.65)])
		gutter.color = Color("374E67")
		gutter.z_index = 1
		gutter.position.y = surface.position.y
		root.add_child(gutter)
		var curb := Polygon2D.new()
		curb.polygon = PackedVector2Array([_bairro_local(a),_bairro_local(b),_bairro_local(b+inward),_bairro_local(a+inward)])
		curb.color = Color("EADBB6") if posmod(floori(float(at.x if edge[4] else at.y)/2),3)!=0 else Color("DFCEA6")
		curb.z_index = 1
		curb.position.y = surface.position.y
		root.add_child(curb)
		for inner in [false,true]:
			var border := Line2D.new()
			var offset: Vector2 = inward if inner else Vector2.ZERO
			border.points = PackedVector2Array([_bairro_local(a+offset),_bairro_local(b+offset)])
			border.default_color = Color("F8ECCF") if inner else Color("3B5061")
			border.width = 1.0 if inner else 1.2
			border.z_index = 1
			border.position.y = surface.position.y
			root.add_child(border)
		if posmod(at.x if edge[4] else at.y,2)==0:
			var joint := Line2D.new()
			joint.points = PackedVector2Array([_bairro_local(a),_bairro_local(a+inward)])
			joint.default_color = Color("56616A")
			joint.width = .8
			joint.z_index = 1
			joint.position.y = surface.position.y
			root.add_child(joint)

func _grass_hash(at: Vector2i, salt: int = 0) -> int:
	# Avalanche hash: no diagonal stripes, negative coordinates work too.
	var value: int = posmod(at.x*374761393 + at.y*668265263 + salt, 2147483647)
	value = posmod((value ^ (value >> 13))*1274126177, 2147483647)
	return value ^ (value >> 16)

func _floor_material_color(material_name: String) -> Color:
	return Color(0,1,0,1) if material_name == "calcada" else Color(0,0,1,1) if material_name == "piso" else Color(1,0,0,1)

func _stair_vertex_key(point: Vector2, level: float) -> String:
	return str(roundi(point.x))+":"+str(roundi(point.y))+":"+str(roundi(level))

func _plan_stair_bevels() -> Dictionary:
	var result := {}
	for index in model.data.cells.size():
		var ramp: Dictionary = model.data.cells[index]
		if ramp.get("ramp") == null: continue
		var at := Vector2i(index%int(model.data.w),index/int(model.data.w))
		var direction: Vector2i = Model.DIRS[ramp.ramp]
		for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
			var rise: int = corner.x if direction.x>0 else 1-corner.x if direction.x<0 else corner.y if direction.y>0 else 1-corner.y
			if rise != 0: continue
			var vertex: Vector2i = at+corner
			var high: Array[Vector2i] = []
			for offset in [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(-1,0),Vector2i(0,0)]:
				var candidate: Vector2i = vertex+offset
				var cell := model.cell_at(candidate)
				if cell.is_empty() or cell.get("ramp") != null: continue
				if int(cell.level) == int(ramp.level)+1: high.append(candidate)
			if high.size()!=1 or model.walkable(high[0]): continue
			var inward := Vector2(high[0])+Vector2(.5,.5)-Vector2(vertex)
			var key := _stair_vertex_key(Vector2(vertex),float(ramp.level)+1)
			result[key] = {"point":Vector2(vertex),"at":high[0],"level":float(ramp.level)+1,"bottom":float(ramp.level),"inward":inward.sign(),"distance":.18}
	return result

func _clip_stair_corner(points: Array[Vector2], bevel: Dictionary) -> Array[Vector2]:
	var clipped: Array[Vector2] = []
	if points.is_empty(): return clipped
	var previous: Vector2 = points[-1]
	var before: float = (previous-bevel.point).dot(bevel.inward)-float(bevel.distance)
	for current in points:
		var after: float = (current-bevel.point).dot(bevel.inward)-float(bevel.distance)
		if (after>=-.00001) != (before>=-.00001): clipped.append(previous.lerp(current,before/(before-after)))
		if after>=-.00001: clipped.append(current)
		previous = current
		before = after
	return clipped

func _floor_coverage(point: Vector2, level: float) -> Color:
	# Interpolate neighbouring cell centres only where their actual surfaces
	# meet this height. A low stair cannot paint a high yard's outer corner.
	var sample := point-Vector2(.5,.5)
	var first := Vector2i(floori(sample.x),floori(sample.y))
	var fraction := sample-Vector2(first)
	var total := Color(0,0,0,0)
	var weight_sum := 0.0
	for v in 2:
		for u in 2:
			var at := first+Vector2i(u,v)
			var other := model.cell_at(at)
			if other.is_empty(): continue
			var height := float(other.level)
			if other.get("ramp") != null:
				var direction: Vector2i = Model.DIRS[other.ramp]
				var local := (point-Vector2(at)).clamp(Vector2.ZERO,Vector2.ONE)
				height += local.x if direction.x>0 else 1.0-local.x if direction.x<0 else local.y if direction.y>0 else 1.0-local.y
			if not is_equal_approx(height,level): continue
			var weight := (fraction.x if u else 1.0-fraction.x)*(fraction.y if v else 1.0-fraction.y)
			total += _floor_material_color(str(other.material))*weight
			weight_sum += weight
	if weight_sum < .0001: return Color(1,0,0,1)
	return Color(total.r/weight_sum,total.g/weight_sum,total.b/weight_sum,1)

func _painted_floor(at: Vector2i, cell: Dictionary, neighbourhood: bool = false) -> Polygon2D:
	var tile := Polygon2D.new()
	tile.position.y = -float(cell.level)*64
	tile.texture = load(kits[1].root + kits[1].floorSurface.file)
	var uv := PackedVector2Array()
	var weights := PackedColorArray()
	var corners := [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
	var colours: Array[Color] = []
	for index in 4: colours.append(_floor_material_color(str(cell.corners[index])))
	var coverage := func(f: Vector2) -> Color:
		if neighbourhood: return _floor_coverage(Vector2(at)+f,float(cell.level))
		return colours[0]*(1-f.x)*(1-f.y)+colours[1]*f.x*(1-f.y)+colours[2]*f.x*f.y+colours[3]*(1-f.x)*f.y
	var bevels: Array = []
	if neighbourhood:
		for bevel: Dictionary in stair_bevels.values():
			if bevel.at == at and is_equal_approx(float(bevel.level),float(cell.level)): bevels.append(bevel)
	var pure := true
	var reference: Color = coverage.call(Vector2(.5,.5))
	for v in 3:
		for u in 3:
			if not reference.is_equal_approx(coverage.call(Vector2(u*.5,v*.5))): pure = false
	var vertices := PackedVector2Array()
	if not bevels.is_empty():
		var triangles: Array[PackedInt32Array] = []
		var divisions := 8
		for v in divisions:
			for u in divisions:
				var a := Vector2(float(u)/divisions,float(v)/divisions)
				var b := Vector2(float(u+1)/divisions,float(v+1)/divisions)
				for source in [[a,Vector2(b.x,a.y),b],[a,b,Vector2(a.x,b.y)]]:
					var polygon: Array[Vector2] = []
					for f: Vector2 in source: polygon.append(Vector2(at)+f)
					for bevel: Dictionary in bevels: polygon = _clip_stair_corner(polygon,bevel)
					if polygon.size()<3: continue
					var indices := PackedInt32Array()
					for point in polygon:
						indices.append(vertices.size())
						var f := point-Vector2(at)
						vertices.append(Vector2((f.x-f.y)*32,(f.x+f.y)*16-16))
						uv.append(point*float(kits[1].floorSurface.cellTexels))
						weights.append(coverage.call(f))
					triangles.append(indices)
		tile.polygons = triangles
	elif pure:
		vertices = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
		for corner: Vector2 in corners:
			uv.append((Vector2(at)+corner)*float(kits[1].floorSurface.cellTexels))
			weights.append(reference)
	else:
		# Tessellate only mixed edges. Bilinear coverage curves naturally around
		# path ends instead of exposing the two triangles of a whole grid cell.
		var triangles: Array[PackedInt32Array] = []
		var divisions := 8
		for v in divisions+1:
			for u in divisions+1:
				var f := Vector2(float(u)/divisions,float(v)/divisions)
				vertices.append(Vector2((f.x-f.y)*32,(f.x+f.y)*16-16))
				uv.append((Vector2(at)+f)*float(kits[1].floorSurface.cellTexels))
				weights.append(coverage.call(f))
		for v in divisions:
			for u in divisions:
				var a := v*(divisions+1)+u
				triangles.append(PackedInt32Array([a,a+1,a+divisions+2]))
				triangles.append(PackedInt32Array([a,a+divisions+2,a+divisions+1]))
		tile.polygons = triangles
	tile.polygon = vertices
	tile.uv = uv
	tile.vertex_colors = weights
	if painted_floor_material == null:
		painted_floor_material = ShaderMaterial.new()
		painted_floor_material.shader = preload("res://scripts/overworld/painted_floor.gdshader")
	tile.material = painted_floor_material
	return tile

func _grass_surface(file: String, level: float = 0.0) -> Polygon2D:
	var floor_tile := Polygon2D.new()
	floor_tile.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
	floor_tile.uv = PackedVector2Array([Vector2(32,0),Vector2(64,16),Vector2(32,32),Vector2(0,16)])
	floor_tile.texture = load(file)
	floor_tile.position.y = -level*64
	if grass_material == null:
		grass_material = ShaderMaterial.new()
		grass_material.shader = preload("res://scripts/overworld/grass_floor.gdshader")
	floor_tile.material = grass_material
	return floor_tile

func _grass_decal(root: Node2D, at: Vector2i, level: int) -> void:
	var real_cell := model.cell_at(at)
	if real_cell.is_empty() or real_cell.material not in ["grama","construcao"] or lots.has(model.key(at)): return
	var details: Array = kits[1].get("decals", [])
	if details.is_empty(): return
	var edge := false
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _yardness(at+offset, level) != _yardness(at, level): edge = true
	if not edge or _grass_hash(at, 971) % 3 != 0: return
	var detail: Dictionary = details[_grass_hash(at, 7391) % details.size()]
	var decal := Sprite2D.new()
	decal.name = "Decal_" + str(detail.id)
	decal.texture = load(kits[1].root + detail.file)
	decal.centered = false
	decal.position = -Vector2(detail.anchor[0], detail.anchor[1]+level*64)
	# Visual-only Sprite2D: no physics body, area, footprint or navigation edits.
	root.add_child(decal)
	set_meta("grass_decal_count", int(get_meta("grass_decal_count", 0))+1)

func _draw_ramp(at: Vector2i, cell: Dictionary) -> void:
	var root := _floor_node(at, float(cell.level))
	var quad := PackedVector2Array()
	for offset in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
		quad.append(model.project(Vector2(at)+offset,false)-Vector2(0,model.surface_height(cell,offset)*64)-root.position)
	var ramp := Polygon2D.new()
	ramp.polygon = quad
	ramp.color = Color("DAD7C5") if model.data.biome == "morro" else Color("C7A16D")
	if art_preview and model.data.biome == "veredas" and kits.size()>1:
		ramp.color = Color.WHITE
		ramp.texture = load(kits[1].root+kits[1].surfaceAtlas)
		var extent: Vector2 = ramp.texture.get_size()
		ramp.uv = PackedVector2Array([Vector2.ZERO,Vector2(extent.x,0),extent,Vector2(0,extent.y)])
		ramp.material = _veredas_material(at,cell)
		# Visible ramp side closes to the lower ground, sharing the exact
		# support plane used by height_at and the actor's feet.
		for side in [Vector2i.RIGHT,Vector2i.DOWN]:
			var neighbor := model.cell_at(at+side)
			if not neighbor.is_empty() and (neighbor.get("ramp") != null or int(neighbor.level)>int(cell.level)): continue
			var a := Vector2(1,0) if side.x else Vector2(0,1)
			var b := Vector2.ONE
			var pa := model.project(Vector2(at)+a,false)-Vector2(0,model.surface_height(cell,a)*64)-root.position
			var pb := model.project(Vector2(at)+b,false)-Vector2(0,model.surface_height(cell,b)*64)-root.position
			var ba := model.project(Vector2(at)+a,false)-root.position-Vector2(0,float(cell.level)*64)
			var bb := model.project(Vector2(at)+b,false)-root.position-Vector2(0,float(cell.level)*64)
			if absf((pa-ba).y)+absf((pb-bb).y)<.01: continue
			var cheek := Polygon2D.new()
			# A side is an occluding wall, not a floor decal at z=-2. Sorting
			# it at its front ground endpoint hides the bank behind the slope.
			var cheek_root := Node2D.new()
			cheek_root.name = "LateralRampa"
			cheek_root.position = model.project(Vector2(at)+b,false)
			cheek_root.position.y -= 1.0
			actors.add_child(cheek_root)
			var shift := root.position-cheek_root.position
			cheek.polygon = PackedVector2Array([pa+shift,pb+shift,bb+shift,ba+shift])
			cheek.texture = load(kits[1].root+"superficies/barranco.png")
			cheek.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			var phase_a := (at.y+a.y if side.x else at.x+a.x)*96.0
			var phase_b := (at.y+b.y if side.x else at.x+b.x)*96.0
			cheek.uv = PackedVector2Array([Vector2(phase_a,-model.surface_height(cell,a)*160),Vector2(phase_b,-model.surface_height(cell,b)*160),Vector2(phase_b,-float(cell.level)*160),Vector2(phase_a,-float(cell.level)*160)])
			cheek.color = Color.WHITE if side.x else Color(.86,.83,.78)
			cheek_root.add_child(cheek)
	root.add_child(ramp)
	# Every riser is drawn on the same continuous height plane used by the feet.
	if model.data.biome == "morro":
		var direction: Vector2i = Model.DIRS[cell.ramp]
		for n in range(1,8):
			var a := Vector2(float(n)/8,0) if direction.x else Vector2(0,float(n)/8)
			var b := Vector2(float(n)/8,1) if direction.x else Vector2(1,float(n)/8)
			var stroke := Line2D.new()
			stroke.width = 1
			stroke.default_color = Color("87918C")
			stroke.points = PackedVector2Array([model.project(Vector2(at)+a.clamp(Vector2.ONE*.00001,Vector2.ONE*.99999))-root.position,model.project(Vector2(at)+b.clamp(Vector2.ONE*.00001,Vector2.ONE*.99999))-root.position])
			root.add_child(stroke)

func _build_faces() -> void:
	var finishes := _wall_finishes() if model.data.biome != "veredas" and art_preview and kits.size()>1 and kits[1].has("wallSurfaces") else {}
	for face in model.data.cliffs:
		# A compiled cliff against a ramp is not a full-height rectangular wall:
		# the steps occupy its lower section. The stair builder emits the exposed
		# cheek above each tread. Keeping both fills the opening with masonry.
		var adjacent := model.cell_at(Vector2i(face.u,face.v)+(Vector2i(1,0) if face.side == "u" else Vector2i(0,1)))
		var adjacent_at := Vector2i(face.u,face.v)+(Vector2i(1,0) if face.side == "u" else Vector2i(0,1))
		if art_preview and model.data.biome == "morro" and stairs_drawn.has(model.key(adjacent_at)) and kits.size()>1 and kits[1].has("wallSurfaces") and not adjacent.is_empty() and adjacent.get("ramp") != null and int(adjacent.level) == int(face.bottom) and int(face.top) == int(face.bottom)+1:
			continue
		var a := Vector2(face.u + 1, face.v) if face.side == "u" else Vector2(face.u, face.v + 1)
		var b := Vector2(face.u + 1, face.v + 1)
		if face.side == "u-": a = Vector2(face.u,face.v+1); b = Vector2(face.u,face.v)
		if face.side == "v-": a = Vector2(face.u+1,face.v); b = Vector2(face.u,face.v)
		var root := Node2D.new()
		root.position = model.project(b, false)
		if model.data.biome == "veredas": root.position.y = maxf(model.project(a,false).y,model.project(b,false).y)-1.0
		actors.add_child(root)
		var edge_a := a
		var edge_b := b
		var cut_a: Dictionary = stair_bevels.get(_stair_vertex_key(a,float(face.top)),{})
		var cut_b: Dictionary = stair_bevels.get(_stair_vertex_key(b,float(face.top)),{})
		if not cut_a.is_empty(): edge_a += (b-a).normalized()*float(cut_a.distance)
		if not cut_b.is_empty(): edge_b += (a-b).normalized()*float(cut_b.distance)
		var pa := model.project(edge_a,false) - root.position
		var pb := model.project(edge_b,false) - root.position
		for tier in range(int(face.bottom),int(face.top)):
			var wall := Polygon2D.new()
			var bottom_a := maxf(float(tier),float(face.get("bottomA",face.bottom)))
			var bottom_b := maxf(float(tier),float(face.get("bottomB",face.bottom)))
			wall.polygon = PackedVector2Array([pa-Vector2(0,(tier+1)*64),pb-Vector2(0,(tier+1)*64),pb-Vector2(0,bottom_b*64),pa-Vector2(0,bottom_a*64)])
			wall.color = Color("B8A58D") if face.side == "u" else Color("8F7C6E")
			if art_preview and kits.size()>1 and kits[1].walls.has("pedra"):
				var style: String = "pedra" if model.data.biome == "veredas" else finishes.get(_wall_face_key(face), "pedra" if _face_touches_path(face) or not kits[1].walls.has("chapisco") else "chapisco")
				if not kits[1].walls.has(style): style = "pedra"
				if kits[1].has("wallSurfaces"):
					var surface: Dictionary = kits[1].wallSurfaces[style]
					var along_v: bool = str(face.side).begins_with("u")
					var u := (edge_a.y if along_v else edge_a.x)*float(surface.repeatTexelsPerCell[0])
					var v := float(-tier*surface.repeatTexelsPerCell[1])
					var width := ((edge_b.y-edge_a.y) if along_v else (edge_b.x-edge_a.x))*float(surface.repeatTexelsPerCell[0])
					var height := float(surface.repeatTexelsPerCell[1])
					wall.texture = load(kits[1].root + surface.file)
					wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
					wall.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
					wall.uv = PackedVector2Array([Vector2(u,v-height),Vector2(u+width,v-height),Vector2(u+width,v-(bottom_b-tier)*height),Vector2(u,v-(bottom_a-tier)*height)])
					wall.color = Color.WHITE if face.side == "u" else Color(.86,.83,.78)
				else:
					wall.texture = load(kits[1].root + kits[1].walls[style][face.side][(int(face.u)+int(face.v))%2])
					wall.uv = PackedVector2Array([Vector2(32,0),Vector2(0,16),Vector2(0,80),Vector2(32,64)]) if face.side == "u" else PackedVector2Array([Vector2(0,0),Vector2(32,16),Vector2(32,80),Vector2(0,64)])
					wall.color = Color.WHITE
			root.add_child(wall)
		var rim := Line2D.new()
		rim.points = PackedVector2Array([pa-Vector2(0,face.top*64),pb-Vector2(0,face.top*64)])
		rim.width = 3.5 if art_preview and kits.size()>1 and kits[1].has("wallSurfaces") else 2.0
		rim.default_color = Color("E8D1A6") if art_preview and kits.size()>1 and kits[1].has("wallSurfaces") else Color("D5C9AD")
		if model.data.biome == "veredas" and str(face.side).ends_with("-"): rim.visible = false
		root.add_child(rim)
		if art_preview and kits.size()>1 and kits[1].has("wallSurfaces"):
			var contact := Line2D.new()
			contact.points = PackedVector2Array([pa-Vector2(0,face.bottom*64),pb-Vector2(0,face.bottom*64)])
			contact.width = 1.5
			contact.default_color = Color(.25,.19,.10,.26)
			root.add_child(contact)
	# Close every clipped corner with the corresponding vertical face and cap.
	for bevel: Dictionary in stair_bevels.values():
		var a: Vector2 = bevel.point+Vector2(bevel.inward.x,0)*float(bevel.distance)
		var b: Vector2 = bevel.point+Vector2(0,bevel.inward.y)*float(bevel.distance)
		var top := float(bevel.level)*64
		var bottom := float(bevel.bottom)*64
		var node := Node2D.new()
		node.name = "CantoChanfradoEscada"
		node.position = model.project(bevel.point,false)
		actors.add_child(node)
		var wall := _stone_wall_quad([a,b],bottom,top,false)
		var points := wall.polygon
		for index in points.size(): points[index] -= node.position
		wall.polygon = points
		node.add_child(wall)
		var cap := Line2D.new()
		cap.points = PackedVector2Array([model.project(a,false)-Vector2(0,top)-node.position,model.project(b,false)-Vector2(0,top)-node.position])
		cap.width = 3.5
		cap.default_color = Color("E8D1A6")
		node.add_child(cap)

func _face_touches_path(face: Dictionary) -> bool:
	var upper := Vector2i(int(face.u), int(face.v))
	var lower := upper + (Vector2i(1,0) if face.side == "u" else Vector2i(0,1))
	return model.walkable(upper) or model.walkable(lower)

func _wall_face_key(face: Dictionary) -> String:
	return str(face.u)+":"+str(face.v)+":"+str(face.side)

func _wall_finishes() -> Dictionary:
	# Connected visible faces at the same height interval share one finish.
	# A corner must not alternate stone/stucco just because one face touches a path.
	var faces: Array = model.data.cliffs
	var vertices: Dictionary = {}
	var corners: Array = []
	for index in faces.size():
		var face: Dictionary = faces[index]
		var a := Vector2i(face.u+1,face.v) if face.side == "u" else Vector2i(face.u,face.v+1)
		var b := Vector2i(face.u+1,face.v+1)
		var keys: Array[String] = []
		for point in [a,b]:
			var key := str(point.x)+":"+str(point.y)+":"+str(face.bottom)+":"+str(face.top)
			keys.append(key)
			if not vertices.has(key): vertices[key] = []
			vertices[key].append(index)
		corners.append(keys)
	var visited: Dictionary = {}
	var result: Dictionary = {}
	var records: Array = []
	for start in faces.size():
		if visited.has(start): continue
		var pending: Array[int] = [start]
		var component: Array[int] = []
		var stone := false
		visited[start] = true
		while not pending.is_empty():
			var current: int = pending.pop_back()
			component.append(current)
			if _face_touches_path(faces[current]): stone = true
			for key in corners[current]:
				for adjacent: int in vertices[key]:
					if visited.has(adjacent): continue
					visited[adjacent] = true
					pending.append(adjacent)
		var finish := "pedra" if stone else "chapisco"
		for index in component: result[_wall_face_key(faces[index])] = finish
		records.append({"faces":component.size(),"finish":finish})
	set_meta("wall_finish_components", records)
	return result

func _soft_yards() -> bool:
	return art_preview and model.data.biome == "morro" and kits.size()>1 and kits[1].materials.has("grama")

func _average_color(path: String) -> Color:
	var image := (load(path) as Texture2D).get_image()
	var sum := Color(0,0,0,0)
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x,y)
			if c.a < .9: continue
			sum += c
			count += 1
	return Color(sum.r/count, sum.g/count, sum.b/count) if count > 0 else Color("7fb85a")

func _yardness(cell: Vector2i, level: int) -> float:
	# 1 for a yard (blocked lot) or outside the map, 0 for the walkable lawn.
	var c := model.cell_at(cell)
	if c.is_empty(): return 1.0
	if int(c.level) != level: return 1.0 if not model.walkable(cell) else 0.0
	return 0.0 if model.walkable(cell) else 1.0

func _build_lawn_base() -> void:
	# Extend the same lawn beyond the map. Inside tiles stand on their own;
	# there is deliberately no coloured underlay concealing diamond seams.
	var base := Node2D.new()
	base.name = "BaseGramado"
	base.z_index = -99
	actors.add_child(base)
	var ring := 8
	var grass: Array = kits[1].materials.grama.variants
	for v in range(-ring, int(model.data.h)+ring):
		for u in range(-ring, int(model.data.w)+ring):
			var at := Vector2i(u,v)
			var inside := not model.cell_at(at).is_empty()
			if inside: continue
			if not inside:
				# The lawn texture runs past the map edge, so the edge has no seam.
				var tile: Polygon2D
				if kits[1].has("floorSurface"):
					tile = _painted_floor(at, {"level":0,"corners":["grama","grama","grama","grama"]})
				else:
					tile = _grass_surface(kits[1].root + grass[_grass_hash(at) % grass.size()])
				tile.position = model.project(Vector2(at)+Vector2(.5,.5), false)
				base.add_child(tile)
			var shade := _yard_shade(at, 0.0)
			shade.position = model.project(Vector2(at)+Vector2(.5,.5), false)
			base.add_child(shade)

func _morro_canopy_shadow() -> void:
	if not art_preview or model.data.biome != "morro" or kits.size()<2: return
	var recipe: Dictionary = kits[1].get("areaVisuals",{}).get(area_id,{})
	var strength := float(recipe.get("canopyShadow",0.0))
	if strength<=0: return
	for piece in model.data.pieces:
		if piece.asset != "arvore-grande": continue
		var trunk := Vector2(piece.u+piece.fu*.5,piece.v+piece.fv*.5)
		var centre := trunk+Vector2(.7,.4)
		var level := model.height_at(trunk)
		for v in range(floori(centre.y)-4,floori(centre.y)+5):
			for u in range(floori(centre.x)-4,floori(centre.x)+5):
				var at := Vector2i(u,v)
				var cell := model.cell_at(at)
				if cell.is_empty() or cell.get("ramp") != null or not is_equal_approx(float(cell.level),level): continue
				var colours := PackedColorArray()
				for corner: Vector2 in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
					var point: Vector2 = Vector2(at)+corner
					var distance: float = point.distance_to(centre)/3.0
					var dapple := .90+.10*sin(point.x*5+point.y*3)*sin(point.y*7-point.x*2)
					colours.append(Color(.10,.18,.23,strength*(1.0-smoothstep(.30,1.0,distance))*dapple))
				var shade := Polygon2D.new()
				shade.name = "SombraDaCopa"
				shade.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
				shade.vertex_colors = colours
				shade.position = model.project(Vector2(at)+Vector2(.5,.5),false)-Vector2(0,level*64)
				shade.z_index = -1
				actors.add_child(shade)

func _yard_shade(at: Vector2i, level: float) -> Polygon2D:
	# Each diamond vertex averages the four cells that share it; Godot blends the
	# vertex colours across the cell, which turns the stair-step edge into a gradient.
	var corners := [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]
	var colors := PackedColorArray()
	for corner in corners:
		var vertex: Vector2i = at + corner
		var amount := 0.0
		for d in [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(-1,0), Vector2i(0,0)]: amount += _yardness(vertex + d, int(level))
		colors.append(Color(YARD_SHADE, YARD_SHADE_ALPHA * amount / 4.0))
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([Vector2(0,-16), Vector2(32,0), Vector2(0,16), Vector2(-32,0)])
	shade.vertex_colors = colors
	shade.position.y = -level * 64
	return shade

func _occupied_lots() -> Dictionary:
	# Cells under a piece footprint, by asset. Bare lots and low yard walls stand on grass.
	var taken := {}
	for piece in model.data.pieces:
		if hidden_pieces.has(str(piece.id)): continue
		for du in int(piece.fu):
			for dv in int(piece.fv): taken[model.key(Vector2i(int(piece.u)+du,int(piece.v)+dv))] = str(piece.asset)
	return taken

func _draw_kit_stairs(at: Vector2i, cell: Dictionary) -> bool:
	# Kit stairs are two cells wide: one sprite covers the pair, from the lower
	# floor to one level up, on the same plane the feet follow.
	if not art_preview or kits.size()<2 or not kits[1].get("stairs",{}).has(cell.ramp): return false
	if stairs_drawn.has(model.key(at)): return true
	var direction: Vector2i = Model.DIRS[cell.ramp]
	var across := Vector2i(absi(direction.y), absi(direction.x))
	if model.data.biome == "morro" and kits[1].has("floorSurface") and kits[1].has("wallSurfaces"):
		# A flight can be one, two, or three cells wide. Pairing only two leaves
		# the last cell of the Mirante staircase as a separate grey ramp.
		var start := at
		var finish := at
		for sign_value: int in [-1,1]:
			var cursor := at
			while true:
				var candidate: Vector2i = cursor+across*sign_value
				var c := model.cell_at(candidate)
				if c.is_empty() or c.get("ramp") != cell.ramp or int(c.level) != int(cell.level):break
				cursor=candidate
			if sign_value<0:start=cursor
			else:finish=cursor
		_draw_stone_stairs(start,finish+Vector2i.ONE,cell)
		var cursor := start
		while true:
			stairs_drawn[model.key(cursor)]=true
			if cursor==finish:break
			cursor+=across
		return true
	var partner := Vector2i(-1,-1)
	for side in [across, -across]:
		var other := model.cell_at(at+side)
		if not other.is_empty() and other.get("ramp") == cell.ramp and int(other.level) == int(cell.level) and not stairs_drawn.has(model.key(at+side)):
			partner = at+side
			break
	if partner.x < 0: return false
	var first := Vector2i(mini(at.x,partner.x), mini(at.y,partner.y))
	var last := Vector2i(maxi(at.x,partner.x), maxi(at.y,partner.y)) + Vector2i.ONE
	var top_left := Vector2(INF, INF)
	for corner in [Vector2(first), Vector2(last.x,first.y), Vector2(first.x,last.y), Vector2(last)]:
		for h in [float(cell.level), float(cell.level)+1.0]:
			top_left = Vector2(minf(top_left.x,(corner.x-corner.y)*32.0), minf(top_left.y,(corner.x+corner.y)*16.0-h*64.0))
	var sprite := Sprite2D.new()
	sprite.texture = load(kits[1].root + kits[1].stairs[cell.ramp].file)
	sprite.centered = false
	sprite.position = top_left
	# Below every actor, like the floor: a person on the steps is never covered.
	sprite.z_index = -1
	actors.add_child(sprite)
	stairs_drawn[model.key(at)] = true
	stairs_drawn[model.key(partner)] = true
	return true

func _stone_wall_quad(points: Array, bottom: float, top: float, along_u: bool) -> Polygon2D:
	var face := Polygon2D.new()
	face.texture = load(kits[1].root+kits[1].wallSurfaces.pedra.file)
	face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	face.color = Color(.86,.83,.78) if along_u else Color.WHITE
	var a: Vector2 = points[0]
	var b: Vector2 = points[1]
	face.polygon = PackedVector2Array([model.project(a,false)-Vector2(0,top),model.project(b,false)-Vector2(0,top),model.project(b,false)-Vector2(0,bottom),model.project(a,false)-Vector2(0,bottom)])
	var u0 := (a.x if along_u else a.y)*128
	var u1 := (b.x if along_u else b.y)*128
	face.uv = PackedVector2Array([Vector2(u0,-top*4),Vector2(u1,-top*4),Vector2(u1,-bottom*4),Vector2(u0,-bottom*4)])
	return face

func _draw_stone_stairs(first: Vector2i, last: Vector2i, cell: Dictionary) -> void:
	# Eight real stone treads, projected from the exact same 2:1 footprint and
	# 64px rise as the navigation ramp. Artwork never defines the endpoints.
	var root := Node2D.new()
	root.name = "EscadaDePedra"
	root.z_index = -1
	root.y_sort_enabled = true
	actors.add_child(root)
	var direction := str(cell.ramp)
	var base := float(cell.level)*64
	var parts: Array = []
	var across_u := direction.begins_with("v")
	var width := float(last.x-first.x) if across_u else float(last.y-first.y)
	for step in 8:
		var t := float(step)/8
		var next := float(step+1)/8
		var height := base+(step+1)*8
		var q: Array[Vector2]
		if direction == "u+": q = [Vector2(t,0),Vector2(next,0),Vector2(next,width),Vector2(t,width)]
		elif direction == "u-": q = [Vector2(1-next,0),Vector2(1-t,0),Vector2(1-t,width),Vector2(1-next,width)]
		elif direction == "v+": q = [Vector2(0,t),Vector2(width,t),Vector2(width,next),Vector2(0,next)]
		else: q = [Vector2(0,1-next),Vector2(width,1-next),Vector2(width,1-t),Vector2(0,1-t)]
		for index in 4: q[index] += Vector2(first)
		var tread := Polygon2D.new()
		var polygon := PackedVector2Array()
		var uv := PackedVector2Array()
		var centre := Vector2.ZERO
		for point in q:
			polygon.append(model.project(point,false)-Vector2(0,height))
			uv.append(point*64)
			centre += point*.25
		tread.polygon = polygon
		tread.uv = uv
		tread.texture = load(kits[1].root+kits[1].floorSurface.file)
		tread.vertex_colors = PackedColorArray([Color(0,1,0,1),Color(0,1,0,1),Color(0,1,0,1),Color(0,1,0,1)])
		tread.material = painted_floor_material
		tread.set_meta("stair_face","tread")
		parts.append({"node":tread,"depth":centre.x+centre.y})
		var edge: Array = [q[0],q[3]] if direction == "u+" else [q[1],q[2]] if direction == "u-" else [q[0],q[1]] if direction == "v+" else [q[2],q[3]]
		var riser := _stone_wall_quad(edge,height-8,height,across_u)
		parts.append({"node":riser,"depth":(edge[0].x+edge[0].y+edge[1].x+edge[1].y)*.5+.0001})
		# Fill the underside at both flanks. Adjacent retaining faces and yards
		# occlude this support naturally, without triangular grey sprite margins.
		var flanks: Array = [[q[0],q[1]],[q[3],q[2]]] if not across_u else [[q[0],q[3]],[q[1],q[2]]]
		for side: Array in flanks:
			var support := _stone_wall_quad(side,base,height,not across_u)
			parts.append({"node":support,"depth":(side[0].x+side[0].y+side[1].x+side[1].y)*.5-.0001})
			# Excavated terrace: the exposed wall is ABOVE the treads. A solid
			# wedge underneath alone makes the flight look buried in the lawn.
			var midpoint: Vector2 = (side[0]+side[1])*.5
			var outward := Vector2(-1,0) if across_u and midpoint.x == first.x else Vector2(1,0) if across_u else Vector2(0,-1) if midpoint.y == first.y else Vector2(0,1)
			var neighbour := model.cell_at(Vector2i((midpoint+outward*.05).floor()))
			if not neighbour.is_empty() and not neighbour.get("ramp","") and float(neighbour.level)*64 >= base+64:
				var cheek := _stone_wall_quad(side,height,base+70,not across_u)
				cheek.name = "ParedeInternaEscada"
				cheek.color *= Color(.60,.61,.58)
				cheek.set_meta("stair_face","cheek")
				parts.append({"node":cheek,"depth":midpoint.x+midpoint.y+.0003,"layer":1})
				var outer_edge: Array = [side[0]+outward*.16,side[1]+outward*.16]
				parts.append({"node":_stone_wall_quad(outer_edge,base+64,base+70,not across_u),"depth":midpoint.x+midpoint.y+outward.x*.16+outward.y*.16,"layer":1})
				var cap := Polygon2D.new()
				cap.name = "CoroamentoEscada"
				cap.color = Color("E8D1A6")
				var cap_points := PackedVector2Array()
				for p: Vector2 in [side[0],side[1],side[1]+outward*.16,side[0]+outward*.16]:
					cap_points.append(model.project(p,false)-Vector2(0,base+70))
				cap.polygon = cap_points
				parts.append({"node":cap,"depth":midpoint.x+midpoint.y+.0004,"layer":1})
				# Close the little curb at both ends; no floating coping strips.
				if step in [0,7]:
					var mouth: Vector2 = side[0] if (direction in ["u+","v+"]) == (step == 0) else side[1]
					parts.append({"node":_stone_wall_quad([mouth,mouth+outward*.16],base+64,base+70,across_u),"depth":mouth.x+mouth.y+.0005,"layer":1})
	var back: Array
	if direction == "u+": back = [Vector2(last.x,first.y),Vector2(last)]
	elif direction == "u-": back = [Vector2(first),Vector2(first.x,last.y)]
	elif direction == "v+": back = [Vector2(first.x,last.y),Vector2(last)]
	else: back = [Vector2(first),Vector2(last.x,first.y)]
	parts.append({"node":_stone_wall_quad(back,base,base+64,across_u),"depth":(back[0].x+back[0].y+back[1].x+back[1].y)*.5+.0002})
	parts.sort_custom(func(a,b): return a.depth < b.depth)
	for part in parts:
		# Floor/steps are support surfaces below actors; upright cheeks join the
		# retaining walls at z=0 and sort by their unraised footprint.
		var anchor := Node2D.new()
		anchor.z_index = int(part.get("layer",0))
		anchor.position.y = float(part.depth)*16
		var points: PackedVector2Array = part.node.polygon
		for index in points.size(): points[index] -= anchor.position
		part.node.polygon = points
		root.add_child(anchor)
		anchor.add_child(part.node)

func _touches_path(u: int, v: int, fu: int, fv: int, reach: int = 1) -> bool:
	for y in range(v-reach, v+fv+reach):
		for x in range(u-reach, u+fu+reach):
			if model.walkable(Vector2i(x,y)): return true
	return false

func _hides_path(u: int, v: int, fu: int, fv: int) -> bool:
	# Tall art covers the cells drawn above it on screen: smaller u+v, about the
	# same screen column. Anything walkable there would be hidden behind it.
	var front := u+fu+v+fv
	for y in range(v-8, v+fv):
		for x in range(u-8, u+fu):
			if front-(x+y) > 9 or front-(x+y) < 2: continue
			if absi((x-y)-(u-v+(fu-fv)/2)) > 3: continue
			if model.walkable(Vector2i(x,y)): return true
	return false

func _next_to_house(u: int, v: int) -> bool:
	# Pots and flowers gather by the doors instead of dotting the whole lot.
	for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
		if lots.get(model.key(Vector2i(u,v)+d), "") == "casa-morro": return true
	return false

func _compose_houses() -> Dictionary:
	# Composition pass (visual only, the map keeps its blocked lots): a few houses
	# facing the path with breathing room between them; the rest of the lot turns
	# into yard and tree mass. Hand-placed houses win over generated filler.
	var hidden := {}
	if not art_preview or model.data.biome != "morro": return hidden
	var authored: Dictionary = kits[1].get("composition",{}).get(area_id,{}) if kits.size()>1 else {}
	if authored.has("houses"):
		var visible_ids := {}
		for house_id in authored.houses: visible_ids[int(house_id)] = true
		for piece in model.data.pieces:
			if piece.asset == "casa-morro" and not visible_ids.has(int(piece.id)): hidden[str(piece.id)] = true
			if piece.asset == "muro-quintal": hidden[str(piece.id)] = true
		return hidden
	var houses: Array = []
	for piece in model.data.pieces:
		if piece.asset == "casa-morro": houses.append(piece)
	houses.sort_custom(func(a, b):
		var ga := str(a.props.get("origem","")).begins_with("PIP-87")
		var gb := str(b.props.get("origem","")).begins_with("PIP-87")
		return int(a.id) < int(b.id) if ga == gb else gb)
	var kept: Array[Rect2i] = []
	var shown := {}
	# First pass: houses behind the path (never cover it). Second pass, until the
	# area has MIN_HOUSES: houses in front, which fade when Kael walks behind them.
	for allow_front in [false, true]:
		for piece in houses:
			if shown.has(str(piece.id)) or kept.size() >= (MAX_HOUSES if not allow_front else MIN_HOUSES): continue
			var rect := Rect2i(int(piece.u), int(piece.v), int(piece.fu), int(piece.fv))
			var crowded := false
			for other in kept:
				if other.grow(2).intersects(rect): crowded = true
			if crowded or not _touches_path(rect.position.x, rect.position.y, rect.size.x, rect.size.y): continue
			if not allow_front and _hides_path(rect.position.x, rect.position.y, rect.size.x, rect.size.y): continue
			kept.append(rect)
			shown[str(piece.id)] = true
	for piece in houses:
		if not shown.has(str(piece.id)): hidden[str(piece.id)] = true
	# Low yard walls in loose fragments read as clutter: the edges are drawn by
	# houses and tree mass instead.
	for piece in model.data.pieces:
		if piece.asset == "muro-quintal": hidden[str(piece.id)] = true
	return hidden

func _dress_bare_lots() -> void:
	# Visual only: blocked lots without a house get yard props. Navigation,
	# events and collision come from the map and stay unchanged.
	if not art_preview or model.data.biome != "morro" or kits.size()<2: return
	var used := lots.duplicate()
	var fits := func(u: int, v: int, n: int) -> bool:
		var base := model.cell_at(Vector2i(u,v))
		for du in n:
			for dv in n:
				var cell := model.cell_at(Vector2i(u+du,v+dv))
				if cell.is_empty() or cell.material != "construcao" or used.has(model.key(Vector2i(u+du,v+dv))) or cell.level != base.level: return false
		return true
	# Back of the lot: tree mass. Along the path: a few yard objects only.
	var woods := [["arvore","a"],["arvore","b"],["arvore","tronco-largo"],["arvore","a"],["arvore","b"]]
	var yard := [["varal",""],["caixa-dagua",""]]
	var small := [["vaso","pneu"],["flores","coral"],["vaso","ceramica"],["flores","amarela"]]
	for v in int(model.data.h):
		for u in int(model.data.w):
			var seed := posmod(u*131+v*57+int(model.data.w)*7,97)
			var pick: Array = []
			var n := 1
			var front := _touches_path(u,v,2,2)
			if bool(kits[1].get("automaticLotTrees",true)) and not front and seed%4 != 0 and fits.call(u,v,2) and not _hides_path(u,v,2,2):
				pick = woods[seed%woods.size()]
				n = 2
			elif bool(kits[1].get("automaticYardFurniture",true)) and front and seed%5 == 0 and fits.call(u,v,2) and not _hides_path(u,v,2,2):
				pick = yard[seed%yard.size()]
				n = 2
			elif bool(kits[1].get("automaticLotSmall",true)) and seed%3 == 0 and fits.call(u,v,1) and _next_to_house(u,v): pick = small[seed%small.size()]
			if pick.is_empty(): continue
			var info := _definition({"asset":pick[0],"id":"lote","props":{"variante":pick[1]} if pick[1] != "" else {}})
			if info.is_empty(): continue
			for du in n:
				for dv in n: used[model.key(Vector2i(u+du,v+dv))] = true
			var sort_point := Vector2(u+n,v+n)
			var node := Prop.new()
			node.configure(info,Vector2i(n,n),float(model.cell_at(Vector2i(u,v)).level),false,model.project(Vector2(u+n*.5,v+n*.5),false)-model.project(sort_point,false))
			node.position = model.project(sort_point,false)
			actors.add_child(node)
			occluders.append(node)

func _bairro_ground_details() -> void:
	if not art_preview or model.data.biome != "bairro" or kits.size()<2: return
	for decoration: Dictionary in kits[1].get("groundDetails",[]):
		var point := Vector2(decoration.point[0],decoration.point[1])
		var cell := model.cell_at(Vector2i(point.floor()))
		if str(cell.get("material","")) not in ["asfalto","calcada"]: continue
		var sprite := Sprite2D.new()
		sprite.texture = load(kits[1].root+decoration.file)
		sprite.position = model.project(point,false)
		sprite.z_index = -1
		actors.add_child(sprite)

func _bairro_ground_shadows() -> void:
	if not art_preview or model.data.biome not in ["bairro","parque","veredas"]: return
	var canopy_material := ShaderMaterial.new()
	canopy_material.shader = load("res://shaders/bairro_ground_shadow.gdshader")
	for node in piece_nodes.values():
		var piece: Dictionary = node.get_meta("piece")
		if str(piece.asset) not in ["casa-kael","casa-assis","loja-pipas"]: continue
		var shadow := Polygon2D.new()
		var vertices := PackedVector2Array()
		for uv in [Vector2(piece.u,piece.v),Vector2(piece.u+piece.fu,piece.v),Vector2(piece.u+piece.fu,piece.v+piece.fv),Vector2(piece.u,piece.v+piece.fv)]:
			vertices.append(model.project(uv,false)+Vector2(18,12))
		shadow.polygon = vertices
		shadow.z_index = -1
		shadow.color = Color(.10,.18,.25,.19)
		actors.add_child(shadow)
	for node in occluders:
		if node.get_script() != Prop: continue
		var definition: Dictionary = node.get("definition")
		var texture_path := str(definition.get("texture",""))
		if not texture_path.contains("arvore") and not texture_path.contains("buriti"): continue
		var art := node.get_node_or_null("Art") as Sprite2D
		if art == null: continue
		var root := Node2D.new()
		root.z_index = -1
		var contact := node.get_node_or_null("Contact") as Sprite2D
		var foot := contact.position if contact != null else Vector2.ZERO
		if model.data.biome == "veredas":
			root.transform = Transform2D(Vector2(.9,.15),Vector2(-.35,-.32),node.position+foot)
		else:
			root.transform = Transform2D(Vector2(.9,.42),Vector2(-.4,-.2),node.position)
		var silhouette := Sprite2D.new()
		silhouette.centered = false
		silhouette.texture = art.texture
		silhouette.position = art.position-foot if model.data.biome == "veredas" else art.position
		silhouette.material = canopy_material
		root.add_child(silhouette)
		actors.add_child(root)

func _definition(piece: Dictionary) -> Dictionary:
	var variant := str(piece.props.get("variante", ""))
	if piece.asset == "arvore" and model.data.biome == "veredas" and kits.size()>1 and kits[1].has("treeMix"):
		var mix: Array = kits[1].treeMix
		variant = mix[posmod(int(str(piece.id)),mix.size())]
	if piece.asset == "bau" and opened.has(area_id+":"+str(piece.id)): variant = "aberto"
	if variant.is_empty() and piece.asset == "banco": variant = "concreto" if model.data.biome == "morro" else "madeira"
	if variant.is_empty() and piece.asset == "placa-mapa": variant = "veredas" if model.data.biome == "veredas" else "parque"
	for kit_index in range(kits.size()-1,-1,-1):
		var kit: Dictionary = kits[kit_index]
		if not kit.pieces.has(piece.asset): continue
		var group: Dictionary = kit.pieces[piece.asset]
		var entry: Dictionary = group.variants.get(variant, group.variants[group.default]).duplicate(true)
		entry.texture = kit.root + entry.file
		if entry.has("roofFile"):
			entry.texture = kit.root + entry.roofFile
			for part in entry.get("supportParts",[]): part.texture = kit.root + part.file
		entry.shadow_texture = kit.root + entry.shadow
		return entry
	# Fruit trees come from their own library, in any biome that places them.
	var orchard: Dictionary = kit_library.get("frutiferas",{})
	if orchard.get("pieces",{}).has(piece.asset):
		var entry: Dictionary = orchard.pieces[piece.asset].variants.values()[0].duplicate(true)
		entry.texture = orchard.root + entry.file
		entry.shadow_texture = orchard.root + entry.shadow
		return entry
	return {}

func _dress_bairro_gardens() -> void:
	# Garden boundaries decorate only already-blocked source cells. No changes
	# to movement, interaction positions or source-map object identifiers.
	if not art_preview or model.data.biome != "bairro" or kits.size()<2: return
	# Visual road continuation beyond both exits, without adding walkable cells.
	for v in int(model.data.h):
		for edge_u in [0,int(model.data.w)-1]:
			var source := model.cell_at(Vector2i(edge_u,v))
			if str(source.material) not in ["calcada","asfalto"]: continue
			for distance in range(1,9):
				var outside_u: int = -distance if edge_u==0 else int(model.data.w)-1+distance
				var cell: Dictionary = source.duplicate(true)
				cell.corners = [source.material,source.material,source.material,source.material]
				_draw_art_floor(Vector2i(outside_u,v),cell)
	var occupied := {}
	for piece in model.data.pieces:
		for du in int(piece.fu):
			for dv in int(piece.fv): occupied[Vector2i(piece.u+du,piece.v+dv)] = true
	var wire_points: Array[Vector2] = []
	for decoration: Dictionary in kits[1].get("dressing",[]):
		var point := Vector2(decoration.point[0],decoration.point[1])
		var at := Vector2i(point.floor())
		if model.cell_at(at).get("material","") != "canteiro" or occupied.has(at): continue
		var entry := _definition({"asset":decoration.asset,"id":"garden-detail","props":{"variante":decoration.variant}})
		if entry.is_empty(): continue
		var prop := Prop.new()
		prop.position = model.project(point,false)
		prop.configure(entry,Vector2i.ONE,0,false)
		actors.add_child(prop)
		occluders.append(prop)
		occupied[at] = true
		if decoration.asset == "poste": wire_points.append(model.project(point,false)-Vector2(0,145))
	if wire_points.size()==2:
		var wire := Line2D.new()
		wire.width = 1.2
		wire.default_color = Color("26394D",.72)
		# The street wire runs behind the roof silhouettes, rather than drawing
		# a diagonal stripe through every foreground facade and window.
		wire.position = wire_points[0]+Vector2(0,145)
		for index in 21:
			var t := float(index)/20
			wire.add_point(wire_points[0].lerp(wire_points[1],t)+Vector2(0,24*4*t*(1-t))-wire.position)
		actors.add_child(wire)
	for v in int(model.data.h):
		for u in int(model.data.w):
			var at := Vector2i(u,v)
			var cell := model.cell_at(at)
			if cell.material != "canteiro" or occupied.has(at): continue
			var boundary := false
			for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var neighbour := model.cell_at(at+delta)
				if not neighbour.is_empty() and str(neighbour.material) in ["calcada","terra"]: boundary = true
			var asset := "cerca-viva" if boundary else ""
			var variant := ""
			# Back gardens continue beyond the houses with the shared tree family.
			if not boundary and v in [1,4] and u%5==2:
				asset = "arvore"
				variant = "a" if u%2==0 else "b"
			if asset.is_empty(): continue
			var entry := _definition({"asset":asset,"id":"garden","props":{"variante":variant}})
			if entry.is_empty(): continue
			var point := Vector2(at)+Vector2(.5,.5)
			var prop := Prop.new()
			prop.position = model.project(point,false)
			prop.configure(entry,Vector2i.ONE,0,false)
			actors.add_child(prop)
			occluders.append(prop)

func _build_pieces(source_pieces: Array = []) -> void:
	var collection: Array = model.data.pieces if source_pieces.is_empty() else source_pieces
	for piece in collection:
		if hidden_pieces.has(str(piece.id)): continue
		if bool(piece.props.get("apenas_colisao",false)):
			# Pillars are painted in the coreto sprite; these five source objects
			# contribute only independent physical bodies and graph blockers.
			var body := StaticBody2D.new()
			body.collision_layer = 2
			body.collision_mask = 0
			body.position = model.project(Vector2(piece.u+.5,piece.v+.5),false)
			var shape := CollisionPolygon2D.new()
			shape.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
			body.add_child(shape)
			actors.add_child(body)
			continue
		var node: Node2D
		var entry := _definition(piece)
		var point := Vector2(piece.u + piece.fu*.5, piece.v + piece.fv*.5)
		var sort_point := Vector2(piece.u + piece.fu, piece.v + piece.fv)
		var center_offset := model.project(point,false)-model.project(sort_point,false)
		if art_preview and not entry.is_empty():
			if entry.has("scene"):
				var packed: PackedScene = load(entry.scene)
				node = packed.instantiate()
			else: node = Prop.new()
			node.configure(entry, Vector2i(piece.fu,piece.fv), model.height_at(point), piece.blocks,center_offset)
		else:
			node = Node2D.new()
			var block := Polygon2D.new()
			var quad := PackedVector2Array()
			for uv in [Vector2(piece.u,piece.v),Vector2(piece.u+piece.fu,piece.v),Vector2(piece.u+piece.fu,piece.v+piece.fv),Vector2(piece.u,piece.v+piece.fv)]: quad.append(model.project(uv,false)-model.project(sort_point,false)-Vector2(0,model.height_at(point)*64))
			block.polygon = quad
			block.color = Color("26394D") if piece.blocks else Color("E8BC58")
			node.add_child(block)
		node.position = model.project(sort_point,false)
		node.set_meta("piece",piece)
		node.set_meta("scenery",true)
		actors.add_child(node)
		piece_nodes[str(piece.id)] = node
		occluders.append(node)
		if art_preview and entry.has("supportParts"):
			var roof := node.get_node("Art") as Sprite2D
			for part in entry.supportParts:
				var foot := Vector2(part.foot[0],part.foot[1])
				var pillar := Node2D.new()
				var elevation: float = model.height_at(point)*64
				pillar.position = node.position+roof.position+foot+Vector2(0,elevation)
				pillar.set_meta("scenery",true)
				var sprite := Sprite2D.new()
				sprite.name = "Art"
				sprite.texture = load(part.texture)
				sprite.centered = false
				sprite.position = -foot-Vector2(0,elevation)
				pillar.add_child(sprite)
				actors.add_child(pillar)
				occluders.append(pillar)
		if piece.interact != null:
			interaction_events.append({"id":"piece-"+str(piece.id),"piece_id":str(piece.id),"type":"piece","name":piece.name,"asset":piece.asset,"u":piece.u,"v":piece.v,"props":{"interacao":piece.interact}})

func _build_events() -> void:
	var npc_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/npcs.json"))
	for event in interaction_events:
		var node := Area2D.new()
		node.name = "Evento" + str(event.id)
		node.position = model.project(Vector2(event.u+.5,event.v+.5),false)
		node.collision_layer = 0
		node.collision_mask = 0
		node.set_meta("event",event)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 28
		shape.shape = circle
		node.add_child(shape)
		actors.add_child(node)
		if event.type=="npc":
			var list: Array = npc_data.morro.get(model.data.scene,[]) if model.data.biome=="morro" else [npc_data.nina] if event.name=="Nina" else [npc_data.lacertubo] if event.props.get("acao", "")=="parkBoss" else [npc_data.assis] if model.data.biome=="parque" else []
			var holder := Node2D.new()
			node.add_child(holder)
			var names: Array[String] = []
			for i in list.size():
				var entry: Dictionary = list[i]
				var bounds: Dictionary = entry.bounds
				var sprite := Sprite2D.new()
				sprite.texture=load(entry.image);sprite.region_enabled=true
				sprite.region_rect=Rect2(bounds.x,bounds.y,bounds.w,bounds.h)
				var native_height := 128.0 if entry.name=="Lacertubo" else 84.0
				sprite.scale=Vector2.ONE*native_height/float(bounds.h)
				sprite.offset=Vector2(0,-bounds.h*.5)
				sprite.position.x=(i-(list.size()-1)*.5)*30
				holder.add_child(sprite)
				names.append(entry.name)
			if not names.is_empty():event.name=" e ".join(names)
			npc_nodes.append({"root":node,"visual":holder,"point":Vector2(event.u+.5,event.v+.5)})

func hide_characters() -> void:
	player_root.hide();follower_root.hide()
	for actor in npc_nodes:actor.root.hide()

func _build_hud() -> void:
	interface = CanvasLayer.new()
	add_child(interface)
	var control := Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.theme = Hud.make_theme()
	interface.add_child(control)
	var header := VBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 18;header.offset_top = 12;header.offset_right = -18
	control.add_child(header)
	title = Label.new()
	title.add_theme_color_override("font_color",Hud.PAPER)
	title.add_theme_constant_override("outline_size",5)
	title.add_theme_color_override("font_outline_color",Hud.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	# The selector already names the area; a second floating title covered the art.
	title.hide()
	var toolbar := HBoxContainer.new()
	header.add_child(toolbar)
	selector = OptionButton.new()
	selector.custom_minimum_size.y = 42
	selector.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Hud.secondary_button(selector)
	selector.fit_to_longest_item = false
	for area in index.areas: selector.add_item(area.name)
	selector.item_selected.connect(func(i: int): load_area(index.areas[i].id))
	toolbar.add_child(selector)
	var toggle := CheckButton.new()
	toggle.text = "Arte em revisão"
	toggle.button_pressed = art_preview
	art_toggle=toggle
	toggle.toggled.connect(func(value: bool): art_preview = value;load_area(area_id))
	toolbar.add_child(toggle)
	var footer := PanelContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 18;footer.offset_right = -18;footer.offset_top = -95;footer.offset_bottom = -12
	control.add_child(footer)
	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(hint)
	Hud.fit_footer(footer,hint,83)

func _refresh_positions() -> void:
	_place_actor(player_root,avatar,player,84)
	_place_actor(follower_root,companion,follower,42)
	for actor in npc_nodes:_place_actor(actor.root,actor.visual,actor.point,84)
	camera.position = model.project(player)
	_fade_occluders()

func _fade_occluders() -> void:
	# A house or tree drawn over Kael turns see-through, so composition can keep
	# some volume in front of the path without hiding the player.
	var body := Rect2(model.project(player)-Vector2(20,84),Vector2(40,84))
	var ground := model.project(player,false).y
	for node in occluders:
		if not is_instance_valid(node): continue
		var art := node.get_node_or_null("Art") as Sprite2D
		if art == null: continue
		if node.has_meta("piece"):
			var piece: Dictionary = node.get_meta("piece")
			if player.x>=float(piece.u)+float(piece.fu) or player.y>=float(piece.v)+float(piece.fv):
				art.modulate.a = 1.0
				continue
		# Bounds follow the sprite's own scale and flip (forest trees vary both).
		var bounds := art.get_transform() * art.get_rect()
		var covers := node.position.y > ground and Rect2(node.position+bounds.position,bounds.size).intersects(body)
		art.modulate.a = .45 if covers else 1.0

func _place_actor(root: Node2D, visual: Node2D, point: Vector2, height: float) -> void:
	var ground := model.project(point,false)
	var raised := model.project(point)
	var lower := -INF
	var upper := INF
	var body := Rect2(raised-Vector2(20,height),Vector2(40,height))
	# Large isometric props sort at their front footprint corner. A person can
	# stand in front of either visible wall before reaching that corner's Y.
	# Shift only the sort root; compensate its art so the feet never move.
	for node in piece_nodes.values():
		var p: Dictionary = node.get_meta("piece")
		var center := Vector2(p.u+p.fu*.5,p.v+p.fv*.5)
		if not is_equal_approx(model.height_at(point),model.height_at(center)):continue
		var art := node.get_node_or_null("Art") as Sprite2D
		if art==null or not Rect2(node.position+art.position,art.texture.get_size()).intersects(body):continue
		if point.x>=p.u+p.fu or point.y>=p.v+p.fv:lower=maxf(lower,node.position.y+.5)
		elif point.x<=p.u or point.y<=p.v:upper=minf(upper,node.position.y-.5)
	var depth := clampf(ground.y,lower,upper) if lower<=upper else ground.y
	root.position=Vector2(ground.x,depth)
	visual.position=Vector2(0,ground.y-depth-model.height_at(point)*64)

func message(text: String) -> void:
	notice = text
	notice_until = clock + 3

func walk_to(point: Vector2) -> bool:
	path = model.path_to(player,point)
	if not path.is_empty() and player.distance_to(path[0]) < .08: path.remove_at(0)
	return not path.is_empty()

func _physics_process(delta: float) -> void:
	clock += delta
	var old := player
	var input := Controls.direction()
	if input.length() > .2:
		# Screen direction converted to iso-lattice direction; one axis at a time
		# at corners, so keyboard input cannot cut a diagonal through blockers.
		path.clear()
		var lattice := Vector2(input.x+2*input.y,-input.x+2*input.y).normalized()
		var candidate := player + lattice * delta * 3.0
		if model.clear_segment(player,candidate): player = candidate
		else:
			for step in [Vector2(lattice.x,0),Vector2(0,lattice.y)]:
				candidate = player + step*delta*3.0
				if model.clear_segment(player,candidate): player = candidate
	elif not path.is_empty():
		var candidate := player.move_toward(path[0],delta*3.0)
		if model.clear_segment(player,candidate): player = candidate
		else: path.clear()
		if not path.is_empty() and player.distance_to(path[0]) < .01: path.remove_at(0)
	avatar.moving = player.distance_to(old) > .001
	if avatar.moving:
		var screen := model.project(player,false)-model.project(old,false)
		avatar.facing = "se" if screen.x >= 0 and screen.y >= 0 else "ne" if screen.x >= 0 else "sw" if screen.y >= 0 else "nw"
		var cell := model.cell_at(Vector2i(floori(player.x),floori(player.y)))
		if cell.material == "mato":
			grass_distance += player.distance_to(old)
			if grass_distance > 6:
				grass_distance = 0
				message("Mato: gatilho de encontro validado • prévia sem batalha ou recompensa")
	if bool(model.data.get("forest",{}).get("followTrail",false)):
		if avatar.moving:follower_trail.append(player)
		_follow_recorded_path(delta)
	elif follower.distance_to(player) > .8:
		var route := model.path_to(follower,player)
		if route.size() > 1:
			var target: Vector2 = route[1]
			# Aim ahead; return to the own-cell center only when the straight line is blocked.
			if not model.clear_segment(follower,target): target = route[0]
			var next := follower.move_toward(target,delta*3.2)
			if model.clear_segment(follower,next): follower = next
	_refresh_positions()
	nearby = {}
	for event in interaction_events:
		if event.type == "entrada": continue
		var target := Vector2(event.u+.5,event.v+.5)
		if player.distance_to(target) < 1.8:
			nearby = event
			break
	hint.text = notice if clock < notice_until else "E • " + nearby.name if not nearby.is_empty() else "WASD / setas • caminhar   Clique • ir até lá   Roda • zoom"

func _follow_recorded_path(delta: float) -> void:
	# On curved banks a freshly recomputed shortest path can switch sides of a
	# long obstacle. Keep the accepted player steps instead; never shortcut water.
	var distance := 0.0
	var previous := follower
	for point in follower_trail:
		distance += previous.distance_to(point)
		previous = point
	var budget := minf(delta*3.2,maxf(0,distance-.8))
	while budget>.00001 and not follower_trail.is_empty():
		var target: Vector2 = follower_trail[0]
		var next := follower.move_toward(target,budget)
		if not model.clear_segment(follower,next):break
		budget -= follower.distance_to(next)
		follower = next
		if follower.distance_to(target)<.00001:follower_trail.remove_at(0)
		else:break

func interact() -> void:
	if nearby.is_empty(): return
	interaction_requested.emit(nearby)
	if nearby.type == "piece" and nearby.get("asset", "") == "bau":
		var key := area_id+":"+str(nearby.piece_id)
		opened[key] = true
		var node: Node2D = piece_nodes.get(str(nearby.piece_id))
		if node != null and node.has_node("Art"):
			var entry: Dictionary = kits[0].pieces.bau.variants.aberto
			var sprite: Sprite2D = node.get_node("Art")
			sprite.texture = load(kits[0].root+entry.file)
			sprite.position = node.get_meta("center_offset",Vector2.ZERO)-Vector2(entry.anchor[0],entry.anchor[1])-Vector2(0,model.height_at(Vector2(nearby.u+.5,nearby.v+.5))*64)
		message("Baú aberto na prévia • sem conceder itens ou alterar saves")
		return
	if nearby.type == "saida":
		var destination := str(nearby.props.get("destino",""))
		if index.scenes.has(destination): load_area(index.scenes[destination], nearby.props.duplicate()); return
		message("Destino fora desta prévia: " + destination)
	else: message(nearby.name + " • " + str(nearby.props.get("texto",nearby.props.get("fala","Interação de revisão, sem alterar a campanha."))))

func _unhandled_input(event: InputEvent) -> void:
	Controls.observe(event)
	if Controls.pressed(event, "interact"): interact(); get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera.zoom = (camera.zoom*1.1).clamp(Vector2.ONE*.65,Vector2.ONE*2.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera.zoom = (camera.zoom/1.1).clamp(Vector2.ONE*.65,Vector2.ONE*2.5)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var mouse := get_global_mouse_position()
			# Search actual raised cell centers, not a flat inverse projection.
			var best := Vector2.ZERO
			var distance := 45.0
			for id in model.graph.get_point_ids():
				var point := model.graph.get_point_position(id)
				var gap := model.project(point).distance_to(mouse)
				if gap < distance: best = point; distance = gap
			if distance < 45: walk_to(best)
