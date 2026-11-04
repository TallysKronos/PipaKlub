extends Node2D
## One-shot opening film over the preserved bedroom, with a legacy broadcast fallback.
const Hud=preload("res://scripts/campaign/hud.gd")
signal handoff_requested
var content: Dictionary
var clock := 0.0
var fighters: Array[Sprite2D]=[]
var movie:VideoStreamPlayer
var border_panel:Polygon2D
var cinematic_handoff:=false
var finish_requested:=false
var cinematic_paused:=false
var skip_button:Button
var error_label:Label
const MOVIE_PATH:="res://assets/campaign/cinematics/pipa-tv-abertura-v4.ogv"
const LEGACY_MOVIE_PATH:="res://assets/campaign/cinematics/pipa-tv-abertura-v2.ogv"
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	cinematic_handoff=ResourceLoader.exists(MOVIE_PATH)
	if cinematic_handoff or ResourceLoader.exists(LEGACY_MOVIE_PATH):
		_start_movie()
		return
	position=Vector2(28,30)
	z_index=100
	var border:=Polygon2D.new()
	border.polygon=PackedVector2Array([Vector2(-3,-3),Vector2(349,-3),Vector2(349,235),Vector2(-3,235)])
	border.color=Hud.INK
	add_child(border)
	var screen:=Node2D.new()
	screen.scale=Vector2.ONE*.36
	add_child(screen)
	var backdrop:=Sprite2D.new()
	backdrop.texture=load("res://assets/campaign/broadcast-background.png")
	backdrop.centered=false
	backdrop.modulate=Color(.68,.74,.82,1)
	backdrop.scale=Vector2(960,640)/backdrop.texture.get_size()
	screen.add_child(backdrop)
	for i in range(2):
		var sprite:=Sprite2D.new()
		sprite.texture=load("res://assets/campaign/"+str(content.broadcast[i].image))
		sprite.region_enabled=true
		sprite.scale=Vector2(-1.6 if i==1 else 1.6,1.6)
		screen.add_child(sprite);fighters.append(sprite)
	var caption:=Label.new()
	caption.text="PIPA TV · AO VIVO"
	caption.position=Vector2(10,8)
	caption.add_theme_font_override("font",Hud.font(true))
	caption.add_theme_font_size_override("font_size",18)
	caption.add_theme_color_override("font_color",Hud.PAPER)
	caption.add_theme_color_override("font_outline_color",Hud.INK)
	caption.add_theme_constant_override("outline_size",4)
	add_child(caption)

func _start_movie()->void:
	# The native room survives underneath and returns after the film-to-room handoff.
	set_as_top_level(true)
	z_index=100
	border_panel=Polygon2D.new()
	border_panel.color=Hud.INK
	add_child(border_panel)
	movie=VideoStreamPlayer.new()
	movie.expand=true
	movie.stream=load(MOVIE_PATH if cinematic_handoff else LEGACY_MOVIE_PATH)
	movie.volume_db=-9
	movie.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(movie)
	movie.finished.connect(func():
		if not visible:return
		if cinematic_handoff:request_handoff()
		else:movie.play())
	if cinematic_handoff:
		skip_button=Button.new()
		skip_button.text="Pular abertura"
		Hud.navigation_button(skip_button,true,"back")
		skip_button.pressed.connect(request_handoff)
		add_child(skip_button)
		error_label=Label.new()
		error_label.add_theme_font_size_override("font_size",18)
		error_label.add_theme_color_override("font_color",Hud.PAPER)
		error_label.add_theme_color_override("font_outline_color",Hud.INK)
		error_label.add_theme_constant_override("outline_size",4)
		error_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		add_child(error_label)
		Hud.focus_later(skip_button)
	get_viewport().size_changed.connect(_layout_movie)
	_layout_movie()
	movie.play()

func _layout_movie()->void:
	var viewport_size:=get_viewport_rect().size
	var width:=minf(viewport_size.x,viewport_size.y*16.0/9.0) if cinematic_handoff else minf(viewport_size.x*.92,viewport_size.y*.62*16.0/9.0)
	var extent:=Vector2(width,width*9.0/16.0)
	position=(viewport_size-extent)*.5 if cinematic_handoff else Vector2((viewport_size.x-width)*.5,12)
	movie.size=extent
	if cinematic_handoff:
		border_panel.color=Color.BLACK
		border_panel.polygon=PackedVector2Array([-position,Vector2(viewport_size.x,0)-position,viewport_size-position,Vector2(0,viewport_size.y)-position])
		skip_button.size=Vector2(minf(240,width-48),48)
		skip_button.position=extent-skip_button.size-Vector2(24,24)
		error_label.position=Vector2(24,extent.y-76)
		error_label.size=Vector2(maxf(80,width-skip_button.size.x-80),60)
	else:
		border_panel.polygon=PackedVector2Array([Vector2(-4,-4),Vector2(extent.x+4,-4),extent+Vector2(4,4),Vector2(-4,extent.y+4)])

func request_handoff()->void:
	if not cinematic_handoff or finish_requested or cinematic_paused:return
	finish_requested=true
	movie.paused=true
	skip_button.disabled=true
	handoff_requested.emit()

func handoff_failed(message:String)->void:
	finish_requested=false
	error_label.text=message
	skip_button.text="Tentar continuar"
	skip_button.disabled=false
	Hud.focus_later(skip_button)

func set_cinematic_paused(value:bool)->void:
	cinematic_paused=value
	set_process(not value)
	if is_instance_valid(movie):movie.paused=value or finish_requested
	if is_instance_valid(skip_button):
		skip_button.disabled=value or finish_requested
		if not skip_button.disabled:Hud.focus_later(skip_button)

func stop_broadcast()->void:
	if is_instance_valid(movie):movie.stop()
	set_process(false)

func _process(delta: float) -> void:
	if is_instance_valid(movie):return
	clock+=delta
	for i in fighters.size():
		var frames: Array=content.broadcast[i].frames
		var frame: Dictionary=frames[int(clock*12)%frames.size()]
		fighters[i].region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
		fighters[i].position=Vector2(300+350*i+sin(clock*1.7+i)*35,280+sin(clock*2+i)*20)
