extends RefCounted

static func collect(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree(): result.append(child)
		result.append_array(collect(child))
	return result

static func visible_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var parent := control.get_parent()
	var viewport := control.get_viewport()
	while parent != null and parent != viewport:
		if parent is Control and parent.clip_contents: rect = rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return rect.intersection(viewport.get_visible_rect())

static func inspect(node: Node) -> Dictionary:
	var nodes := collect(node)
	var findings: Array = []
	var checked := 0
	for decor in nodes:
		if not decor is TextureRect or not decor.get_meta("ui_decorative", false): continue
		checked += 1
		var rect := visible_rect(decor)
		for widget in nodes:
			if not (widget is Label or widget is Button) or widget.text.is_empty(): continue
			if widget.get_window() != decor.get_window(): continue
			var overlap := rect.intersection(visible_rect(widget))
			if overlap.size.x <= 0 or overlap.size.y <= 0: continue
			findings.append({"kind":"decor_overlaps_text", "priority":"P1", "decor":str(decor.get_path()), "text":widget.text, "intersection":[overlap.position.x,overlap.position.y,overlap.size.x,overlap.size.y]})
	return {"decorations_checked":checked,"findings":findings}
