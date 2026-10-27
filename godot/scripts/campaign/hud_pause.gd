extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
signal chosen(action: String)
var player: Dictionary = {}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.anchor_left = .07
	column.anchor_right = .43
	column.anchor_top = .12
	column.anchor_bottom = .90
	add_child(column)
	var title := Label.new()
	title.text = "UM RESPIRO"
	title.add_theme_font_override("font", Hud.display())
	title.add_theme_font_size_override("font_size", 42)
	column.add_child(title)
	var first: Button
	var index := 0
	for option in [["Retomar", "resume", "back"], ["Equipe", "team", "team"], ["Mochila", "bag", "bag"], ["Configurações", "settings", "settings"], ["Salvar e voltar ao menu", "menu", "save"]]:
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", index * 10)
		column.add_child(margin)
		var button := Button.new()
		button.text = option[0]
		Hud.secondary_button(button)
		button.icon = Hud.icon(option[2])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.custom_minimum_size.y = 56
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): chosen.emit(option[1]))
		margin.add_child(button)
		if index == 0: first = button
		index += 1
	var hints := HBoxContainer.new()
	column.add_child(hints)
	Hud.input_hint(hints,"accept","Confirmar")
	Hud.input_hint(hints,"pause","Retomar")
	var card := PanelContainer.new()
	card.anchor_left = .56
	card.anchor_right = .93
	card.anchor_top = .24
	card.anchor_bottom = .69
	card.theme_type_variation = "RecortePaperPanel"
	add_child(card)
	var details := VBoxContainer.new()
	card.add_child(details)
	Hud.decorate(details, 0, Vector2(72, 48))
	var summary: Array[String] = [str(player.get("name", "Kael")), "%d moedas" % int(player.get("coins", 0))]
	for partner in player.get("partners", []):
		if partner.id != player.get("equippedPartnerId", ""): continue
		var condition: Dictionary = partner.get("condition", {"line": 100, "structure": 100})
		summary.append("Parceiro · " + partner.get("personalName", partner.modelId))
		summary.append("Linha %d%% · Armação %d%%" % [condition.line, condition.structure])
		summary.append("Reparo disponível no ateliê do Sr. Assis." if condition.line < 100 or condition.structure < 100 else "Pronto para explorar.")
	for text in summary:
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.theme_type_variation = "RecortePaperText"
		details.add_child(label)
	Hud.focus_later(first)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.VEU)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x * .51, 0), Vector2(size.x * .42, size.y), Vector2(0, size.y)]), Hud.INK)
	draw_line(Vector2(size.x * .51, 0), Vector2(size.x * .42, size.y), Hud.CORAL, 5, true)
	var art := Hud.ornament(2)
	draw_texture_rect(art, Hud.fit_texture(art, Rect2(size.x * .77, size.y * .73, 220, 146)), false)
