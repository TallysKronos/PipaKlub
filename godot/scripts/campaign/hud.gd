extends RefCounted
const Recorte = preload("res://scripts/campaign/recorte_theme.gd")
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
## HUD Recorte: shared visual contracts for the native campaign.
const INK := Tokens.TINTA
const SURFACE := Tokens.TINTA_2
const PAPER := Tokens.PAPEL
const GOLD := Tokens.SOL
const MUTED := Tokens.PAPEL_2
const DANGER := Tokens.RABIOLA
const LINE := Tokens.FOLHA
const ENERGY := Tokens.CEU
const TRACK := Tokens.NANQUIM
const CORAL := Tokens.RABIOLA
const CYAN := Tokens.CEU
const BLACK := Tokens.NANQUIM
const EDGE := 3.0
const Pin = preload("res://scripts/campaign/hud_pin.gd")
const Icons = preload("res://scripts/campaign/recorte_icons.gd")
const InputHint = preload("res://scripts/campaign/recorte_input_hint.gd")
static var manifest: Dictionary = {}
static var sheets: Dictionary = {}

static var art_cache: Dictionary = {}
const ART_ROOT := "res://assets/campaign/ui-recorte/"
static func artwork(id: String) -> Texture2D:
	if not art_cache.has(id): art_cache[id] = load(ART_ROOT + id + ".svg")
	return art_cache[id]

static func ornament(index: int = 0) -> AtlasTexture:
	var key := "ornament-" + str(clampi(index, 0, 3))
	if art_cache.has(key): return art_cache[key]
	if not art_cache.has("ornaments"): art_cache.ornaments = load(ART_ROOT + "kite-ornaments-v1.png")
	var texture := AtlasTexture.new()
	texture.atlas = art_cache.ornaments
	# Full quadrant regions retain the alpha fringe, without rewriting the generated PNG.
	texture.region = [Rect2(0, 0, 768, 512), Rect2(768, 0, 768, 512), Rect2(0, 512, 768, 512), Rect2(768, 512, 768, 512)][clampi(index, 0, 3)]
	art_cache[key] = texture
	return texture

static func decorate(target: Control, index: int = 0, extent: Vector2 = Vector2(96, 64)) -> void:
	var art := TextureRect.new()
	art.set_meta("ui_decorative", true)
	art.texture = ornament(index)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = extent
	art.size_flags_horizontal = Control.SIZE_SHRINK_END
	target.add_child(art)

static func secondary_button(button: Button) -> void:
	button.theme_type_variation = "RecorteSecondaryButton"

static func pause_glyph(button:Button) -> void:
	button.text=""
	button.icon=preload("res://scripts/campaign/controls.gd").glyph("pause",true)
	button.expand_icon=true
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width",32)
	button.custom_minimum_size=Vector2(56,56)
	button.tooltip_text="Pausar"
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=INK
		style.border_color=CYAN if state in ["hover","focus"] else TRACK
		style.set_border_width_all(2)
		style.set_content_margin_all(6)
		button.add_theme_stylebox_override(state,style)

static func navigation_button(button:Button, secondary:bool=false, icon_id:String="") -> void:
	button.custom_minimum_size.y=maxf(48,button.custom_minimum_size.y)
	button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	if secondary:secondary_button(button)
	if not icon_id.is_empty():
		button.icon=icon(icon_id)
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",28)

static func focus_space(parent: Node) -> MarginContainer:
	# Contains the 24px visual shift, slanted edge and rabiola without moving input.
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",4)
	margin.add_theme_constant_override("margin_right",32)
	parent.add_child(margin)
	return margin

