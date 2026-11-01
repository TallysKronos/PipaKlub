extends Control
## Standalone PIP-130 lab. No front_end, session, campaign state, network or save.
const Mural = preload("res://scripts/ui_mural/mural_theme.gd")
const MuralButton = preload("res://scripts/ui_mural/mural_button.gd")
const Meter = preload("res://scripts/ui_mural/mural_meter.gd")
const T = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const OPTIONS := [["Soulmonsters","team"],["Itens","bag"],["Missões","missions"],
	["Emblemas","emblems"],["Tamer","identity"],["Oficina","workshop"],
	["Salvar","save"],["Configurações","settings"]]
var menu_buttons: Array[Button] = []
var state_buttons: Array[Button] = []
var labels: Array[Label] = []
var meters: Array[Range] = []
var margin: MarginContainer
var scroll: ScrollContainer
var status: Label
var field: LineEdit
var dialog: AcceptDialog
var return_focus: Control
var activations := 0
var text_scale := 1.0
var prompt_label: Label
var info_panel: PanelContainer

func label(value:String,parent:Node,variation:="MuralBody") -> Label:
	var node:=Label.new()
	node.text=value;node.theme_type_variation=variation
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(node);labels.append(node)
	return node

func panel(parent:Node,title:="") -> VBoxContainer:
	var holder:=PanelContainer.new()
	holder.theme_type_variation="MuralPaperPanel"
	holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(holder)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	holder.add_child(column)
	if not title.is_empty():label(title,column,"MuralHeading")
	return column

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Mural.install(self)
	Controls.install()
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var background:=ColorRect.new()
	background.color=T.MURAL_GROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background)
	margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	margin.add_theme_constant_override("margin_top",24)
	margin.add_theme_constant_override("margin_bottom",24)
	scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	margin.add_child(scroll)
	var column:=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",18)
	scroll.add_child(column)
	var heading:=PanelContainer.new()
	heading.theme_type_variation="MuralTitlePanel"
	column.add_child(heading)
	var headings:=VBoxContainer.new();heading.add_child(headings)
	label("Mural de Kronasta",headings,"MuralTitle")
	label("Laboratório de peças ilustradas · PIP-130",headings,"MuralCaption")
	var split:=HFlowContainer.new()
	split.add_theme_constant_override("h_separation",20)
	split.add_theme_constant_override("v_separation",20)
	column.add_child(split)
	var menu:=panel(split,"O bairro, em cada escolha")
	menu.get_parent().custom_minimum_size.x=554
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	menu.add_child(grid)
	for pair in OPTIONS:
		var button:=MuralButton.new()
		button.text=pair[0];button.icon_id=pair[1]
		if pair[1] in ["missions","workshop"]:button.variant="MuralMintButton"
		if pair[1]=="settings":button.variant="MuralInkButton"
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(button);menu_buttons.append(button)
		button.pressed.connect(func():_activate(button.text))
	var info:=panel(split,"Seu parceiro")
	info.add_theme_constant_override("separation",8)
	info_panel=info.get_parent()
	info_panel.custom_minimum_size.x=320
	var hero:=HBoxContainer.new();info.add_child(hero)
	var portrait:=TextureRect.new()
	portrait.texture=Mural.icon("team")
	portrait.custom_minimum_size=Vector2(86,84)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.add_child(portrait)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hero.add_child(identity)
	label("Rabbito",identity,"MuralTitle")
	label("Nv. 8 · parceiro ativo",identity,"MuralCaption")
	for row in [["Linha","line",84],["Armação","hull",96],["Energia","energy",70]]:
		var caption:=HBoxContainer.new();info.add_child(caption)
		label(row[0],caption,"MuralCaption")
		var value:=label(str(row[2])+"%",caption,"MuralCaption")
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		var meter:=Meter.new();meter.kind=row[1];meter.value=float(row[2]);meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		info.add_child(meter);meters.append(meter)
	label("Prévia de dados · sem salvar",info,"MuralCaption")
	var state_panel:=panel(column,"Estado, conteúdo e retorno")
	var state_row:=HFlowContainer.new()
	state_row.add_theme_constant_override("h_separation",12)
	state_row.add_theme_constant_override("v_separation",12)
	state_panel.add_child(state_row)
	for pair in [["Disponível","dex"],["Indisponível","emblems"],["Abrir aviso","missions"]]:
		var button:=MuralButton.new()
		button.text=pair[0];button.icon_id=pair[1]
		button.disabled=pair[0]=="Indisponível"
		state_row.add_child(button);state_buttons.append(button)
		if pair[0]=="Abrir aviso":button.pressed.connect(func():open_notice(button))
		else:button.pressed.connect(func():_activate(button.text))
	field=LineEdit.new()
	field.placeholder_text="Nome do conjunto de pipas"
	field.custom_minimum_size.y=64
	state_panel.add_child(field)
	label("Oficina das Pipas e Memórias do Primeiro Vento",state_panel,"MuralHeading")
	label("Cantos e presilhas ficam firmes. Só o miolo do cartaz acompanha o conteúdo.",state_panel,"MuralCaption")
	status=label("Escolha um cartaz. Este laboratório não salva a campanha.",state_panel,"MuralCaption")
	label("Erro de exemplo: o cartaz não carregou. Tente novamente.",state_panel,"MuralErrorText")
	label("Carregando os registros do mural…",state_panel,"MuralCaption")
	prompt_label=label("",state_panel,"MuralCaption")
	var icon_strip:=HFlowContainer.new()
	icon_strip.add_theme_constant_override("h_separation",14)
	icon_strip.add_theme_constant_override("v_separation",10)
	state_panel.add_child(icon_strip)
	for item in [["Pipa Dex","dex"],["Evolução","evolution"],["Varal","varal"],["Puxão","puxao"]]:
		var entry:=VBoxContainer.new();entry.custom_minimum_size.x=116
		icon_strip.add_child(entry)
		var art:=TextureRect.new();art.texture=Mural.icon(item[1]);art.custom_minimum_size=Vector2(80,80)
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		entry.add_child(art);label(item[0],entry,"MuralCaption")
	dialog=AcceptDialog.new()
	dialog.title="Aviso do mural"
	dialog.dialog_text="O cartaz foi aberto. Feche para retornar ao mesmo ponto do mural."
	dialog.min_size=Vector2i(340,180)
	dialog.theme=Mural.shared()
	dialog.dialog_autowrap=true
	add_child(dialog)
	dialog.visibility_changed.connect(func():
		if not dialog.visible and is_instance_valid(return_focus):return_focus.grab_focus.call_deferred())
	_wire_focus()
	resized.connect(_layout)
	_layout()
	menu_buttons[0].grab_focus.call_deferred()
	_update_prompts()

