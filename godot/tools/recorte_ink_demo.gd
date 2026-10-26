extends Control
## PIP-63 review scene. No campaign, account, network or save access.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
const Frame = preload("res://scripts/campaign/recorte_ink_frame.gd")
const Sequence = preload("res://scripts/campaign/recorte_splat_sequence.gd")
var sequence := Sequence.new(63)
var content: VBoxContainer
var capture_mode := ""
var selection := "frame-panel"
var splat_preview: TextureRect

func _ready() -> void:
	var extent := Vector2i(1920, 1080)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_mode = arg.trim_prefix("--capture=")
		if arg.begins_with("--asset="): selection = arg.trim_prefix("--asset=")
		if arg.begins_with("--width="): extent.x = arg.trim_prefix("--width=").to_int()
		if arg.begins_with("--height="): extent.y = arg.trim_prefix("--height=").to_int()
	get_window().content_scale_size = extent
	get_window().size = extent
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme_resource := Theme.new()
	theme_resource.default_font = Tokens.text()
	theme_resource.default_font_size = 20
	theme_resource.set_color("font_color", "Label", Tokens.PAPEL)
	theme = theme_resource
	var background := ColorRect.new()
	background.color = Tokens.TINTA
	background.mouse_filter = MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	margin.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	if capture_mode == "stretch": build_stretch(selection)
	else: build_board()
	if not capture_mode.is_empty():
		for index in 6: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var destination := "res://assets/ui/recorte-v1/mockups/kit-tinta.png" if capture_mode == "board" else "res://../documentation/evidence/pip63/stretch-" + selection.validate_filename() + ".png"
		var absolute := ProjectSettings.globalize_path(destination).simplify_path()
		DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
		var error := get_viewport().get_texture().get_image().save_png(absolute)
		print("PIP-63 native capture: ", absolute, " error=", error)
		get_tree().quit(error)

func caption(text: String, parent: Node, size_px: int = 20, color: Color = Tokens.PAPEL) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", Tokens.label())
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func row(parent: Node, gap: int = 16) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	parent.add_child(node)
	return node

func section(title: String, parent: Node) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	node.add_theme_constant_override("separation", 8)
	parent.add_child(node)
	caption(title, node, 24, Tokens.CEU)
	return node

func preview(id: String, parent: Node, extent: Vector2, tint: Color = Tokens.UNTINTED) -> TextureRect:
	var image := TextureRect.new()
	image.texture = Ink.texture(id)
	image.custom_minimum_size = extent
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.modulate = tint
	image.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func paper_frame(id: String, parent: Node, extent: Vector2, dense: bool = false) -> Control:
	var box := Control.new()
	box.custom_minimum_size = extent
	box.size_flags_horizontal = SIZE_SHRINK_BEGIN
	parent.add_child(box)
	var fill := ColorRect.new()
	fill.color = Tokens.PAPEL
	fill.mouse_filter = MOUSE_FILTER_IGNORE
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(fill)
	var frame := Frame.new()
	frame.asset_id = id
	frame.high_density = dense
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(frame)
	return box

