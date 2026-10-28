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

func _ready() -> void:
	player = spawn_point
	follower = spawn_point
	super()
	if not ground.walkable(player): player = Park.ENTRY
	var behind := player + Vector2(-24, 15)
	follower = behind if ground.walkable(behind) and ground.clear_segment(behind, player) else player
	trail.assign(_path(follower, player))
	_refresh_positions()
	camera.position = player
	camera.reset_smoothing()
	chest.hide()
	for id in Park.CHESTS:
		var item := Sprite2D.new()
		item.texture = preload("res://assets/chest.png")
		item.scale = Vector2.ONE * .12
		item.offset = Vector2(0, -115)
		item.position = Park.CHESTS[id].point
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
	guardian.offset = Vector2(0, -75)
	guardian.position = Park.BOSS
	guardian.scale = Vector2.ONE * .5
	actors.add_child(guardian)
	tail = Sprite2D.new()
	tail.texture = load("res://assets/campaign/nina-tail.png")
	tail.scale = Vector2.ONE * 40 / tail.texture.get_width()
	tail.position = Park.TAIL
	actors.add_child(tail)
	last_point = player
	grass_threshold = randf_range(180, 360)
	refresh(saved_player)

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
	super(delta)
	if is_instance_valid(guardian) and not guardian_frames.is_empty():
		var frame: Dictionary = guardian_frames[int(clock * 12) % guardian_frames.size()]
		guardian.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
		tail.modulate = Tokens.alpha(Tokens.SOL, .65 + .35 * sin(clock * 4))
	if paused: return
	hint.text = _near_action().get("label", "")
	hint.get_parent().visible = not _near_action().is_empty()
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
	if player.distance_to(nina.position) < 65: return {"id": "nina", "label": "Conversar com Nina"}
	if guardian.visible and player.distance_to(Park.BOSS) < 85: return {"id": "boss", "label": "DESAFIAR · Lacertubo"}
	if tail.visible and player.distance_to(Park.TAIL) < 60: return {"id": "tail", "label": "Recolher rabiola"}
	for id in chest_nodes:
		if chest_nodes[id].visible and player.distance_to(chest_nodes[id].position) < 50: return {"id": "chest:" + id, "label": "Abrir baú"}
	if player.distance_to(Park.ENTRY) < 60: return {"id": "exit", "label": "Voltar à rua"}
	return {}

func _interact() -> void:
	if paused: return
	var target := _near_action()
	if not target.is_empty(): action_requested.emit(target.id)

func _movement_direction() -> Vector2:
	return Controls.direction()

func _unhandled_input(event: InputEvent) -> void:
	if Controls.pressed(event, "interact"):
		get_viewport().set_input_as_handled()
		_interact()
	elif Controls.cancel(event):
		get_viewport().set_input_as_handled()
		menu_requested.emit()
	elif Controls.pressed(event, "map"): _overview()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not paused:
		route = _path(player, get_global_mouse_position())
