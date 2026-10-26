extends Node2D
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
## Pixel coordinates refer directly to the approved 1536x1024 clean plate.
## Separate experimental slice: no connection to the JS game's save/economy.
const Avatar = preload("res://scripts/avatar.gd")
const PLATE = preload("res://assets/illustrated/veredas-clean.png")
const Ground = preload("res://scripts/illustrated_ground.gd")
const TreeScene = preload("res://scenes/illustrated_tree.tscn")
const STEP := 4
var ground_material: ShaderMaterial
var separated_trees: Array[Node2D] = []
var ground: RefCounted
var data: Dictionary
var navigation := AStar2D.new()
var cells: Dictionary = {}
var actors: Node2D
var avatar: Node2D
var companion: Sprite2D
var nina: Sprite2D
var camera: Camera2D
var player := Vector2(224,810)
var follower := Vector2(190,826)
var route := PackedVector2Array()
var trail: Array[Vector2] = []
var companion_frames: Array[Rect2] = []
var clock := 0.0
var modal: PanelContainer
var speech: Label
var hint: Label
var opened := false
var paused := false
var overview := false
var debug_routes := false
var chest: Sprite2D

func _ready() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/illustrated/routes-v2.json"))
	ground=Ground.new(data)
	ground_material=ShaderMaterial.new()
	ground_material.shader=preload("res://shaders/ground_patch.gdshader")
	ground_material.set_shader_parameter("corrected_plate",preload("res://assets/illustrated/tree-test/ground-without-tree.png"))
	ground_material.set_shader_parameter("patch_uv",Vector4(300.0/1536,405.0/1024,540.0/1536,655.0/1024))
	var background:=Sprite2D.new()
	background.texture=PLATE
	background.centered=false
	background.show_behind_parent=true
	background.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	background.material=ground_material
	add_child(background)
	_build_navigation()
	trail.assign(_path(follower,player))
	actors=Node2D.new()
	actors.y_sort_enabled=true
	add_child(actors)
	avatar=Avatar.new()
	actors.add_child(avatar)
	avatar.scale=Vector2.ONE*.62
	companion=Sprite2D.new()
	companion.texture=preload("res://assets/rabbito.png")
	companion.region_enabled=true
	companion.offset=Vector2(0,-100)
	companion.scale=Vector2.ONE*.22
	actors.add_child(companion)
	var atlas: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rabbito.json"))
	for frame_name in atlas.animations.idle:
		var frame: Dictionary=atlas.frames[frame_name].frame
		companion_frames.append(Rect2(frame.x,frame.y,frame.w,frame.h))
	nina=Sprite2D.new()
	nina.texture=preload("res://assets/nina.png")
	nina.scale=Vector2.ONE*.047
	nina.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	nina.offset=Vector2(-18,-712)
	nina.position=Vector2(data.nina[0],data.nina[1])
	actors.add_child(nina)
	chest=Sprite2D.new()
	chest.texture=preload("res://assets/chest.png")
	chest.scale=Vector2.ONE*.12
	chest.offset=Vector2(0,-115)
	chest.position=Vector2(1040,775)
	actors.add_child(chest)
	for entry in data.separated_trees:
		var tree:=TreeScene.instantiate()
		tree.name=entry.id
		tree.position=Vector2(entry.position[0],entry.position[1])
		tree.root_offset=Vector2(entry.root_offset[0],entry.root_offset[1])
		tree.root_radius=Vector2(entry.root_radius[0],entry.root_radius[1])
		actors.add_child(tree)
		separated_trees.append(tree)
	# Reproject selected foreground contours from the unchanged plate; no new raster art.
	for mask in data.foreground:
		var tree:=Node2D.new()
		tree.name=mask.name
		tree.position.y=float(mask.baseline)
		actors.add_child(tree)
		var polygon:=Polygon2D.new()
		var vertices:=PackedVector2Array()
		var uv:=PackedVector2Array()
		for point in mask.points:
			uv.append(Vector2(point[0],point[1]))
			vertices.append(Vector2(point[0],point[1]-float(mask.baseline)))
		polygon.polygon=vertices
		polygon.uv=uv
		polygon.texture=PLATE
		polygon.material=ground_material
		# This adjacent tree was also changed by generation outside the requested target.
		# Keep its original foreground art, including its roots along the patch boundary.
		if mask.name=="Arvore junto ao mato": polygon.material=null
		polygon.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		tree.add_child(polygon)
	camera=Camera2D.new()
	camera.zoom=Vector2.ONE*1.6
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=8.0
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=1536
	camera.limit_bottom=1024
	add_child(camera)
	_build_ui()
	_refresh_positions()
	camera.position=player
	camera.reset_smoothing()
	if "--smoke" in OS.get_cmdline_user_args():
		call_deferred("_smoke")
	if "--proof" in OS.get_cmdline_user_args():
		call_deferred("_proof")

