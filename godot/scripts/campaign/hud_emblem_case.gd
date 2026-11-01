extends Control
signal closed
const Hud = preload("res://scripts/campaign/hud.gd")
const Identity = preload("res://scripts/campaign/pipeiro_identity.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
var player: Dictionary = {}
var initial_slot := 0
var selected := 0
var filter_index := 0
var slots: Array[Button] = []
var tabs: Array[Button] = []
var title: Label
var location: Label
var chief: Label
var description: Label
var count: Label
var empty: Label
var art: Control
var back: Button
var filters := ["Todos", "Conquistados", "Pendentes"]

class Seal extends Control:
	var earned := false
	var variant := 0
	func _draw() -> void:
		var c := size/2
		var r := minf(size.x,size.y)*.37
		if not earned:
			draw_arc(c-Vector2(0,r*.12),r*.3,PI,TAU,18,Color("697587"),r*.11,true)
			draw_style_box(_box(Color("697587")),Rect2(c+Vector2(-r*.37,-r*.13),Vector2(r*.74,r*.65)))
			draw_circle(c+Vector2(0,r*.12),r*.07,Color("202a3c"))
			draw_line(c+Vector2(0,r*.14),c+Vector2(0,r*.28),Color("202a3c"),r*.07,true)
			return
		var points := PackedVector2Array()
		for i in 8:points.append(c+Vector2.from_angle(PI*.25*i-PI*.5)*r*(1.0 if i%2==0 else .82))
		draw_colored_polygon(points,Hud.PAPER)
		var edge := points.duplicate();edge.append(edge[0])
		draw_polyline(edge,Hud.BLACK,maxf(2,r*.08),true)
		var colors := [Color("54c9ef"),Color("f3a34e"),Color("f3756b")]
		var color: Color = colors[posmod(variant,3)]
		for i in points.size(): points[i]=c+(points[i]-c)*.72
		draw_colored_polygon(points,color)
		if variant%3==0:
			for arm in 4:
				var curve := PackedVector2Array()
				for step in 20:
					var t:=float(step)/19
					curve.append(c+Vector2.from_angle(arm*PI*.5+t*PI*1.15)*r*(.1+t*.48))
				draw_polyline(curve,Color("164c83"),maxf(2,r*.13),true)
				draw_polyline(curve,Color("b8f3ff"),maxf(1,r*.04),true)
		elif variant%3==1:
			var p:=PackedVector2Array([c+Vector2(0,-r*.53),c+Vector2(r*.43,0),c+Vector2(0,r*.53),c+Vector2(-r*.43,0),c+Vector2(0,-r*.53)])
			draw_polyline(p,Hud.PAPER,maxf(2,r*.09),true)
			draw_line(c-Vector2(r*.38,0),c+Vector2(r*.38,0),Hud.INK,maxf(1,r*.04),true)
		else:
			var p:=PackedVector2Array([c+Vector2(-r*.45,-r*.46),c-Vector2(0,r*.1),c+Vector2(r*.45,-r*.46),c+Vector2(r*.56,-r*.25),c+Vector2(r*.2,r*.05),c+Vector2(r*.43,r*.4),c+Vector2(0,r*.58),c+Vector2(-r*.43,r*.4),c+Vector2(-r*.2,r*.05),c+Vector2(-r*.56,-r*.25),c+Vector2(-r*.45,-r*.46)])
			draw_polyline(p,Hud.PAPER,maxf(2,r*.09),true)
	static func _box(color:Color) -> StyleBoxFlat:
		var box:=StyleBoxFlat.new();box.bg_color=color;box.set_corner_radius_all(2);return box

class Socket extends Button:
	var active := false
	func _draw() -> void:
		var rect:=Rect2(Vector2(3,3),size-Vector2(6,6))
		var p:=PackedVector2Array([rect.position+Vector2(14,0),Vector2(rect.end.x-14,rect.position.y),Vector2(rect.end.x,rect.position.y+14),rect.end-Vector2(0,14),rect.end-Vector2(14,0),Vector2(rect.position.x+14,rect.end.y),Vector2(rect.position.x,rect.end.y-14),rect.position+Vector2(0,14)])
		draw_colored_polygon(p,Color("1b2435"))
		p.append(p[0])
		if active:draw_polyline(p,Color(Hud.GOLD,.15),9,true)
		draw_polyline(p,Hud.GOLD if active or has_focus() else Color("66738b"),3 if active else 2,true)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_STOP
	z_index=240
	set_meta("emblem_case",true)
	var body:=HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left=142;body.offset_right=-68;body.offset_top=90;body.offset_bottom=-126
	body.add_theme_constant_override("separation",56)
	add_child(body)
	var left:=VBoxContainer.new();left.size_flags_horizontal=SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",12);body.add_child(left)
	copy("Porta-Emblemas",left,36)
	copy("Emblemas dos Chefes de Bairro",left,20,Hud.GOLD)
	var grid:=GridContainer.new();grid.columns=4;grid.size_flags_vertical=SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",12);left.add_child(grid)
	for index in 12:
		var holder:=Control.new();holder.custom_minimum_size=Vector2(72,74);holder.size_flags_horizontal=SIZE_EXPAND_FILL;holder.size_flags_vertical=SIZE_EXPAND_FILL;grid.add_child(holder)
		var socket:=Socket.new();socket.set_meta("recorte_decorated",true)
		for state in ["normal","hover","pressed","focus","disabled"]:socket.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		socket.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);holder.add_child(socket)
		var seal:=Seal.new();seal.mouse_filter=MOUSE_FILTER_IGNORE;seal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);seal.offset_bottom=-12;socket.add_child(seal)
		seal.earned=emblems().has(Identity.slot_id(index));seal.variant=index
		var number:=copy("%02d"%(index+1),socket,13,Hud.MUTED);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		number.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);number.offset_top=-22;number.offset_bottom=-3
		socket.pressed.connect(select_slot.bind(index));socket.focus_entered.connect(select_slot.bind(index))
		socket.tooltip_text="Espaço %02d"%(index+1)
		slots.append(socket)
	var right:=VBoxContainer.new();right.size_flags_horizontal=SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",12);body.add_child(right)
	var tab_row:=HBoxContainer.new();tab_row.add_theme_constant_override("separation",8);right.add_child(tab_row)
	for index in filters.size():
		var tab:=Button.new();tab.text=filters[index];tab.size_flags_horizontal=SIZE_EXPAND_FILL;tab.custom_minimum_size.y=42
		Hud.secondary_button(tab);tab.pressed.connect(set_filter.bind(index));tab_row.add_child(tab);tabs.append(tab)
	var heading:=HBoxContainer.new();heading.custom_minimum_size.y=142;heading.add_theme_constant_override("separation",14);right.add_child(heading)
	art=Seal.new();art.custom_minimum_size.x=132;heading.add_child(art)
	var labels:=VBoxContainer.new();labels.size_flags_horizontal=SIZE_EXPAND_FILL;labels.add_theme_constant_override("separation",12);heading.add_child(labels)
	title=copy("",labels,30,Hud.PAPER)
	location=copy("",labels,18,Hud.GOLD)
	chief=copy("",labels,18,Hud.MUTED)
	for label in [title,location,chief]:label.max_lines_visible=2;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var plate:=PanelContainer.new();plate.size_flags_vertical=SIZE_EXPAND_FILL;plate.set_meta("recorte_decorated",true)
	var panel_style:=StyleBoxFlat.new();panel_style.bg_color=Color("202d40");panel_style.border_color=Color("526580");panel_style.set_border_width_all(2);panel_style.set_corner_radius_all(3);plate.add_theme_stylebox_override("panel",panel_style);right.add_child(plate)
	var inset:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+side,18)
	plate.add_child(inset)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;inset.add_child(scroll)
	description=copy("",scroll,21,Hud.PAPER);description.size_flags_horizontal=SIZE_EXPAND_FILL
	empty=copy("",right,16,Hud.MUTED)
	count=copy("",right,24,Hud.GOLD)
	var footer:=HBoxContainer.new();footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);footer.offset_left=42;footer.offset_right=-42;footer.offset_top=-74;footer.offset_bottom=-18
	footer.add_theme_constant_override("separation",16);add_child(footer)
	Hud.input_hint(footer,"accept","Selecionar")
	var gap:=Control.new();gap.custom_minimum_size.x=24;footer.add_child(gap)
	var help:=copy("Tab · filtros",footer,17,Hud.MUTED);help.size_flags_horizontal=SIZE_EXPAND_FILL
	back=Button.new();back.text="Fechar";back.custom_minimum_size=Vector2(190,48);Hud.secondary_button(back);footer.add_child(back);back.pressed.connect(func():closed.emit())
	select_slot(clampi(initial_slot,0,11))
	set_filter(0)
	Hud.focus_later(slots[selected])
	resized.connect(queue_redraw)

