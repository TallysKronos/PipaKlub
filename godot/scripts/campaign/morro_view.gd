extends "res://scripts/campaign/park_route_view.gd"
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Rules = preload("res://scripts/campaign/morro_rules.gd")
var navigation := AStar2D.new()
var path: PackedVector2Array = []
var gate: Dictionary = {}
var gate_closed := true
var decorations: Array = []
var npc_sprites: Array = []
var goal: Label

func project(point: Vector2) -> Vector2:
	return point

func level_at(point: Vector2) -> int:
	for rect in data.walkable:
		if Rect2(rect.x, rect.y, rect.w, rect.h).has_point(point): return int(rect.properties.level)
	return 0

func region_at(point: Vector2) -> Dictionary:
	for rect in data.walkable:
		if point.x >= rect.x and point.x <= rect.x + rect.w and point.y >= rect.y and point.y <= rect.y + rect.h: return rect
	return {}

func segment(a: Vector2, b: Vector2) -> bool:
	if not safe(a) or not safe(b): return false
	var previous := region_at(a)
	for index in range(1, maxi(1, ceili(a.distance_to(b))) + 1):
		var point := a.lerp(b, float(index) / maxi(1, ceili(a.distance_to(b))))
		if not safe(point): return false
		var next := region_at(point)
		if previous.id != next.id and previous.properties.level != next.properties.level:
			var stair: Dictionary = previous if previous.properties.get("connects_to", -1) == next.properties.level else next if next.properties.get("connects_to", -1) == previous.properties.level else {}
			if stair.is_empty(): return false
			var floor_rect: Dictionary = next if stair.id == previous.id else previous
			if stair.y != floor_rect.y + floor_rect.h and stair.y + stair.h != floor_rect.y: return false
		previous = next
	return true

