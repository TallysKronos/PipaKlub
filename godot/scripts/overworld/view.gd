extends Node2D
## Review scene. No campaign save or rules are changed until area art is approved.
const Model = preload("res://scripts/overworld/map_model.gd")
const Prop = preload("res://scripts/overworld/prop.gd")
const Avatar = preload("res://scripts/avatar.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal interaction_requested(event: Dictionary)
var model := Model.new()
var area_id := "veredas-piloto"
var art_preview := false
var player := Vector2.ZERO
var follower := Vector2.ZERO
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
	for biome in ["comum", "bairro", "parque", "veredas", "morro"]:
		var file: String = "res://assets/overworld/kits/" + biome + "/kit.json"
		if not FileAccess.file_exists(file): continue
		var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
		kit.root = "res://assets/overworld/kits/" + biome + "/"
		kit_library[biome] = kit
	_build_hud()
	load_area(area_id)

func load_area(id: String) -> void:
	var source := "res://assets/overworld/maps/" + id + ".json"
	if not FileAccess.file_exists(source): return
	area_id = id
	for node in [terrain, camera]:
		if is_instance_valid(node): remove_child(node); node.queue_free()
	terrain_layers.clear()
	stairs_drawn.clear()
	model.setup(JSON.parse_string(FileAccess.get_file_as_string(source)))
	kits.assign([kit_library.comum])
	if kit_library.has(model.data.biome): kits.append(kit_library[model.data.biome])
	path.clear()
	nearby.clear()
	piece_nodes.clear()
	npc_nodes.clear()
	interaction_events = model.data.events.duplicate(true)
	terrain = Node2D.new()
	terrain.y_sort_enabled = true
	add_child(terrain)
	actors = terrain
	_build_context()
	_build_tiles()
	_build_faces()
	_build_pieces()
	_dress_bare_lots()
	_build_events()
	var spawn: Dictionary = model.data.spawn
	player = Vector2(spawn.u + .5, spawn.v + .5)
	follower = player
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
	camera.zoom = Vector2.ONE * 1.4
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
	context.name="ContextoNaoJogavel";context.z_index=-100;context.y_sort_enabled=true
	actors.add_child(context)
	var floor_plane := Polygon2D.new()
	floor_plane.z_index=-1
	floor_plane.color=Color(str(recipe.get("color","476643")))
	floor_plane.polygon=PackedVector2Array([model.project(Vector2(-radius,-radius),false),model.project(Vector2(model.data.w+radius,-radius),false),model.project(Vector2(model.data.w+radius,model.data.h+radius),false),model.project(Vector2(-radius,model.data.h+radius),false)])
	context.add_child(floor_plane)
	if recipe.is_empty() or not art_preview:return
	var spacing := int(recipe.get("spacing",3))
	for v in range(-radius,int(model.data.h)+radius,spacing):
		for u in range(-radius,int(model.data.w)+radius,spacing):
			if not (u+3<=0 or v+3<=0 or u>=int(model.data.w) or v>=int(model.data.h)):continue
			var seed := posmod(u*137+v*71+u*v*13,23)
			if seed<5:continue
			# Jitter inside the lattice so the ring reads as a neighbourhood, not a grid.
			var shift := Vector2(seed%3-1, (seed/3)%3-1)
			if not (u+3+shift.x<=0 or v+3+shift.y<=0 or u+shift.x>=int(model.data.w) or v+shift.y>=int(model.data.h)): shift = Vector2.ZERO
			var garden: bool = u>=int(model.data.w) or v>=int(model.data.h) or seed%4==0
			var piece := {"asset":"arvore" if garden else recipe.asset,"id":"context","props":{"variante":["a","b","florida","tronco-largo"][seed%4] if garden else ["telha","laje","muro-chapisco"][(seed/2)%3]}}
			var info := _definition(piece)
			if info.is_empty():continue
			var node := Prop.new()
			var center:=Vector2(u+1.5,v+1.5)+shift
			var sort_point:=Vector2(u+3,v+3)+shift
			node.configure(info,Vector2i(3,3),0,false,model.project(center,false)-model.project(sort_point,false))
			node.position=model.project(sort_point,false)
			context.add_child(node)

func _build_tiles() -> void:
	var texture: Texture2D = load("res://assets/overworld/rascunho-atlas.png")
	var ids: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/rascunho-atlas.json"))
	var levels: Dictionary = {}
	for cell in model.data.cells: levels[int(cell.level)] = true
	lots = _occupied_lots()
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
			elif art_preview and kits.size()>1 and cell.material == "construcao" and kits[1].materials.has("grama") and lots.get(model.key(at), "muro-quintal") == "muro-quintal":
				# A blocked lot without a house reads as a yard, not as bare brick.
				_draw_art_floor(at, {"material":"grama","level":cell.level,"corners":["grama","grama","grama","grama"]})
			elif art_preview and kits.size()>1 and kits[1].materials.has(cell.material):
				_draw_art_floor(at, cell)
			else: layer.set_cell(at, 0, Vector2i((at.x * 7 + at.y * 13) % 4, int(ids.get(cell.material, 0))))

func _draw_bridge(at: Vector2i, cell: Dictionary) -> void:
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
	node.position = model.project(Vector2(at) + Vector2(.5, .5), false)
	actors.add_child(node)
	return node

func _draw_art_floor(at: Vector2i, cell: Dictionary) -> void:
	var kit: Dictionary = kits[1]
	var file := ""
	if kit.materials.has(cell.material): file = kit.materials[cell.material].variants[(at.x*7+at.y*13)%4]
	if file.is_empty(): return
	var root := _floor_node(at, float(cell.level))
	var sprite := Sprite2D.new()
	sprite.texture = load(kit.root + file)
	sprite.position.y = -float(cell.level) * 64
	root.add_child(sprite)
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
			if material not in parts:continue
			var mask := (1<<bit) if parts[1]==material else 15^(1<<bit)
			var patch := Polygon2D.new()
			var uv: PackedVector2Array = wedges[bit]
			var poly := PackedVector2Array()
			for point in uv:poly.append(point-Vector2(32,16+float(cell.level)*64))
			patch.polygon=poly;patch.uv=uv
			patch.texture=load(kit.root+kit.transitions[pair].files[mask])
			root.add_child(patch)
			break

func _draw_ramp(at: Vector2i, cell: Dictionary) -> void:
	var root := _floor_node(at, float(cell.level))
	var quad := PackedVector2Array()
	for offset in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
		# Sample inside the ramp cell, so its end interpolates to the adjacent floor.
		var p: Vector2 = Vector2(at) + offset.clamp(Vector2.ONE*.00001, Vector2.ONE*.99999)
		quad.append(model.project(p) - root.position)
	var ramp := Polygon2D.new()
	ramp.polygon = quad
	ramp.color = Color("DAD7C5") if model.data.biome == "morro" else Color("C7A16D")
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
	for face in model.data.cliffs:
		var a := Vector2(face.u + 1, face.v) if face.side == "u" else Vector2(face.u, face.v + 1)
		var b := Vector2(face.u + 1, face.v + 1)
		var root := Node2D.new()
		root.position = model.project(b, false)
		actors.add_child(root)
		var pa := model.project(a,false) - root.position
		var pb := model.project(b,false) - root.position
		for tier in range(int(face.bottom),int(face.top)):
			var wall := Polygon2D.new()
			wall.polygon = PackedVector2Array([pa-Vector2(0,(tier+1)*64),pb-Vector2(0,(tier+1)*64),pb-Vector2(0,tier*64),pa-Vector2(0,tier*64)])
			wall.color = Color("B8A58D") if face.side == "u" else Color("8F7C6E")
			if art_preview and kits.size()>1 and kits[1].walls.has("pedra"):
				var style := "pedra" if _face_touches_path(face) or not kits[1].walls.has("chapisco") else "chapisco"
				wall.texture = load(kits[1].root + kits[1].walls[style][face.side][(int(face.u)+int(face.v))%2])
				wall.uv = PackedVector2Array([Vector2(32,0),Vector2(0,16),Vector2(0,80),Vector2(32,64)]) if face.side == "u" else PackedVector2Array([Vector2(0,0),Vector2(32,16),Vector2(32,80),Vector2(0,64)])
				wall.color = Color.WHITE
			root.add_child(wall)
		var rim := Line2D.new()
		rim.points = PackedVector2Array([pa-Vector2(0,face.top*64),pb-Vector2(0,face.top*64)])
		rim.width = 2
		rim.default_color = Color("D5C9AD")
		root.add_child(rim)

func _face_touches_path(face: Dictionary) -> bool:
	var upper := Vector2i(int(face.u), int(face.v))
	var lower := upper + (Vector2i(1,0) if face.side == "u" else Vector2i(0,1))
	return model.walkable(upper) or model.walkable(lower)

func _occupied_lots() -> Dictionary:
	# Cells under a piece footprint, by asset. Bare lots and low yard walls stand on grass.
	var taken := {}
	for piece in model.data.pieces:
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
	var large := [["varal",""],["arvore","a"],["caixa-dagua",""],["arvore","florida"],["arvore","b"]]
	var small := [["vaso","pneu"],["flores","coral"],["vaso","ceramica"],["flores","amarela"]]
	for v in int(model.data.h):
		for u in int(model.data.w):
			var seed := posmod(u*131+v*57+int(model.data.w)*7,97)
			var pick: Array = []
			var n := 1
			if seed%3 != 0 and fits.call(u,v,2):
				pick = large[seed%large.size()]
				n = 2
			elif seed%5 == 0 and fits.call(u,v,1): pick = small[seed%small.size()]
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

func _definition(piece: Dictionary) -> Dictionary:
	var variant := str(piece.props.get("variante", ""))
	if piece.asset == "bau" and opened.has(area_id+":"+str(piece.id)): variant = "aberto"
	if variant.is_empty() and piece.asset == "banco": variant = "concreto" if model.data.biome == "morro" else "madeira"
	if variant.is_empty() and piece.asset == "placa-mapa": variant = "veredas" if model.data.biome == "veredas" else "parque"
	for kit in kits:
		if not kit.pieces.has(piece.asset): continue
		var group: Dictionary = kit.pieces[piece.asset]
		var entry: Dictionary = group.variants.get(variant, group.variants[group.default]).duplicate(true)
		entry.texture = kit.root + entry.file
		entry.shadow_texture = kit.root + entry.shadow
		return entry
	return {}

func _build_pieces() -> void:
	for piece in model.data.pieces:
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
		actors.add_child(node)
		piece_nodes[str(piece.id)] = node
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
	if follower.distance_to(player) > .8:
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
		if index.scenes.has(destination): load_area(index.scenes[destination]); return
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
