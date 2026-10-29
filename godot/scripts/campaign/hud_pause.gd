extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
signal chosen(action: String)
var player: Dictionary = {}
var battle_paused := false
var partner_portrait:Texture2D
var focus_action:="resume"
var buttons:Dictionary={}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.anchor_left = .07
	column.anchor_right = .43
	column.anchor_top = .06
	column.anchor_bottom = .90
	column.add_theme_constant_override("separation",8)
	add_child(column)
	var title := Label.new()
	title.text = "Um respiro"
	title.add_theme_font_override("font", Hud.display())
	title.add_theme_font_size_override("font_size", 56)
	column.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Batalha em pausa" if battle_paused else "A aventura espera por você."
	subtitle.add_theme_font_size_override("font_size",17)
	subtitle.add_theme_color_override("font_color",Hud.MUTED)
	column.add_child(subtitle)
	var first: Button
	var index := 0
	for option in [["Retomar", "resume", "back"], ["Equipe", "team", "team"], ["Mochila", "bag", "bag"], ["Mapa", "map", "map"], ["Configurações", "settings", "settings"], ["Salvar jornada", "save", "save"], ["Voltar ao menu", "menu", "back"]]:
		var margin := MarginContainer.new()
		# Board: one aligned column (no staircase), the focused item turns to paper.
		margin.add_theme_constant_override("margin_left", 0)
		margin.add_theme_constant_override("margin_right", 24)
		column.add_child(margin)
		var button := Button.new()
		button.text = option[0]
		Hud.navigation_button(button,true,option[2])
		button.icon = Hud.icon(option[2])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 22)
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
	var card=load("res://scripts/campaign/hud_result_plate.gd").new()
	card.anchor_left = .56
	card.anchor_right = .93
	card.anchor_top = .23
	card.anchor_bottom = .73
	add_child(card)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation",10)
	card.add_child(details)
	_copy("SUA JORNADA",details,16,Hud.CYAN)
	var tamer_row:=HBoxContainer.new()
	tamer_row.add_theme_constant_override("separation",18)
	details.add_child(tamer_row)
	var face:=TextureRect.new()
	var face_atlas:=AtlasTexture.new()
	face_atlas.atlas=preload("res://assets/campaign/portrait-kael.png")
	face_atlas.region=Rect2(160,10,460,500)
	face.texture=face_atlas
	face.custom_minimum_size=Vector2(72,78)
	face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.mouse_filter=MOUSE_FILTER_IGNORE
	tamer_row.add_child(face)
	var tamer_text:=VBoxContainer.new()
	tamer_text.alignment=BoxContainer.ALIGNMENT_CENTER
	tamer_row.add_child(tamer_text)
	_copy(str(player.get("name","Kael")),tamer_text,34,Hud.PAPER,Hud.display(),false)
	_copy("%d MOEDAS"%int(player.get("coins",0)),tamer_text,18,Hud.GOLD,Hud.font(true),false)
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
		_copy(partner.get("personalName",partner.modelId),partner_details,24,Hud.PAPER,Hud.display())
		for stat in [["Linha",condition.line,Hud.LINE],["Armação",condition.structure,Hud.GOLD]]:
			_copy("%s · %d%%"%[str(stat[0]).to_upper(),stat[1]],partner_details,15,Hud.PAPER,Hud.font(true))
			var bar:=ProgressBar.new()
			bar.value=clampf(stat[1],0,100)
			bar.show_percentage=false
			bar.custom_minimum_size.y=8
			var fill:=StyleBoxFlat.new()
			fill.bg_color=stat[2]
			bar.add_theme_stylebox_override("fill",fill)
			partner_details.add_child(bar)
		_copy("Retome quando estiver pronto." if battle_paused else "Reparos no ateliê do Sr. Assis." if condition.line<100 or condition.structure<100 else "Pronto para explorar.",details,16,Hud.MUTED)
	if not found:_copy("Sua história está começando.",partner_details,18,Hud.MUTED)
	Hud.focus_later(buttons.get(focus_action,first))
	# The world HUD (place, objective, partner chip) steps aside while the pause is open.
	for overlay in get_tree().get_nodes_in_group("exploration_hud"):
		if overlay.visible:
			overlay.hide()
			var minimap:Control=overlay.get("map")
			if is_instance_valid(minimap):minimap.hide()
			tree_exiting.connect(func():
				if is_instance_valid(overlay):overlay.show()
				if is_instance_valid(minimap):minimap.show())
func _copy(text:String,parent:Node,font_size:int,color:Color,font:Font=null,wrap:bool=true) -> void:
	var label:=Label.new()
	if font!=null:label.add_theme_font_override("font",font)
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
# Board: the world stays visible under an even ink veil with a fine dot screen.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.VEU)
	for x in range(12,int(size.x),18):
		for y in range(12,int(size.y),18):draw_circle(Vector2(x,y),1.2,Color(Hud.PAPER,.07))