static func fit_footer(panel: PanelContainer, contents: Control, minimum_height: float = 0) -> void:
	# Height follows actual wrapped content, not a percentage of the viewport.
	var weak_panel: WeakRef = weakref(panel)
	var weak_contents: WeakRef = weakref(contents)
	var layout := func():
		var surface: PanelContainer = weak_panel.get_ref()
		var body: Control = weak_contents.get_ref()
		if surface == null or body == null or not surface.is_inside_tree(): return
		var height := maxf(minimum_height, body.get_combined_minimum_size().y + surface.get_theme_stylebox("panel").get_minimum_size().y + 8)
		surface.anchor_top = 1
		surface.offset_top = surface.offset_bottom - ceilf(height)
	contents.minimum_size_changed.connect(layout.call_deferred)
	if panel.get_parent() is Control: panel.get_parent().resized.connect(layout.call_deferred)
	layout.call_deferred()

static func focus_later(control: Control) -> void:
	var reference: WeakRef = weakref(control)
	control.get_tree().process_frame.connect(func():
		var target: Control = reference.get_ref()
		if target != null and target.is_inside_tree() and target.is_visible_in_tree(): target.grab_focus()
	, CONNECT_ONE_SHOT)

static func map_for(subject: Node2D, layer: Node) -> Control:
	var map := load("res://scripts/campaign/hud_minimap.gd").new() as Control
	map.subject = subject
	layer.add_child(map)
	return map

static func retract_after(control: Control, delay: float) -> void:
	control.create_tween().tween_property(control, "modulate:a", 0.0, .25).set_delay(delay)
static func font(heading: bool = false) -> Font:
	return Tokens.label() if heading else Tokens.text()

static func display() -> Font:
	return Tokens.display()

static func lettering() -> Font:
	return Tokens.lettering()

static func icon(id: String, high_density: bool = false) -> Texture2D:
	return Icons.texture(id,false,high_density)

static func input_hint(parent: Node, action: String, caption: String = "") -> Control:
	var hint := InputHint.new()
	hint.action = action
	hint.caption = caption
	parent.add_child(hint)
	return hint

static func interaction_glyph(panel: PanelContainer) -> void:
	panel.theme_type_variation = "RecortePromptPanel"
	var holder := Node2D.new()
	panel.add_child(holder)
	var glyph := input_hint(holder,"interact")
	var align := func(): glyph.position = Vector2(12,(panel.size.y-40)/2)
	panel.resized.connect(align)
	align.call_deferred()

static func panel(role: String = "dark") -> StyleBoxFlat:
	return make_theme().get_stylebox("panel", "RecortePaperPanel" if role == "paper" else "PanelContainer")

static func flat_panel(role: String = "dark") -> StyleBoxFlat:
	return panel(role).duplicate()

static func button_style(state: String = "normal") -> StyleBoxFlat:
	return make_theme().get_stylebox(state, "Button")

static func focus_style(fill_background: bool = true) -> StyleBox:
	return make_theme().get_stylebox("focus", "Button" if fill_background else "ItemList")

static func make_theme() -> Theme:
	return Recorte.shared()

static func card(text: String) -> PanelContainer:
	var container := PanelContainer.new()
	container.theme = make_theme()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font(true))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.size_flags_vertical = Control.SIZE_FILL
	container.add_child(label)
	# A Node2D holder is excluded from Container layout; only the surface grows.
	var holder := Node2D.new()
	holder.z_index = 1
	container.add_child(holder)
	var pin := Pin.new()
	pin.position = Vector2.ZERO
	pin.size = Vector2(20, 28)
	holder.add_child(pin)
	container.resized.connect(func(): holder.position = Vector2(container.size.x - 26, -8))
	return container

static func fit_texture(texture: Texture2D, bounds: Rect2) -> Rect2:
	var fitted := texture.get_size() * minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	return Rect2(bounds.position + (bounds.size - fitted) / 2, fitted)

static func sliced_panel(texture: Texture2D, insets: Vector4) -> StyleBoxTexture:
	# Insets are source pixels: left/top/right/bottom. No automatic shrinking of corners.
	assert(insets.x + insets.z < texture.get_width() and insets.y + insets.w < texture.get_height())
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = insets.x
	style.texture_margin_top = insets.y
	style.texture_margin_right = insets.z
	style.texture_margin_bottom = insets.w
	style.content_margin_left = insets.x
	style.content_margin_top = insets.y
	style.content_margin_right = insets.z
	style.content_margin_bottom = insets.w
	return style

