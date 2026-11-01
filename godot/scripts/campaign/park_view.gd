extends "res://scripts/illustrated_veredas.gd"
const Controls = preload("res://scripts/campaign/controls.gd")
## Campaign adapter: retains the reviewed ground/controller; removes prototype warps.
signal action_requested(id: String)
signal menu_requested
const Park = preload("res://scripts/campaign/park_data.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
var saved_player: Dictionary = {}
var spawn_point := Park.ENTRY
var chest_nodes: Dictionary = {}
var guardian: Sprite2D
var tail: Sprite2D
var guardian_frames: Array = []
var objective: Label
var autosave_distance := 0.0
var last_point := Park.ENTRY
var ui_theme: Theme
var grass_distance := 0.0
var grass_threshold := 180.0
var resource_label: Label
var exploration_hud:Control
var nina_ambient_seen:=false
var landscape: Node2D
var ledge_jump = preload("res://scripts/overworld/ledge_jump.gd").new()
var jump_links: Array = []
var jump_companion_start := Vector2.ZERO
var jump_companion_end := Vector2.ZERO
var jump_marker: Node2D
var item_receipt: Dictionary = {}

func celebrate_item(message: String) -> bool:
	if not item_receipt.is_empty() or ledge_jump.active or paused: return false
	route.clear()
	avatar.moving=false
	item_receipt={"elapsed":0.0,"facing":avatar.facing,"message":message,"shown":false}
	hint.text=""
	hint.get_parent().hide()
	avatar.item_pose(0,avatar.facing)
	return true

func _advance_item_receipt(delta: float) -> void:
	var duration: float=(avatar.item_frames.durationMs+avatar.item_frames.turnMs)/1000.0
	item_receipt.elapsed=minf(duration,item_receipt.elapsed+delta)
	avatar.item_pose(item_receipt.elapsed/duration,item_receipt.facing)
	if not item_receipt.shown and item_receipt.elapsed>=.8:
		item_receipt.shown=true
		exploration_hud.push_notice(item_receipt.message,"item")
	if item_receipt.elapsed<duration:return
	avatar.stop_item()
	item_receipt.clear()
	last_point=player

func _ready() -> void:
	Controls.install()
	player = spawn_point
	follower = spawn_point
	super()
	# Keep the tested video walk/jump scale and match Nina to that actual body height.
	avatar.scale=Vector2.ONE*.78
	var pixels=preload("res://scripts/npc_pixel_sprite.gd")
	pixels.setup(nina,"nina",pixels.height_for("nina",avatar.scale.y))
	# The old plate's 0..1536 / 0..1024 limits clipped raised destinations.
	# Let the camera follow their projected position, including the far mirante.
	camera.limit_left=-100000;camera.limit_right=100000
	camera.limit_top=-100000;camera.limit_bottom=100000
	if not ground.walkable(player): player = Park.ENTRY
	var behind := player + Vector2(-24, 15)
	follower = behind if ground.walkable(behind) and ground.clear_segment(behind, player) else player
	trail.assign(_path(follower, player))
	_refresh_positions()
	camera.position = landscape.project(player)
	camera.reset_smoothing()
	chest.hide()
	for id in Park.CHESTS:
		var item := Sprite2D.new()
		item.texture = load("res://assets/overworld/kits/veredas-modular-v5/bau.png")
		item.centered=false
		var pivot: Array=landscape.layout.chest.pivot
		item.offset=-Vector2(pivot[0],pivot[1])
		item.position = landscape.project(Park.CHESTS[id].point)
		item.z_index = landscape.depth(Park.CHESTS[id].point)
		actors.add_child(item)
		chest_nodes[id] = item
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	for partner in saved_player.partners:
		if partner.id != saved_player.get("equippedPartnerId", ""): continue
		var id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}.get(partner.modelId, "rabbito")
		var selected: Dictionary = content.combat[id]
		companion.texture = load("res://assets/campaign/" + selected.image)
		companion_frames.clear()
		for frame in selected.animations.idle: companion_frames.append(Rect2(frame.x, frame.y, frame.w, frame.h))
	var art: Dictionary = content.combat.lacertubo
	guardian = Sprite2D.new()
	guardian.texture = load("res://assets/campaign/" + art.image)
	guardian_frames = art.animations.idle
	guardian.region_enabled = true
	var first_frame: Dictionary=guardian_frames[0]
	guardian.region_rect=Rect2(first_frame.x,first_frame.y,first_frame.w,first_frame.h)
	guardian.offset = Vector2(0, -75)
	guardian.position = landscape.project(Park.BOSS)
	guardian.z_index = landscape.depth(Park.BOSS)
	guardian.scale = Vector2.ONE * .5
	actors.add_child(guardian)
	tail = Sprite2D.new()
	tail.texture = load("res://assets/campaign/nina-tail.png")
	tail.scale = Vector2.ONE * 40 / tail.texture.get_width()
	tail.position = landscape.project(Park.TAIL)
	tail.z_index = landscape.depth(Park.TAIL)
	actors.add_child(tail)
	last_point = player
	grass_threshold = randf_range(180, 360)
	jump_links = landscape.jump_links()
	jump_marker = Node2D.new()
	add_child(jump_marker)
	_build_jump_markers()
	refresh(saved_player)

