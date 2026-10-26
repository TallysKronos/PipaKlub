extends SceneTree
## Interactive component lab. No campaign session, network or save writes.
const Hud = preload("res://scripts/campaign/hud.gd")
const Backdrop = preload("res://scripts/campaign/hud_backdrop.gd")
func _initialize() -> void:
	call_deferred("build_lab")
func label(text: String, parent: Node, heading: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", Hud.display() if heading else Hud.font())
	node.add_theme_font_size_override("font_size", 32 if heading else 18)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(node)
	return node
func build_lab() -> void:
	var width := 1280
	var height := 720
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--width="): width = clampi(argument.trim_prefix("--width=").to_int(), 800, 2560)
		if argument.begins_with("--height="): height = clampi(argument.trim_prefix("--height=").to_int(), 600, 1440)
	root.size = Vector2i(width, height)
	var surface := Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.theme = Hud.make_theme()
	root.add_child(surface)
	var background := ColorRect.new()
	background.color = Hud.INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(background)
	surface.add_child(Backdrop.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 32)
	surface.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	label("SOULMONSTERS  /  HUD RECORTE", column).add_theme_color_override("font_color", Hud.CYAN)
	label("Personalidade na forma. Clareza na informação.", column, true)
	label("Papel, varetas e nós · moldura em nove partes · texto e adornos independentes", column)
	var family := HBoxContainer.new()
	column.add_child(family)
	for index in 4:
		var ornament := TextureRect.new()
		ornament.texture = Hud.ornament(index)
		ornament.custom_minimum_size = Vector2(150, 100)
		ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ornament.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		family.add_child(ornament)
	var palette := HFlowContainer.new()
	column.add_child(palette)
	for pair in [["Tinta", Hud.INK], ["Papel", Hud.PAPER], ["Dourado", Hud.GOLD], ["Verde", Hud.SURFACE], ["Risco", Hud.DANGER], ["Linha", Hud.LINE], ["Energia", Hud.ENERGY]]:
		var swatch := PanelContainer.new()
		var style := Hud.flat_panel()
		style.bg_color = pair[1]
		swatch.add_theme_stylebox_override("panel", style)
		swatch.custom_minimum_size = Vector2(140, 52)
		palette.add_child(swatch)
		var caption := label(pair[0], swatch)
		caption.add_theme_color_override("font_color", Hud.PAPER if pair[0] in ["Tinta", "Verde"] else Hud.BLACK)
	label("01  /  MESMO COMPONENTE, TRÊS LARGURAS", column).add_theme_color_override("font_color", Hud.GOLD)
	var cards := HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 20)
	cards.add_theme_constant_override("v_separation", 20)
	column.add_child(cards)
	for extent in [220, 360, 540]:
		var card := Hud.card("Veredas do Encantamento\n%d px · cantos fixos" % extent)
		card.custom_minimum_size = Vector2(extent, 130)
		cards.add_child(card)
	label("02  /  ESTADOS SEM MUDAR A CAIXA", column).add_theme_color_override("font_color", Hud.GOLD)
	var states := HFlowContainer.new()
	column.add_child(states)
	var focused: Button
	for state in ["Normal", "Destaque", "Pressionado", "Indisponível", "Foco / controle"]:
		var button := Button.new()
		button.text = state
		button.custom_minimum_size = Vector2(205, 56)
		states.add_child(button)
		if state == "Destaque": button.add_theme_stylebox_override("normal", Hud.button_style("hover"))
		if state == "Pressionado": button.add_theme_stylebox_override("normal", Hud.button_style("pressed"))
		if state == "Indisponível": button.disabled = true
		if state == "Foco / controle": focused = button
	label("03  /  CONTEÚDO NO PAPEL, AÇÃO EM EVIDÊNCIA", column).add_theme_color_override("font_color", Hud.GOLD)
	var dialogue := PanelContainer.new()
	dialogue.add_theme_stylebox_override("panel", Hud.panel("paper"))
	column.add_child(dialogue)
	var body := VBoxContainer.new()
	dialogue.add_child(body)
	label("Nina  /  Um laço que vale recuperar", body).add_theme_color_override("font_color", Hud.INK)
	label("Cada Pipamon tem seu jeito de voar. A interface abre espaço para a história — os enfeites acompanham a moldura sem esticar com ela.", body).add_theme_color_override("font_color", Hud.INK)
	focused.grab_focus()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://").path_join("../tmp/campaign-review").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var output := folder.path_join("hud-lab-%dx%d.png" % [width, height])
	root.get_texture().get_image().save_png(output)
	print(output)
	if "--capture" in OS.get_cmdline_user_args(): quit()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): quit()