func walkable(point: Vector2) -> bool:
	return ground.walkable(point)

func _build_navigation() -> void:
	for y in range(0,1024,STEP):
		for x in range(0,1536,STEP):
			var p:=Vector2(x,y)
			if ground.walkable(p,1.5):
				var id:=navigation.get_available_point_id()
				cells[Vector2i(x/STEP,y/STEP)]=id
				navigation.add_point(id,p)
	for cell: Vector2i in cells:
		for offset in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i(1,1),Vector2i(-1,1)]:
			var neighbor: Vector2i=cell+offset
			if not cells.has(neighbor):
				continue
			if offset.x!=0 and offset.y!=0 and (not cells.has(cell+Vector2i(offset.x,0)) or not cells.has(cell+Vector2i(0,offset.y))):
				continue
			if ground.clear_segment(navigation.get_point_position(cells[cell]),navigation.get_point_position(cells[neighbor]),1.5):
				navigation.connect_points(cells[cell],cells[neighbor])

func _path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not walkable(to):
		return PackedVector2Array()
	var start:=navigation.get_closest_point(from)
	var end:=navigation.get_closest_point(to)
	if not ground.clear_segment(from,navigation.get_point_position(start)) or not ground.clear_segment(navigation.get_point_position(end),to):
		return PackedVector2Array()
	var result:=navigation.get_point_path(start,end)
	if result.is_empty(): return result
	result.append(to)
	var smooth:=PackedVector2Array([result[0]])
	var anchor:=result[0]
	var index:=1
	while index<result.size():
		var next:=mini(index+48,result.size()-1)
		while next>index and not ground.clear_segment(anchor,result[next],1.0): next-=1
		smooth.append(result[next])
		anchor=result[next]
		index=next+1
	if "--smoke" in OS.get_cmdline_user_args():
		var previous:=from
		for point in smooth:
			if not ground.clear_segment(previous,point): print("UNSAFE_ROUTE ",previous," -> ",point)
			previous=point
	return smooth

func _physics_process(delta: float) -> void:
	clock+=delta
	if modal.visible or paused:
		avatar.moving=false
		return
	var direction := _movement_direction()
	var before:=player
	if direction.length()>.1:
		route.clear()
		_move(direction.limit_length()*145*delta)
	elif not route.is_empty():
		_follow_route(145*delta)
	var displacement:=player-before
	avatar.moving=displacement.length()>.01
	if avatar.moving:
		avatar.facing=("n" if displacement.y<0 else "s")+("w" if displacement.x<0 else "e")
		_follow_companion(145*delta)
	_refresh_positions()
	if not overview:
		camera.position=player
	hint.text="E · Conversar com Nina" if player.distance_to(nina.position)<65 else ("E · Abrir baú" if not opened and player.distance_to(chest.position)<50 else "")

func _move(motion: Vector2) -> void:
	var count:=maxi(1,int(ceil(motion.length()/2.0)))
	var step:=motion/count
	for i in count:
		player=ground.slide_step(player,step)
		if trail.is_empty() or trail.back().distance_to(player)>=1.5:
			trail.append(player)

func _follow_route(budget: float) -> void:
	# Consume the whole frame's travel budget, including several tiny waypoints.
	# The former one-waypoint-per-frame loop paused at every cell of the AStar grid.
	while budget>.001 and not route.is_empty():
		var distance:=player.distance_to(route[0])
		if distance<.01:
			route.remove_at(0)
			continue
		var amount:=minf(budget,distance)
		var before:=player
		_move(player.direction_to(route[0])*amount)
		budget-=amount
		if player.distance_to(before)<.001:
			if "--smoke" in OS.get_cmdline_user_args():
				print("ROUTE_STALL ",player," target=",route[0]," clear=",ground.clear_segment(player,route[0])," endpoint=",walkable(route[0]))
			route.clear()
			break

func _follow_companion(budget: float) -> void:
	# Replay the player's actual footsteps. Never draw a straight chord across roots.
	var remaining:=0.0
	var previous:=follower
	for point in trail:
		remaining+=previous.distance_to(point)
		previous=point
	budget=minf(budget,maxf(0,remaining-32))
	while budget>.001 and not trail.is_empty():
		var target:=trail[0]
		var distance:=follower.distance_to(target)
		if distance<.01:
			trail.pop_front()
			continue
		var amount:=minf(budget,distance)
		var next:=follower.move_toward(target,amount)
		if not ground.clear_segment(follower,next): break
		follower=next
		budget-=amount