func action(text: String, parent: Node, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 44)
	button.add_theme_font_override("font", Tokens.label())
	button.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "focus", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Tokens.PAPEL if state in ["hover", "focus"] else Tokens.TINTA_2
		style.set_content_margin_all(10)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Tokens.PAPEL)
	button.add_theme_color_override("font_hover_color", Tokens.NANQUIM)
	button.add_theme_color_override("font_focus_color", Tokens.NANQUIM)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func clear_content() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func build_board() -> void:
	clear_content()
	var header := row(content)
	var title := caption("RECORTE / TINTA VIVA", header, 46)
	title.add_theme_font_override("font", Tokens.display())
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	var inspect := action("INSPECIONAR 9-PATCH", header, func(): build_stretch("frame-panel"))
	if capture_mode.is_empty(): inspect.grab_focus()
	caption("PIP-63 · 64 PEÇAS · PNG 1× / 2× · TINTA E PAPEL · NENHUM TEXTO GRAVADO NOS ASSETS", content, 20, Tokens.PAPEL_2)
	var first := row(content, 28)
	var frames := section("01  MOLDURAS / CANTOS FIXOS", first)
	var frame_row := row(frames, 10)
	for pair in [["frame-panel", "PAINEL"], ["frame-ribbon", "FAIXA"], ["frame-button", "BOTÃO"], ["frame-list-item", "LISTA"], ["frame-speech", "BALÃO"]]:
		var stack := VBoxContainer.new()
		frame_row.add_child(stack)
		paper_frame(pair[0], stack, Vector2(148, 116))
		caption(pair[1], stack, 18)
	caption("48 px nos cantos · 64 px no trecho repetível · centro transparente", frames, 18, Tokens.PAPEL_2)
	var balloons := section("02  FALA, GRITO, PENSAMENTO, SUSSURRO", first)
	var balloon_row := row(balloons, 12)
	for pair in [["speech", "left"], ["shout", "right"], ["thought", "thought"], ["whisper", "whisper"]]:
		var stack := VBoxContainer.new()
		balloon_row.add_child(stack)
		paper_frame("balloon-" + pair[0], stack, Vector2(220, 160))
		var tail_area := PanelContainer.new()
		var tail_paper := StyleBoxFlat.new()
		tail_paper.bg_color = Tokens.PAPEL
		tail_area.add_theme_stylebox_override("panel", tail_paper)
		stack.add_child(tail_area)
		preview("tail-" + pair[1], tail_area, Vector2(64, 32), Tokens.UNTINTED)
	caption("Rabichos separados · composição e texto permanecem no Godot", balloons, 18, Tokens.PAPEL_2)
	var splats := section("03  RESPINGOS / CHEIOS + CONTORNOS", content)
	var splat_row := row(splats, 12)
	for family in ["small", "medium", "large", "drip", "trail"]:
		for id in Ink.family(family):
			var stack := VBoxContainer.new()
			splat_row.add_child(stack)
			var pair := row(stack, 0)
			preview(id, pair, Vector2(52, 80), Tokens.CEU)
			preview(id + "-outline", pair, Vector2(52, 80), Tokens.PAPEL)
			caption(id.to_upper(), stack, 16, Tokens.PAPEL_2)
	caption("3 P (48 px) · 3 M (120 px) · 2 G (320 px) · 4 escorridos · 3 rastros · fonte branca recolorível", splats, 18, Tokens.PAPEL_2)
	var third := row(content, 28)
	var emotes := section("04  EMOÇÕES / ADESIVO DE PAPEL", third)
	var emote_row := row(emotes, 12)
	for id in ["sweat", "anger", "sparkle", "surprise", "question", "heart", "dizzy", "sigh"]:
		preview(id, emote_row, Vector2(96, 108))
	caption("96 px · dupla tinta nanquim/papel · sem recolorir a borda", emotes, 18, Tokens.PAPEL_2)
	var stickers := section("05  RECOMPENSA / TEXTO VIVO", third)
	var sticker_row := row(stickers, 12)
	for id in ["sticker-new", "sticker-rare", "sticker-level", "sticker-double"]:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(160, 108)
		sticker_row.add_child(holder)
		var art := preview(id, holder, Vector2.ZERO)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var live := caption(Ink.definition(id).live_label, holder, 24)
		live.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		live.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		live.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption("160 px · letras são Labels, não pixels dos adesivos", stickers, 18, Tokens.PAPEL_2)
	var fourth := row(content, 28)
	var strokes := section("06  SELEÇÃO / TRÊS PINCELADAS", fourth)
	var stroke_row := row(strokes, 12)
	for index in 3: preview("selection-%d" % (index + 1), stroke_row, Vector2(250, 80), Tokens.PAPEL)
	caption("64 px de altura · 3-slice horizontal · pontas preservadas", strokes, 18, Tokens.PAPEL_2)
	var textures := section("07  IMPACTO E TRANSIÇÃO", fourth)
	var texture_row := row(textures, 16)
	for id in ["concentration", "parallel", "splat_mask", "dots-fine", "dots-dense", "dots-ramp"]:
		preview(id, texture_row, Vector2(120, 110), Tokens.UNTINTED)
	caption("Linhas 2048 px · máscara 1024 px · retículas 256 px", textures, 18, Tokens.PAPEL_2)
	var footer := row(content)
	splat_preview = preview("medium-1", footer, Vector2(64, 48), Tokens.RABIOLA)
	action("OUTRO RESPINGO", footer, next_splat)
	caption("SEMENTE 63 · variação sem repetir a anterior · sem animação contínua\nPrancha para revisão visual do responsável. Integração das telas segue nas próximas tarefas.", footer, 18, Tokens.PAPEL_2)
	call_deferred("next_splat")

func next_splat() -> void:
	var choice := sequence.next("medium")
	splat_preview.texture = Ink.texture(choice.id)
	splat_preview.flip_h = choice.flip_h
	splat_preview.flip_v = choice.flip_v
	splat_preview.pivot_offset = splat_preview.size / 2
	splat_preview.rotation = choice.rotation

func build_stretch(id: String) -> void:
	clear_content()
	selection = id
	var header := row(content)
	caption("CANTOS FIXOS / 200 → 1600 PX", header, 36).size_flags_horizontal = SIZE_EXPAND_FILL
	var picker := OptionButton.new()
	var choices := ["frame-panel", "frame-ribbon", "frame-button", "frame-list-item", "frame-speech", "balloon-speech", "balloon-shout", "balloon-thought", "balloon-whisper", "selection-1", "selection-2", "selection-3"]
	for option in choices: picker.add_item(option)
	picker.select(choices.find(id))
	picker.item_selected.connect(func(index: int): build_stretch(choices[index]))
	header.add_child(picker)
	action("VOLTAR À PRANCHA", header, build_board)
	var stroke: bool = Ink.definition(id).slice.mode == "three_slice"
	var extent := 64 if stroke else 160 if id.begins_with("balloon-") else 120
	caption(id + (" · 3-slice / miolo elástico" if stroke else " · NinePatchRect TILE_FIT / centro transparente") + " · camada sem captura de input", content, 22, Tokens.CEU)
	for width in [200, 400, 800, 1600]:
		caption("%d PX / FONTE 1×" % width, content, 20, Tokens.PAPEL_2)
		var surface := paper_frame(id, content, Vector2(width, extent))
		if stroke: (surface.get_child(0) as ColorRect).color = Tokens.TINTA_3
	caption("1600 PX / FONTE 2× · mesma dimensão dos cantos na tela", content, 20, Tokens.PAPEL_2)
	var dense_surface := paper_frame(id, content, Vector2(1600, extent), true)
	if stroke: (dense_surface.get_child(0) as ColorRect).color = Tokens.TINTA_3
