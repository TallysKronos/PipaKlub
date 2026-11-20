extends Node2D
## Independent lakeside fixture using the production Kael actor, without save operations.
const KIT="res://assets/overworld/kits/mormaco-cel-pixel-pilot/"
const Avatar=preload("res://scripts/kael_video_avatar.gd")
const Pixel=preload("res://scripts/pixelgen_sprites.gd")
const STEP=16.0
var data:Dictionary
var ground:=PackedVector2Array()
var water:=PackedVector2Array()
var raised:Array[PackedVector2Array]=[]
var colliders:Array=[]
var actors:Node2D
var player_root:Node2D
var avatar:Node2D
var camera:Camera2D
var boss:Sprite2D
var age:=0.0
var player:=Vector2.ZERO
var path:=PackedVector2Array()
var grid:=AStarGrid2D.new()
var overview:=false
var paused:=false
var hint:Label
var navigation_ready:=false

class LakeLife extends Node2D:
	var clock:=0.0
	func _process(delta:float)->void:
		clock+=delta
		queue_redraw()
	func _draw()->void:
		var t:float=floorf(clock*10.0)/10.0
		# The submerged animation already contains the wake at the waterline.
		for jet in 2:
			for i in 6:
				var phase:float=fmod(t*.40+i/6.0+jet*.31,1.0)
				var p:=Vector2(-43+jet*58+sin(i*2.3+t)*phase*14,-190-phase*37).round()
				var size:float=2+floorf(phase*3)
				draw_rect(Rect2(p,Vector2(size*2,size)),Color(.75,.91,.94,(1-phase)*.66))

func polygon(raw:Array)->PackedVector2Array:
	var points:=PackedVector2Array()
	for p in raw:points.append(Vector2(p[0],p[1]))
	return points

func _ready()->void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	data=JSON.parse_string(FileAccess.get_file_as_string(KIT+"kit.json"))
	ground=polygon(data.navigation.ground)
	water=polygon(data.navigation.water)
	for p in data.navigation.raised:raised.append(polygon(p))
	colliders=data.colliders
	actors=Node2D.new()
	actors.y_sort_enabled=true
	add_child(actors)
	preload("res://scripts/overworld/mormaco_cel_layers.gd").build(actors,data,Vector2.ZERO)
	boss=Sprite2D.new()
	boss.texture=Pixel.load_texture("res://assets/campaign/mormaco-v1/submerged.png")
	boss.region_enabled=true
	boss.region_filter_clip_enabled=true
	boss.region_rect=Rect2(0,0,320,320)
	boss.position=Vector2(1760,938)
	boss.scale=Vector2.ONE*1.3
	boss.offset=Vector2(0,-142)
	actors.add_child(boss)
	var ambient:=LakeLife.new()
	ambient.position=boss.position
	actors.add_child(ambient)
	player_root=Node2D.new()
	player_root.name="Kael"
	actors.add_child(player_root)
	var shadow:=Polygon2D.new()
	var shadow_points:=PackedVector2Array()
	for i in 16:shadow_points.append(Vector2(cos(i*TAU/16.0)*12,sin(i*TAU/16.0)*4))
	shadow.polygon=shadow_points
	shadow.color=Color(0.05,.10,.14,.26)
	player_root.add_child(shadow)
	avatar=Avatar.new()
	player_root.add_child(avatar)
	player=Vector2(1300,1080)
	camera=Camera2D.new()
	camera.position_smoothing_enabled=false
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=int(data.size[0])
	camera.limit_bottom=int(data.size[1])
	add_child(camera)
	_build_hud()
	_build_navigation()
	player=nearest_walkable(player)
	refresh_visuals()
	DisplayServer.window_set_title("Soulmonsters · Lago do Mormaço — cel + pixel")
	for action in ["pilot_left","pilot_right","pilot_up","pilot_down","pilot_run"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
	var bindings:Dictionary={"pilot_left":[KEY_A,KEY_LEFT],"pilot_right":[KEY_D,KEY_RIGHT],"pilot_up":[KEY_W,KEY_UP],"pilot_down":[KEY_S,KEY_DOWN],"pilot_run":[KEY_SHIFT]}
	for action:String in bindings:
		for key:int in bindings[action]:
			var event:=InputEventKey.new()
			event.physical_keycode=key
			InputMap.action_add_event(action,event)

func _build_hud()->void:
	var canvas:=CanvasLayer.new()
	add_child(canvas)
	var panel:=PanelContainer.new()
	panel.position=Vector2(20,18)
	var box:=StyleBoxFlat.new()
	box.bg_color=Color("10263a")
	box.border_color=Color("36b9df")
	box.set_border_width_all(1)
	box.content_margin_left=16
	box.content_margin_right=16
	box.content_margin_top=9
	box.content_margin_bottom=9
	panel.add_theme_stylebox_override("panel",box)
	canvas.add_child(panel)
	var label:=Label.new()
	label.text="LAGO DO MORMAÇO  ·  Margem do lago"
	label.add_theme_font_size_override("font_size",18)
	panel.add_child(label)
	hint=Label.new()
	hint.text="WASD / setas · mover    Shift · correr    Clique · caminhar    F2 · visão geral    Esc · sair"
	hint.position=Vector2(23,61)
	hint.add_theme_font_size_override("font_size",14)
	hint.add_theme_color_override("font_shadow_color",Color("071625"))
	hint.add_theme_constant_override("shadow_offset_x",1)
	hint.add_theme_constant_override("shadow_offset_y",1)
	canvas.add_child(hint)

func point_walkable(point:Vector2)->bool:
	if not Geometry2D.is_point_in_polygon(point,ground):return false
	if Geometry2D.is_point_in_polygon(point,water):return false
	for p in raised:
		if Geometry2D.is_point_in_polygon(point,p):return false
	for c:Dictionary in colliders:
		if c.kind=="fence":
			var segment:Array=c.segment
			var a:=Vector2(segment[0][0],segment[0][1])
			var b:=Vector2(segment[1][0],segment[1][1])
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))<10:return false
			continue
		var center:=Vector2(c.at[0],c.at[1])
		if point.distance_squared_to(center)<pow(float(c.radius)+5.0,2):return false
	return true