func _build_jump_markers() -> void:
	for entry: Dictionary in jump_links:
		var at: Vector2 = landscape.project(entry.from)
		var direction: Vector2 = (landscape.project(entry.to)-at).normalized()
		var side := direction.orthogonal() * 5
		for offset in [-4.0, 3.0]:
			var tip: Vector2 = direction * float(offset)
			var line := Line2D.new()
			line.position=at
			line.z_index=landscape.depth(entry.from)+1
			line.points=PackedVector2Array([tip-direction*4+side,tip,tip-direction*4-side])
			line.width=1.5;line.default_color=Color("e3c77d");line.antialiased=true
			jump_marker.add_child(line)

func _near_jump() -> Dictionary:
	return ledge_jump.nearby(player,jump_links,ground)

func _start_jump() -> bool:
	if paused or modal.visible or not item_receipt.is_empty() or not ledge_jump.begin(_near_jump(),player,ground): return false
	route.clear()
	jump_companion_start = companion.position
	jump_companion_end = ledge_jump.link.to
	var destination: Vector2=landscape.warp.transform(ledge_jump.link.to)
	for offset in [Vector2(28,12),Vector2(-28,12),Vector2(36,0)]:
		var candidate: Vector2=landscape.warp.transform(destination+offset,true)
		if ground.walkable(candidate,2) and ground.clear_segment(ledge_jump.link.to,candidate) and is_equal_approx(landscape.elevation(destination+offset),landscape.elevation(destination)):
			jump_companion_end=candidate
			break
	# The flying partner follows through the air; it does not walk through the wall.
	avatar.moving = false
	var direction: Vector2 = landscape.project(ledge_jump.link.to)-landscape.project(ledge_jump.link.from)
	avatar.face_motion(direction)
	hint.text = ""
	hint.get_parent().hide()
	return true

func _advance_jump(delta: float) -> void:
	clock+=delta
	if not companion_frames.is_empty():companion.region_rect=companion_frames[int(clock*8)%companion_frames.size()]
	var landed: bool = ledge_jump.advance(delta)
	avatar.position = ledge_jump.screen_position(landscape.project)
	avatar.z_index = landscape.depth(ledge_jump.link.from.lerp(ledge_jump.link.to,ledge_jump.progress()))
	if avatar.has_method("jump_pose"): avatar.jump_pose(ledge_jump.pose_progress())
	var t := clampf((ledge_jump.elapsed-.15)/.65,0,1)
	companion.position = jump_companion_start.lerp(landscape.project(jump_companion_end),smoothstep(0,1,t))+Vector2(36,-16)*sin(t*PI)
	companion.z_index = avatar.z_index-1
	if not overview: camera.position=avatar.position
	if not landed: return
	player=ledge_jump.link.to
	follower=jump_companion_end
	trail.clear()
	last_point=player
	if avatar.has_method("stop_jump"): avatar.stop_jump()
	_refresh_positions()
	action_requested.emit("autosave")

func refresh(value: Dictionary) -> void:
	saved_player = value.duplicate(true)
	if not is_instance_valid(guardian): return
	guardian.visible = not saved_player.flags.get("guardianDefeated", false)
	tail.visible = saved_player.flags.get("guardianDefeated", false) and not saved_player.flags.get("ninaTail", false)
	for id in chest_nodes: chest_nodes[id].visible = id not in saved_player.openedChests
	objective.text = Park.objective(saved_player)
	exploration_hud.refresh(saved_player)
	resource_label.text = "%s  ·  %d moedas" % [saved_player.get("name", "Kael"), saved_player.get("coins", 0)]

func _build_ui() -> void:
	var ui:=CanvasLayer.new()
	add_child(ui)
	exploration_hud=load("res://scripts/campaign/hud_exploration.gd").new()
	exploration_hud.subject=self
	exploration_hud.area_name="Veredas do Encanamento"
	exploration_hud.player_data=saved_player
	ui.add_child(exploration_hud)
	exploration_hud.map=Hud.map_for(self,ui)
	hint=exploration_hud.prompt
	objective=exploration_hud.objective
	resource_label=exploration_hud.coins
	exploration_hud.chosen.connect(func(id:String):
		if id=="menu":menu_requested.emit()
		else:action_requested.emit(id))
	modal=PanelContainer.new()
	modal.hide()
	ui.add_child(modal)
	speech=Label.new()
	modal.add_child(speech)

