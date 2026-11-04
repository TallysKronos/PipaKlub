extends Node2D
const Recorte = preload("res://scripts/campaign/recorte_theme.gd")
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Region = preload("res://scripts/region.gd")
const Avatar = preload("res://scripts/avatar.gd")
@export var reference_yard: bool = false
@export_range(1.0,2.0) var camera_scale: float = 1.4
var nina_point := Vector2(1536,992)
var save_path := "user://veredas-prototype-v1.json"
var region: Node2D
var actors: Node2D
var avatar: Node2D
var companion: Sprite2D
var camera: Camera2D
var player := Vector2(224,816)
var follower := Vector2(160,816)
var path := PackedVector2Array()
var history: Array[Vector2] = []
var opened: Array = []
var chests: Dictionary = {}
var status: Label
var hint: Label
var dialog: PanelContainer
var dialog_text: Label
var dialogue_open := false
var interacted_nina := false
var nearest := ""
var companion_frames: Array = []
var animation_time := 0.0

func _ready() -> void:
	if "--smoke" in OS.get_cmdline_user_args():
		save_path="user://veredas-smoke-only.json"
	region = Region.new()
	if reference_yard:
		region.layout_path="res://assets/scale-yard.json"
		save_path="user://scale-yard-smoke-only.json" if "--smoke" in OS.get_cmdline_user_args() else "user://scale-yard-v1.json"
		player=Vector2(256,480)
		follower=Vector2(216,480)
		nina_point=Vector2(512,480)
	add_child(region)
	actors=Node2D.new()
	actors.y_sort_enabled=true
	add_child(actors)
	avatar=Avatar.new()
	actors.add_child(avatar)
	companion=Sprite2D.new()
	companion.texture=preload("res://assets/rabbito.png")
	companion.region_enabled=true
	companion.offset=Vector2(0,-100)
	companion.scale=Vector2(.3,.3)
	actors.add_child(companion)
	var atlas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rabbito.json"))
	for name in atlas.animations.idle:
		var f: Dictionary=atlas.frames[name].frame
		companion_frames.append(Rect2(f.x,f.y,f.w,f.h))
	for solid in region.data.solids:
		var p:=Vector2(solid.x+solid.w/2,solid.y+solid.h)
		var tree:=Node2D.new()
		tree.position=region.project(p)
		actors.add_child(tree)
		var trunk:=Sprite2D.new()
		trunk.texture=preload("res://assets/trunk.png")
		trunk.scale=Vector2(.30,.30)
		trunk.position=Vector2(0,-39)
		tree.add_child(trunk)
		var canopy:=Sprite2D.new()
		canopy.texture=preload("res://assets/canopy.png")
		canopy.scale=Vector2(.42,.42)
		canopy.position=Vector2(0,-112)
		tree.add_child(canopy)
	for chest in region.data.chests:
		var sprite:=Sprite2D.new()
		sprite.texture=preload("res://assets/chest.png")
		sprite.scale=Vector2(.24,.24)
		sprite.offset=Vector2(0,-115)
		sprite.position=region.project(Vector2(chest.x,chest.y))
		actors.add_child(sprite)
		chests[chest.id]=sprite
	var nina:=Sprite2D.new()
	nina.texture=preload("res://assets/nina.png")
	nina.scale=Vector2(.06,.06)
	nina.offset=Vector2(-18,-712)
	nina.position=region.project(nina_point)
	actors.add_child(nina)
	camera=Camera2D.new()
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=7.0
	camera.zoom=Vector2.ONE*camera_scale
	add_child(camera)
	_build_ui()
	_load_save()
	camera.position=region.project(player)
	camera.reset_smoothing()
	if "--smoke" in OS.get_cmdline_user_args():
		call_deferred("_smoke")
	if "--proof" in OS.get_cmdline_user_args():
		call_deferred("_proof")

func _build_ui() -> void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_top",18)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_bottom",18)
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(margin)
	var box:=VBoxContainer.new()
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	status=Label.new()
	status.text="SOULMONSTERS · VEREDAS\nProtótipo Godot — save local independente"
	status.add_theme_font_size_override("font_size",18)
	box.add_child(status)
	if reference_yard:
		status.text="PÁTIO DE REFERÊNCIA · ESCALA
