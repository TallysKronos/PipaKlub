extends Control
signal closed
const Hud = preload("res://scripts/campaign/hud.gd")
const Identity = preload("res://scripts/campaign/pipeiro_identity.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Surface=preload("res://scripts/ui_mural/menu_surface.gd")
const Option=preload("res://scripts/ui_mural/dialogue_option.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var text_scale:=1.0
var detail_scroll:ScrollContainer
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
	var seal_texture:Texture2D
	func _draw() -> void:
		var c := size/2
		var r := minf(size.x,size.y)*.37
		if earned and seal_texture!=null:
			texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
			draw_texture_rect(seal_texture,Hud.fit_texture(seal_texture,Rect2(c-Vector2.ONE*r*1.22,Vector2.ONE*r*2.44)),false)
			return
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
		Paper.frame(self,Rect2(Vector2(3,3),size-Vector2(6,6)),"MuralSunPanel" if active or has_focus() else "MuralInkPanel",.18)

func _init() -> void:set_meta("owns_ui_theme",true)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_STOP;z_index=240;set_meta("emblem_case",true)
	text_scale=maxf(text_scale,Mural.text_scale_for(self));Mural.install(self)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	copy("Porta-Emblemas",column,32,T.MURAL_PAPER)
	var filters_row:=HBoxContainer.new();filters_row.add_theme_constant_override("separation",12);column.add_child(filters_row)
	for index in filters.size():
		var tab:=Option.new();tab.text=filters[index];tab.text_scale=text_scale;tab.size_flags_horizontal=SIZE_EXPAND_FILL;filters_row.add_child(tab);tab.pressed.connect(set_filter.bind(index));tabs.append(tab)
	var body:=HBoxContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",20);column.add_child(body)
	var sheet:=Surface.new();sheet.family="case";sheet.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_child(sheet)
	var grid:=GridContainer.new();grid.columns=4;grid.size_flags_vertical=SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);sheet.add_child(grid)
	for index in 12:
		var holder:=Control.new();holder.custom_minimum_size=Vector2(64,68);holder.size_flags_horizontal=SIZE_EXPAND_FILL;holder.size_flags_vertical=SIZE_EXPAND_FILL;grid.add_child(holder)
		var socket:=Socket.new();socket.set_anchors_and_offsets_preset(PRESET_FULL_RECT);holder.add_child(socket)
		for state in ["normal","hover","pressed","focus","disabled"]:socket.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		var seal:=Seal.new();seal.mouse_filter=MOUSE_FILTER_IGNORE;seal.set_anchors_and_offsets_preset(PRESET_FULL_RECT);seal.offset_bottom=-T.text().get_height(roundi(13*text_scale))-28;socket.add_child(seal)
		seal.earned=emblems().has(Identity.slot_id(index));seal.variant=index
		if emblems().get(Identity.slot_id(index),{}).get("bossId","")=="mikka":seal.seal_texture=load("res://assets/ui/key-items/insignia-morro-do-sol.png")
		var number:=copy("%02d"%(index+1),socket,13,T.MURAL_PAPER);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;number.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE);number.offset_top=-20-T.text().get_height(roundi(13*text_scale));number.offset_bottom=-20
		socket.pressed.connect(select_slot.bind(index));socket.focus_entered.connect(select_slot.bind(index));socket.tooltip_text="Espaço %02d"%(index+1);slots.append(socket)
	var details_paper:=Surface.new();details_paper.family="case";details_paper.size_flags_horizontal=SIZE_EXPAND_FILL;body.add_child(details_paper)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;scroll.focus_mode=FOCUS_ALL;details_paper.add_child(scroll)
	detail_scroll=scroll;scroll.gui_input.connect(_detail_input)
	var right:=VBoxContainer.new();right.size_flags_horizontal=SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",12);scroll.add_child(right)
	art=Seal.new();art.custom_minimum_size=Vector2(132,142);right.add_child(art)
	title=copy("",right,28,T.MURAL_PAPER);location=copy("",right,20,T.MURAL_MINT);chief=copy("",right,18,T.MURAL_PAPER)
	description=copy("",right,20,T.MURAL_PAPER)
	empty=copy("",right,18,T.MURAL_PAPER)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",20);column.add_child(footer)
	count=copy("",footer,22,T.MURAL_PAPER);count.size_flags_horizontal=SIZE_EXPAND_FILL
	back=Option.new();back.text="Fechar";back.text_scale=text_scale;back.custom_minimum_size.x=200;footer.add_child(back);back.pressed.connect(func():closed.emit())
	select_slot(clampi(initial_slot,0,11));set_filter(0);Hud.focus_later(slots[selected]);resized.connect(queue_redraw)

func emblems() -> Dictionary: return player.get("districtEmblems",{})
func select_slot(index:int) -> void:
	selected=index
	for i in slots.size():
		slots[i].active=i==index;slots[i].queue_redraw()
		for child in slots[i].get_children():
			if child is Label:child.add_theme_color_override("font_color",T.MURAL_INK if i==index else T.MURAL_PAPER)
	var entry:Dictionary=emblems().get(Identity.slot_id(index),{})
	art.earned=not entry.is_empty();art.variant=index;art.queue_redraw()
	art.seal_texture=load("res://assets/ui/key-items/insignia-morro-do-sol.png") if entry.get("bossId","")=="mikka" else null
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
		slots[i].get_parent().visible=visible_slot
		if visible_slot:matches.append(i)
	for i in tabs.size():
		tabs[i].selected=i==filter_index
		if is_instance_valid(tabs[i].backing):tabs[i].backing.queue_redraw()
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
func _detail_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		detail_scroll.scroll_vertical+=roundi(64*text_scale)*(1 if event.is_action_pressed("ui_down") else -1);detail_scroll.accept_event()
	elif event.is_action_pressed("ui_left") and slots[selected].is_visible_in_tree():slots[selected].grab_focus();detail_scroll.accept_event()

func copy(value:String,parent:Node,font_size:int,color:Color=T.MURAL_INK) -> Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",roundi(font_size*text_scale));label.add_theme_color_override("font_color",color);label.add_theme_font_override("font",T.label() if font_size>=24 else T.text());parent.add_child(label);return label

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),T.alpha(T.MURAL_GROUND,.98))
	for y in range(24,int(size.y),36):draw_line(Vector2(0,y),Vector2(size.x,y),T.alpha(T.MURAL_MINT,.04),1)
