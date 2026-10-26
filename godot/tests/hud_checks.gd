extends SceneTree
const Hud = preload("res://scripts/campaign/hud.gd")
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)
func luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return .2126 * linear.r + .7152 * linear.g + .0722 * linear.b
func contrast(a: Color, b: Color) -> float:
	return (maxf(luminance(a), luminance(b)) + .05) / (minf(luminance(a), luminance(b)) + .05)
func _initialize() -> void:
	call_deferred("run_checks")
func frame() -> void:
	for index in 4: await process_frame
func buttons(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is Button: result.append(child)
		result.append_array(buttons(child))
	return result
func dialogs(node: Node) -> Array[AcceptDialog]:
	var result: Array[AcceptDialog] = []
	for child in node.get_children():
		if child is AcceptDialog: result.append(child)
		result.append_array(dialogs(child))
	return result

func run_checks() -> void:
	for pair in [[Hud.INK, Hud.PAPER], [Hud.PAPER, Hud.SURFACE], [Hud.INK, Hud.GOLD], [Hud.BLACK, Hud.DANGER], [Hud.MUTED, Hud.SURFACE], [Hud.Tokens.TINTA_3, Hud.PAPER]]:
		var ratio := contrast(pair[0], pair[1])
		print("CONTRAST: ", pair[0].to_html(), "/", pair[1].to_html(), " = ", snappedf(ratio, .01))
		check(ratio >= 4.5, "body text contrast >= 4.5")
	for fill in [Hud.LINE, Hud.ENERGY, Hud.GOLD]: check(contrast(fill, Hud.TRACK) >= 3, "bar distinguishes filled and empty")
	var texture := load("res://assets/campaign/victory.png") as Texture2D
	var fitted := Hud.fit_texture(texture, Rect2(0, 0, 540, 120))
	check(is_equal_approx(fitted.size.x / fitted.size.y, float(texture.get_width()) / texture.get_height()), "ribbon preserves source proportions")
	check(fitted.size.x <= 540 and fitted.size.y <= 120, "ribbon fits reserved bounds")
	var normal := Hud.button_style()
	for state in ["hover", "pressed", "disabled"]:
		check(Hud.button_style(state).get_minimum_size() == normal.get_minimum_size(), "state does not move layout: " + state)
		check(Hud.button_style(state).content_margin_right == normal.content_margin_right, "state keeps Theme content insets: " + state)
	var front := Front.new()
	front.session._store = Store.new("user://hud-checks-" + State.new_id())
	root.add_child(front)
	await frame()
	for extent in [220, 360, 540, 900]:
		var card := Hud.card("Nome longo de um lugar que precisa quebrar em linhas sem aumentar a largura da interface")
		card.position = Vector2(20, 20)
		card.size = Vector2(extent, 180)
		root.add_child(card)
		await frame()
		var text: Label = card.get_child(0)
		var pin: Control = card.get_child(1).get_child(0)
		check(text.size.x <= extent - 36, "text fits content width " + str(extent))
		check(pin.size == Vector2(20, 28), "detached pin keeps exact size " + str(extent))
		check(pin.get_parent().position == Vector2(card.size.x - 26, -8), "pin stays anchored to frame, not text")
		check(pin.mouse_filter == Control.MOUSE_FILTER_IGNORE, "ornament cannot intercept input")
		check(card.get_theme_stylebox("panel") is StyleBoxFlat and card.get_theme_stylebox("panel").skew == Vector2(.21,0), "Theme owns panel geometry; ink corners are a separate decoration " + str(extent))
		card.free()
	for viewport_size in [Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1920, 1080)]:
		root.size = viewport_size
		front._menu()
		await frame()
		var all_buttons := buttons(front)
		check(all_buttons.size() == 5, "three slots and two menu commands")
		for button in all_buttons:
			check(button.size.x >= 100 and button.size.y >= 48, "usable target " + button.text)
		var focused := root.gui_get_focus_owner()
		check(focused is Button, "menu has keyboard focus")
	for scenario in ["long-notice", "starter-confirm", "workshop-cancel", "morro-dialog", "binding-dialog"]:
		Fixtures.show(front, scenario)
		await frame()
		var active_dialogs := dialogs(front)
		check(active_dialogs.size() == 1, "one dialog in " + scenario)
		for dialog in active_dialogs:
			check(not dialog.title.strip_edges().is_empty() and dialog.title not in ["Alert!", "Please Confirm...", "OK", "Cancel"], "explicit localized title in " + scenario)
			check(not dialog.ok_button_text.strip_edges().is_empty() and dialog.ok_button_text not in ["Alert!", "Please Confirm...", "OK", "Cancel"], "localized primary action in " + scenario)
			if dialog is ConfirmationDialog:
				check(not dialog.cancel_button_text.strip_edges().is_empty() and dialog.cancel_button_text not in ["Alert!", "Please Confirm...", "OK", "Cancel"], "localized cancel action in " + scenario)
	front.free()
	print("HUD CHECKS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
