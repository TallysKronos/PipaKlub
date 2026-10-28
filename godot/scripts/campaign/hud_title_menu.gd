extends Control
## Illustrated background and live native navigation; artwork never contains buttons.
signal selected(id:String)
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/recorte_ink.gd")
var mode:="main"
var has_saves:=false
var reduced_motion:=false
var column:VBoxContainer
var first:Button
var start_label:Label
var age:=0.0
var background:Texture2D
var logo:Texture2D
static var _art_cache:Dictionary={}
static func artwork(path:String) -> Texture2D:
	if _art_cache.has(path):return _art_cache[path]
	if ResourceLoader.exists(path) and (FileAccess.file_exists(path+".import") or OS.has_feature("standalone")):
		_art_cache[path]=load(path)
		return _art_cache[path]
	var image:=Image.load_from_file(ProjectSettings.globalize_path(path))
	_art_cache[path]=ImageTexture.create_from_image(image)
	return _art_cache[path]
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	background=artwork("res://assets/campaign/title-v1/neighborhood-starters-soulgen-v4.png")
	logo=artwork("res://assets/campaign/title-v1/logo.png")
	column=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	add_child(column)
	if mode=="title":
		first=_button("PRESSIONE START","start",0)
		first.add_theme_font_size_override("font_size",28)
	elif mode=="main":
		var index:=0
		for option in [["CONTINUAR","continue"],["NOVA JORNADA","new"],["CONFIGURAÇÕES","settings"],["SAIR","quit"]]:
			var button:=_button(option[0],option[1],index)
			button.disabled=option[1]=="continue" and not has_saves
			if first==null and not button.disabled:first=button
			index+=1
	resized.connect(_layout)
	_layout()
	if first!=null:Hud.focus_later(first)
func _button(text:String,id:String,index:int) -> Button:
	var margin:=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",index*18)
	margin.add_theme_constant_override("margin_right",60-index*18)
	column.add_child(margin)
	var button:=Button.new()
	button.text=text
	Hud.navigation_button(button,true)
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y=60
	button.pressed.connect(func():selected.emit(id))
	margin.add_child(button)
	return button
func _layout() -> void:
	column.position=Vector2(size.x*.065,size.y*.43 if mode!="title" else size.y*.72)
	column.size=Vector2(minf(480,size.x*.43),0)
	queue_redraw()
func _process(delta:float) -> void:
	age+=delta
	if mode=="title" and first!=null:first.modulate.a=1 if reduced_motion else .65+.35*cos(age*TAU)
func _draw() -> void:
	if background==null:return
	var factor:=maxf(size.x/background.get_width(),size.y/background.get_height())
	draw_texture_rect(background,Rect2((size-background.get_size()*factor)/2,background.get_size()*factor),false)
	if mode=="slots":
		draw_rect(Rect2(Vector2.ZERO,size),Color(Hud.INK,.94))
		return
	if mode!="title":
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(size.x*.55,0),Vector2(size.x*.42,size.y),Vector2(0,size.y)]),Color(Hud.INK,.96))
		draw_line(Vector2(size.x*.55,0),Vector2(size.x*.42,size.y),Hud.CYAN,4,true)
	var logo_rect:=Rect2(size.x*.06,size.y*.08,size.x*.52,size.y*.27)
	if mode=="title":logo_rect=Rect2(size.x*.12,size.y*.1,size.x*.76,size.y*.33)
	draw_texture_rect(Ink.texture("medium-1"),Rect2(logo_rect.position+Vector2(-20,20),Vector2(150,90)),false,Color(Hud.CYAN,.65))
	draw_texture_rect(logo,Hud.fit_texture(logo,logo_rect),false)
