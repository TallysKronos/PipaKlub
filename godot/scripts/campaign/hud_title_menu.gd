extends Control
## PIP-131: Mural title, native navigation; no save access in this view.
signal selected(id:String)
const Hud=preload("res://scripts/campaign/hud.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const PaperButton=preload("res://scripts/ui_mural/mural_button.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var mode:="main"
var has_saves:=false
var reduced_motion:=false
var text_scale:=1.0
var column:VBoxContainer
var first:Button
var start_label:Label
var footer:Label
var buttons:Array[Button]=[]
var background:Texture2D
var logo:Texture2D
var logo_rect:=Rect2()
static var _art_cache:Dictionary={}
static func artwork(path:String) -> Texture2D:
	if _art_cache.has(path):return _art_cache[path]
	if ResourceLoader.exists(path) and (FileAccess.file_exists(path+".import") or OS.has_feature("standalone")):
		_art_cache[path]=load(path)
	else:
		_art_cache[path]=ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))
	return _art_cache[path]
func _init() -> void:set_meta("owns_ui_theme",true)
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	Mural.install(self)
	background=artwork("res://assets/campaign/title-v1/neighborhood-starters-soulgen-v4.png")
	logo=artwork("res://assets/ui/mural-v1/brand/logo.png")
	column=VBoxContainer.new();column.add_theme_constant_override("separation",14);add_child(column)
	if mode=="title":
		first=_button("Entrar em Kronasta","start","team")
	elif mode=="main":
		for option in [["Continuar","continue","save"],["Nova jornada","new","team"],["Configurações","settings","settings"],["Sair","quit","varal"]]:
			var button:=_button(option[0],option[1],option[2])
			button.set_available(option[1]!="continue" or has_saves)
			if option[1]=="continue" and not has_saves:button.tooltip_text="Ainda não há uma jornada salva. Escolha Nova jornada."
			if first==null and not button.disabled:first=button
	footer=Label.new();footer.theme_type_variation="MuralCaption"
	footer.add_theme_color_override("font_color",T.MURAL_PAPER)
	footer.add_theme_font_size_override("font_size",roundi(18*text_scale))
	footer.mouse_filter=MOUSE_FILTER_IGNORE;add_child(footer)
	resized.connect(_layout);_layout();_hint()
	if first!=null:Hud.focus_later(first)
func _button(text:String,id:String,icon_id:String) -> Button:
	var button:=PaperButton.new();button.text=text;button.icon_id=icon_id
	button.variant="MuralButton"
	button.add_theme_font_size_override("font_size",roundi(25*text_scale))
	column.add_child(button)
	button.custom_minimum_size.y=maxf(82,66*text_scale)
	button.pressed.connect(func():selected.emit(id))
	buttons.append(button)
	return button
func _layout() -> void:
	if column==null or footer==null:return
	var wide:=minf(480,size.x*.43)
	if mode=="title":
		logo_rect=Rect2(size.x*.08,24,size.x*.69,size.y*.32)
		column.position=Vector2(size.x*.07,size.y-170)
	else:
		var panel:=_panel_rect()
		column.position=Vector2(68,panel.end.y-maxf(82,66*text_scale)*4-42-64)
		logo_rect=Rect2(36,panel.position.y+12,wide+42,minf(200,column.position.y-panel.position.y-28))
	column.size=Vector2(wide,0)
	footer.position=Vector2(68 if mode=="main" else 36,_panel_rect().end.y-48 if mode=="main" else size.y-44)
	footer.size=Vector2(size.x-104,44)
	footer.visible=mode!="slots"
	queue_redraw()
func _input(event:InputEvent) -> void:
	Controls.observe(event);_hint()
func _hint() -> void:
	if footer==null:return
	footer.text=Controls.prompt("accept")+" · Confirmar"
	if mode=="main":footer.text+="     "+Controls.prompt("back")+" · Voltar"
func _panel_rect() -> Rect2:
	var height:=minf(760,size.y-24)
	return Rect2(12,(size.y-height)/2,minf(560,size.x*.52),height)
func _draw() -> void:
	if background==null:return
	var factor:=maxf(size.x/background.get_width(),size.y/background.get_height())
	draw_texture_rect(background,Rect2((size-background.get_size()*factor)/2,background.get_size()*factor),false)
	if mode=="slots":
		draw_rect(Rect2(Vector2.ZERO,size),T.alpha(T.MURAL_GROUND,.94));return
	if mode=="main":
		get_theme_stylebox("panel","MuralInkPanel").draw(get_canvas_item(),_panel_rect())
	else:
		draw_rect(Rect2(0,size.y-64,size.x,64),T.alpha(T.MURAL_GROUND,.92))
	draw_texture_rect(logo,Hud.fit_texture(logo,logo_rect),false)
