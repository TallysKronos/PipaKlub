extends Node2D
signal interaction_requested(event: Dictionary)
var test_seconds: float=0.0
var event_flags: Dictionary={}
var used_events: Dictionary={}
const Terrain = preload("res://studio-generated/verification-1793991837046/terrain.gd")
const Trees = preload("res://studio-generated/verification-1793991837046/trees.gd")
const CollisionShapes=preload("res://studio-generated/verification-1793991837046/collision_shapes.gd")
const Waterfalls = preload("res://studio-generated/verification-1793991837046/waterfalls.gd")
var tree_textures: Dictionary={}
var catalog: Dictionary={}
var tree_brush: String="arvore-kronasta"
var edit_behind: bool = false
var support_level: int = 0
var height_brush: int = 0
var cliff_material: String = "earth"
var WALL_IDS: Array[String]=["earth","rock"]
var revision: int = 0

var IDS: Array[String] = ["capim-rabiola-a", "capim-rabiola-b", "arbusto-folha-pipa-a", "arbusto-folha-pipa-b", "bromelia-do-vento-a", "bromelia-do-vento-b", "pedra-da-margem", "junco-da-margem", "vitoria-regia"]
var FLOORS: Array[String] = ["grass", "dirt", "stone", "sand", "water"]
var save_path: String = "user://jardim-kronasta.json"
var runtime_only: bool=false
var layout: Dictionary = {}
var world: Node2D
var player: Sprite2D
var camera: Camera2D
var selected: Sprite2D
var dragging: bool = false
var offset: Vector2 = Vector2.ZERO
var mode: String = "select"
var brush: int = 0
var floor_brush: int = 1
var testing: bool = false
var grid: bool = false
var hint: Label
var textures: Dictionary = {}
var next_id: int = 1
var notice: String = ""

func _ready() -> void:
	var project_meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991837046/project-meta.json"))
	save_path="user://jardim-"+str(project_meta.id).sha256_text().substr(0,12)+".json"
	var wall_defs: Array=JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991837046/walls.json"))
	for definition: Dictionary in wall_defs:
		WALL_IDS.append(str(definition.id))
	var ground_defs: Array=JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991837046/grounds.json"))
	for definition: Dictionary in ground_defs:
		FLOORS.append(str(definition.id))
	var definitions: Array=JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991837046/catalog.json"))
	IDS.clear()
	for definition: Dictionary in definitions:
		var id: String=definition.id
		catalog[id]=definition
		textures[id]=load("res://studio-generated/verification-1793991837046/assets/%s.png" % id)
		if id!="kael":
			IDS.append(id)
		if Trees.is_tree(id):
			var atlas_id := "tree-atlas" if id=="arvore-kronasta" else "tree-atlas-"+id
			textures[atlas_id]=load("res://studio-generated/verification-1793991837046/assets/%s.png" % atlas_id)
	textures["waterfall-atlas"]=load("res://studio-generated/verification-1793991837046/assets/waterfall-atlas.png")
	textures["kael-walk"]=load("res://studio-generated/verification-1793991837046/assets/kael-walk.png")
	textures["kael-back"]=load("res://studio-generated/verification-1793991837046/assets/kael-back.png")
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	camera = Camera2D.new()
	add_child(camera)
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	ui.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 14)
	margin.add_child(hint)
	load_layout(save_path if FileAccess.file_exists(save_path) else "res://studio-generated/verification-1793991837046/layout.json")
	update_hint()

