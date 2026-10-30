extends Node2D
## Independent playable dock. Surface graph owns height and edge collision.
## Does not load/write campaign slots or access the network.
const Controls = preload("res://scripts/campaign/controls.gd")
const Avatar = preload("res://scripts/avatar.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Depth = preload("res://scripts/overworld/pier_depth.gd")
const SPEED := 3.0
const RADIUS := .13
@export_file("*.tscn") var world_scene_path := "res://scenes/overworld/pier/cais-dos-elos.tscn"
const LADDER_LINKS := [
	{"lower":"middle","upper":"peak","bottom":Vector2(-.35,5.6),"top":Vector2(-.85,5.6),"axis":Vector2(-.60,5.6)},
	{"lower":"cliff_landing","upper":"middle","bottom":Vector2(1.55,6.4),"top":Vector2(1.03,6.4),"axis":Vector2(1.30,6.4)},
	{"lower":"tower_floor","upper":"tower_upper","bottom":Vector2(8.22,-.85),"top":Vector2(8.22,-.85),"axis":Vector2(8.55,-.85)}]
var world: Node2D
var depth = Depth.new()
var roofless_depth = Depth.new()
var avatar: Node2D
var player_root: Node2D
var partner_root: Node2D
var partner: Sprite2D
var player_material: ShaderMaterial
var partner_material: ShaderMaterial
var camera: Camera2D
var cell := Vector2(8.5,22.5)
var surface := "terminal"
var elevation := 12.0
var follower := Vector2(8.5,22.8)
var follower_height := 12.0
var follower_surface := "terminal"
var trail: Array[Dictionary] = []
var distance_walked := 0.0
var ladder: Dictionary = {}
var ladder_time := 0.0
var paused := false
var overview := false
var finished := false
var visited: Dictionary = {"terminal":true}
var clock := 0.0
var objective: Label
var context: Label
var pause_panel: PanelContainer
var resume_button: Button
var progress_label: Label
var compass: Label
var hud_root: Control
var atlas: Dictionary
var partner_frames: Array = []
var nearest_ladder: Dictionary = {}
var roof_nodes: Array[Node2D] = []
var roof_opacity := 1.0

func _ready() -> void:
	Controls.install()
	world = load(world_scene_path).instantiate()
	add_child(world)
	world.set_process_unhandled_key_input(false)
	depth.bake(world.parts)
	for item in world.parts:
		if item.surface=="tower_roof":roof_nodes.append(item.node)
	if roof_nodes.is_empty():roofless_depth.texture = depth.texture
	else:roofless_depth.bake(world.parts,true)
	player_root = Node2D.new()
	player_root.z_index = 10
	add_child(player_root)
	player_material = depth.material()
	player_material.set_shader_parameter("roofless_depth_map",roofless_depth.texture)
	avatar = Avatar.new()
	avatar.material = player_material
	player_root.add_child(avatar)
	avatar.scale = Vector2.ONE*.58*Avatar.BODY_SCALE
	_shadow(player_root,player_material,Vector2(10,4))
	partner_root = Node2D.new()
	partner_root.z_index = 9
	add_child(partner_root)
	partner_material = depth.material()
	partner_material.set_shader_parameter("roofless_depth_map",roofless_depth.texture)
	partner = Sprite2D.new()
	partner.texture = load("res://assets/rabbito.png")
	partner.region_enabled = true
	partner.scale = Vector2.ONE*.135
	partner.offset = Vector2(0,-104)
	partner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	partner.material = partner_material
	partner_root.add_child(partner)
	_shadow(partner_root,partner_material,Vector2(6,2.5))
	atlas = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rabbito.json"))
	for id: String in atlas.frames:
		if id.begins_with("idle-"):partner_frames.append(atlas.frames[id].frame)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE*1.55
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	_build_ui()
	trail = [{"p":follower,"h":follower_height,"surface":surface,"distance":-.3},
		{"p":cell,"h":elevation,"surface":surface,"distance":0.0}]
	_refresh_visuals()
	camera.position = player_root.position-Vector2(0,35)
	camera.reset_smoothing()
	_update_hint()
	print("Playable pier ready; depth atlas %s, bake %d ms; no campaign save loaded." % [depth.texture.get_size(),depth.bake_ms])

func _shadow(parent: Node2D,mat: ShaderMaterial,radius: Vector2) -> void:
	var shadow := Polygon2D.new()
	# Packed array properties return a copy: assign the complete contour.
	var contour := PackedVector2Array()
	for i in range(16):contour.append(Vector2(cos(i*TAU/16),sin(i*TAU/16))*radius)
	shadow.polygon = contour
	shadow.color = Color(0.10,0.17,0.17,.25)
	shadow.material = mat
	shadow.z_index = -1
	parent.add_child(shadow)

func state() -> Dictionary:
	return {"p":cell,"surface":surface,"h":elevation}

func _obstructed(p: Vector2,id: String) -> bool:
	if id in ["tower_base","tower_floor","tower_upper"]:
		for post in [Vector2(5.5,-2),Vector2(8.5,-2),Vector2(8.5,0),Vector2(5.5,0)]:
			if p.distance_to(post)<.24:return true
	if id=="outpost" and p.distance_to(Vector2(11.2,.2))<.31:return true
	if id=="beach":
		for prop in [Vector2(17,9),Vector2(18.3,10),Vector2(18.7,11.6)]:
			if p.distance_to(prop)<.30:return true
	return false

func resolve_step(origin: Dictionary,next: Vector2) -> Dictionary:
	var current: Dictionary = world.find_surface(origin.surface)
	var h0: float = world.surface_height(current,origin.p)
	var target: Dictionary = {}
	if not current.has("steps"):
		for id: String in current.neighbors:
			var neighbor: Dictionary = world.find_surface(id)
			if neighbor.has("steps") and world.contains(neighbor,next) and absf(h0-world.surface_height(neighbor,next))<2.5:
				target = neighbor
				break
	if target.is_empty() and world.contains(current,next):target = current
	if target.is_empty():
		for id: String in current.neighbors:
			var neighbor: Dictionary = world.find_surface(id)
			if world.contains(neighbor,next) and absf(h0-world.surface_height(neighbor,next))<6:
				target = neighbor
				break
	if target.is_empty() or _obstructed(next,target.id):return origin
	# A foot disc may straddle a real join, but not an exposed edge or another floor.
	var h: float = world.surface_height(target,next)
	for offset in [Vector2(RADIUS,0),Vector2(-RADIUS,0),Vector2(0,RADIUS),Vector2(0,-RADIUS)]:
		var sample: Vector2 = next+offset
		var supported: bool = world.contains(target,sample)
		if not supported:
			for id: String in target.neighbors:
				var neighbor: Dictionary = world.find_surface(id)
				if world.contains(neighbor,sample) and absf(h-world.surface_height(neighbor,sample))<9:
					supported = true
					break
		if not supported:return origin
	return {"p":next,"surface":str(target.id),"h":world.surface_height(target,next,true)}

func walk(delta: Vector2) -> void:
	var count := maxi(1,ceili(delta.length()/.035))
	var step := delta/float(count)
	for i in range(count):
		var before := state()
		var next := resolve_step(before,cell+step)
		if next.p==cell:
			for slide in [Vector2(step.x,0),Vector2(0,step.y)]:
				next = resolve_step(state(),cell+slide)
				_adopt(next)
		else:_adopt(next)

func _adopt(next: Dictionary) -> void:
	var old := cell
	var old_height := elevation
	cell = next.p
	surface = next.surface
	elevation = next.h
	visited[surface] = true
	if cell!=old or elevation!=old_height:
		_record_trail(old,old_height)

func _record_trail(old: Vector2,old_height: float) -> void:
	distance_walked += old.distance_to(cell)+absf(elevation-old_height)/48.0
	trail.append({"p":cell,"h":elevation,"surface":surface,"distance":distance_walked})
	var target := distance_walked-.7
	while trail.size()>2 and float(trail[1].distance)<target:trail.pop_front()
	if trail.size()>1:
		var a := trail[0]
		var b := trail[1]
		var t := clampf((target-float(a.distance))/maxf(.00001,float(b.distance)-float(a.distance)),0,1)
		follower = (a.p as Vector2).lerp(b.p,t)
		follower_height = lerpf(a.h,b.h,t)
		follower_surface = b.surface if t>.5 else a.surface

func _physics_process(delta: float) -> void:
	if paused or overview:return
	clock += delta
	var old := cell
	if not ladder.is_empty():_advance_ladder(delta)
	else:
		var input := Controls.direction()
		if input.length()>.1:
			var lattice := Vector2(input.x+2*input.y,-input.x+2*input.y).normalized()
			walk(lattice*SPEED*delta*minf(input.length(),1.0))
	avatar.moving = old.distance_to(cell)>.0001 or not ladder.is_empty()
	if avatar.moving and ladder.is_empty():
		var screen: Vector2 = world.iso(cell)-world.iso(old)
		avatar.face_motion(screen)
	_refresh_visuals()
	_update_hint()
	var look: Vector2 = (world.iso(cell)-world.iso(old))*8
	var target: Vector2 = player_root.position+look-Vector2(0,35)
	var half := get_viewport_rect().size/(2*camera.zoom)
	var box: Rect2 = depth.bounds.grow(130)
	camera.position = Vector2(clampf(target.x,box.position.x+half.x,box.end.x-half.x),clampf(target.y,box.position.y+half.y,box.end.y-half.y))

func _refresh_visuals() -> void:
	player_root.position = world.iso(cell,elevation)
	partner_root.position = world.iso(follower,follower_height)
	player_material.set_shader_parameter("ray_constant",(cell.x+cell.y)*48.0)
	partner_material.set_shader_parameter("ray_constant",(follower.x+follower.y)*48.0)
	player_material.set_shader_parameter("reveal_under_deck",surface=="underpass")
	partner_material.set_shader_parameter("reveal_under_deck",follower_surface=="underpass")
	var open_roof: bool = surface=="tower_upper" or (not ladder.is_empty() and elevation>230 and ladder.end_id=="tower_upper")
	player_material.set_shader_parameter("roof_cutaway",open_roof)
	partner_material.set_shader_parameter("roof_cutaway",open_roof)
	roof_opacity = lerpf(roof_opacity,.18 if open_roof else 1.0,1.0-exp(-10.0*get_physics_process_delta_time()))
	for node in roof_nodes:node.modulate.a = roof_opacity
	player_root.z_index = 10 if cell.x+cell.y>=follower.x+follower.y else 9
	partner_root.z_index = 9 if player_root.z_index==10 else 10
	if not partner_frames.is_empty():
		var f: Dictionary = partner_frames[int(clock*10)%partner_frames.size()]
		partner.region_rect = Rect2(f.x,f.y,f.w,f.h)
	partner.flip_h = avatar.facing in ["sw","nw"]
	var goal := _goal()
	var toward: Vector2 = world.iso(goal.p,goal.h)-player_root.position
	compass.text = ["→","↘","↓","↙","←","↖","↑","↗"][posmod(roundi(toward.angle()/(PI/4)),8)]

func _goal() -> Dictionary:
	if surface in ["peak","middle","cliff_landing"]:
		return {"p":Vector2(1.55,6.4) if surface=="cliff_landing" else Vector2(-.35,5.6),"h":elevation}
	if not visited.has("upper_hub"):return {"p":Vector2(7.75,8),"h":128.0}
	if not visited.has("tower_floor"):return {"p":Vector2(7.5,-.5),"h":192.0}
	if surface=="tower_upper":return {"p":Vector2(7,-1),"h":256.0}
	return {"p":Vector2(8.22,-.85),"h":192.0}

func _update_hint() -> void:
	nearest_ladder = {}
	for link in LADDER_LINKS:
		var anchor: Vector2 = link.bottom if surface==link.lower else link.top
		if surface in [link.lower,link.upper] and cell.distance_to(anchor)<.65:
			nearest_ladder = link
			break
	var interact := Controls.prompt("interact")
	if not ladder.is_empty():context.text = "Segure firme…"
	elif not nearest_ladder.is_empty():context.text = interact+" · "+("Subir" if surface==nearest_ladder.lower else "Descer")+" a escada de mão"
	elif surface=="tower_upper" and cell.distance_to(Vector2(7,-1))<.85 and not finished:context.text = interact+" · Contemplar o cais"
	elif finished:context.text = "Mirante alcançado · explore os patamares ou volte ao desembarque."
	else:context.text = "WASD / setas · caminhar     "+Controls.prompt("map")+" · ver o cais     Esc · pausa"
	objective.text = "Um fio até o horizonte" if not finished else "O horizonte é só o começo"
	progress_label.text = "Chegue ao mirante · atravesse os decks e a ponte." if not visited.has("tower_floor") else "Encontre a escada de mão e suba ao último andar." if not finished else "Travessia concluída · Kael e Rabbito chegaram juntos."

func interact() -> void:
	if paused or overview or not ladder.is_empty():return
	_update_hint()
	if not nearest_ladder.is_empty():
		var link := nearest_ladder
		var up: bool = surface==link.lower
		var end_id: String = link.upper if up else link.lower
		var end_point: Vector2 = link.top if up else link.bottom
		ladder = {"start":cell,"start_h":elevation,"end":end_point,"end_h":world.surface_height(world.find_surface(end_id),end_point),"end_id":end_id,"axis":link.axis,"up":up}
		ladder_time = 0
		avatar.facing = "nw" if up else "se"
		avatar.set_motion_action("subir" if up else "descer")
	elif surface=="tower_upper" and cell.distance_to(Vector2(7,-1))<.85:
		finished = true
		_update_hint()

func _advance_ladder(delta: float) -> void:
	ladder_time += delta
	var duration := .45+absf(ladder.end_h-ladder.start_h)/65.0
	var t := clampf(ladder_time/duration,0,1)
	var old := cell
	var old_h := elevation
	if t<.15:cell = (ladder.start as Vector2).lerp(ladder.axis,t/.15)
	elif t>.85:cell = (ladder.axis as Vector2).lerp(ladder.end,(t-.85)/.15)
	else:cell = ladder.axis
	elevation = lerpf(ladder.start_h,ladder.end_h,smoothstep(.12,.88,t))
	_record_trail(old,old_h)
	if t>=1:
		surface = ladder.end_id
		visited[surface] = true
		ladder = {}
		avatar.set_motion_action("")

func _unhandled_input(event: InputEvent) -> void:
	Controls.observe(event)
	if Controls.cancel(event):
		set_paused(not paused)
		get_viewport().set_input_as_handled()
	elif Controls.pressed(event,"map") and not paused:
		overview = not overview
		camera.zoom = Vector2.ONE*(.72 if overview else 1.55)
		if overview:camera.position = depth.bounds.get_center()
		context.text = Controls.prompt("map")+" · voltar à caminhada" if overview else ""
	elif Controls.pressed(event,"interact"):
		interact()

func set_paused(value: bool) -> void:
	paused = value
	pause_panel.visible = value
	avatar.set_process(not value)
	if value:resume_button.grab_focus()
	else:get_viewport().gui_release_focus()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	var theme := Theme.new()
	theme.default_font = Hud.font()
	theme.default_font_size = 19
	hud_root.theme = theme
	var panel := PanelContainer.new()
	panel.position = Vector2(22,20)
	panel.custom_minimum_size = Vector2(460,0)
	panel.add_theme_stylebox_override("panel",Hud.panel())
	hud_root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	panel.add_child(row)
	compass = Label.new()
	compass.add_theme_font_size_override("font_size",36)
	compass.add_theme_color_override("font_color",Hud.GOLD)
	row.add_child(compass)
	var text := VBoxContainer.new()
	row.add_child(text)
	var title := Label.new()
	title.text = "CAIS DOS ELOS"
	title.add_theme_color_override("font_color",Hud.MUTED)
	title.add_theme_font_size_override("font_size",14)
	text.add_child(title)
	objective = Label.new()
	objective.add_theme_color_override("font_color",Hud.PAPER)
	text.add_child(objective)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size",16)
	progress_label.add_theme_color_override("font_color",Hud.MUTED)
	text.add_child(progress_label)
	var footer := PanelContainer.new()
	hud_root.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 22
	footer.offset_right = -22
	footer.offset_top = -64
	footer.offset_bottom = -18
	footer.add_theme_stylebox_override("panel",Hud.panel())
	context = Label.new()
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context.add_theme_color_override("font_color",Hud.PAPER)
	footer.add_child(context)
	pause_panel = PanelContainer.new()
	hud_root.add_child(pause_panel)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -210
	pause_panel.offset_right = 210
	pause_panel.offset_top = -115
	pause_panel.offset_bottom = 115
	pause_panel.add_theme_stylebox_override("panel",Hud.panel())
	var choices := VBoxContainer.new()
	pause_panel.add_child(choices)
	var pause_title := Label.new()
	pause_title.text = "Uma pausa no cais"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_color_override("font_color",Hud.PAPER)
	choices.add_child(pause_title)
	resume_button = Button.new()
	resume_button.text = "Continuar"
	Hud.secondary_button(resume_button)
	resume_button.pressed.connect(func():set_paused(false))
	choices.add_child(resume_button)
	var restart := Button.new()
	restart.text = "Recomeçar a travessia"
	Hud.secondary_button(restart)
	restart.pressed.connect(func():get_tree().reload_current_scene())
	choices.add_child(restart)
	var exit_button := Button.new()
	exit_button.text = "Fechar prévia"
	Hud.secondary_button(exit_button)
	exit_button.pressed.connect(func():get_tree().quit())
	choices.add_child(exit_button)
	pause_panel.hide()
