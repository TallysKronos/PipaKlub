extends Node2D
const Controls = preload("res://scripts/campaign/controls.gd")
signal action_requested(id: String)
signal menu_requested
const Avatar = preload("res://scripts/avatar.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
var data: Dictionary
var content: Dictionary
var saved_player: Dictionary
var player := Vector2.ZERO
var follower := Vector2.ZERO
var paused := false
var avatar: Node2D
var companion: Sprite2D
var frames: Array = []
var camera: Camera2D
var hint: Label
var near := ""
var clock := 0.0
var distance := 0.0
var grass_distance := 0.0
var threshold := 240.0
var ui_theme: Theme
var trail: Array[Vector2] = []
var foot_radius := 10.0
var exploration_hud:Control
var ambient_seen:Dictionary={}
func ambient_speech(id:String) -> void:
	if id.is_empty() or ambient_seen.has(id):return
	for place in data.places:
		if place.id!=id or not place.has("stage"):continue
		ambient_seen[id]=true
		var story:Dictionary=load("res://scripts/campaign/morro_rules.gd").content().stories[place.stage]
		load("res://scripts/campaign/hud_world_speech.gd").spawn(self,project(Vector2(place.point[0],place.point[1])),str(story.before[0][1]))

func project(point: Vector2) -> Vector2:
	return Vector2((point.x - point.y) * .82 + 930, (point.x + point.y) * .41 + 20)

func safe(point: Vector2) -> bool:
	if not point.is_finite(): return false
	var radius := foot_radius
	for rect in data.blocked:
		if point.x + radius > rect.x and point.x - radius < rect.x + rect.w and point.y + radius > rect.y and point.y - radius < rect.y + rect.h: return false
	var xs: Array[float] = [point.x - radius, point.x + radius]
	for rect in data.walkable:
		for x in [rect.x, rect.x + rect.w]:
			if x > point.x - radius and x < point.x + radius: xs.append(x)
	xs.sort()
	for index in range(1, xs.size()):
		var x: float = (xs[index - 1] + xs[index]) / 2
		var spans: Array = []
		for rect in data.walkable:
			if x >= rect.x and x <= rect.x + rect.w: spans.append([rect.y, rect.y + rect.h])
		spans.sort_custom(func(a: Array, b: Array): return a[0] < b[0])
		var covered: float = point.y - radius
		for span in spans:
			if span[0] > covered: break
			covered = maxf(covered, span[1])
		if covered < point.y + radius: return false
	return true

func in_grass(point: Vector2) -> bool:
	for rect in data.walkable:
		if rect.properties.get("encounter_zone", "") != "" and Rect2(rect.x, rect.y, rect.w, rect.h).has_point(point): return true
	return false

func _ready() -> void:
	if not safe(player): player = Vector2(data.spawn[0], data.spawn[1])
	follower = player
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = load("res://assets/campaign/park/" + data.floorImage)
	floor_sprite.centered = false
	add_child(floor_sprite)
	for prop in data.props:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/campaign/park/" + prop.image)
		sprite.centered = false
		sprite.position = Vector2(prop.rect[0], prop.rect[1])
		sprite.z_index = int(prop.depth)
		add_child(sprite)
	for place in data.places:
		if place.action != "wildGuide": continue
		var professor := Sprite2D.new()
		professor.texture = load("res://assets/campaign/assis-overworld.png")
		professor.offset = Vector2(0, -professor.texture.get_height() / 2.0)
		professor.scale = Vector2.ONE * 90 / professor.texture.get_height()
		professor.position = project(Vector2(place.point[0], place.point[1]) + Vector2(0, -35))
		professor.z_index = int(professor.position.y)
		add_child(professor)
	avatar = Avatar.new()
	add_child(avatar)
	avatar.scale = Vector2.ONE * .8
	companion = Sprite2D.new()
	var partner_id: String = "rabbito"
	for partner in saved_player.partners:
		if partner.id == saved_player.get("equippedPartnerId", ""): partner_id = partner.modelId
	var atlas_id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}.get(partner_id, "rabbito")
	var atlas: Dictionary = content.combat[atlas_id]
	companion.texture = load("res://assets/campaign/" + atlas.image)
	companion.region_enabled = true
	frames = atlas.animations.idle
	companion.scale = Vector2.ONE * .3
	companion.offset = Vector2(0, -100)
	add_child(companion)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * 1.05
	camera.position = project(player)
	add_child(camera)
	var ui := CanvasLayer.new()
	add_child(ui)
	exploration_hud=load("res://scripts/campaign/hud_exploration.gd").new()
	exploration_hud.subject=self
	exploration_hud.area_name=data.name
	exploration_hud.player_data=saved_player
	ui.add_child(exploration_hud)
	exploration_hud.map=Hud.map_for(self,ui)
	hint=exploration_hud.prompt
	exploration_hud.chosen.connect(func(id:String):
		if id=="menu":menu_requested.emit()
		else:action_requested.emit(id))
	threshold = randf_range(240, 480)
	_refresh()

func _refresh() -> void:
	avatar.position = project(player)
	avatar.z_index = int(avatar.position.y)
	companion.position = project(follower)
	companion.z_index = int(companion.position.y)
	var frame: Dictionary = frames[int(clock * 12) % frames.size()]
	companion.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
	camera.position = project(player)

func _physics_process(delta: float) -> void:
	clock += delta
	if paused:
		avatar.moving = false
		return
	var input := Controls.direction()
	var before := player
	var movement := Vector2(input.x + 2 * input.y, 2 * input.y - input.x).normalized() * input.length() * 300 * minf(delta, .05)
	var steps := maxi(1, ceili(movement.length() / 3))
	for index in steps:
		var step := movement / steps
		if safe(player + step): player += step
		elif safe(player + Vector2(step.x, 0)): player.x += step.x
		elif safe(player + Vector2(0, step.y)): player.y += step.y
		if trail.is_empty() or trail.back().distance_to(player) >= 2: trail.append(player)
	avatar.moving = before.distance_to(player) > .01
	if avatar.moving: avatar.facing = ("n" if input.y < 0 else "s") + ("w" if input.x < 0 else "e")
	var remaining := 0.0
	var previous := follower
	for point in trail:
		remaining += previous.distance_to(point)
		previous = point
	var budget := minf(300 * delta, maxf(0, remaining - 65))
	while budget > .001 and not trail.is_empty():
		var length := follower.distance_to(trail[0])
		var amount := minf(budget, length)
		var candidate := follower.move_toward(trail[0], amount)
		if not safe(candidate): break
		follower = candidate
		budget -= amount
		if length <= amount + .001: trail.pop_front()
	_refresh()
	near = ""
	for place in data.places:
		if player.distance_to(Vector2(place.point[0], place.point[1])) < 90: near = place.id
	hint.text = ""
	for place in data.places:
		if place.id == near: hint.text = place.name
	hint.get_parent().visible = not near.is_empty()
	var moved := before.distance_to(player)
	distance += moved
	grass_distance = grass_distance + moved if in_grass(player) else 0
	if grass_distance >= threshold:
		grass_distance = 0
		threshold = randf_range(240, 480)
		action_requested.emit("wild")
	elif distance >= 250:
		distance = 0
		action_requested.emit("autosave")

func _unhandled_input(event: InputEvent) -> void:
	if Controls.cancel(event) or Controls.pressed(event, "interact"):
		if Controls.cancel(event):
			get_viewport().set_input_as_handled()
			menu_requested.emit()
		elif not paused and not near.is_empty():
			get_viewport().set_input_as_handled()
			action_requested.emit(near)

