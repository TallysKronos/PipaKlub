extends "res://scripts/campaign/hud_carretel_kit.gd"
const Shop = preload("res://scripts/campaign/item_shop.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const ART := "res://assets/ui/loja-itens-v1/"
signal purchase_requested(item_id: String, quantity: int)
signal back_requested
var player: Dictionary={}
var selected_id := "kit-remendo"
var amount := 1
var category := "Tudo"
var rows: Dictionary={}
var filters: Dictionary={}
var balance: Label
var item_name: Label
var category_name: Label
var owned: Label
var description: Label
var quantity_label: Label
var total_label: Label
var message: Label
var item_image: TextureRect
var buy_button: Button
var minus_button: Button
var plus_button: Button
var back_button: Button

class ProductRow extends Button:
	var product: Dictionary
	var art: Texture2D
	var selected := false
	var owned := 0
	func _ready() -> void:
		set_meta("recorte_decorated",true)
		for state in ["normal","hover","pressed","focus","disabled"]:
			add_theme_stylebox_override(state,StyleBoxEmpty.new())
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
	func _draw() -> void:
		var active:=selected or has_focus() or is_hovered()
		CarretelMenuKit.plate(self,Rect2(3,3,size.x-6,size.y-6),active)
		CarretelMenuKit.image(self,art,Rect2(18,8,66,66))
		CarretelMenuKit.write(self,product.name,Vector2(108,35),23,CarretelMenuKit.WHITE,360,true)
		CarretelMenuKit.write(self,product.category,Vector2(108,62),17,CarretelMenuKit.MUTED,320)
		CarretelMenuKit.write(self,"%d moedas" % product.price,Vector2(526,35),21,Color("ffcf60"),160,true)
		CarretelMenuKit.write(self,"Na mochila: %d" % owned,Vector2(526,62),16,CarretelMenuKit.MUTED,170)

func _ready() -> void:
	super()
	texture(menu_icon("workshop"),Rect2(32,22,70,70))
	label("LINHA & PAPEL",Rect2(116,24,720,58),46,WHITE,true)
	label("Itens e materiais",Rect2(119,83,650,26),19,MUTED)
	panel(Rect2(935,28,310,68))
	texture(load(ART+"moedas.png"),Rect2(949,39,48,46))
	balance=label("",Rect2(1005,43,221,39),27,WHITE,true)
	for i in 3:
		var filter_name: String=["Tudo","Cuidados","Materiais"][i]
		var button:=card(filter_name,Rect2(32+i*239,122,232,42),null,true)
		button.managed_selection=true
		filters[filter_name]=button
		button.pressed.connect(_filter.bind(filter_name))
	for product: Dictionary in Shop.CATALOGUE:
		var row:=ProductRow.new()
		row.name="Product_"+str(product.id)
		row.product=product
		row.art=load(ART+product.id+".png")
		row.tooltip_text=product.name
		canvas.add_child(row)
		rows[product.id]=row
		row.focus_entered.connect(_select.bind(product.id))
		row.pressed.connect(func():_select(product.id);buy_button.grab_focus())
	panel(Rect2(783,122,462,503))
	item_name=label("",Rect2(808,143,410,42),29,WHITE,true)
	category_name=label("",Rect2(810,186,400,28),18,CYAN)
	item_image=texture(null,Rect2(820,218,163,130))
	owned=label("",Rect2(995,255,222,60),19,MUTED)
	description=label("",Rect2(810,353,402,89),18,WHITE)
	label("Quantidade",Rect2(809,452,185,34),20,MUTED)
	minus_button=card("−",Rect2(1000,445,57,44),null,true)
	quantity_label=label("",Rect2(1067,450,68,34),24,WHITE,true)
	quantity_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	plus_button=card("+",Rect2(1147,445,57,44),null,true)
	minus_button.pressed.connect(_change_amount.bind(-1))
	plus_button.pressed.connect(_change_amount.bind(1))
	label("Total",Rect2(810,506,150,35),22,MUTED)
	total_label=label("",Rect2(975,502,232,39),26,Color("ffcf60"),true)
	total_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	buy_button=card("Comprar",Rect2(801,557,424,54),null,true)
	buy_button.light=true
	buy_button.pressed.connect(_purchase)
	message=label("",Rect2(790,636,445,60),17,CYAN)
	back_button=card("Voltar à loja",Rect2(32,650,218,48),menu_icon("back"),true)
	back_button.pressed.connect(func():back_requested.emit())
	var hints:=HBoxContainer.new()
	hints.add_theme_constant_override("separation",22)
	canvas.add_child(hints)
	place(hints,Rect2(287,653,475,42))
	Hud.input_hint(hints,"accept","Confirmar")
	Hud.input_hint(hints,"back","Voltar")
	_filter("Tudo")
	refresh(player)
	Hud.focus_later(rows[selected_id])

func refresh(value: Dictionary) -> void:
	player=value.duplicate(true)
	balance.text="%d moedas" % int(player.get("coins",0))
	for id in rows:
		rows[id].owned=int(player.get("inventory",{}).get(id,0))
		rows[id].queue_redraw()
	_update_details()

func _select(id: String) -> void:
	if id!=selected_id:
		amount=1
		message.text=""
	selected_id=id
	for key in rows:
		rows[key].selected=key==id
		rows[key].queue_redraw()
	_update_details()

func _filter(value: String) -> void:
	category=value
	var visible_rows: Array[Button]=[]
	for product: Dictionary in Shop.CATALOGUE:
		var row: Button=rows[product.id]
		row.visible=value=="Tudo" or product.category==value
		if row.visible:
			place(row,Rect2(32,179+visible_rows.size()*89,713,82))
			visible_rows.append(row)
	for key in filters:
		filters[key].selected=key==value
		filters[key].queue_redraw()
	if not rows[selected_id].visible:
		_select(str(visible_rows[0].get("product").id))
	for i in visible_rows.size():
		var row: Button=visible_rows[i]
		row.focus_neighbor_top=visible_rows[i-1].get_path() if i>0 else filters[value].get_path()
		row.focus_neighbor_bottom=visible_rows[i+1].get_path() if i+1<visible_rows.size() else back_button.get_path()
		row.focus_neighbor_right=buy_button.get_path()
		row.focus_next=visible_rows[i+1].get_path() if i+1<visible_rows.size() else minus_button.get_path()
		row.focus_previous=visible_rows[i-1].get_path() if i>0 else filters[value].get_path()
	visible_rows[0].focus_neighbor_top=filters[value].get_path()
	buy_button.focus_neighbor_left=rows[selected_id].get_path()
	buy_button.focus_neighbor_top=plus_button.get_path()
	buy_button.focus_neighbor_bottom=back_button.get_path()
	back_button.focus_neighbor_top=visible_rows.back().get_path()
	back_button.focus_neighbor_right=buy_button.get_path()
	minus_button.focus_neighbor_right=plus_button.get_path()
	plus_button.focus_neighbor_left=minus_button.get_path()
	for key in filters:
		filters[key].focus_neighbor_bottom=visible_rows[0].get_path()

func _update_details() -> void:
	if item_name==null:
		return
	var product:=Shop.item(selected_id)
	item_name.text=product.name
	category_name.text=product.category
	item_image.texture=load(ART+selected_id+".png")
	description.text=product.description
	owned.text="Na mochila\n%d unidades" % int(player.get("inventory",{}).get(selected_id,0))
	quantity_label.text=str(amount)
	var total: int=int(product.price)*amount
	total_label.text="%d moedas" % total
	buy_button.disabled=int(player.get("coins",0))<total
	buy_button.text="Moedas insuficientes" if buy_button.disabled else "Comprar"
	minus_button.disabled=amount<=1
	plus_button.disabled=amount>=Shop.MAX_QUANTITY
	buy_button.focus_neighbor_left=rows[selected_id].get_path()

func _change_amount(delta: int) -> void:
	amount=clampi(amount+delta,1,Shop.MAX_QUANTITY)
	message.text=""
	_update_details()

func _purchase() -> void:
	if buy_button.disabled:
		return
	buy_button.disabled=true
	purchase_requested.emit(selected_id,amount)

func purchase_result(value: Dictionary, result: Dictionary, quantity: int) -> void:
	refresh(value)
	var status: String=result.status
	if status in ["ok","already_applied"]:
		message.text="%d × %s na mochila." % [quantity,Shop.item(selected_id).name]
	else:
		message.text="Moedas insuficientes." if status=="not_enough_coins" else "Não foi possível concluir a compra. Tente novamente."
	message.add_theme_color_override("font_color",CYAN if status in ["ok","already_applied"] else Color("ffb08b"))

func _input(event: InputEvent) -> void:
	if Controls.cancel(event) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()