func load_layout(file: String) -> void:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not value is Dictionary:
		return
	layout = value
	for field: String in ["levels", "ramps", "cliffs"]:
		if not layout.has(field):
			layout[field] = []
			layout[field].resize(int(layout.width)*int(layout.height))
			layout[field].fill(0 if field=="levels" else ("earth" if field=="cliffs" else null))
	revision += 1
	selected = null
	dragging = false
	for node: Node in world.get_children():
		world.remove_child(node)
		node.queue_free()
	for item: Dictionary in layout.get("objects", []):
		var piece := add_piece(String(item["asset"]), Vector2(float(item["x"]), float(item["y"])), int(item["id"]), bool(item.get("flip", false)), bool(item.get("collidable",false)), String(item.get("layer","vegetation")))
		piece.set_meta("collision",item.get("collision",{"shape":"circle","radius":12}))
		piece.set_meta("decorative",item.get("decorative",false))
	var point: Dictionary = layout.get("player", {"x": 300, "y": 260})
	player = add_piece("kael", Vector2(float(point["x"]), float(point["y"])), -1)
	camera.position = Vector2(float(layout["width"]) * 16.0, float(layout["height"]) * 16.0)
	next_id = int(layout.get("nextId", 1))
	queue_redraw()

func tree_texture(point: Vector2,asset: String) -> Texture2D:
	var data := layout.duplicate()
	var trees: Array[Dictionary]=[]
	for entry: Node2D in world.get_children():
		if Trees.is_tree(str(entry.get_meta("asset",""))):
			trees.append({"asset":entry.get_meta("asset"),"x":entry.position.x,"y":entry.position.y})
	data["objects"]=trees
	var region := Trees.region(data,point,asset)
	var key := asset+str(region)
	if not tree_textures.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas=textures["tree-atlas" if asset=="arvore-kronasta" else "tree-atlas-"+asset]
		atlas.region=region
		tree_textures[key]=atlas
	return tree_textures[key]

func add_piece(asset: String, point: Vector2, id: int, flipped: bool = false, collidable: bool = false, layer: String = "vegetation") -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = textures[asset]
	node.centered = false
	node.offset = -Vector2(40, 65) if asset == "kael" else -Vector2(32, 52)
	node.position = point.round()
	node.flip_h = flipped
	node.set_meta("asset", asset)
	node.set_meta("collidable",collidable)
	node.set_meta("layer",layer)
	node.set_meta("id", id)
	world.add_child(node)
	refresh_piece(node)
	return node

func pick(point: Vector2) -> Sprite2D:
	var list: Array[Node] = world.get_children()
	list.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y > b.position.y)
	for entry: Node in list:
		var sprite := entry as Sprite2D
		var local: Vector2 = point - sprite.position - sprite.offset
		var size: Vector2 = sprite.texture.get_size()
		if local.x < 0 or local.y < 0 or local.x >= size.x or local.y >= size.y:
			continue
		var x: int = int(local.x)
		if sprite.flip_h:
			x = int(size.x) - 1 - x
		if sprite.texture.get_image().get_pixel(x, int(local.y)).a > 0.5:
			return sprite
	return null

func clamp_point(point: Vector2) -> Vector2:
	return Vector2(clampf(point.x, 0, float(layout["width"]) * 32), clampf(point.y, 0, float(layout["height"]) * 32))