func _refresh_positions() -> void:
	avatar.position=player
	companion.position=follower
	if not companion_frames.is_empty():
		companion.region_rect=companion_frames[int(clock*8)%companion_frames.size()]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E, KEY_ENTER: _interact()
			KEY_ESCAPE:
				if modal.visible: modal.hide()
				else: paused=not paused
				get_node("UI/Layout/Title").text="PAUSADO · Esc para continuar" if paused else "VEREDAS DO ENCANTAMENTO"
			KEY_M: _overview()
			KEY_F3:
				debug_routes=not debug_routes
				queue_redraw()
			KEY_F4:
				for tree in separated_trees: tree.visible=not tree.visible
	if event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_A:
		_interact()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not modal.visible and not paused:
		route=_path(player,get_global_mouse_position())

func _interact() -> void:
	if paused: return
	if modal.visible:
		modal.hide()
		return
	if player.distance_to(nina.position)<65:
		speech.text="Nina\nEu achei que conseguiria passar pelos canos… Meu Carcará ficou lá em cima."
		modal.show()
	elif not opened and player.distance_to(chest.position)<50:
		opened=true
		chest.hide()
		speech.text="Baú encontrado\nVocê encontrou o esconderijo da margem!\nNeste trecho de teste, a coleta não altera seu inventário do jogo."
		modal.show()

func _overview() -> void:
	# Map is the actual scene, without a second illustration or revealed markers.
	overview=not overview
	camera.zoom=Vector2.ONE*(.70 if overview else 1.6)
	camera.position=Vector2(768,512) if overview else player
	camera.reset_smoothing()

func _build_ui() -> void:
	var ui:=CanvasLayer.new()
	ui.name="UI"
	add_child(ui)
	var layout:=VBoxContainer.new()
	layout.name="Layout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left=24
	layout.offset_top=18
	layout.offset_right=-24
	layout.offset_bottom=-18
	layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(layout)
	var title:=Label.new()
	title.name="Title"
	title.text="VEREDAS DO ENCANTAMENTO"
	title.add_theme_font_size_override("font_size",20)
	layout.add_child(title)
	var detail:=Label.new()
	detail.text="Protótipo ilustrado · exploração das Veredas"
	layout.add_child(detail)
	var row:=HBoxContainer.new()
	layout.add_child(row)
	for destination in [["Entrada",Vector2(224,810)],["Árvore",Vector2(420,668)],["Ponte norte",Vector2(588,456)],["Nina",Vector2(824,480)],["Ponte sul",Vector2(866,834)],["Mirante",Vector2(300,115)],["Pátio",Vector2(1300,154)]]:
		var button:=Button.new()
		button.text=destination[0]
		var target: Vector2=destination[1]
		button.pressed.connect(func() -> void:
			player=target
			follower=target
			trail.clear()
			route.clear()
			modal.hide()
			_refresh_positions()
			camera.position=player
			camera.reset_smoothing())
		row.add_child(button)
	var spacer:=Control.new()
	spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	modal=PanelContainer.new()
	var style:=StyleBoxFlat.new()
	style.bg_color=Tokens.PAPEL
	style.border_color=Tokens.NANQUIM
	style.set_border_width_all(3)
	style.content_margin_left=24
	style.content_margin_top=16
	style.content_margin_bottom=16
	modal.add_theme_stylebox_override("panel",style)
	layout.add_child(modal)
	speech=Label.new()
	speech.add_theme_color_override("font_color",Tokens.TINTA)
	speech.add_theme_font_size_override("font_size",22)
	modal.add_child(speech)
	modal.hide()
	hint=Label.new()
	layout.add_child(hint)
	var controls:=Label.new()
	controls.text="WASD / setas: andar · clique: caminhar · E: interagir · M: visão geral · Esc: pausa · F3: caminhos"
	layout.add_child(controls)

func _draw() -> void:
	if debug_routes:
		for polygon in ground.floors:
			draw_colored_polygon(polygon,Tokens.alpha(Tokens.FOLHA, .30))
		for polygon in ground.obstacles:
			draw_colored_polygon(polygon,Tokens.alpha(Tokens.RABIOLA, .65))
		for landmark in data.landmarks:
			var point:=Vector2(landmark.point[0],landmark.point[1])
			draw_circle(point,6,Tokens.UNTINTED)
			draw_string(ThemeDB.fallback_font,point+Vector2(8,-8),landmark.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Tokens.UNTINTED)