static var _stat_styles: Dictionary = {}
static func stat_card(canvas: CanvasItem, rect: Rect2, title: String, actor: Dictionary, role: String = "dark", training: bool = false) -> void:
	if not _stat_styles.has(role): _stat_styles[role] = panel(role)
	canvas.draw_style_box(_stat_styles[role], rect)
	canvas.draw_string(font(true), rect.position + Vector2(14, 28), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 23, PAPER)
	var names := ["Linha", "Energia"] if training else ["Linha", "Armação", "Energia"]
	var values: Array = [actor.hp / 100.0, actor.energy / 100.0] if training else [actor.hp / actor.stats.line, actor.hull / actor.stats.line, actor.energy / actor.stats.energy]
	for index in names.size():
		var y: float = rect.position.y + 52 + index * 24
		var fraction: float = clampf(values[index], 0, 1)
		var track_width := rect.size.x - 186
		var color: Color = ENERGY if names[index] == "Energia" else MUTED if names[index] == "Armação" else CORAL if role == "danger" else CYAN
		if index == 0 and fraction < .25: color = Tokens.RABIOLA
		canvas.draw_string(font(), Vector2(rect.position.x + 14, y), names[index], HORIZONTAL_ALIGNMENT_LEFT, 94, 21, PAPER)
		canvas.draw_rect(Rect2(rect.position.x + 110, y - 13, track_width, 11), TRACK)
		if names[index] == "Energia":
			var cell_width := (track_width - 18) / 10
			for cell in 10:
				var amount := clampf(fraction * 10 - cell, 0, 1)
				canvas.draw_rect(Rect2(rect.position.x + 110 + cell * (cell_width + 2), y - 13, cell_width * amount, 11), color)
		else: canvas.draw_rect(Rect2(rect.position.x + 110, y - 13, track_width * fraction, 11), color)
		canvas.draw_string(font(true), Vector2(rect.end.x - 64, y), "%d%%" % roundi(fraction * 100), HORIZONTAL_ALIGNMENT_LEFT, 62, 21, PAPER)

static func draw_result(canvas: CanvasItem, won: bool, fled: bool = false) -> void:
	var splat := artwork("splat")
	canvas.draw_texture_rect(splat, Rect2(150, 340, 230, 170), false, Color(CYAN if won else CORAL, .8))
	canvas.draw_texture_rect(splat, Rect2(650, 330, 205, 155), false, Color(CYAN if won else CORAL, .6))
	var ribbon := artwork("ribbon-victory" if won else "ribbon-defeat")
	canvas.draw_texture_rect(ribbon, fit_texture(ribbon, Rect2(170, 385, 660, 146)), false)
	var left := ornament(0 if won else 1)
	canvas.draw_texture_rect(left, fit_texture(left, Rect2(124, 370, 155, 103)), false)
	var right := ornament(1 if won else 3)
	canvas.draw_texture_rect(right, fit_texture(right, Rect2(745, 408, 130, 87)), false)
	var text := "VITÓRIA!" if won else "ATÉ A PRÓXIMA" if fled else "DERROTA"
	var text_width := display().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x
	canvas.draw_string(display(), Vector2(500 - text_width / 2, 480), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, INK)

static func item_icon(id: String) -> Texture2D:
	return icon("missoes" if id.begins_with("quest-") else "rabiola" if "rabiola" in id else "mochila")

static func item_art(id: String) -> Texture2D:
	if id=="kit-remendo":return load("res://assets/ui/kit-remendo.svg")
	var model_id := id.trim_prefix("damaged-").trim_prefix("rabiola-")
	if model_id in ["basica", "mata", "azulao", "raio", "lacertubo", "quest-nina-tail"]: return artwork("item-" + model_id)
	return icon("bag")