func _ready() -> void:
	foot_radius = 12.0
	var progress: Dictionary = saved_player.get("morro", Rules.defaults())
	gate_closed = not progress.stars.has(data.stage)
	data = data.duplicate(true)
	for rect in data.foreground:
		if rect.properties.get("road_gate", false):
			gate = rect
			if gate_closed: data.blocked.append(rect)
	if gate_closed and not gate.is_empty():
		var frame: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/morro/gate.json"))
		var fence := Sprite2D.new()
		fence.texture = load("res://assets/campaign/morro/gate-sheet.png")
		fence.region_enabled = true
		fence.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
		fence.centered = false
		fence.scale = Vector2.ONE * (gate.w + 12) / frame.w
		fence.position = Vector2(gate.x - 6, gate.y + gate.h - frame.h * fence.scale.y)
		fence.z_index = int(gate.properties.level) * 1200 + int(gate.y + gate.h)
		add_child(fence)
	if not safe(player): player = Vector2(data.spawn[0], data.spawn[1])
	follower = player
	for offset in [Vector2(35, 25), Vector2(-35, 25), Vector2(0, 42)]:
		if safe(player + offset) and level_at(player + offset) == level_at(player) and segment(player, player + offset):
			follower = player + offset
			break
	for image in data.images:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/campaign/morro/" + image.image)
		sprite.centered = false
		sprite.position = Vector2(image.x, image.y)
		sprite.z_index = -100 if image.render == "ground" else int(image.level) * 1200 + int(image.sortY)
		add_child(sprite)
		if image.render == "depth": decorations.append({"node": sprite, "data": image})
	for rect in data.foreground:
		if not rect.properties.has("image_sheet"): continue
		for image in data.images:
			if image.sheet != rect.properties.image_sheet: continue
			var sprite := Sprite2D.new()
			sprite.texture = load("res://assets/campaign/morro/" + image.image)
			sprite.region_enabled = true
			sprite.region_rect = Rect2(rect.x, rect.y, rect.w, rect.h)
			sprite.centered = false
			sprite.position = Vector2(rect.x, rect.y)
			sprite.z_index = int(rect.properties.level) * 1200 + int(rect.properties.sort_y)
			add_child(sprite)
	for npc in data.npcs:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/campaign/morro/" + npc.image)
		sprite.region_enabled = true
		var bounds: Dictionary = npc.bounds
		sprite.region_rect = Rect2(bounds.x, bounds.y, bounds.w, bounds.h)
		sprite.scale = Vector2.ONE * 72 / bounds.h
		sprite.offset.y = -bounds.h / 2
		sprite.position = Vector2(npc.point[0], npc.point[1])
		sprite.z_index = level_at(sprite.position) * 1200 + int(sprite.position.y)
		add_child(sprite)
		npc_sprites.append(sprite)
		var name_label := Label.new()
		name_label.text = "Juninho e Lia" if data.npcs.size() == 2 else npc.name
		name_label.position = Vector2(-57, -92) if data.npcs.size() == 2 else Vector2(-45, -92)
		name_label.size.x = 160 if data.npcs.size() == 2 else 90
		name_label.visible = data.npcs.size() != 2 or npc.name == "Juninho"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.theme_type_variation = "RecorteWorldText"
		name_label.add_theme_constant_override("outline_size", 4)
		var label_root := Node2D.new()
		label_root.position = sprite.position
		label_root.z_index = sprite.z_index
		add_child(label_root)
		label_root.add_child(name_label)
	avatar = Avatar.new()
	add_child(avatar)
	avatar.scale = Vector2.ONE * .62
	companion = Sprite2D.new()
	var model := "rabbito"
	for partner in saved_player.partners:
		if partner.id == saved_player.get("equippedPartnerId", ""): model = partner.modelId
	var art: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}.get(model, "rabbito")
	var atlas: Dictionary = content.combat[art]
	companion.texture = load("res://assets/campaign/" + atlas.image)
	companion.region_enabled = true
	frames = atlas.animations.idle
	companion.scale = Vector2.ONE * .24
	companion.offset.y = -100
	add_child(companion)
	camera = Camera2D.new()
	camera.position = player
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1536
	camera.limit_bottom = 1024
	add_child(camera)
	for index in data.nodes.size():
		var point := Vector2(data.nodes[index][0], data.nodes[index][1])
		navigation.add_point(index, point)
		# Exported nodes/edges already satisfy the original swept-foot geometry.
		# Only the dynamic gate changes that graph at runtime.
		var gate_overlap: bool = gate_closed and not gate.is_empty() and point.x + foot_radius > gate.x and point.x - foot_radius < gate.x + gate.w and point.y + foot_radius > gate.y and point.y - foot_radius < gate.y + gate.h
		navigation.set_point_disabled(index, gate_overlap)
	for edge in data.edges:
		navigation.connect_points(edge[0], edge[1])
	var ui := CanvasLayer.new()
	add_child(ui)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.theme = ui_theme
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 20)
	ui.add_child(margin)
	Hud.map_for(self, ui)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	var card := Hud.card(data.name)
	card.custom_minimum_size.x = 320
	row.add_child(card)
	Hud.retract_after(card, 3)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	for option in [["Equipe", "collection"], ["Bolsa", "bag"], ["Menu", "menu"]]:
		var button := Button.new()
		button.text = option[0]
		Hud.secondary_button(button)
		button.icon = Hud.icon({"collection": "team", "bag": "bag", "menu": "settings"}[option[1]])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 24)
		button.custom_minimum_size = Vector2(122, 48)
		var id: String = option[1]
		button.pressed.connect(func():
			if id == "menu": menu_requested.emit()
			else: action_requested.emit(id))
		row.add_child(button)
	goal = Label.new()
	goal.text = "Passagem liberada" if not gate_closed else "Explore o bairro e converse com os pipeiros."
	goal.theme_type_variation = "RecorteWorldText"
	goal.add_theme_constant_override("outline_size", 0)
	var objective_panel := PanelContainer.new()
	objective_panel.theme_type_variation = "PanelContainer"
	objective_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_panel.add_child(goal)
	column.add_child(objective_panel)
	Hud.retract_after(objective_panel, 4)
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(gap)
	hint = Label.new()
	hint.theme_type_variation = "RecorteWorldText"
	hint.add_theme_constant_override("outline_size", 0)
	var prompt_panel := PanelContainer.new()
	prompt_panel.theme_type_variation = "PanelContainer"
	prompt_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.add_child(hint)
	column.add_child(prompt_panel)
	_refresh()
	camera.reset_smoothing()