func apply_tool(screen: Vector2) -> void:
	var point := Terrain.surface(layout,screen,support_level if edit_behind and mode not in ["height","ramp","face","select","erase"] else -1)
	if point.x < 0 or point.y < 0 or point.x >= float(layout["width"]) * 32 or point.y >= float(layout["height"]) * 32:
		return
	if mode in ["height","ramp","face"]:
		var i := Terrain.face_cell(layout,screen)
		if i<0:
			i=int(point.y/32)*int(layout.width)+int(point.x/32)
		if mode=="face":
			layout.cliffs[i]=cliff_material
		elif mode=="height":
			layout.levels[i]=height_brush
			layout.cliffs[i]=cliff_material
			layout.ramps[i]=null
			Terrain.clean(layout)
		elif Input.is_physical_key_pressed(KEY_SHIFT):
			layout.ramps[i]=null
		elif Terrain.valid_ramp(layout,i):
			layout.ramps[i]="n"
			layout.floors[i]="dirt"
			for j: int in [i-int(layout.width),i+int(layout.width)]:
				if layout.floors[j]=="grass":
					layout.floors[j]="dirt"
		else:
			notice="Rampa: patamar 1 nível acima ao norte e chão baixo ao sul."
		revision+=1
		update_hint()
	elif mode == "forest":
		var cx := int(floor(point.x/32))
		var cy := int(floor(point.y/32))
		var cell := cy*int(layout.width)+cx
		var existing: Sprite2D=null
		for entry: Node2D in world.get_children():
			if Trees.is_tree(str(entry.get_meta("asset",""))) and Trees.cell(layout,entry.position)==cell:
				existing=entry as Sprite2D
		if Input.is_physical_key_pressed(KEY_SHIFT):
			if existing!=null:
				world.remove_child(existing)
				existing.queue_free()
		elif existing==null and cell>=0 and cell<layout.floors.size() and layout.floors[cell]!="water" and layout.ramps[cell]==null:
			add_piece(tree_brush,Vector2(cx*32+16,cy*32+28),next_id,false,true)
			next_id+=1
		revision+=1
	elif mode == "plant":
		selected = add_piece(IDS[brush], point.snapped(Vector2(8, 8)), next_id,false,bool(catalog[IDS[brush]].get("collidable",false)))
		next_id += 1
	elif mode == "floor":
		var index: int = int(point.y / 32) * int(layout["width"]) + int(point.x / 32)
		layout["floors"][index] = FLOORS[floor_brush]
	elif mode == "erase":
		erase_at(screen)
	else:
		selected = pick(screen)
		dragging = selected != null
		if dragging:
			offset = screen - Terrain.project(layout,selected.position)
	queue_redraw()

