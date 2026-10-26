extends SceneTree
## Rendered UI audit, separate from the earned gameplay replay. Isolated storage only.
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
var front: Control
var results: Array = []
var phase := "before"
var output := ""
var scenarios: Array[String] = []
var sizes: Array[Vector2i] = [Vector2i(1270, 710), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(960, 540)]
func _initialize() -> void:
	call_deferred("run_audit")
func controls(node: Node) -> Array[Control]:
	var found: Array[Control] = []
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree(): found.append(child)
		found.append_array(controls(child))
	return found
func area(rect: Rect2) -> float:
	return maxf(0, rect.size.x) * maxf(0, rect.size.y)
func effective_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var parent := control.get_parent()
	var viewport := control.get_viewport()
	while parent != null and parent != viewport:
		if parent is Control and parent.clip_contents: rect = rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return rect.intersection(viewport.get_visible_rect())
func measure(id: String, requested: Vector2i) -> Dictionary:
	var entries: Array = []
	var findings: Array = []
	var nodes := controls(front)
	for node in nodes:
		if is_instance_valid(front.pause_overlay) and not front.pause_overlay.is_ancestor_of(node): continue
		if not (node is Button or node is Label or node is LineEdit): continue
		var rect := node.get_global_rect()
		if area(rect) < 1: continue
		var visible := effective_rect(node)
		var ratio := area(visible) / area(rect)
		var text: String = node.text if node is Button or node is Label else node.placeholder_text
		entries.append({"type": node.get_class(), "text": text, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "visible_fraction": snappedf(ratio, .001)})
		if node is Button:
			var important := text.begins_with("Voltar") or text.begins_with("Avançar") or text.begins_with("Confirmar") or text.begins_with("Próxima") or text.begins_with("Concluir") or text.begins_with("Sair") or text.begins_with("Retomar") or text.begins_with("Pausar") or text == "Continuar" or text.begins_with("Buscar") or text.begins_with("Salvar")
			if ratio < .985 and (ratio > .01 or important): findings.append({"kind": "scroll_row_partial" if _in_scroll(node) and not important else "button_clipped", "priority": "P1" if important else "P3" if _in_scroll(node) else "P2", "text": text, "fraction": snappedf(ratio, .001)})
			var style: StyleBox = node.get_theme_stylebox("normal")
			var reserve: float = style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT)
			if node.icon != null: reserve += node.get_theme_constant("icon_max_width") + node.get_theme_constant("h_separation")
			var width := node.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, node.get_theme_font_size("font_size")).x
			if width > rect.size.x - reserve + 2 and node.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING: findings.append({"kind": "button_text_trimmed", "priority": "P2", "text": text})
		elif node is Label and not text.is_empty():
			if not _in_scroll(node) and ratio < .985: findings.append({"kind": "label_clipped", "priority": "P2", "text": text.left(130), "fraction": snappedf(ratio, .001)})
			for other in nodes:
				if is_instance_valid(front.pause_overlay) and not front.pause_overlay.is_ancestor_of(other): continue
				if not other is Button or other.get_window() != node.get_window() or other.is_ancestor_of(node) or node.is_ancestor_of(other): continue
				var intersection := visible.intersection(effective_rect(other))
				if area(intersection) > 8: findings.append({"kind": "label_over_button", "priority": "P1", "text": text.left(130), "button": other.text})
	var focus := root.gui_get_focus_owner()
	return {"scenario": id, "requested_pixels": [requested.x, requested.y], "actual_pixels": [root.size.x, root.size.y], "ui_units": [front.size.x, front.size.y], "focus": focus.text if focus is Button else focus.get_class() if focus != null else "none", "widgets": entries, "findings": findings}
func _in_scroll(node: Node) -> bool:
	var parent := node.get_parent()
	while parent != null:
		if parent is ScrollContainer: return true
		parent = parent.get_parent()
	return false
func run_audit() -> void:
	scenarios = Fixtures.scenarios()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		if arg.begins_with("--scenes="):
			scenarios.clear()
			for id in arg.trim_prefix("--scenes=").split(","): scenarios.append(id)
		if arg.begins_with("--sizes="):
			sizes.clear()
			for pair in arg.trim_prefix("--sizes=").split(","):
				var dims := pair.split("x")
				sizes.append(Vector2i(int(dims[0]), int(dims[1])))
	output = ProjectSettings.globalize_path("res://").path_join("../tmp/player-audit-2026-10-26/" + phase).simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	front = Front.new()
	front.session._store = Store.new("user://visual-audit-" + State.new_id())
	front.preferences.storage_path = "user://visual-audit-settings-" + State.new_id() + ".cfg"
	root.add_child(front)
	front.preferences.reduced_motion = true
	front.preferences.crt = true
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	for requested in sizes:
		root.size = requested
		for frame in 4: await process_frame
		for id in scenarios:
			Fixtures.show(front, id)
			for frame in 5: await process_frame
			await create_timer(.13).timeout
			var record := measure(id, requested)
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var filename := "%s-%dx%d.png" % [id, requested.x, requested.y]
				root.get_texture().get_image().save_png(output.path_join(filename))
				record.image = filename
			results.append(record)
			if id in ["controls", "bag-full", "team-long"]:
				var reached := 0
				for node in controls(front):
					if not node is Button or not _in_scroll(node) or node.disabled: continue
					node.grab_focus()
					for frame in 4: await process_frame
					if area(effective_rect(node)) / area(node.get_global_rect()) < .985:
						record.findings.append({"kind": "scroll_focus_inaccessible", "priority": "P1", "text": node.text})
					else: reached += 1
				record.focus_reachable_rows = reached
			if not record.findings.is_empty(): print("FINDINGS ", id, " ", requested, " ", record.findings.size())
			# Persist after every scenario so an interruption still leaves reviewable evidence.
			var file := FileAccess.open(output.path_join("measurements.json"), FileAccess.WRITE)
			file.store_string(JSON.stringify(results, "\t"))
	print("VISUAL AUDIT: ", results.size(), " rendered scenarios. Evidence: ", output)
	front.free()
	quit()