func _refresh() -> void:
	avatar.position = player
	avatar.z_index = level_at(player) * 1200 + int(player.y)
	companion.position = follower
	companion.z_index = level_at(follower) * 1200 + int(follower.y)
	var frame: Dictionary = frames[int(clock * 12) % frames.size()]
	companion.region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
	camera.position = player
	for entry in decorations:
		var rect: Variant = entry.data.occlusion
		entry.node.modulate.a = .55 if rect != null and Rect2(rect.x, rect.y, rect.w, rect.h).has_point(player) and player.y < entry.data.sortY else 1.0
	queue_redraw()

func walk_to(point: Vector2) -> bool:
	path.clear()
	var start := navigation.get_closest_point(player)
	var end := navigation.get_closest_point(point)
	if start < 0 or end < 0 or navigation.get_point_position(end).distance_to(point) > 72: return false
	var points := navigation.get_point_path(start, end)
	if points.is_empty() or not segment(player, points[0]): return false
	path = points
	if safe(point) and segment(points[points.size() - 1], point): path.append(point)
	return true

func _physics_process(delta: float) -> void:
	clock += delta
	if paused:
		avatar.moving = false
		return
	var direction := Controls.direction()
	if direction.length() > .05: path.clear()
	elif not path.is_empty():
		while not path.is_empty() and player.distance_to(path[0]) < 3: path.remove_at(0)
		if not path.is_empty(): direction = (path[0] - player).normalized() * minf(1, player.distance_to(path[0]) / maxf(1, 240 * delta))
	var before := player
	var movement := direction * 240 * minf(delta, .05)
	var steps := maxi(1, ceili(movement.length() / 3))
	for index in steps:
		var step := movement / steps
		if segment(player, player + step): player += step
		elif segment(player, player + Vector2(step.x, 0)): player.x += step.x
		elif segment(player, player + Vector2(0, step.y)): player.y += step.y
		if trail.is_empty() or trail.back().distance_to(player) >= 2: trail.append(player)
	avatar.moving = before.distance_to(player) > .01
	if avatar.moving: avatar.facing = ("n" if direction.y < 0 else "s") + ("w" if direction.x < 0 else "e")
	var remaining := 0.0
	var previous := follower
	for point in trail:
		remaining += previous.distance_to(point)
		previous = point
	var budget := minf(240 * delta, maxf(0, remaining - 42))
	while budget > .001 and not trail.is_empty():
		var length := follower.distance_to(trail[0])
		var amount := minf(budget, length)
		var candidate := follower.move_toward(trail[0], amount)
		if not segment(follower, candidate): break
		follower = candidate
		budget -= amount
		if length <= amount + .001: trail.pop_front()
	_refresh()
	near = ""
	var nearest := 85.0
	for place in data.places:
		var point := Vector2(place.point[0], place.point[1])
		var gap := player.distance_to(point)
		if gap < nearest:
			nearest = gap
			near = place.id
	hint.text = "Analógico · Mover" if Controls.gamepad else "WASD / setas · Mover · Clique no caminho para caminhar"
	hint.get_parent().visible = not near.is_empty()
	for place in data.places:
		if place.id == near:
			hint.text = Controls.prompt("interact") + " · " + ("Conversar com " + " e ".join(Rules.stage(data.stage).foes.map(func(f): return f.name)) if place.has("stage") else place.name)
	distance += before.distance_to(player)
	if distance >= 250:
		distance = 0
		action_requested.emit("autosave")

func _unhandled_input(event: InputEvent) -> void:
	if paused: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		walk_to(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	else: super._unhandled_input(event)