func erase_at(point: Vector2) -> void:
	var node: Sprite2D = pick(point)
	if node != null and node != player:
		if selected == node:
			selected = null
		world.remove_child(node)
		node.queue_free()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode
		if runtime_only and key!=KEY_E:
			return
		if testing and key==KEY_E:
			for definition: Dictionary in layout.get("events",[]):
				if player.position.distance_to(event_position(definition))>40 or (definition.get("condition","")!="" and not event_flags.get(definition.condition,false)) or (definition.get("once",false) and used_events.has(definition.id)):
					continue
				interaction_requested.emit(definition)
				notice=definition.get("text",definition.get("label","Evento"))
				if definition.get("setsFlag","")!="":
					event_flags[definition.setsFlag]=true
				if definition.get("once",false):
					used_events[definition.id]=true
				if definition.type=="exit":
					for target: Dictionary in layout.get("events",[]):
						if target.id==definition.get("targetEvent",""):
							player.position=Vector2(target.x,target.y)
				update_hint()
				return
		elif key==KEY_N:
			brush=(brush+1)%IDS.size()
			mode="forest" if Trees.is_tree(IDS[brush]) else "plant"
			if mode=="forest":
				tree_brush=IDS[brush]
			update_hint()
		elif key==KEY_K:
			mode="forest"
			tree_brush=IDS[brush] if Trees.is_tree(IDS[brush]) else "arvore-kronasta"
			update_hint()
		elif key >= KEY_1 and key <= KEY_9:
			brush = key - KEY_1
			mode = "plant"
			testing = false
		elif key == KEY_V:
			mode = "select"
		elif key == KEY_E:
			mode = "erase"
		elif key == KEY_P:
			mode = "floor"
			floor_brush = (floor_brush + 1) % 3
		elif key == KEY_O:
			edit_behind=not edit_behind
			revision+=1
		elif key == KEY_BRACKETLEFT:
			support_level=maxi(0,support_level-1)
		elif key == KEY_BRACKETRIGHT:
			support_level=mini(12,support_level+1)
		elif key == KEY_H:
			mode="height"
			height_brush=height_brush%12+1
		elif key == KEY_L:
			mode="height"
			height_brush=0
		elif key == KEY_J:
			mode="face"
		elif key == KEY_U:
			mode="ramp"
		elif key == KEY_T:
			cliff_material=WALL_IDS[(WALL_IDS.find(cliff_material)+1)%WALL_IDS.size()]
		elif key == KEY_G:
			grid = not grid
		elif key == KEY_TAB:
			testing = not testing
			dragging = false
		elif key == KEY_DELETE and is_instance_valid(selected) and selected != player:
			world.remove_child(selected)
			selected.queue_free()
			selected = null
		elif key == KEY_F and is_instance_valid(selected):
			selected.flip_h = not selected.flip_h
		elif key == KEY_R:
			load_layout("res://studio-generated/verification-1793991837046/layout.json")
		elif key == KEY_F5:
			save_layout()
		update_hint()
		queue_redraw()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera.zoom = Vector2.ONE * minf(4.0, camera.zoom.x + 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera.zoom = Vector2.ONE * maxf(1.0, camera.zoom.x - 1.0)
		elif not testing and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				apply_tool(get_global_mouse_position())
			else:
				dragging = false
		elif not testing and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			erase_at(get_global_mouse_position())
	if event is InputEventMouseMotion and not testing:
		if dragging and is_instance_valid(selected):
			var destination := Terrain.surface(layout,get_global_mouse_position()-offset,support_level if edit_behind else -1)
			if destination.is_finite():
				selected.position = clamp_point(destination).snapped(Vector2(8,8))
		elif mode in ["floor","height","forest","face"] and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			apply_tool(get_global_mouse_position())
		queue_redraw()

func _process(delta: float) -> void:
	if testing:
		test_seconds+=delta
	if layout.get("floors",[]).has("water"):
		queue_redraw()
	if testing and is_instance_valid(player):
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		player.set_meta("walking",direction!=Vector2.ZERO)
		if direction!=Vector2.ZERO:
			player.set_meta("back",direction.y<0)
		var speed: float = 125.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 70.0
		if direction != Vector2.ZERO:
			var destination := Terrain.move(layout,player.position,direction.normalized()*speed*delta)
			var blocked := false
			for entry: Node2D in world.get_children():
				if entry==player or not entry.get_meta("collidable",false):
					continue
				if absf(Terrain.height_at(layout,entry.position)-Terrain.height_at(layout,destination))<0.35 and CollisionShapes.distance(destination-entry.position,entry.get_meta("collision",{}))<0 and CollisionShapes.distance(destination-entry.position,entry.get_meta("collision",{}))<CollisionShapes.distance(player.position-entry.position,entry.get_meta("collision",{})):
					blocked=true
			if not blocked:
				player.position=destination
			if direction.x != 0:
				player.flip_h = direction.x > 0
		queue_redraw()

	for entry: Node in world.get_children():
		refresh_piece(entry as Sprite2D)

func save_layout() -> void:
	var objects: Array[Dictionary] = []
	for entry: Node in world.get_children():
		var node := entry as Sprite2D
		if node == player:
			continue
		objects.append({"id": node.get_meta("id"), "asset": node.get_meta("asset"), "x": roundi(node.position.x), "y": roundi(node.position.y), "flip": node.flip_h, "collidable": node.get_meta("collidable",false), "layer": node.get_meta("layer","vegetation"),"collision":node.get_meta("collision",{"shape":"circle","radius":12}),"decorative":node.get_meta("decorative",false)})
	layout["objects"] = objects
	layout["player"] = {"x": roundi(player.position.x), "y": roundi(player.position.y)}
	layout["nextId"] = next_id
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(layout, "  "))
		notice = "Salvo em " + ProjectSettings.globalize_path(save_path)
	else:
		notice = "Não foi possível salvar a cópia local."

func update_hint() -> void:
	hint.text = "JARDIM DE KRONASTA · " + ("TESTE VISUAL" if testing else "EDIÇÃO")
	hint.text += "\nN próxima peça · K floresta (Shift apaga) · 1–9 peças · V mover · E apagar · P alternar piso · G grade"
	hint.text += "\nTab testar/editar · WASD/setas andar · Shift correr · roda zoom"
	hint.text += "\nDel excluir · F espelhar · F5 salvar cópia local · R restaurar exportação"
	hint.text += "\nFerramenta: " + (IDS[brush] if mode == "plant" else mode)
	hint.text += " · piso: " + FLOORS[floor_brush] + "\nBarrancos bloqueiam; rampas dão acesso. E interage em teste; caminhada animada."
	hint.text += "\nH altura 1–12 · L chão 0 · U rampa · Shift remover rampa · J revestir face · T trocar revestimento"
	hint.text += " · cota: %s · face: %s" % [height_brush,cliff_material]
	hint.text += "\nO revelar atrás · [ / ] cota de apoio: %s · %s" % [support_level,"REVELADO" if edit_behind and not testing else "NORMAL"]
	if not notice.is_empty():
		hint.text += "\n" + notice