func _layout() -> void:
	var inset:=maxi(24,roundi((size.x-1440)/2))
	margin.add_theme_constant_override("margin_left",inset)
	margin.add_theme_constant_override("margin_right",inset)

func _wire_focus() -> void:
	for i in menu_buttons.size():
		var b:=menu_buttons[i]
		b.focus_neighbor_left=b.get_path_to(menu_buttons[i-1 if i%2 else i+1])
		b.focus_neighbor_right=b.get_path_to(menu_buttons[i-1 if i%2 else i+1])
		b.focus_neighbor_top=b.get_path_to(menu_buttons[(i+6)%8])
		b.focus_neighbor_bottom=b.get_path_to(menu_buttons[(i+2)%8])
		b.focus_previous=b.get_path_to(menu_buttons[(i+7)%8])
		b.focus_next=b.get_path_to(menu_buttons[i+1] if i<7 else state_buttons[0])

func _activate(title:String) -> void:
	activations+=1
	status.text=title+" selecionado · prévia sem efeitos na campanha."

func open_notice(origin:Control) -> void:
	return_focus=origin
	dialog.popup_centered(Vector2i(440,230))

func _input(event:InputEvent) -> void:
	Controls.observe(event)
	_update_prompts()

func _update_prompts() -> void:
	if not is_instance_valid(prompt_label):return
	prompt_label.text="%s · confirmar   %s · voltar   Setas / direcional · navegar"%[Controls.prompt("accept"),Controls.prompt("back")]

func set_text_scale(value:float) -> void:
	text_scale=clampf(value,1,1.5)
	info_panel.custom_minimum_size.x=roundi(320*text_scale)
	for node in labels:
		if not node.has_meta("mural_base_size"):node.set_meta("mural_base_size",node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size",roundi(float(node.get_meta("mural_base_size"))*text_scale))
	for button in menu_buttons+state_buttons:
		button.add_theme_font_size_override("font_size",roundi(25*text_scale))
		button.custom_minimum_size.y=roundi(82*text_scale)
	field.add_theme_font_size_override("font_size",roundi(20*text_scale))
