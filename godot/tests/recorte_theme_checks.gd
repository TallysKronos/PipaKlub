extends SceneTree
## PIP-64 bounded UI checks; never starts a campaign or reads/writes a save.
const Recorte = preload("res://scripts/campaign/recorte_theme.gd")
const Spawner = preload("res://scripts/campaign/recorte_splat_spawner.gd")
const Wipe = preload("res://scripts/campaign/recorte_ink_wipe.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL ",message)

func _initialize() -> void:
	call_deferred("run_checks")

func inspect_sources(directory: String) -> void:
	var folder := DirAccess.open(directory)
	for file in folder.get_files():
		if not file.ends_with(".gd"): continue
		var source := FileAccess.get_file_as_string(directory.path_join(file))
		# Token-based semantic overrides and adaptive inset geometry are supported.
		# Forbid parallel Theme factories; palette/font literals have their own strict guard.
		check(not source.contains("Theme.new("),"screen inherits the shared Theme: "+file)
	for child in folder.get_directories(): inspect_sources(directory.path_join(child))

func run_checks() -> void:
	var theme := Recorte.shared()
	inspect_sources("res://scripts")
	for type in ["Button","Label","PanelContainer","ItemList","ProgressBar","TabBar","LineEdit","HSlider","CheckButton","ScrollBar","TooltipPanel","AcceptDialog","ConfirmationDialog"]:
		check(type in theme.get_type_list(),"Theme explicitly covers "+type)
	var base := theme.get_stylebox("normal","Button") as StyleBoxFlat
	check(base != null and base.skew == Vector2(.21,0) and base.shadow_size == 0 and base.shadow_offset == Vector2(6,6),"flat geometry, hard shadow and fixed skew")
	check(theme.get_stylebox("hover","Button") == theme.get_stylebox("focus","Button"),"focus and hover share a visual contract")
	var surface := Control.new()
	root.add_child(surface)
	surface.size = Vector2(900,600)
	Recorte.install(surface)
	var button := Button.new()
	button.text = "Foco sem mouse"
	button.position = Vector2(60,60)
	button.size = Vector2(300,64)
	surface.add_child(button)
	var disabled := Button.new()
	disabled.text = "Indisponível"
	disabled.disabled = true
	disabled.position = Vector2(60,150)
	disabled.size = Vector2(300,64)
	surface.add_child(disabled)
	for frame in 8: await process_frame
	button.grab_focus()
	await create_timer(.22).timeout
	var decoration: Control = button.get_node("RecorteArt").get_child(0)
	check(root.gui_get_focus_owner() == button,"native keyboard focus")
	check(decoration.marker.modulate.a > .99 and decoration.marker.size.x >= 12 and decoration.underline != null and decoration.underline.modulate.a > .99,"focus shows the coral ▶ and yellow stroke of the approved board, not color alone")
	check(button.offset_transform_position == Vector2(10,-2),"focus finishes its bounded 10px shift")
	check(not disabled.get_node("RecorteArt").get_child(0).active,"disabled control never receives active decoration")
	get_root().gui_release_focus()
	button.grab_focus()
	surface.get_node("RecorteUX").set_reduced_motion(true)
	await create_timer(.10).timeout
	check(button.offset_transform_position == Vector2.ZERO,"reducing motion cancels an existing shift")
	check(decoration.marker.modulate.a > .99,"reduced motion preserves static shape feedback")
	check(decoration._tween == null or not decoration._tween.is_running(),"no looping or blinking focus tween")
	var spawner := Spawner.new()
	spawner.reduced_motion = true
	surface.add_child(spawner)
	var first := spawner.spawn(Vector2(300,300))
	var previous: String = first.get_meta("source_id")
	check(first.rotation == 0,"reduced motion disables impact rotation")
	for index in 20:
		var sprite := spawner.spawn(Vector2(300,300))
		check(sprite.get_meta("source_id") != previous,"consecutive splats never reuse their source variant")
		previous = sprite.get_meta("source_id")
	check(spawner._bursts.size() <= 12,"bounded simultaneous effects")
	await create_timer(.70).timeout
	check(spawner.get_child_count() == 0,"all ink clears after 600ms")
	var wipe := Wipe.new()
	surface.add_child(wipe)
	wipe.play(Recorte.shared().get_color("font_color","Label"),true,false)
	check(wipe.material == null,"reduced wipe uses fade instead of the spatial shader")
	await create_timer(.10).timeout
	check(is_zero_approx(wipe.modulate.a) and not wipe._tween.is_running(),"reduced wipe ends within 80ms without repeat")
	surface.free()
	print("PIP-64 THEME: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
