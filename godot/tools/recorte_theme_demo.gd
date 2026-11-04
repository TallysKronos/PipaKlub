extends Control
## PIP-64: actual native controls, live focus, no campaign or saved preferences.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Recorte = preload("res://scripts/campaign/recorte_theme.gd")
const FX = preload("res://scripts/campaign/recorte_effects.gd")
const Spawner = preload("res://scripts/campaign/recorte_splat_spawner.gd")
const Wipe = preload("res://scripts/campaign/recorte_ink_wipe.gd")
var content: VBoxContainer
var reduced_motion := false
var spawner: Control
var impact_zone: Control
var speed: ColorRect
var word: Label
var focused: Button
var capture := false
var extent := Vector2i(1920,1080)
var _impact_serial := 0
var parallel := false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--capture": capture = true
		if arg == "--reduced-motion": reduced_motion = true
		if arg == "--parallel": parallel = true
		if arg.begins_with("--width="): extent.x = arg.trim_prefix("--width=").to_int()
		if arg.begins_with("--height="): extent.y = arg.trim_prefix("--height=").to_int()
	get_window().content_scale_size = Vector2i(1920,1080)
	get_window().size = extent
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Recorte.install(self,reduced_motion)
	var background := ColorRect.new()
	background.color = Tokens.TINTA
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for pair in [["left",64],["right",64],["top",40],["bottom",40]]: margin.add_theme_constant_override("margin_"+pair[0],pair[1])
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	margin.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",20)
	scroll.add_child(content)
	build()
	for index in 8: await get_tree().process_frame
	focused.grab_focus()
	if capture:
		await get_tree().create_timer(.20).timeout
		impact()
		for index in 3: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var destination := "res://assets/ui/recorte-v1/mockups/revisao/kit-%dx%d%s.png" % [extent.x,extent.y,"-reduced" if reduced_motion else ""]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
		var error := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(destination))
		var decoration: Control = focused.get_node("RecorteArt").get_child(0)
		var record := {"physical_size":[get_window().size.x,get_window().size.y],"reference_size":[1920,1080],
			"renderer":RenderingServer.get_current_rendering_method(),"reduced_motion":reduced_motion,
			"focus_owner":str(get_viewport().gui_get_focus_owner().get_path()),
			"focus_offset":[focused.offset_transform_position.x,focused.offset_transform_position.y],
			"rabiola_alpha":decoration.marker.modulate.a,"speedlines_visible":speed.visible,"parallel":parallel,
			"scope":"Native laboratory capture, not campaign test execution"}
		var metadata := FileAccess.open(destination.trim_suffix(".png")+".json",FileAccess.WRITE)
		metadata.store_string(JSON.stringify(record,"\t"))
		print("PIP-64 native capture: ",destination," error=",error)
		get_tree().quit(error)

func text(value: String, parent: Node, role: String = "Label") -> Label:
	var label := Label.new()
	label.text = value
	label.theme_type_variation = role
	parent.add_child(label)
	return label

func row(parent: Node, separation: int = 16) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation",separation)
	parent.add_child(node)
	return node

func button(value: String, parent: Node, action: Callable = Callable(), role: String = "Button") -> Button:
	var node := Button.new()
	node.text = value
	node.theme_type_variation = role
	node.custom_minimum_size = Vector2(240,64)
	if action.is_valid(): node.pressed.connect(action)
	parent.add_child(node)
	return node

