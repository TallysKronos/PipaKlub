extends Node2D
const Terrain = preload("res://terrain.gd")
var edit_behind: bool = false
var support_level: int = 0
var height_brush: int = 0
var cliff_material: String = "earth"
var revision: int = 0

const IDS: Array[String] = ["capim-rabiola-a", "capim-rabiola-b", "arbusto-folha-pipa-a", "arbusto-folha-pipa-b", "bromelia-do-vento-a", "bromelia-do-vento-b"]
const FLOORS: Array[String] = ["grass", "dirt", "stone"]
const SAVE_PATH: String = "user://jardim-kronasta.json"
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
	for id: String in IDS + ["kael", "kael-back"]:
		textures[id] = load("res://assets/%s.png" % id)
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
	load_layout(SAVE_PATH if FileAccess.file_exists(SAVE_PATH) else "res://layout.json")
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
		add_piece(String(item["asset"]), Vector2(float(item["x"]), float(item["y"])), int(item["id"]), bool(item.get("flip", false)))
	var point: Dictionary = layout.get("player", {"x": 300, "y": 260})
	player = add_piece("kael", Vector2(float(point["x"]), float(point["y"])), -1)
	camera.position = Vector2(float(layout["width"]) * 16.0, float(layout["height"]) * 16.0)
	next_id = int(layout.get("nextId", 1))
	queue_redraw()

func add_piece(asset: String, point: Vector2, id: int, flipped: bool = false) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = textures[asset]
	node.centered = false
	node.offset = -Vector2(40, 65) if asset == "kael" else -Vector2(32, 52)
	node.position = point.round()
	node.flip_h = flipped
	node.set_meta("asset", asset)
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
	var point := Terrain.surface(layout,screen,support_level if edit_behind and mode not in ["height","ramp","select","erase"] else -1)
	if point.x < 0 or point.y < 0 or point.x >= float(layout["width"]) * 32 or point.y >= float(layout["height"]) * 32:
		return
	if mode == "height" or mode == "ramp":
		var i := int(point.y/32)*int(layout.width)+int(point.x/32)
		if mode=="height":
			layout.levels[i]=height_brush
			layout.cliffs[i]=cliff_material
			layout.ramps[i]=null
			Terrain.clean(layout)
		elif Input.is_physical_key_pressed(KEY_SHIFT):
			layout.ramps[i]=null
		elif Terrain.valid_ramp(layout,i):
			layout.ramps[i]="n"
			layout.floors[i]="dirt"
		else:
			notice="Rampa: patamar 1 nível acima ao norte e chão baixo ao sul."
		revision+=1
		update_hint()
	elif mode == "plant":
		selected = add_piece(IDS[brush], point.snapped(Vector2(8, 8)), next_id)
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
		if key >= KEY_1 and key <= KEY_6:
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
		elif key == KEY_U:
			mode="ramp"
		elif key == KEY_T:
			cliff_material="rock" if cliff_material=="earth" else "earth"
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
			load_layout("res://layout.json")
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
		elif mode in ["floor","height"] and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			apply_tool(get_global_mouse_position())
		queue_redraw()

func _process(delta: float) -> void:
	if testing and is_instance_valid(player):
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		var speed: float = 125.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 70.0
		if direction != Vector2.ZERO:
			player.position = Terrain.move(layout,player.position,direction.normalized()*speed*delta)
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
		objects.append({"id": node.get_meta("id"), "asset": node.get_meta("asset"), "x": roundi(node.position.x), "y": roundi(node.position.y), "flip": node.flip_h})
	layout["objects"] = objects
	layout["player"] = {"x": roundi(player.position.x), "y": roundi(player.position.y)}
	layout["nextId"] = next_id
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(layout, "  "))
		notice = "Salvo em " + ProjectSettings.globalize_path(SAVE_PATH)
	else:
		notice = "Não foi possível salvar a cópia local."

func update_hint() -> void:
	hint.text = "JARDIM DE KRONASTA · " + ("TESTE VISUAL" if testing else "EDIÇÃO")
	hint.text += "\n1–6 plantas · V mover · E apagar · P alternar piso · G grade"
	hint.text += "\nTab testar/editar · WASD/setas andar · Shift correr · roda zoom"
	hint.text += "\nDel excluir · F espelhar · F5 salvar cópia local · R restaurar exportação"
	hint.text += "\nFerramenta: " + (IDS[brush] if mode == "plant" else mode)
	hint.text += " · piso: " + FLOORS[floor_brush] + "\nBarrancos bloqueiam; rampas dão acesso. Plantas sem colisão; pose estática."
	hint.text += "\nH altura 1–12 · L chão 0 · U rampa · Shift remover rampa · T terra/rocha"
	hint.text += " · cota: %s · face: %s" % [height_brush,cliff_material]
	hint.text += "\nO revelar atrás · [ / ] cota de apoio: %s · %s" % [support_level,"REVELADO" if edit_behind and not testing else "NORMAL"]
	if not notice.is_empty():
		hint.text += "\n" + notice

func _draw() -> void:
	if layout.is_empty():
		return
	for i: int in range(layout.floors.size()):
		draw_floor(i,Rect2(i%int(layout.width)*32,int(i/int(layout.width))*32,32,32))
	for i: int in range(layout.floors.size()):
		var r := Terrain.top(layout,i)
		draw_floor(i,r)
		var face := Terrain.face(layout,i)
		if face.has_area():
			var rock: bool = layout.cliffs[i]=="rock"
			draw_rect(face,terrain_color(Color("747c75" if rock else "8e6245")))
			for yy: int in range(int(face.position.y)+3,int(face.end.y)-1,7):
				draw_rect(Rect2(face.position.x,yy,32,1),terrain_color(Color("626e68" if rock else "765038")))
			var grass: bool = layout.floors[i]=="grass"
			draw_rect(Rect2(face.position,Vector2(32,2)),terrain_color(Color("536e39" if grass else "d4b37c")))
			if grass:
				for x: int in range(0,32,4):
					draw_rect(Rect2(face.position+Vector2(x,0),Vector2(3,3+x%2)),terrain_color(Color("93ad5e")))
			draw_rect(Rect2(face.position.x,face.end.y-1,32,1),terrain_color(Color("553f2e")))
	for node: Node2D in world.get_children():
		var root := Terrain.project(layout,node.position)
		var hidden_root := false
		for r: Rect2 in Terrain.occluders(layout,node.position):
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
	if node==player and testing:
		asset="kael-back" if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) else "kael"
	var anchor := Vector2(40,65) if asset.begins_with("kael") else Vector2(32,52)
	node.offset=-anchor-Vector2(0,Terrain.height_at(layout,node.position)*16)
	var signature := "%s/%s/%s/%s/%s" % [asset,node.position.floor(),node.flip_h,str(revision)+str(edit_behind and not testing),layout.get("floors",[]).hash()]
	if node.get_meta("terrain_signature","")==signature:
		return
	node.set_meta("terrain_signature",signature)
	var original: Texture2D = textures[asset]
	var image: Image
	var origin := Terrain.project(layout,node.position)-anchor
	var bounds := Rect2(origin,original.get_size())
	if edit_behind and not testing:
		node.texture=original
		return
	for r: Rect2 in Terrain.occluders(layout,node.position):
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