func event_position(e: Dictionary) -> Vector2:
	var origin := Vector2(float(e.x),float(e.y))
	if e.type!="npc" or e.get("route",[]).is_empty():
		return origin
	var points: Array[Vector2]=[origin]
	for p: Dictionary in e.route:
		points.append(Vector2(float(p.x),float(p.y)))
	points.append(origin)
	var length: float=0.0
	for i: int in range(points.size()-1):
		length+=points[i].distance_to(points[i+1])
	if length==0:
		return origin
	var distance: float=fmod(test_seconds*24.0,length)
	for i: int in range(points.size()-1):
		var segment: float=points[i].distance_to(points[i+1])
		if segment>0 and distance<=segment:
			return points[i].lerp(points[i+1],distance/segment)
		distance-=segment
	return origin

func _draw() -> void:
	if layout.is_empty():
		return
	var terrain := Terrain.Autotile.plan(layout)
	draw_texture(terrain.top,Vector2(0,-Terrain.Autotile.PAD))
	draw_texture(terrain.faces,Vector2(0,-Terrain.Autotile.PAD))
	draw_texture(terrain.shadow,Vector2(0,-Terrain.Autotile.PAD))
	var phase := int(Time.get_ticks_msec()/240)%4
	var water_color: Color=[Color("71c8c0"),Color("8bd2c7"),Color("64b7b5"),Color("96dad0")][phase]
	for point: Vector2 in Terrain.Autotile.ripple_points(layout,phase):
		var projected := Terrain.project(layout,point)
		var pixel := (int(floor(projected.y))+Terrain.Autotile.PAD)*int(terrain.width)+int(point.x)
		if pixel>=0 and pixel<terrain.kinds.size() and not terrain.kinds[pixel] and absf(float(terrain.depth[pixel])-point.y)<2:
			draw_rect(Rect2(projected.floor(),Vector2.ONE),water_color)
	for e: Dictionary in layout.get("events",[]):
		if testing and e.get("once",false) and used_events.has(e.id):
			continue
		draw_circle(Terrain.project(layout,event_position(e)),5,Color("e9bc68"))
	if grid and not testing:
		for i: int in range(layout.floors.size()):
			draw_rect(Terrain.top(layout,i),Color(0.1,0.2,0.15,0.3),false,1)
	for node: Node2D in world.get_children():
		var root := Terrain.project(layout,node.position)
		var hidden_root := false
		for r: Rect2 in Terrain.occluders(layout,node.position,str(node.get_meta("asset",""))):
			if r.has_point(root):
				hidden_root=true
		if not hidden_root:
			draw_rect(Rect2(root+Vector2(-8,-1),Vector2(16,3)),Color(0.1,0.2,0.12,0.2))
	if not testing and is_instance_valid(selected):
		draw_rect(Rect2(Terrain.project(layout,selected.position)-Vector2(2,2),Vector2(4,4)),Color("f5cf75"))

func draw_floor(i: int, r: Rect2) -> void:
	var kind: String = layout.floors[i]
	var color := Color("8fa65b" if kind=="grass" else ("c3a16e" if kind=="dirt" else "9eafa4"))
	draw_rect(r,terrain_color(color))
	for k: int in range(5):
		var dx := posmod(i*17+k*11,27)+2
		var dy := posmod(i*5+k*7,27)+2
		draw_rect(Rect2(r.position+Vector2(dx,floor(dy*r.size.y/32)),Vector2(2,1)),terrain_color(color.darkened(0.1)))
	if layout.ramps[i]!=null:
		for y: int in range(6,int(r.size.y),8):
			draw_rect(Rect2(r.position+Vector2(4,y),Vector2(24,1)),terrain_color(Color("b28e5d")))
	if grid and not testing:
		draw_rect(r,Color(0.1,0.2,0.15,0.25),false,1)

