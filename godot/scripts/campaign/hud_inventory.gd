extends VBoxContainer
const Hud = preload("res://scripts/campaign/hud.gd")
var inventory: Dictionary = {}
var list: VBoxContainer
var item_name: Label
var description: Label
var item_art: TextureRect
var quantity: Label
signal retry_requested
signal care_requested
var use_button:Button
var care_available:=true
var tabs:Array[Button]=[]
var current_filter:="Tudo"
var page_index:=0
var page_size:=4
var scroll:ScrollContainer
var pager:Label
var previous:Button
var following:Button
var load_state:="ready"
var reduced_motion:=false
var state_time:=0.0
static var seen:Dictionary={}
const NAMES := {"kit-remendo":"Kit de Remendo","quest-nina-tail": "Rabiola do Carcará de Nina", "rabiola-lacertubo": "Rabiola de Lacertubo", "rabiola-basica": "Rabiola de Carcará", "rabiola-azulao": "Rabiola de Azulão", "rabiola-mata": "Rabiola de Mata verde", "rabiola-raio": "Rabiola de Raio de sol","papel-seda":"Papel de seda","vareta-bambu":"Vareta de bambu","cola-reparo":"Cola de reparo","linha-encerada":"Linha encerada","pista-caderno-heleana-1":"Página do caderno"}
func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",16)
	var tab_row := HFlowContainer.new()
	var tab_group := ButtonGroup.new()
	add_child(tab_row)
	for category in ["Tudo", "Rabiolas", "Missão", "Materiais"]:
		var tab := Button.new()
		tab.text = category
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.button_pressed = category == "Tudo"
		Hud.secondary_button(tab)
		tab.theme_type_variation = "RecorteTabButton"
		tab.custom_minimum_size = Vector2(125, 48)
		tab_row.add_child(tab)
		tabs.append(tab)
		tab.pressed.connect(func():page_index=0;populate(category))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 30)
	add_child(row)
	scroll = ScrollContainer.new()
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation",8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var detail=load("res://scripts/campaign/hud_result_plate.gd").new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
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
	quantity.add_theme_font_override("font",Hud.font(true))
	description = Label.new()
	for label in [item_name, quantity, description]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color",Hud.PAPER)
		column.add_child(label)
	quantity.add_theme_color_override("font_color",Hud.CYAN)
	description.add_theme_font_size_override("font_size",18)
	use_button=Button.new();use_button.text="Cuidar do parceiro"
	Hud.navigation_button(use_button,true);column.add_child(use_button)
	use_button.pressed.connect(func():care_requested.emit())
	var paging:=HBoxContainer.new()
	paging.add_theme_constant_override("separation",16)
	add_child(paging)
	previous=Button.new();previous.text="Anterior"
	following=Button.new();following.text="Próxima"
	for button in [previous,following]:
		Hud.navigation_button(button,true)
		button.custom_minimum_size=Vector2(150,44)
		paging.add_child(button)
	pager=Label.new();paging.add_child(pager)
	previous.pressed.connect(func():page_index-=1;populate(current_filter);_focus_item())
	following.pressed.connect(func():page_index+=1;populate(current_filter);_focus_item())
	scroll.resized.connect(_fit_page.call_deferred)
	populate("Tudo")
func _fit_page() -> void:
	if not is_instance_valid(scroll):return
	if inventory.is_empty():return
	var capacity:=maxi(1,floori((scroll.size.y+8)/80.0))
	if page_size!=capacity:page_size=capacity;page_index=0;populate(current_filter)
func _focus_item() -> void:
	for child in list.get_children():
		if child is Button:Hud.focus_later(child);return
func _unhandled_input(event:InputEvent) -> void:
	var direction:=0
	if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:direction=-1 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 1
	if event.is_action_pressed("campaign_guard"):direction=-1
	if event.is_action_pressed("campaign_line"):direction=1
	if direction!=0:
		var index: int=["Tudo","Rabiolas","Missão","Materiais"].find(current_filter)
		index=posmod(index+direction,4)
		page_index=0;populate(tabs[index].text);tabs[index].grab_focus()
		get_viewport().set_input_as_handled()
func category(id: String) -> String:
	return "Missão" if id.begins_with("quest-") or id.begins_with("pista-") else "Rabiolas" if "rabiola" in id else "Materiais"