func walkable(point:Vector2)->bool:
	for offset in [Vector2.ZERO,Vector2(-7,0),Vector2(7,0),Vector2(0,-4),Vector2(0,4)]:
		if not point_walkable(point+offset):return false
	return true

func _build_navigation()->void:
	grid.region=Rect2i(0,0,ceili(float(data.size[0])/STEP),ceili(float(data.size[1])/STEP))
	grid.cell_size=Vector2.ONE*STEP
	grid.offset=Vector2.ONE*STEP*.5
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			grid.set_point_solid(Vector2i(x,y),not walkable(Vector2(x+.5,y+.5)*STEP))
	navigation_ready=true

func nearest_walkable(point:Vector2)->Vector2:
	var cell:=Vector2i(point/STEP)
	for radius in 12:
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var at:=cell+Vector2i(x,y)
				if grid.is_in_boundsv(at) and not grid.is_point_solid(at):return grid.get_point_position(at)
	return player

func walk_to(point:Vector2)->bool:
	var target:=nearest_walkable(point)
	path=grid.get_point_path(Vector2i(player/STEP),Vector2i(target/STEP))
	if not path.is_empty() and player.distance_to(path[0])<STEP:path.remove_at(0)
	return not path.is_empty()

func move_player(displacement:Vector2)->void:
	var steps:int=maxi(1,ceili(displacement.length()/3.0))
	var step:Vector2=displacement/steps
	for i in steps:
		if walkable(player+step):player+=step
		elif walkable(player+Vector2(step.x,0)):player.x+=step.x
		elif walkable(player+Vector2(0,step.y)):player.y+=step.y

func _physics_process(delta:float)->void:
	if not navigation_ready or paused:return
	var direction:=Input.get_vector("pilot_left","pilot_right","pilot_up","pilot_down")
	if direction.length_squared()>.01:path.clear()
	elif not path.is_empty():
		if player.distance_to(path[0])<3:path.remove_at(0)
		if not path.is_empty():direction=(path[0]-player).normalized()
	var before:=player
	var running:=Input.is_action_pressed("pilot_run")
	move_player(direction*(160.0 if running else 98.0)*delta)
	avatar.moving=player.distance_squared_to(before)>.001
	avatar.running=running
	if avatar.moving:avatar.face_motion(player-before)
	refresh_visuals()

func refresh_visuals()->void:
	player_root.position=player.round()
	if overview:
		camera.zoom=Vector2.ONE*.38
		camera.position=Vector2(data.size[0],data.size[1])*.5
	else:
		camera.zoom=Vector2.ONE
		camera.position=(player+Vector2(0,-90)).round()

func _process(delta:float)->void:
	if paused:return
	age+=delta
	var frame:int=int(age*3.0)%4
	boss.region_rect=Rect2(frame*320,0,320,320)

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:get_tree().quit()
		if event.keycode==KEY_F2:
			overview=not overview
			refresh_visuals()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		walk_to(get_global_mouse_position())