Kael, parceiro, Nina, árvore, baú, água e rampa"
	var travel:=HBoxContainer.new()
	box.add_child(travel)
	var destinations: Array = [["Entrada",Vector2(224,816)],["Canal",Vector2(1184,960)],["Nina",Vector2(1488,1008)],["Encosta",Vector2(2112,384)]]
	if reference_yard:
		destinations=[["Clareira",Vector2(256,480)],["Nina",Vector2(496,480)],["Rampa",Vector2(632,400)],["Baú",Vector2(728,216)]]
	for destination in destinations:
		var jump:=Button.new()
		jump.text=destination[0]
		var point: Vector2=destination[1]
		jump.pressed.connect(func() -> void:
			player=point
			follower=point-Vector2(48,0)
			history.clear()
			path.clear()
			camera.position=region.project(player)
			camera.reset_smoothing())
		travel.add_child(jump)
	var spacer:=Control.new()
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	dialog=PanelContainer.new()
	dialog.hide()
	box.add_child(dialog)
	dialog.theme = Recorte.shared()
	dialog.theme_type_variation = "RecortePaperPanel"
	var inner:=VBoxContainer.new()
	dialog.add_child(inner)
	dialog_text=Label.new()
	dialog_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size=Vector2(400,90)
	dialog_text.theme_type_variation = "RecortePaperText"
	dialog_text.add_theme_font_size_override("font_size",22)
	inner.add_child(dialog_text)
	var close:=Button.new()
	close.text="Continuar · Enter / A"
	close.pressed.connect(_close_dialog)
	inner.add_child(close)
	hint=Label.new()
	hint.add_theme_font_size_override("font_size",20)
	box.add_child(hint)
	var controls:=Label.new()
	controls.text="WASD / setas / analógico: andar · clique: caminhar · E / A: interagir · F5: salvar · Esc: pausa"
	box.add_child(controls)

func _physics_process(delta: float) -> void:
	if dialogue_open:
		avatar.moving=false
		return
	var input:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if not Input.get_connected_joypads().is_empty():
		var device:int=Input.get_connected_joypads()[0]
		var stick:=Vector2(Input.get_joy_axis(device,JOY_AXIS_LEFT_X),Input.get_joy_axis(device,JOY_AXIS_LEFT_Y))
		if stick.length()>.2:
			input=stick
	var before:=player
	if input.length()>.1:
		path.clear()
		var direction:=Vector2(input.x/1.64+input.y/.82,input.y/.82-input.x/1.64).normalized()
		_move(direction*250*delta)
	elif not path.is_empty():
		var target:=path[0]
		if player.distance_to(target)<4:
			path.remove_at(0)
		else:
			_move((target-player).normalized()*minf(250*delta,player.distance_to(target)))
	var movement: Vector2=region.project(player)-region.project(before)
	avatar.moving=movement.length()>.1
	if avatar.moving:
		avatar.facing=("ne" if movement.y<0 else "se") if movement.x>=0 else ("nw" if movement.y<0 else "sw")
		if history.is_empty() or player.distance_to(history[-1])>8:
			history.append(player)
		if history.size()>9:
			follower=history.pop_front()
	avatar.position=region.project(player)
	companion.position=region.project(follower)
	animation_time+=delta
	companion.region_rect=companion_frames[int(animation_time*12)%companion_frames.size()]
	camera.position=avatar.position
	_update_context()

func _move(offset: Vector2) -> void:
	var target:=player+offset
	if region.walkable(target) and absf(region.elevation(target)-region.elevation(player))<12:
		player=target

func _update_context() -> void:
	nearest=""
	if player.distance_to(nina_point)<105:
		nearest="nina"
	for chest in region.data.chests:
		if player.distance_to(Vector2(chest.x,chest.y+48))<90:
			nearest=chest.id
	hint.text="E / A · Conversar com Nina" if nearest=="nina" else ("E / A · Abrir baú" if nearest!="" and not nearest in opened else "Atravesse a ponte e suba a rampa para explorar.")

func _unhandled_input(event: InputEvent) -> void:
	var interact: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_E,KEY_ENTER]
	interact=interact or event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_A
	if interact:
		if dialogue_open:
			_close_dialog()
		elif nearest=="nina":
			interacted_nina=true
			_talk("Nina", "O Lacertubo levou a rabiola do meu Carcará... Eu consegui escapar, mas ela ficou entre os canos.\n\nEsta é a primeira cena narrativa da versão Godot. A batalha ainda será migrada.")
			_save()
		elif nearest!="":
			if nearest in opened:
				_talk("Baú", "Você já recolheu os materiais deste baú.")
			else:
				opened.append(nearest)
				chests[nearest].modulate=Color(.55,.65,.55)
				_save()
				_talk("Materiais encontrados", "Retalhos e varetas guardados no save local do protótipo.\nNenhum item foi concedido à conta do jogo original.")
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not dialogue_open:
		path=region.route(player,region.pick(get_global_mouse_position()))
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_F5:
			_save()
			_talk("Progresso salvo", "Seu passeio e os baús estão guardados localmente.")
		if event.physical_keycode==KEY_ESCAPE:
			if dialogue_open:
				_close_dialog()
			else:
				_save()
				_talk("Pausa", "Protótipo Godot · Veredas\nAbertura, combate e serviços online continuam na versão original por enquanto.")