func populate(filter: String) -> void:
	current_filter=filter
	for tab in tabs:tab.set_pressed_no_signal(tab.text==filter)
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if load_state!="ready":
		var state:=Label.new()
		state.text="◆ ◇ ◇  Carregando…" if load_state=="loading" else "Não foi possível ler os itens."
		list.add_child(state)
		if load_state=="error":
			var retry:=Button.new();retry.text="Tentar de novo";Hud.navigation_button(retry,true);list.add_child(retry)
			retry.pressed.connect(func():retry_requested.emit())
		select_item("");previous.disabled=true;following.disabled=true;pager.text=""
		return
	var keys:Array=[]
	for key in inventory:
		if inventory[key]>0 and (filter=="Tudo" or category(str(key))==filter):keys.append(key)
	var pages:=maxi(1,ceili(float(keys.size())/page_size))
	page_index=clampi(page_index,0,pages-1)
	previous.disabled=page_index==0;following.disabled=page_index>=pages-1
	pager.text="%d / %d · %d itens"%[page_index+1,pages,keys.size()]
	var first := ""
	for key in keys.slice(page_index*page_size,(page_index+1)*page_size):
		var id: String = str(key)
		if inventory[id] <= 0 or (filter != "Tudo" and category(id) != filter): continue
		if first.is_empty(): first = id
		var button := Button.new()
		button.text = "%s  × %d%s" % [NAMES.get(id, id.replace("-", " ").capitalize()), inventory[id]," · NOVO!" if not seen.has(id) else ""]
		button.icon = Hud.item_icon(id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.custom_minimum_size.y = 72
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
	if first.is_empty():
		var empty:=Label.new()
		empty.text="Nenhum item nesta categoria.\nExplore para encontrar materiais e rabiolas."
		empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size",18)
		list.add_child(empty)
		var show_all:=Button.new();show_all.text="Ver todos os itens";Hud.navigation_button(show_all,true)
		show_all.set_meta("recorte_decorated",true)
		list.add_child(show_all)
		show_all.pressed.connect(func():page_index=0;populate("Tudo");tabs[0].grab_focus())
	select_item(first)
func select_item(id: String) -> void:
	use_button.visible=id=="kit-remendo"
	use_button.disabled=not care_available
	if not id.is_empty():seen[id]=true
	for child in list.get_children():
		if child is Button:
			child.set_pressed_no_signal(child.get_meta("item_id", "") == id)
			if child.get_meta("item_id","")==id:child.text=child.text.trim_suffix(" · NOVO!")
	item_art.texture = Hud.item_art(id)
	item_name.text = NAMES.get(id, id.replace("-", " ").capitalize()) if not id.is_empty() else "Nada por aqui"
	quantity.text = ("MISSÃO · " if category(id) == "Missão" else "") + "%d na mochila" % inventory.get(id, 0) if not id.is_empty() else ""
	description.text = "Esta categoria ainda está vazia." if id.is_empty() else "Nina está esperando por esta rabiola. Entregue-a pessoalmente." if id == "quest-nina-tail" else "Leve ao ateliê do Sr. Assis para trabalhar nesta rabiola." if category(id) == "Rabiolas" else "Material guardado para sua jornada."
	if id=="pista-caderno-heleana-1": description.text="Página encontrada em um dos platôs do Bosque dos Ventos. Guardada entre suas pistas."
	if id=="kit-remendo":
		item_name.text="Kit de Remendo"
		description.text="Papel, cola e linha para cuidar de um Soulmonster. Restaura toda a linha e a armação ao concluir os cuidados."
	if id.is_empty() and load_state!="ready":
		item_name.text="Carregando itens" if load_state=="loading" else "Itens indisponíveis"
		description.text="Aguarde a leitura da mochila." if load_state=="loading" else "Tente novamente para atualizar a lista."
func set_load_state(value:String) -> void:
	load_state=value if value in ["ready","loading","error"] else "error"
	populate(current_filter)
func _process(delta:float) -> void:
	if load_state!="loading" or list.get_child_count()==0:return
	if reduced_motion:return
	state_time+=delta
	list.get_child(0).text=["◆ ◇ ◇","◇ ◆ ◇","◇ ◇ ◆"][int(state_time*3)%3]+"  Carregando…"