func emblems() -> Dictionary: return player.get("districtEmblems",{})
func select_slot(index:int) -> void:
	selected=index
	for i in slots.size():slots[i].active=i==index;slots[i].queue_redraw()
	var entry:Dictionary=emblems().get(Identity.slot_id(index),{})
	art.earned=not entry.is_empty();art.variant=index;art.queue_redraw()
	if entry.is_empty():
		title.text="Emblema %02d"%(index+1);location.text="Ainda não conquistado";chief.text="Chefe de bairro"
		description.text="Este encaixe espera uma conquista sua.\n\nVença o chefe de um bairro para guardar o emblema correspondente aqui."
	else:
		title.text=entry.name
		location.text=entry.get("districtName","Conquista de bairro")
		chief.text="Chefe: "+entry.bossName if entry.has("bossName") else "Vitória registrada na jornada"
		var date:=Time.get_datetime_dict_from_unix_time(int(entry.earnedAt))
		description.text=entry.get("description","Este emblema registra sua vitória contra um chefe de bairro.")+"\n\nConquistado em %02d/%02d/%04d."%[date.day,date.month,date.year]
	count.text="Emblemas conquistados     %d / 12"%emblems().size()
	title.tooltip_text=title.text;location.tooltip_text=location.text;chief.tooltip_text=chief.text