func _physics_process(delta: float) -> void:
	if not item_receipt.is_empty():
		if not paused:_advance_item_receipt(delta)
		return
	if ledge_jump.active:
		if not paused: _advance_jump(delta)
		return
	super(delta)
	if is_instance_valid(guardian) and not guardian_frames.is_empty():
		var frame: Dictionary = guardian_frames[int(clock * 12) % guardian_frames.size()]
		guardian.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
		tail.modulate = Tokens.alpha(Tokens.SOL, .65 + .35 * sin(clock * 4))
	if not overview:camera.position=landscape.project(player)
	if paused: return
	var jump_target := _near_jump()
	hint.text = "Pular barranco · descer" if not jump_target.is_empty() else _near_action().get("label", "")
	hint.get_parent().visible = not jump_target.is_empty() or not _near_action().is_empty()
	if not nina_ambient_seen and _near_action().get("id","")=="nina":
		nina_ambient_seen=true
		load("res://scripts/campaign/hud_world_speech.gd").spawn(self,nina.position,"Ei… você pode me ajudar?")
	var moved := last_point.distance_to(player)
	autosave_distance += moved
	if Park.in_grass(player): grass_distance += moved
	else: grass_distance = 0
	last_point = player
	if grass_distance >= grass_threshold:
		grass_distance = 0
		grass_threshold = randf_range(180, 360)
		action_requested.emit("wild")
		return
	if autosave_distance >= 250:
		autosave_distance = 0
		action_requested.emit("autosave")

func _near_action() -> Dictionary:
	if player.distance_to(Park.NINA) < 65: return {"id": "nina", "label": "Conversar com Nina"}
	if guardian.visible and player.distance_to(Park.BOSS) < 85: return {"id": "boss", "label": "DESAFIAR · Lacertubo"}
	if tail.visible and player.distance_to(Park.TAIL) < 60: return {"id": "tail", "label": "Recolher rabiola"}
	for id in chest_nodes:
		if chest_nodes[id].visible and player.distance_to(Park.CHESTS[id].point) < 50: return {"id": "chest:" + id, "label": "Abrir baú"}
	if player.distance_to(Park.ENTRY) < 60: return {"id": "exit", "label": "Voltar à rua"}
	return {}

func _interact() -> void:
	if paused or ledge_jump.active or not item_receipt.is_empty(): return
	if _start_jump(): return
	var target := _near_action()
	if not target.is_empty(): action_requested.emit(target.id)

func _movement_direction() -> Vector2:
	return Controls.direction()

func _unhandled_input(event: InputEvent) -> void:
	if ledge_jump.active or not item_receipt.is_empty():
		if Controls.cancel(event):
			get_viewport().set_input_as_handled()
			menu_requested.emit()
		return
	if Controls.pressed(event, "interact"):
		get_viewport().set_input_as_handled()
		_interact()
	elif Controls.cancel(event):
		get_viewport().set_input_as_handled()
		menu_requested.emit()
	elif Controls.pressed(event, "map"): _overview()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not paused:
		route = _path(player, landscape.unproject(get_global_mouse_position()))

func _build_landscape() -> bool:
	landscape=load("res://scripts/overworld/veredas_modular_landscape.gd").new()
	add_child(landscape)
	landscape.build("park-veredas",data)
	data=landscape.legacy_layout(data)
	return true

func _has_landscape() -> bool:return true

func _navigation_stride() -> int:return 8

func project(point: Vector2) -> Vector2:return landscape.project(point)

func _facing_displacement(a: Vector2,b: Vector2) -> Vector2:
	return landscape.warp.transform(b)-landscape.warp.transform(a)

func _refresh_positions() -> void:
	if not is_instance_valid(landscape):return
	super._refresh_positions()
	avatar.position=landscape.project(player)
	avatar.z_index=landscape.depth(player)
	companion.position=landscape.project(follower)
	companion.z_index=landscape.depth(follower)
	if is_instance_valid(nina):
		nina.position=landscape.project(Park.NINA)
		nina.z_index=landscape.depth(Park.NINA)

func _overview() -> void:
	overview=not overview
	camera.zoom=Vector2.ONE*(.65 if overview else 1.6)
	camera.position=Vector2(768,450) if overview else landscape.project(player)
	camera.reset_smoothing()
