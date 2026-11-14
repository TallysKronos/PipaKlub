extends PanelContainer
## Opening dialogue skin. The campaign still owns pagination and progression.

const Hud = preload("res://scripts/campaign/hud.gd")
const Layout = preload("res://scripts/campaign/hud_layout.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const NAVY := Color("#081b38")
const DEEP := Color("#0b182c")
const BLUE := Color("#1747a6")
const CYAN := Color("#51c9ff")
const ICE := Color("#ecf6ff")
const CORAL := Color("#ff585a")

var speaker := ""
var shouted := false
var portrait_present := false
var minimum_height := 176.0

func _ready() -> void:
	set_meta("recorte_decorated", true)
	var inset := StyleBoxEmpty.new()
	inset.content_margin_left = 50
	inset.content_margin_right = 50
	inset.content_margin_top = 33
	inset.content_margin_bottom = 16
	add_theme_stylebox_override("panel", inset)
	resized.connect(queue_redraw)
	var viewport_owner := get_parent() as Control
	viewport_owner.resized.connect(fit)
	minimum_size_changed.connect(fit.call_deferred)
	fit()

func fit() -> void:
	var viewport_owner := get_parent() as Control
	if viewport_owner == null:
		return
	var safe := Layout.safe_rect(viewport_owner.size)
	var left := safe.position.x + (safe.size.x * .215 if portrait_present else 0.0)
	var height := maxf(minimum_height, get_combined_minimum_size().y)
	position = Vector2(left, safe.end.y - height)
	size = Vector2(safe.end.x - left, height)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	plate(self, rect.grow(5), Color("#102958"), Color("#214b91"), 35, 1)
	plate(self, rect, NAVY, ICE, 33, 3)
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, size.y - 16), Vector2(44, size.y - 16),
		Vector2(72, size.y - 2), Vector2(2, size.y - 2)
	]), BLUE)
	draw_line(Vector2(12, size.y - 2), Vector2(92, size.y - 2), CYAN, 2, true)
	draw_line(Vector2(size.x - 115, 1), Vector2(size.x - 12, 1), CYAN, 3, true)
	if not speaker.is_empty():
		var cue := Vector2(size.x - 248, size.y - 34)
		draw_colored_polygon(PackedVector2Array([cue + Vector2(-6, 0), cue + Vector2(6, 0), cue + Vector2(0, 8)]), CORAL)
	if speaker.is_empty():
		return
	var font := Hud.display()
	var title_size := 27
	var width := maxf(156.0, font.get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x + 68)
	var tab := Rect2(25, -32, width, 48)
	plate(self, tab, BLUE, CYAN, 17, 2)
	draw_string(font, tab.position + Vector2(32, 33), speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, ICE)
	slash(self, tab.position + Vector2(width + 4, 2), 8, 28, CORAL)
	slash(self, tab.position + Vector2(width + 17, 2), 7, 28, CYAN)
	if shouted:
		slash(self, Vector2(size.x - 52, -17), 5, 12, CORAL)

static func plate(canvas: CanvasItem, rect: Rect2, fill: Color, edge: Color, cut: float, stroke: float) -> void:
	var p := rect.position
	var e := rect.end
	var outline := PackedVector2Array([
		p + Vector2(cut, 0), Vector2(e.x - 8, p.y),
		Vector2(e.x, p.y + 9), e - Vector2(cut, 8),
		e - Vector2(cut + 10, 0), Vector2(p.x + 8, e.y),
		Vector2(p.x, e.y - 9)
	])
	canvas.draw_colored_polygon(outline, fill)
	outline.append(outline[0])
	canvas.draw_polyline(outline, edge, stroke, true)

static func slash(canvas: CanvasItem, origin: Vector2, width: float, height: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		origin, origin + Vector2(width, 0), origin + Vector2(width + 13, height), origin + Vector2(13, height)
	]), color)