func set_filter(index:int) -> void:
	filter_index=posmod(index,filters.size())
	var matches:Array[int]=[]
	for i in slots.size():
		var earned:=emblems().has(Identity.slot_id(i))
		var visible_slot:=filter_index==0 or (filter_index==1 and earned) or (filter_index==2 and not earned)
		slots[i].visible=visible_slot
		if visible_slot:matches.append(i)
	for i in tabs.size():tabs[i].modulate=Color.WHITE if i==filter_index else Color(.65,.7,.8)
	empty.text="Nenhum emblema conquistado ainda." if matches.is_empty() and filter_index==1 else "Todos os espaços foram conquistados." if matches.is_empty() else ""
	if not matches.is_empty() and selected not in matches:select_slot(matches[0])
	if matches.is_empty():
		title.text="Seu caminho continua";location.text="Porta-emblemas";chief.text=""
		description.text=empty.text;art.earned=false;art.queue_redraw()
	elif selected in matches:select_slot(selected)

func _input(event:InputEvent) -> void:
	if Controls.cancel(event) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled();closed.emit()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_TAB:
		set_filter(filter_index+(-1 if event.shift_pressed else 1));tabs[filter_index].grab_focus();get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
		set_filter(filter_index+(-1 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 1));tabs[filter_index].grab_focus();get_viewport().set_input_as_handled()

func _unhandled_input(_event:InputEvent) -> void:
	get_viewport().set_input_as_handled()