func refresh_piece(node: Sprite2D) -> void:
	var asset: String = node.get_meta("asset")
	if Waterfalls.WIDTHS.has(asset):
		var key := str(node.position)+"/"+str(revision)+"/"+str(int(Time.get_ticks_msec()/120)%4)
		if node.get_meta("waterfall_signature","")==key:
			return
		node.set_meta("waterfall_signature",key)
		var result := Waterfalls.render(layout,node.position,asset,textures["waterfall-atlas"].get_image(),int(Time.get_ticks_msec()/120)%4)
		node.visible=not result.is_empty()
		if not result.is_empty():
			node.texture=ImageTexture.create_from_image(result.image)
			node.offset=Vector2(result.x,result.y)-node.position
		return
	if node==player and testing:
		asset="kael-walk" if node.get_meta("walking",false) else ("kael-back" if node.get_meta("back",false) else "kael")
	var anchor := Vector2(40,65) if asset.begins_with("kael") else (Vector2(32,80) if Trees.is_tree(asset) else Vector2(32,52))
	node.offset=-anchor-Vector2(0,Terrain.height_at(layout,node.position)*16)
	if catalog.has(asset) and catalog[asset].get("custom",false):
		anchor=Vector2(catalog[asset].anchor[0],catalog[asset].anchor[1])
		node.offset=-anchor-Vector2(0,Terrain.height_at(layout,node.position)*16)
	var signature := "%s/%s/%s/%s/%s" % [asset,node.position.floor(),node.flip_h,str(revision)+str(edit_behind and not testing),layout.get("floors",[]).hash()]
	if catalog.has(asset) and catalog[asset].get("custom",false):
		signature+=str(int(Time.get_ticks_msec()*float(catalog[asset].fps)/1000)%int(catalog[asset].frames))
	if asset=="kael-walk":
		signature+=str(int(Time.get_ticks_msec()/130)%4)+str(node.get_meta("back",false))
	if Trees.is_tree(asset):
		signature+=str(tree_texture(node.position,asset).get_rid())
	if node.get_meta("terrain_signature","")==signature:
		return
	node.set_meta("terrain_signature",signature)
	var original: Texture2D = tree_texture(node.position,asset) if Trees.is_tree(asset) else textures[asset]
	if asset=="kael-walk":
		var atlas := AtlasTexture.new()
		atlas.atlas=textures["kael-walk"]
		atlas.region=Rect2(int(Time.get_ticks_msec()/130)%4*80,80 if node.get_meta("back",false) else 0,80,80)
		original=atlas
	if catalog.has(asset) and catalog[asset].get("custom",false):
		var definition: Dictionary=catalog[asset]
		var frame := int(Time.get_ticks_msec()*float(definition.fps)/1000)%int(definition.frames)
		var cols := int(definition.width)/int(definition.frameWidth)
		var atlas := AtlasTexture.new()
		atlas.atlas=textures[asset]
		atlas.region=Rect2(frame%cols*int(definition.frameWidth),int(frame/cols)*int(definition.frameHeight),definition.frameWidth,definition.frameHeight)
		original=atlas
	var image: Image
	var origin := Terrain.project(layout,node.position)-anchor
	var bounds := Rect2(origin,original.get_size())
	if edit_behind and not testing:
		node.texture=original
		return
	for r: Rect2 in Terrain.occluders(layout,node.position,str(node.get_meta("asset",""))):
		if not bounds.intersects(r):
			continue
		if image==null:
			image=original.get_image()
		var cut := r.intersection(bounds)
		var local := Rect2i((cut.position-origin).floor(),cut.size.ceil())
		if node.flip_h:
			local.position.x=image.get_width()-local.end.x
		image.fill_rect(local,Color.TRANSPARENT)
	node.texture=ImageTexture.create_from_image(image) if image!=null else original

func terrain_color(color: Color) -> Color:
	if edit_behind and not testing:
		color.a=0.22
	return color
