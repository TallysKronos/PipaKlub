extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
signal chosen(action: String)
var player: Dictionary = {}
var battle_paused := false
var partner_portrait:Texture2D
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.anchor_left = .07
	column.anchor_right = .43
	column.anchor_top = .12
	column.anchor_bottom = .90
	column.add_theme_constant_override("separation",12)
	add_child(column)
	var title := Label.new()
	title.text = "UM RESPIRO"
	title.add_theme_font_override("font", Hud.display())
	title.add_theme_font_size_override("font_size", 42)
	column.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Batalha em pausa" if battle_paused else "A aventura espera por você."
	subtitle.add_theme_font_size_override("font_size",17)
	subtitle.add_theme_color_override("font_color",Hud.MUTED)
	column.add_child(subtitle)
	var first: Button
	var index := 0
	for option in [["Retomar", "resume", "back"], ["Equipe", "team", "team"], ["Mochila", "bag", "bag"], ["Configurações", "settings", "settings"], ["Salvar e voltar ao menu", "menu", "save"]]:
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", index * 10)
		margin.add_theme_constant_override("margin_right", 24)
		column.add_child(margin)
		var button := Button.new()
		button.text = option[0]
		Hud.navigation_button(button,true,option[2])
		button.icon = Hud.icon(option[2])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.custom_minimum_size.y = 54
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text=option[0]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): chosen.emit(option[1]))
		margin.add_child(button)
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
	_copy(str(player.get("name","Kael")),details,26,Hud.PAPER)
	_copy("%d moedas"%int(player.get("coins",0)),details,18,Hud.GOLD)
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
			_copy("%s · %d%%"%[stat[0],stat[1]],partner_details,16,Hud.MUTED)
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
	Hud.focus_later(first)
func _copy(text:String,parent:Node,font_size:int,color:Color) -> void:
	var label:=Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.VEU)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x * .51, 0), Vector2(size.x * .42, size.y), Vector2(0, size.y)]), Hud.INK)
	draw_line(Vector2(size.x * .51, 0), Vector2(size.x * .42, size.y), Hud.CYAN, 4, true)
	var art := Hud.ornament(2)
	draw_texture_rect(art, Hud.fit_texture(art, Rect2(size.x * .77, size.y * .73, 220, 146)), false)
