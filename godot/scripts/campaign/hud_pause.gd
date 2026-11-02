extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Layout = preload("res://scripts/campaign/hud_layout.gd")
signal chosen(action: String)
var player: Dictionary = {}
var battle_paused := false
var partner_portrait:Texture2D
var focus_action:="resume"
var buttons:Dictionary={}
var column:VBoxContainer
var card:PanelContainer
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation",int(Layout.space("s")))
	add_child(column)
	var title := Label.new()
	title.text = "UM RESPIRO"
	title.add_theme_font_override("font", Hud.display())
	title.add_theme_font_size_override("font_size", 40)
	column.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Batalha em pausa" if battle_paused else "A aventura espera por você."
	subtitle.add_theme_font_size_override("font_size",Layout.type("small"))
	subtitle.add_theme_color_override("font_color",Hud.MUTED)
	column.add_child(subtitle)
	var first: Button
	var index := 0
	for option in [["Retomar", "resume", "back"], ["Equipe", "team", "team"], ["Mochila", "bag", "bag"], ["Mapa", "map", "map"], ["Configurações", "settings", "settings"], ["Salvar jornada", "save", "save"], ["Voltar ao menu", "menu", "back"]]:
		var margin := MarginContainer.new()
		# Persona stair: each step 12 to the right, the same width for every button.
		margin.add_theme_constant_override("margin_left", index * 12)
		margin.add_theme_constant_override("margin_right", (6 - index) * 12)
		column.add_child(margin)
		var button := Button.new()
		button.text = option[0]
		Hud.navigation_button(button,true,option[2])
		button.icon = Hud.icon(option[2])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size",Layout.type("label"))
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text=option[0]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): chosen.emit(option[1]))
		margin.add_child(button)
		buttons[option[1]]=button
		if index == 0: first = button
		index += 1
	var hints := HBoxContainer.new()
	column.add_child(hints)
	Hud.input_hint(hints,"accept","Confirmar")
	Hud.input_hint(hints,"pause","Retomar")
	card=load("res://scripts/campaign/hud_result_plate.gd").new()
	add_child(card)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation",10)
	card.add_child(details)
	_copy("SUA JORNADA",details,Layout.type("small"),Hud.CYAN)
	_copy(str(player.get("name","Kael")),details,26,Hud.PAPER)
	_copy("%d moedas"%int(player.get("coins",0)),details,Layout.type("body"),Hud.GOLD)
	var separator:=HSeparator.new()
	details.add_child(separator)
	var partner_row:=HBoxContainer.new()
	partner_row.add_theme_constant_override("separation",16)
	details.add_child(partner_row)
	if partner_portrait!=null:
		var portrait:=TextureRect.new()
		portrait.texture=partner_portrait
		portrait.custom_minimum_size=Vector2(112,128)
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter=MOUSE_FILTER_IGNORE
		partner_row.add_child(portrait)
	var partner_details:=VBoxContainer.new()
	partner_details.size_flags_horizontal=SIZE_EXPAND_FILL
	partner_details.add_theme_constant_override("separation",8)
	partner_row.add_child(partner_details)
	var found:=false
	for partner in player.get("partners", []):
		if partner.id != player.get("equippedPartnerId", ""): continue
		found=true
		var condition: Dictionary = partner.get("condition", {"line": 100, "structure": 100})
		_copy(partner.get("personalName",partner.modelId),partner_details,22,Hud.PAPER)
		for stat in [["Linha",condition.line,Hud.LINE],["Armação",condition.structure,Hud.GOLD]]:
			_copy("%s · %d%%"%[stat[0],stat[1]],partner_details,Layout.type("small"),Hud.MUTED)
			var bar:=ProgressBar.new()
			bar.value=clampf(stat[1],0,100)
			bar.show_percentage=false
			bar.custom_minimum_size.y=8
			var fill:=StyleBoxFlat.new()
			fill.bg_color=stat[2]
			bar.add_theme_stylebox_override("fill",fill)
			partner_details.add_child(bar)
		_copy("Retome quando estiver pronto." if battle_paused else "Reparos no ateliê do Sr. Assis." if condition.line<100 or condition.structure<100 else "Pronto para explorar.",details,Layout.type("small"),Hud.MUTED)
	if not found:_copy("Sua história está começando.",partner_details,18,Hud.MUTED)
	resized.connect(_place)
	_place()
	# Second pass once the card has its width and its labels wrapped to it.
	_place.call_deferred()
	Hud.focus_later(buttons.get(focus_action,first))
## Menu column on the left of the safe rect, journey card on the right, both inside
## the 16:9 column on ultrawide.
func _place() -> void:
	var safe:=Layout.safe_rect(size)
	column.position=safe.position+Vector2(Layout.space("l"),Layout.space("s"))
	column.size=Vector2(safe.size.x*.38,0)
	var width:=safe.size.x*.38
	# Fixed share of the safe height: wrapped labels report a word-per-line minimum
	# before the card has a width, which would make the card fill the screen.
	var height:=clampf(safe.size.y*.56,340,460)
	card.size=Vector2(width,height)
	card.size=Vector2(width,height)
	card.position=Vector2(safe.end.x-width-Layout.space("l"),safe.position.y+(safe.size.y-height)*.42)
	queue_redraw()
func _copy(text:String,parent:Node,font_size:int,color:Color) -> void:
	var label:=Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.VEU)
	# The 12-degree cut follows the safe column, so ultrawide keeps the same split.
	var safe:=Layout.safe_rect(size)
	var top:=safe.position.x+safe.size.x*.49
	var bottom:=top-size.y*.21
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(top, 0), Vector2(bottom, size.y), Vector2(0, size.y)]), Hud.INK)
	draw_line(Vector2(top, 0), Vector2(bottom, size.y), Hud.CYAN, 4, true)
	for x in range(20,int(bottom-8),22):
		for y in range(20,int(size.y),22):draw_circle(Vector2(x,y),1.3,Color(Hud.PAPER,.08))
	var kael:Texture2D=preload("res://assets/campaign/portrait-kael.png")
	draw_texture_rect(kael,Hud.fit_texture(kael,Rect2(size.x*.58,size.y*.06,size.x*.32,size.y*.75)),false,Color(Hud.CYAN,.08))
	var art := Hud.ornament(2)
	draw_texture_rect(art, Hud.fit_texture(art, Rect2(size.x * .77, size.y * .73, 220, 146)), false)