func section(title: String, parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	panel.add_child(body)
	text(title,body,"RecorteAccentText")
	return body

func build() -> void:
	var header := row(content,24)
	text("RECORTE / FEITO PARA JOGAR",header,"RecorteTitle").size_flags_horizontal = SIZE_EXPAND_FILL
	button("1280×720 ↔ 1920×1080",header,toggle_resolution,"RecorteSecondaryButton")
	var toggle := CheckButton.new()
	toggle.text = "Reduzir movimento"
	toggle.button_pressed = reduced_motion
	toggle.toggled.connect(set_reduced)
	header.add_child(toggle)
	text("Theme único · foco de teclado/controle · tinta por evento · todos os textos são controles nativos",content,"RecorteMutedText")
	var states := row(content,32)
	for state in ["NORMAL","HOVER","FOCO REAL","PRESSIONADO","INDISPONÍVEL"]:
		var stack := VBoxContainer.new()
		stack.size_flags_horizontal = SIZE_EXPAND_FILL
		states.add_child(stack)
		text(state,stack,"RecorteMutedText")
		var node := button("VAMOS VOAR",stack)
		node.size_flags_horizontal = SIZE_EXPAND_FILL
		if state == "HOVER": node.theme_type_variation = "RecortePreviewHover"
		if state == "FOCO REAL": focused = node
		if state == "PRESSIONADO":
			node.toggle_mode = true
			node.button_pressed = true
		if state == "INDISPONÍVEL": node.disabled = true
	var middle := row(content,28)
	var nav := section("01 / NAVEGAÇÃO E SELEÇÃO",middle)
	var tabs := TabBar.new()
	for title in ["Equipe","Bolsa","Bloqueado"]: tabs.add_tab(title)
	tabs.set_tab_disabled(2,true)
	nav.add_child(tabs)
	var items := ItemList.new()
	items.custom_minimum_size = Vector2(0,150)
	items.size_flags_horizontal = SIZE_EXPAND_FILL
	for title in ["Rabiola de Carcará","Rabiola de Azulão","Ainda não encontrado"]: items.add_item(title)
	items.set_item_disabled(2,true)
	items.select(0)
	nav.add_child(items)
	button("Escolha secundária",nav,Callable(),"RecorteSecondaryButton")
	var form := section("02 / CAMPOS E AJUSTES",middle)
	for editable in [true,false]:
		var field := LineEdit.new()
		field.placeholder_text = "Nome do seu parceiro"
		field.text = "" if editable else "Somente leitura"
		field.editable = editable
		field.custom_minimum_size.y = 56
		form.add_child(field)
	var toggles := row(form)
	var switch := CheckButton.new()
	switch.text = "Som ligado"
	switch.button_pressed = true
	toggles.add_child(switch)
	var check := CheckBox.new()
	check.text = "Vibração"
	check.disabled = true
	toggles.add_child(check)
	var sliders := row(form)
	for editable in [true,false]:
		var slider := HSlider.new()
		slider.size_flags_horizontal = SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(200,48)
		slider.value = 64 if editable else 30
		slider.editable = editable
		sliders.add_child(slider)
	var status := section("03 / BARRAS, DICAS E DIÁLOGOS",middle)
	for pair in [["LINHA",78,"ProgressBar"],["ENERGIA",54,"RecorteEnergyBar"],["EXPERIÊNCIA",35,"RecorteXPBar"]]:
		var bar_row := row(status)
		text(pair[0],bar_row).custom_minimum_size.x = 180
		var bar := ProgressBar.new()
		bar.theme_type_variation = pair[2]
		bar.value = pair[1]
		bar.show_percentage = false
		bar.size_flags_horizontal = SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 18
		bar_row.add_child(bar)
	var tip := PanelContainer.new()
	tip.theme_type_variation = "RecorteTooltipPanel"
	status.add_child(tip)
	text("Foco tem rabiola e forma, além da cor.",tip,"RecortePaperText")
	var dialogs := row(status)
	button("Aviso",dialogs,show_notice,"RecorteSecondaryButton").custom_minimum_size.x = 180
	button("Confirmar",dialogs,show_confirm).custom_minimum_size.x = 180
	var effects := row(content,28)
	var halftone := section("04 / RETÍCULA EM ESPAÇO DE TELA",effects)
	var hatch := FX.surface("halftone",Tokens.PAPEL)
	hatch.custom_minimum_size = Vector2(360,105)
	hatch.size_flags_horizontal = SIZE_EXPAND_FILL
	halftone.add_child(hatch)
	text("45° · passo de 8 px · opacidade 10%",halftone,"RecorteMutedText")
	var hits := section("05 / IMPACTO ÚNICO, SEM ACÚMULO",effects)
	impact_zone = Control.new()
	impact_zone.custom_minimum_size = Vector2(420,105)
	hits.add_child(impact_zone)
	speed = FX.surface("speedlines",Tokens.CEU)
	speed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	impact_zone.add_child(speed)
	speed.hide()
	spawner = Spawner.new()
	spawner.reduced_motion = reduced_motion
	impact_zone.add_child(spawner)
	word = text("TCHAC!",impact_zone,"RecorteLettering")
	word.position = Vector2(40,8)
	word.hide()
	var hit_controls := row(hits)
	button("CRÍTICO!",hit_controls,impact,"RecorteSecondaryButton")
	var direction := OptionButton.new()
	direction.add_item("Concentração")
	direction.add_item("Paralelas")
	direction.select(1 if parallel else 0)
	direction.item_selected.connect(func(index: int): parallel = index == 1; impact())
	hit_controls.add_child(direction)
	var wipe := section("06 / MÁSCARA DO WIPE",effects)
	var sample := FX.surface("ink_wipe",Tokens.CEU)
	sample.material.set_shader_parameter("progress",.5)
	sample.custom_minimum_size = Vector2(360,105)
	sample.size_flags_horizontal = SIZE_EXPAND_FILL
	wipe.add_child(sample)
	button("Transição de tinta",wipe,show_wipe,"RecorteSecondaryButton")
	text("TAB / DIRECIONAIS  navegar    ENTER / A  confirmar    •    Movimento: 120 ms / rabiola +40 ms    •    Reduzido: fade de 80 ms",content,"RecorteMutedText")

func toggle_resolution() -> void:
	extent = Vector2i(1280,720) if get_window().size.x > 1280 else Vector2i(1920,1080)
	get_window().size = extent

func set_reduced(value: bool) -> void:
	reduced_motion = value
	get_node("RecorteUX").set_reduced_motion(value)
	if value:
		speed.hide()
		word.hide()

func impact() -> void:
	_impact_serial += 1
	var serial := _impact_serial
	spawner.spawn(Vector2(260,56),"ceu","medium")
	speed.material.set_shader_parameter("parallel",parallel)
	word.show()
	word.modulate.a = 1
	speed.visible = not reduced_motion
	if reduced_motion:
		word.modulate.a = 0
		var fade := create_tween()
		fade.tween_property(word,"modulate:a",1.0,.04)
		fade.tween_property(word,"modulate:a",0.0,.04)
	await get_tree().create_timer(.08 if reduced_motion else .25).timeout
	if serial == _impact_serial:
		speed.hide()
		word.hide()

func show_wipe() -> void:
	var wipe := Wipe.new()
	add_child(wipe)
	wipe.finished.connect(wipe.queue_free,CONNECT_ONE_SHOT)
	wipe.play(Tokens.TINTA,reduced_motion,false)

func show_notice() -> void:
	var dialog := AcceptDialog.new()
	dialog.theme = Recorte.shared()
	dialog.title = "UM NOVO VENTO"
	dialog.ok_button_text = "Entendi"
	dialog.dialog_text = "Esta demonstração não altera sua jornada."
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(560,180))

func show_confirm() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.theme = Recorte.shared()
	dialog.title = "PRONTO PARA VOAR?"
	dialog.ok_button_text = "Confirmar"
	dialog.cancel_button_text = "Cancelar"
	dialog.dialog_text = "Teste os estados do kit. Nenhum dado será gravado."
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600,190))