static func make_backdrop(parent: Control, step: int) -> Control:
	var backdrop := Control.new()
	backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	backdrop.resized.connect(backdrop.queue_redraw)
	backdrop.draw.connect(func():
		var extent := backdrop.size
		backdrop.draw_rect(Rect2(Vector2.ZERO, extent), DEEP)
		var safe := Layout.safe_rect(extent)
		var origin := Vector2(safe.position.x, 0)
		backdrop.draw_colored_polygon(PackedVector2Array([
			origin + Vector2(-340, extent.y * .13), origin + Vector2(300, extent.y * .59),
			origin + Vector2(143, extent.y + 1), origin + Vector2(-340, extent.y + 1)
		]), Color("#102b5d"))
		backdrop.draw_colored_polygon(PackedVector2Array([
			origin + Vector2(-280, extent.y * .23), origin + Vector2(245, extent.y * .61),
			origin + Vector2(202, extent.y * .73), origin + Vector2(-280, extent.y * .38)
		]), Color("#17498c"))
		for y in range(int(extent.y * .25), int(extent.y * .75), 12):
			for x in range(maxi(0, int(origin.x) - 96), int(origin.x) + 228, 12):
				backdrop.draw_circle(Vector2(x, y), 1.25, Color(CYAN, .21))
		var kite := Vector2(safe.end.x - 65, extent.y * .24)
		backdrop.draw_polyline(PackedVector2Array([
			kite + Vector2(0, -62), kite + Vector2(50, -9), kite + Vector2(0, 79),
			kite + Vector2(-50, -9), kite + Vector2(0, -62), kite + Vector2(0, 79),
			kite + Vector2(-17, 111), kite + Vector2(4, 136), kite + Vector2(-14, 165)
		]), Color(CORAL, .27), 2.0, true)
		if step == 2:
			var badge := Rect2(safe.position, Vector2(190, 48))
			plate(backdrop, badge, NAVY, Color("#3665b5"), 19, 2)
			slash(backdrop, badge.position + Vector2(151, 3), 8, 34, CORAL)
			backdrop.draw_string(Hud.display(), badge.position + Vector2(31, 34), "Kael",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, ICE)
			backdrop.draw_string(Hud.font(), badge.position + Vector2(18, 73), "Pipeiro iniciante",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#98c7ef")))
	return backdrop

static func style_button(button: Button, action: String) -> void:
	button.set_meta("recorte_decorated", true)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var inset := StyleBoxEmpty.new()
		inset.set_content_margin_all(10)
		inset.content_margin_left = 22
		inset.content_margin_right = 22
		button.add_theme_stylebox_override(state, inset)
	button.custom_minimum_size.y = 50
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 25)
	button.add_theme_constant_override("h_separation", 9)
	button.add_theme_font_override("font", Hud.Tokens.text(true))
	button.add_theme_font_size_override("font_size", 20 if action == "accept" else 16)
	var accent := action == "accept"
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, DEEP if accent else ICE)
	button.add_theme_color_override("font_disabled_color", Color("#324968") if accent else Color("#a4b9d2"))
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var art := Control.new()
	art.mouse_filter = MOUSE_FILTER_IGNORE
	art.show_behind_parent = true
	button.add_child(art)
	art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	art.draw.connect(func():
		var rect := Rect2(Vector2.ZERO, art.size)
		var focused := button.has_focus() or button.is_hovered()
		var edge := CYAN if focused else Color("#365c97")
		var fill := Color("#bfe7ff") if button.button_pressed else ICE
		if button.disabled:
			fill = Color("#b5c9e2") if accent else Color("#20324d")
		elif not accent:
			fill = BLUE if focused else NAVY
		if focused:
			plate(art, rect.grow(3), Color("#14346c"), CYAN, 15, 2)
		plate(art, rect, fill, edge, 15, 2))
	for signal_name in ["focus_entered", "focus_exited", "mouse_entered", "mouse_exited", "button_down", "button_up", "resized"]:
		button.connect(signal_name, art.queue_redraw)
	var update_glyph := func():
		button.icon = Controls.glyph(action)
		art.queue_redraw()
	Controls.events.changed.connect(update_glyph)
	button.tree_exiting.connect(func(): Controls.events.changed.disconnect(update_glyph), CONNECT_ONE_SHOT)
	update_glyph.call()