func _talk(speaker: String,text: String) -> void:
	dialogue_open=true
	path.clear()
	dialog_text.text=speaker+"\n\n"+text
	dialog.show()

func _close_dialog() -> void:
	dialog.hide()
	dialogue_open=false

func _save() -> void:
	var file:=FileAccess.open(save_path,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version":1,"x":player.x,"y":player.y,"opened":opened,"nina":interacted_nina}))

func _load_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary or data.get("version")!=1:
		return
	var candidate:=Vector2(float(data.get("x",224)),float(data.get("y",816)))
	if region.walkable(candidate):
		player=candidate
		follower=candidate-Vector2(48,0)
	if data.get("opened") is Array:
		for id in data.opened:
			if chests.has(id) and not id in opened:
				opened.append(id)
				chests[id].modulate=Color(.55,.65,.55)
	interacted_nina=data.get("nina",false)==true

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(region):
		_save()

func _smoke() -> void:
	if reference_yard:
		var crossing: PackedVector2Array=region.route(Vector2(256,480),Vector2(728,216))
		assert(crossing.size()>20,"Yard must connect bridge, ramp and chest")
		assert(region.elevation(Vector2(728,216))==80)
		assert(not region.walkable(Vector2(416,336)))
		assert(camera.zoom==Vector2(1.4,1.4))
		assert(region.ground_tiles is TileMapLayer)
		var tiles: TileMapLayer=region.ground_tiles
		var tile_step: Vector2=(tiles.map_to_local(Vector2i(1,0))-tiles.map_to_local(Vector2i.ZERO))*tiles.scale
		assert(tile_step.is_equal_approx(Vector2(52.48,26.24)),"Tiles must match world projection")
		assert(chests.size()==1)
		assert(is_instance_valid(region.path_tiles))
		var low: TileMapLayer=region.path_tiles.get_node("PathsLow")
		assert(low.tile_set.get_source(0).get_tiles_count()==64)
		assert(low.get_cell_source_id(Vector2i(12,15))==-1,"Earth cannot paint over bridge")
		var interior: Vector2i=low.get_cell_atlas_coords(Vector2i(7,15))
		assert(interior.x==0,"Interior road cells must not paint isolated borders")
		var border: Vector2i=low.get_cell_atlas_coords(Vector2i(4,14))
		assert((border.x&1)!=0 and (border.x&4)!=0,"Outer corner needs both edge transitions")
		player=Vector2(496,480)
		_update_context()
		assert(nearest=="nina")
		_save()
		player=Vector2(256,480)
		_load_save()
		assert(player==Vector2(496,480))
		DirAccess.remove_absolute(save_path)
		print("GODOT_YARD_OK: scale, bridge, ramp, height, chest, Nina and save")
		get_tree().quit(0)
		return
	var route: PackedVector2Array=region.route(Vector2(224,816),Vector2(2944,352))
	assert(route.size()>20,"Boss courtyard must be reachable")
	assert(region.elevation(Vector2(2944,352))==96)
	assert(not region.walkable(Vector2(1184,1200)),"Water outside bridges must block movement")
	assert(chests.size()==5)
	assert(companion_frames.size()>1)
	player=Vector2(1488,1008)
	_update_context()
	assert(nearest=="nina")
	player=Vector2(416,432)
	_update_context()
	assert(nearest=="lookout")
	opened=["lookout"]
	interacted_nina=true
	_save()
	player=Vector2(224,816)
	opened=[]
	interacted_nina=false
	_load_save()
	assert(player==Vector2(416,432))
	assert(opened==["lookout"] and interacted_nina)
	DirAccess.remove_absolute(save_path)
	print("GODOT_SMOKE_OK: native scene, avatar, follower, navigation, ramp, bridges, five chests")
	get_tree().quit(0)


func _proof() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://proof-yard.png" if reference_yard else "res://proof.png")
	get_tree().quit(0)