func _smoke() -> void:
	var failures: Array[String]=[]
	if separated_trees.size()!=1: failures.append("Expected one independently separated tree")
	for tree in separated_trees:
		var image: Image=tree.texture.get_image()
		if image.get_pixel(0,0).a>0 or image.get_pixel(image.get_width()-1,image.get_height()-1).a>0:
			failures.append("Tree transparency missing")
		if tree.alpha_bounds.size.x<100 or tree.alpha_bounds.size.y<100:
			failures.append("Tree art is empty or mis-scaled")
		var root: Vector2=tree.position+tree.root_offset
		if walkable(root): failures.append("Separated tree roots are not solid")
		if tree.get_node_or_null("Roots")==null: failures.append("Native root collider missing")
	for mask in data.foreground:
		if mask.name=="Copa oeste": failures.append("Legacy cutout still covers the separated tree")
	for point in [Vector2(420,590),Vector2(420,668),Vector2(365,635),Vector2(475,635)]:
		if _path(Vector2(224,810),point).is_empty(): failures.append("Tree cannot be circled at "+str(point))
	for landmark in data.landmarks:
		var target:=Vector2(landmark.point[0],landmark.point[1])
		if not walkable(target):
			failures.append("Landmark blocked: "+landmark.name)
			continue
		var outward:=_path(Vector2(224,810),target)
		var backward:=_path(target,Vector2(224,810))
		if outward.is_empty() or backward.is_empty():
			failures.append("Disconnected: "+landmark.name)
			continue
		for i in range(1,outward.size()):
			if not ground.clear_segment(outward[i-1],outward[i]):
				failures.append("Unsafe segment: "+landmark.name)
	for point in data.blocked_checks:
		if walkable(Vector2(point[0],point[1])):
			failures.append("Obstacle admits feet: "+str(point))
	# Exercise the fixed-frame click controller and breadcrumb follower along real routes.
	player=Vector2(224,810)
	follower=player
	trail.clear()
	for target in [Vector2(824,480),Vector2(866,834),Vector2(224,810),Vector2(300,115),Vector2(1300,154),Vector2(224,810)]:
		route=_path(player,target)
		if route.is_empty():
			failures.append("No traversal route to "+str(target))
			continue
		var frames:=0
		while not route.is_empty() and frames<6000:
			_follow_route(145.0/60)
			_follow_companion(145.0/60)
			if not walkable(player) or not walkable(follower):
				failures.append("Actor left support during traversal")
				break
			frames+=1
		if player.distance_to(target)>1:
			failures.append("Click movement stalled at "+str(player)+" toward "+str(target))
		if follower.distance_to(player)>50:
			failures.append("Companion stuck at "+str(follower))
	# Continuous input speed must be preserved across several short AStar cells.
	player=Vector2(210,810)
	follower=player
	trail.clear()
	route=_path(player,Vector2(240,800))
	var before:=player
	_follow_route(145.0/60)
	if player.distance_to(before)<2.0: failures.append("Click controller wasted its frame budget")
	player=Vector2(824,480)
	_interact()
	if not modal.visible: failures.append("Nina interaction broke")
	modal.hide()
	player=Vector2(1040,775)
	_interact()
	if not opened: failures.append("Chest interaction broke")
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("ILLUSTRATED_GROUND_OK: ten landmarks both directions, roots/rocks/water/cliffs, fixed-frame full traversal, follower and click speed")
	get_tree().quit(0 if failures.is_empty() else 1)

func _proof() -> void:
	if "--tree-tour" in OS.get_cmdline_user_args():
		paused=true
		camera.position=Vector2(420,590)
		camera.reset_smoothing()
		for sample in [["front",Vector2(420,668)],["back",Vector2(420,590)],["left",Vector2(365,635)],["right",Vector2(475,635)]]:
			player=sample[1]
			follower=player-Vector2(28,0)
			_refresh_positions()
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://proof-tree-"+sample[0]+".png")
		for tree in separated_trees: tree.hide()
		avatar.hide()
		companion.hide()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://proof-tree-ground.png")
		get_tree().quit(0)
		return
	if "--overview" in OS.get_cmdline_user_args(): _overview()
	if "--debug-ground" in OS.get_cmdline_user_args():
		debug_routes=true
		queue_redraw()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--at="):
			var coordinates:=argument.trim_prefix("--at=").split(",")
			player=Vector2(float(coordinates[0]),float(coordinates[1]))
			follower=player
			_refresh_positions()
			camera.position=player
			camera.reset_smoothing()
	if "--nina" in OS.get_cmdline_user_args():
		player=Vector2(824,520)
		follower=Vector2(786,523)
		_refresh_positions()
		camera.position=player
		camera.reset_smoothing()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://proof-illustrated.png")
	get_tree().quit(0)

func _movement_direction() -> Vector2:
	var direction:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if not Input.get_connected_joypads().is_empty():
		var device: int=Input.get_connected_joypads()[0]
		var stick:=Vector2(Input.get_joy_axis(device,JOY_AXIS_LEFT_X),Input.get_joy_axis(device,JOY_AXIS_LEFT_Y))
		if stick.length()>.2:
			direction=stick
	return direction
