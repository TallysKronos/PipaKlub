extends Control
signal closed
signal emblems_requested(index:int)
const Hud = preload("res://scripts/campaign/hud.gd")
const Identity = preload("res://scripts/campaign/pipeiro_identity.gd")
const Training = preload("res://scripts/campaign/park_training.gd")
var saved: Dictionary = {}
var reduced_motion := false
var back: Button
var slots: Array[Button] = []
var detail: Label
var name_label: Label

class EmblemSlot extends Button:
	var index := 0
	var earned := false
	func _draw() -> void:
		var center := Vector2(size.x * .5, size.y * .43)
		var radius := minf(size.x * .27, size.y * .29)
		var points := PackedVector2Array([center + Vector2(0,-radius),center + Vector2(radius,0),center + Vector2(0,radius),center + Vector2(-radius,0)])
		draw_colored_polygon(points, Hud.GOLD if earned else Color("263b49"))
		points.append(points[0])
		draw_polyline(points, Hud.PAPER if earned else Color("60747c"), 2, true)
		draw_line(center-Vector2(radius,0),center+Vector2(radius,0),Hud.INK if earned else Color("425764"),1,true)
		draw_line(center-Vector2(0,radius),center+Vector2(0,radius),Hud.INK if earned else Color("425764"),1,true)
		var text := "%02d" % (index + 1)
		var font := Hud.font(true)
		var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		draw_string(font,Vector2((size.x-width)/2,size.y-10),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Hud.GOLD if earned else Hud.MUTED)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,32)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	margin.add_child(column)
	copy("SUA JORNADA · KRONASTA",column,18,Hud.CYAN)
	copy("Carteira de Pipeiro",column,38)
	var spread := HBoxContainer.new()
	spread.size_flags_vertical = SIZE_EXPAND_FILL
	spread.add_theme_constant_override("separation",20)
	column.add_child(spread)
	var card := panel(spread,Color("eae2c7"))
	card.size_flags_stretch_ratio = 1.15
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation",12)
	card.add_child(left)
	copy("REGISTRO DE ELOS  /  PIPA KLUB",left,18,Hud.SURFACE)
	var player: Dictionary = saved.player
	var registration: Dictionary = player.pipeiroIdentity
	copy("Nº " + registration.id,left,16,Color("526572"))
	var row := HBoxContainer.new()
	row.size_flags_vertical = SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation",18)
	left.add_child(row)
	var portrait := TextureRect.new()
	var photo := AtlasTexture.new()
	photo.atlas = preload("res://assets/campaign/portrait-kael-manga-v4.png")
	photo.region = Rect2(115,0,610,870)
	portrait.texture = photo
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size.x = 185
	row.add_child(portrait)
	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation",10)
	row.add_child(stats)
	copy("PIPEIRO",stats,14,Color("526572"))
	name_label = copy(player.get("name","Kael"),stats,30,Hud.INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.tooltip_text = player.get("name","Kael")
	copy("Tamer · nível %d" % Identity.tamer_level(int(player.get("tamerXp",0))),stats,22,Hud.INK)
	copy("%d XP de tamer" % int(player.get("tamerXp",0)),stats,16,Color("526572"))
	copy("%d moedas" % int(player.get("coins",0)),stats,24,Color("885426"))
	var seconds := int(saved.get("playSeconds",0))
	copy("Tempo · %02dh %02dmin" % [seconds/3600,(seconds/60)%60],stats,17,Hud.SURFACE)
	var active: Dictionary = Training.active(player)
	if not active.is_empty():
		copy("Parceiro · %s\nNv. %d" % [active.get("personalName",active.modelId),Training.level(player)],stats,18,Hud.SURFACE)
	var date := Time.get_datetime_dict_from_unix_time(int(registration.issuedAt))
	copy("Emitida em %02d/%02d/%04d · Sr. Assis" % [date.day,date.month,date.year],left,15,Color("526572"))
	var case_panel := panel(spread,Hud.SURFACE)
	var case_column := VBoxContainer.new()
	case_column.add_theme_constant_override("separation",12)
	case_panel.add_child(case_column)
	var emblems: Dictionary = player.get("districtEmblems",{})
	copy("PORTA-EMBLEMAS",case_column,28)
	copy("%02d / 12  ·  Chefes de bairro" % emblems.size(),case_column,18,Hud.GOLD)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	case_column.add_child(grid)
	for index in Identity.SLOT_COUNT:
		var slot := EmblemSlot.new()
		slot.index = index
		slot.earned = emblems.has(Identity.slot_id(index))
		slot.set_meta("recorte_decorated",true)
		slot.custom_minimum_size = Vector2(80,74)
		slot.size_flags_horizontal = SIZE_EXPAND_FILL
		slot.size_flags_vertical = SIZE_EXPAND_FILL
		for state in ["normal","hover","pressed","focus"]:
			var skin := StyleBoxFlat.new()
			skin.bg_color = Color("14232e") if state=="normal" else Color("2d4554")
			skin.border_color = Hud.CYAN if state=="focus" else Color("526572")
			skin.set_border_width_all(2 if state=="focus" else 1)
			slot.add_theme_stylebox_override(state,skin)
		grid.add_child(slot)
		slots.append(slot)
		var data: Dictionary = emblems.get(Identity.slot_id(index),{})
		slot.tooltip_text = data.get("name","Espaço %02d · emblema ainda não conquistado" % (index+1))
		slot.pressed.connect(func(): select_slot(index))
	detail = copy("Um emblema por chefe de bairro.\nCada conquista guarda seu lugar aqui.",case_column,17,Hud.MUTED)
	detail.custom_minimum_size.y = 50
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",20)
	column.add_child(footer)
	var hint := copy("Os dados acompanham sua jornada salva.",footer,17,Hud.MUTED)
	hint.size_flags_horizontal = SIZE_EXPAND_FILL
	var open_case:=Button.new()
	open_case.text="Abrir porta-emblemas"
	open_case.custom_minimum_size=Vector2(260,56)
	Hud.secondary_button(open_case)
	footer.add_child(open_case)
	open_case.pressed.connect(func():emblems_requested.emit(0))
	back = Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(280,56)
	Hud.navigation_button(back)
	footer.add_child(back)
	back.pressed.connect(func(): closed.emit())
	Hud.focus_later(back)
	if not reduced_motion:
		margin.modulate.a = 0
		create_tween().tween_property(margin,"modulate:a",1,.3)

func select_slot(index: int) -> void:
	var emblem: Dictionary = saved.player.get("districtEmblems",{}).get(Identity.slot_id(index),{})
	if emblem.is_empty():
		detail.text = "Espaço %02d · ainda não conquistado.\nReserve este lugar para uma vitória de bairro." % (index+1)
	else:
		var date := Time.get_datetime_dict_from_unix_time(int(emblem.earnedAt))
		detail.text = "%s\nConquistado em %02d/%02d/%04d." % [emblem.name,date.day,date.month,date.year]

func panel(parent: Node, color: Color) -> MarginContainer:
	var plate := PanelContainer.new()
	plate.set_meta("recorte_decorated",true)
	plate.size_flags_horizontal = SIZE_EXPAND_FILL
	var skin := StyleBoxFlat.new()
	skin.bg_color = color
	skin.border_color = Hud.BLACK
	skin.set_border_width_all(3)
	skin.shadow_color = Color(0,0,0,.3)
	skin.shadow_offset = Vector2(5,6)
	skin.shadow_size = 4
	plate.add_theme_stylebox_override("panel",skin)
	parent.add_child(plate)
	var inset := MarginContainer.new()
	for side in ["left","right","top","bottom"]: inset.add_theme_constant_override("margin_"+side,22)
	plate.add_child(inset)
	return inset

func copy(value: String, parent: Node, font_size: int, color: Color = Hud.PAPER) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	if font_size>=28: label.add_theme_font_override("font",Hud.display())
	parent.add_child(label)
	return label
