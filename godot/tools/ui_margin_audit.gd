extends RefCounted
## Layout review: reports text that leaves its box, gets cut, leaves the screen or
## sits too close to the screen or to the panel that frames it. Read-only.
## Distances are in the 1280x720 design space (canvas_items stretch).
const SCREEN_GAP := 16.0
const PANEL_GAP := 8.0

static func report(root: Window, shot: String) -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var found := 0
	for control in _controls(root):
		for issue in _check(control, screen):
			found += 1
			print("AUDIT ", JSON.stringify({"shot": shot, "path": _short(control), "text": _text(control).left(48), "issue": issue,"ink":str(_ink(control)),"screen":str(screen),"control":str(control.get_global_rect())}))
	print("AUDIT_DONE ", shot, " textos=", _controls(root).size(), " problemas=", found)

static func _controls(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		if child is CanvasItem and not child.visible: continue
		# World signage (labels under a Node2D scene) moves with the camera; not HUD.
		if child is Node2D: continue
		if child is Label or child is Button or child is RichTextLabel or child is LineEdit:
			if child.is_visible_in_tree() and not _text(child).strip_edges().is_empty(): out.append(child)
		out.append_array(_controls(child))
	return out

static func _text(control: Control) -> String:
	if control is RichTextLabel: return control.get_parsed_text()
	return str(control.get("text"))

static func _short(control: Control) -> String:
	var parts: PackedStringArray = []
	var node: Node = control
	for i in 4:
		if node == null: break
		var label := node.name as String
		var script: Script = node.get_script()
		if script: label += "<" + script.resource_path.get_file().get_basename() + ">"
		parts.insert(0, label)
		node = node.get_parent()
	return "/".join(parts)

static func _scale(control: Control) -> float:
	var t := control.get_global_transform_with_canvas()
	return t.get_scale().x

# Rectangle the glyphs really occupy, in screen space.
static func _ink(control: Control) -> Rect2:
	var rect := Rect2(Vector2.ZERO, control.size)
	if control is Label and not control.clip_text:
		var font: Font = control.get_theme_font("font")
		var size: int = control.get_theme_font_size("font_size")
		var width := 0.0
		for line in control.text.split("\n"): width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
		if control.autowrap_mode != TextServer.AUTOWRAP_OFF:
			width=minf(width,control.size.x)
			if control.get_line_count()>1:width=font.get_multiline_string_size(control.text,control.horizontal_alignment,control.size.x,size).x
		var height: float = control.get_line_count() * control.get_line_height() + max(0, control.get_line_count() - 1) * control.get_theme_constant("line_spacing")
		var x := 0.0
		if control.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER: x = (control.size.x - width) * .5
		elif control.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT: x = control.size.x - width
		var y := 0.0
		if control.vertical_alignment == VERTICAL_ALIGNMENT_CENTER: y = (control.size.y - height) * .5
		elif control.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM: y = control.size.y - height
		rect = Rect2(x, y, width, height)
	elif control is Button and not control.text.is_empty():
		var font: Font = control.get_theme_font("font")
		var fsize: int = control.get_theme_font_size("font_size")
		var text_size: Vector2 = font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
		var box: StyleBox = control.get_theme_stylebox("normal")
		var inner := Rect2(Vector2(box.get_margin(SIDE_LEFT), box.get_margin(SIDE_TOP)), control.size - box.get_minimum_size())
		var icon_w := 0.0
		if control.icon != null:
			var limit: int = control.get_theme_constant("icon_max_width")
			icon_w = (minf(control.icon.get_width(), limit) if limit > 0 else float(control.icon.get_width())) + control.get_theme_constant("h_separation")
			if control.expand_icon: icon_w = minf(icon_w, inner.size.y + control.get_theme_constant("h_separation"))
		var x: float = inner.position.x + icon_w
		if control is CheckButton or control is CheckBox: inner.size.x -= control.get_theme_icon("checked").get_width() + control.get_theme_constant("h_separation")
		if control.autowrap_mode!=TextServer.AUTOWRAP_OFF:text_size=font.get_multiline_string_size(control.text,control.alignment,maxf(1,inner.size.x-icon_w),fsize)
		if control.alignment == HORIZONTAL_ALIGNMENT_CENTER: x = inner.position.x + icon_w + (inner.size.x - icon_w - text_size.x) * .5
		elif control.alignment == HORIZONTAL_ALIGNMENT_RIGHT: x = inner.end.x - text_size.x
		rect = Rect2(x, inner.position.y + (inner.size.y - text_size.y) * .5, text_size.x, text_size.y)
	var t := control.get_global_transform_with_canvas()
	return Rect2(t * rect.position, rect.size * t.get_scale())

static func _check(control: Control, screen: Rect2) -> Array:
	var issues: Array = []
	var original_ink:=_ink(control)
	var ink:=original_ink
	# Scroll content is deliberately outside its viewport until navigated to.
	# Measure only pixels that can actually be painted; keep focused clipping a fault.
	var ancestor:=control.get_parent()
	while ancestor!=null and ancestor!=control.get_viewport():
		if ancestor is Control and ancestor.clip_contents:
			var bounds:=Rect2(ancestor.get_global_transform_with_canvas().origin,ancestor.size*ancestor.get_global_transform_with_canvas().get_scale())
			ink=ink.intersection(bounds)
		ancestor=ancestor.get_parent()
	if control.has_focus() and not ink.grow(.5).encloses(original_ink):issues.append("texto com foco cortado pelo scroll")
	if not ink.has_area():return issues
	var own := Rect2(control.get_global_transform_with_canvas().origin, control.size * _scale(control))
	if control is Label:
		if control.autowrap_mode == TextServer.AUTOWRAP_OFF and not control.clip_text and control.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING:
			var need: float = control.get_minimum_size().x
			if need > control.size.x + 1.0: issues.append("texto mais largo que a caixa (%d > %d)" % [need, control.size.x])
		if control.get_line_count() > control.get_visible_line_count(): issues.append("linhas cortadas (%d de %d visíveis)" % [control.get_visible_line_count(), control.get_line_count()])
		elif control.autowrap_mode != TextServer.AUTOWRAP_OFF and control.get_minimum_size().y > control.size.y + 1.0: issues.append("texto mais alto que a caixa")
		if control.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING and control.get_minimum_size().x > control.size.x + 1.0 and control.autowrap_mode == TextServer.AUTOWRAP_OFF:
			issues.append("texto truncado com reticências")
	elif control is Button:
		var need: float = control.get_minimum_size().x
		if need > control.size.x + 1.0 and not control.clip_text: issues.append("rótulo do botão maior que o botão (%d > %d)" % [need, control.size.x])
	elif control is RichTextLabel:
		if not control.fit_content and not control.scroll_active and control.get_content_height() > control.size.y + 1.0: issues.append("texto rico mais alto que a caixa")
	if not screen.encloses(ink.grow(-1.0)): issues.append("texto sai da tela")
	else:
		var gap: float = minf(minf(ink.position.x - screen.position.x, ink.position.y - screen.position.y), minf(screen.end.x - ink.end.x, screen.end.y - ink.end.y))
		if gap < SCREEN_GAP: issues.append("texto a %d px da borda da tela" % gap)
	var frame: Control = control if control is Button and not (control.get_theme_stylebox("normal") is StyleBoxEmpty) else _frame(control)
	if frame != null:
		var box := Rect2(frame.get_global_transform_with_canvas().origin, frame.size * _scale(frame))
		var gap_min := 6.0 if control is Button else PANEL_GAP
		if box.size.x > 4 and box.size.y > 4 and box.size.x < screen.size.x * .98:
			if not box.grow(1.0).encloses(ink): issues.append("texto sai do painel " + frame.name)
			else:
				var gap: float = minf(minf(ink.position.x - box.position.x, ink.position.y - box.position.y), minf(box.end.x - ink.end.x, box.end.y - ink.end.y))
				if gap < gap_min: issues.append("texto a %d px da borda do painel %s" % [gap, frame.name])
	return issues

# Nearest ancestor that paints a background: panel, panel container or custom drawing.
static func _frame(control: Control) -> Control:
	var node := control.get_parent()
	while node != null:
		if node is Control:
			if (node is Panel or node is PanelContainer) and not (node.get_theme_stylebox("panel") is StyleBoxEmpty): return node
			if node is Button: return node
			if node.get_script() != null and node.get_script().has_method("_draw") or (node.has_method("_draw") and node.get_script() != null and node.get_script().source_code.contains("func _draw")): return node
		node = node.get_parent()
	return null
