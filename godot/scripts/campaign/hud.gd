extends RefCounted
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
	# Container layouts must not measure the ornament as content.
	var holder := Node2D.new()
	holder.z_index = 2
	target.add_child(holder)
	var art := TextureRect.new()
	art.texture = ornament(index)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.size = extent
	holder.add_child(art)
	var align := func(): holder.position = Vector2(target.size.x - extent.x + 12, -extent.y * .75)
	target.resized.connect(align)
	align.call()

static func secondary_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", panel())
	button.add_theme_color_override("font_color", PAPER)

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

static func map_for(subject: Node2D, layer: CanvasLayer) -> void:
	var map := load("res://scripts/campaign/hud_minimap.gd").new() as Control
	map.subject = subject
	layer.add_child(map)

static func retract_after(control: Control, delay: float) -> void:
	control.create_tween().tween_property(control, "modulate:a", 0.0, .25).set_delay(delay)
static func font(heading: bool = false) -> Font:
	return Tokens.label() if heading else Tokens.text()

static func display() -> Font:
	return Tokens.display()

static func lettering() -> Font:
	return Tokens.lettering()

static func icon(id: String) -> Texture2D:
	if id in ["attack", "energy", "dodge", "puxao", "line", "bag", "team", "map", "settings", "back", "save", "tail"]: return artwork("icon-" + id)
	if manifest.is_empty():
		manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/hud-manifest.json"))
		sheets.panels = load("res://assets/campaign/hud-panels.png")
		sheets.icons = load("res://assets/campaign/hud-icons.png")
	var frame: Array = manifest.frames[id]
	var texture := AtlasTexture.new()
	texture.atlas = sheets[frame[0]]
	texture.region = Rect2(frame[1], frame[2], frame[3], frame[4])
	return texture

static func panel(role: String = "dark") -> StyleBoxTexture:
	var style := sliced_panel(artwork("frame-" + (role if role in ["dark", "danger", "paper"] else "dark")), Vector4(24, 24, 24, 24))
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 18
	return style

static func flat_panel(role: String = "dark") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER if role == "paper" else DANGER if role == "danger" else SURFACE
	style.border_color = BLACK
	style.set_border_width_all(2)
	style.border_width_left = 3
	style.border_width_bottom = 5
	style.corner_detail = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = int(EDGE)
	style.corner_radius_bottom_left = int(EDGE)
	style.corner_radius_bottom_right = 2
	style.shadow_color = BLACK
	style.shadow_offset = Vector2(4, 4)
	style.shadow_size = 0
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func button_style(state: String = "normal") -> StyleBoxTexture:
	var style := sliced_panel(artwork("button-" + state), Vector4(26, 12, 26, 12))
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func focus_style(fill_background: bool = true) -> StyleBox:
	if fill_background: return button_style("focus")
	var style := StyleBoxFlat.new()
	style.draw_center = fill_background
	style.bg_color = PAPER
	style.border_color = CYAN
	style.set_border_width_all(3)
	style.set_expand_margin_all(4)
	style.corner_detail = 1
	style.corner_radius_top_right = int(EDGE + 4)
	style.corner_radius_bottom_left = int(EDGE + 4)
	return style

static func make_theme() -> Theme:
	var ui := Theme.new()
	ui.default_font = font()
	ui.default_font_size = 20
	for state in ["normal", "hover", "pressed", "disabled"]: ui.set_stylebox(state, "Button", button_style(state))
	ui.set_stylebox("focus", "Button", focus_style())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]: ui.set_color(state, "Button", INK)
	ui.set_color("font_disabled_color", "Button", Tokens.TINTA_3)
	ui.set_font("font", "Button", font(true))
	ui.set_constant("outline_size", "Button", 0)
	ui.set_color("font_color", "Label", PAPER)
	ui.set_color("font_color", "RichTextLabel", PAPER)
	ui.set_constant("separation", "VBoxContainer", 12)
	ui.set_constant("separation", "HBoxContainer", 12)
	for state in ["normal", "hover", "pressed", "disabled"]: ui.set_stylebox(state, "CheckButton", panel())
	ui.set_stylebox("focus", "CheckButton", focus_style(false))
	for color_key in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]: ui.set_color(color_key, "CheckButton", PAPER)
	ui.set_icon("checked", "CheckButton", artwork("toggle-on"))
	ui.set_icon("unchecked", "CheckButton", artwork("toggle-off"))
	ui.set_stylebox("panel", "PanelContainer", panel())
	ui.set_stylebox("panel", "AcceptDialog", panel())
	var frame := panel()
	frame.content_margin_top = 34
	frame.expand_margin_top = 34
	ui.set_stylebox("embedded_border", "Window", frame)
	ui.set_stylebox("embedded_unfocused_border", "Window", frame)
	ui.set_color("title_color", "Window", PAPER)
	ui.set_color("title_outline_modulate", "Window", INK)
	ui.set_font("title_font", "Window", font(true))
	ui.set_stylebox("normal", "LineEdit", panel("paper"))
	ui.set_stylebox("focus", "LineEdit", focus_style(false))
	ui.set_color("font_color", "LineEdit", INK)
	ui.set_color("caret_color", "LineEdit", INK)
	ui.set_color("font_placeholder_color", "LineEdit", Tokens.TINTA_3)
	ui.set_color("selection_color", "LineEdit", GOLD)
	ui.set_color("font_selected_color", "LineEdit", INK)
	var track := flat_panel()
	track.bg_color = TRACK
	track.set_border_width_all(0)
	track.shadow_size = 0
	track.shadow_offset = Vector2.ZERO
	track.set_content_margin_all(0)
	track.set_corner_radius_all(3)
	var fill: StyleBoxFlat = track.duplicate()
	fill.bg_color = LINE
	ui.set_stylebox("background", "ProgressBar", track)
	ui.set_stylebox("fill", "ProgressBar", fill)
	return ui

static func card(text: String) -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", panel())
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font(true))
	label.add_theme_color_override("font_color", PAPER)
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
	var model_id := id.trim_prefix("damaged-").trim_prefix("rabiola-")
	if model_id in ["basica", "mata", "azulao", "raio", "lacertubo", "quest-nina-tail"]: return artwork("item-" + model_id)
	return icon("bag")
