extends Control
## Shared manga HUD, with a persistent completion and no invented story rewards.
signal chosen(action: String)
const Hud = preload("res://scripts/campaign/hud.gd")
var partner_portrait: Texture2D
var buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	label("SOULMONSTERS · DEMO CONCLUÍDA", column, 22, Hud.CYAN)
	label("Um fio de volta para casa", column, 44)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 32)
	column.add_child(body)
	var art := TextureRect.new()
	art.texture = partner_portrait
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size.x = 280
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(art)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.7
	body.add_child(panel)
	var inset := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(inset)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 16)
	inset.add_child(copy)
	label("A rabiola de Nina", copy, 30)
	label("Você enfrentou o Lacertubo e devolveu a rabiola do Carcará à Nina. Obrigado por jogar este primeiro trecho da jornada de Kael!", copy, 22)
	label("Primeiro voo e oficina concluídos\nParque e Veredas explorados\nRabiola entregue à Nina", copy, 20, Hud.CYAN)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.add_child(space)
	label("Sua jornada está salva. Você pode continuar explorando; as áreas futuras aparecem apagadas no mapa.", copy, 18)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	for entry in [["explore", "Continuar explorando"], ["map", "Mapa de Kronasta"], ["menu", "Voltar ao menu"]]:
		var button := Button.new()
		button.text = entry[1]
		button.custom_minimum_size.y = 56
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Hud.navigation_button(button)
		if entry[0] != "explore": Hud.secondary_button(button)
		actions.add_child(button)
		buttons[entry[0]] = button
		button.pressed.connect(func(): chosen.emit(entry[0]))
	Hud.focus_later(buttons.explore)

func label(text: String, parent: Node, font_size: int, color: Color = Hud.PAPER) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	if font_size >= 30: result.add_theme_font_override("font", Hud.display())
	parent.add_child(result)
	return result
