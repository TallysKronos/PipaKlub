extends VBoxContainer
const Hud = preload("res://scripts/campaign/hud.gd")
var inventory: Dictionary = {}
var list: VBoxContainer
var item_name: Label
var description: Label
var item_art: TextureRect
var quantity: Label
const NAMES := {"quest-nina-tail": "Rabiola do Carcará de Nina", "rabiola-lacertubo": "Rabiola de Lacertubo", "rabiola-basica": "Rabiola de Carcará", "rabiola-azulao": "Rabiola de Azulão", "rabiola-mata": "Rabiola de Mata verde", "rabiola-raio": "Rabiola de Raio de sol"}
func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tabs := HFlowContainer.new()
	var tab_group := ButtonGroup.new()
	add_child(tabs)
	for category in ["Tudo", "Rabiolas", "Missão", "Materiais"]:
		var tab := Button.new()
		tab.text = category
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.button_pressed = category == "Tudo"
		Hud.secondary_button(tab)
		tab.theme_type_variation = "RecorteTabButton"
		tab.custom_minimum_size = Vector2(125, 48)
		tabs.add_child(tab)
		tab.pressed.connect(func(): populate(category))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 30)
	add_child(row)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var detail := PanelContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.theme_type_variation = "RecortePaperPanel"
	row.add_child(detail)
	var column := VBoxContainer.new()
	detail.add_child(column)
	item_art = TextureRect.new()
	item_art.custom_minimum_size = Vector2(120, 145)
	item_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(item_art)
	item_name = Label.new()
	item_name.add_theme_font_override("font", Hud.display())
	item_name.add_theme_font_size_override("font_size", 28)
	quantity = Label.new()
	description = Label.new()
	for label in [item_name, quantity, description]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.theme_type_variation = "RecortePaperText"
		column.add_child(label)
	populate("Tudo")
func category(id: String) -> String:
	return "Missão" if id.begins_with("quest-") else "Rabiolas" if "rabiola" in id else "Materiais"
func populate(filter: String) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var first := ""
	for key in inventory:
		var id: String = str(key)
		if inventory[id] <= 0 or (filter != "Tudo" and category(id) != filter): continue
		if first.is_empty(): first = id
		var button := Button.new()
		button.text = "%s  × %d" % [NAMES.get(id, id.replace("-", " ").capitalize()), inventory[id]]
		button.icon = Hud.item_icon(id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.custom_minimum_size.y = 64
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = button.text
		Hud.secondary_button(button)
		button.set_meta("item_id", id)
		button.toggle_mode = true
		button.theme_type_variation = "RecorteListButton"
		button.pressed.connect(func(): select_item(id))
		button.focus_entered.connect(func(): select_item(id))
		list.add_child(button)
	select_item(first)
func select_item(id: String) -> void:
	for child in list.get_children():
		if child is Button: child.set_pressed_no_signal(child.get_meta("item_id", "") == id)
	item_art.texture = Hud.item_icon(id)
	item_name.text = NAMES.get(id, id.replace("-", " ").capitalize()) if not id.is_empty() else "Nada por aqui"
	quantity.text = ("MISSÃO · " if category(id) == "Missão" else "") + "%d na mochila" % inventory.get(id, 0) if not id.is_empty() else ""
	description.text = "Esta categoria ainda está vazia." if id.is_empty() else "Nina está esperando por esta rabiola. Entregue-a pessoalmente." if id == "quest-nina-tail" else "Leve ao ateliê do Sr. Assis para trabalhar nesta rabiola." if category(id) == "Rabiolas" else "Material guardado para sua jornada."