func copy(value:String,parent:Node,font_size:int,color:Color=Hud.PAPER) -> Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color)
	if font_size>=24:label.add_theme_font_override("font",Hud.display())
	parent.add_child(label);return label

func frame(rect:Rect2,color:Color,edge:Color,width:float=3) -> void:
	var c:=18.0
	var p:=PackedVector2Array([rect.position+Vector2(c,0),Vector2(rect.end.x-c,rect.position.y),Vector2(rect.end.x,rect.position.y+c),rect.end-Vector2(0,c),rect.end-Vector2(c,0),Vector2(rect.position.x+c,rect.end.y),Vector2(rect.position.x,rect.end.y-c),rect.position+Vector2(0,c)])
	draw_colored_polygon(p,color);p.append(p[0]);draw_polyline(p,edge,width,true)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,.035,.06,.72))
	draw_rect(Rect2(0,size.y-88,size.x,88),Hud.INK)
	var book:=Rect2(30,34,size.x-60,size.y-128)
	frame(Rect2(book.position+Vector2(5,8),book.size),Color(0,0,0,.45),Color(0,0,0,.4),7)
	frame(book,Color("24324e"),Hud.BLACK,8)
	frame(book.grow(-5),Color("263954"),Color("6486ad"),3)
	frame(book.grow(-14),Color("172236"),Color("3f5878"),4)
	var spine:=Rect2(book.position+Vector2(8,0),Vector2(78,book.size.y))
	frame(spine,Color("263754"),Color("617a9a"),3)
	for y in [book.position.y+70,book.end.y-160]:
		draw_rect(Rect2(spine.position.x+6,y,14,94),Color("f6a04b"))
		draw_line(Vector2(spine.position.x+9,y+4),Vector2(spine.position.x+9,y+88),Hud.GOLD,2)
		draw_rect(Rect2(spine.position.x+1,y+30,23,28),Color("334c6c"));draw_line(Vector2(spine.position.x+2,y+30),Vector2(spine.position.x+22,y+30),Color("9aadc5"),2)
		draw_rect(Rect2(book.end.x-16,y,10,94),Color("e98c46"));draw_line(Vector2(book.end.x-13,y+4),Vector2(book.end.x-13,y+88),Hud.GOLD,2)
	var hinge:=size.x*.51
	draw_line(Vector2(hinge,book.position.y+28),Vector2(hinge,book.end.y-22),Hud.BLACK,12,true)
	for y in [book.position.y+80,book.end.y-100]:
		draw_rect(Rect2(hinge-6,y,12,40),Color("5e7b99"));draw_line(Vector2(hinge-3,y+3),Vector2(hinge-3,y+35),Color("a9bdcb"),2)
	for x in [book.position.x+105,book.end.x-16]:
		draw_rect(Rect2(x,book.end.y-20,70 if x<1000 else 9,12),Color("ea8a43"))
	# Ink stipple remains at the seams, away from text and emblems.
	for x in range(128,int(book.end.x)-24,11):
		for y in [int(book.position.y)+24,int(book.end.y)-25]:draw_circle(Vector2(x,y+(x%3)*2),1.3,Color("4d6585"))
	var portrait:Texture2D=preload("res://assets/campaign/portrait-kael-manga-v4.png")
	draw_texture_rect(portrait,Hud.fit_texture(portrait,Rect2(book.end.x-290,book.end.y-255,240,240)),false,Color(.65,.75,1,.085))
	for offset in [0,150]:
		var c:=Vector2(spine.get_center().x,book.position.y+165+offset)
		var kite:=PackedVector2Array([c+Vector2(0,-24),c+Vector2(23,0),c+Vector2(0,32),c+Vector2(-23,0),c+Vector2(0,-24)])
		draw_polyline(kite,Color("8c9ac3"),2,true);draw_line(c-Vector2(20,0),c+Vector2(20,0),Color("8c9ac3"),2,true)
