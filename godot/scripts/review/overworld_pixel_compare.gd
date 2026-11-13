extends Node
## Interactive visual comparison using the real campaign map and a disposable save.
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
const Follow = preload("res://scripts/campaign/companion_follow.gd")
const OLD_SHEET := "res://assets/campaign/overworld-companions/azulfazo.png"
const OLD_CELL := Vector2(80, 80)
var front: Control
var park: Node2D
var twin_root: Node2D
var old: Sprite2D
var labels: Label
var old_label: Label
var references: Array[Sprite2D] = []
var model_ids: Array[String] = []
var model_id := "azulfazo"
var model_index := 0
var view_mode := 3
var scene_name := "park-veredas"

func _ready() -> void:
	process_priority = 100
	model_ids.assign(Follow.reviewed_sheets.keys())
	model_ids.sort()
	model_index = model_ids.find(model_id)
	DisplayServer.window_set_title("Soulmonsters · Overworld v2 · 194 formas")
	get_window().size = Vector2i(1280, 720)
	front = Front.new()
	var folder := ProjectSettings.globalize_path("res://../tmp/xprite-qa-" + State.new_id())
	front.session._store = Store.new(folder)
	front.preferences.storage_path = folder.path_join("preferences.cfg")
	add_child(front)
	front.preferences.crt = false
	front.preferences.reduced_motion = true
	front.crt_layer.hide()
	front.sound.process_mode = Node.PROCESS_MODE_DISABLED
	AudioServer.set_bus_mute(0, true)
	var player: Dictionary = front.session.start("slot-1").data.player
	for id in model_ids:
		player.partners.append({"id":"xprite-"+id,"modelId":id,"personalName":id,"xp":0,"craftBonus":0})
	player.equippedPartnerId = "xprite-" + model_id
	var checkpoint := Checkpoint.make(scene_name, Checkpoint.spawn(scene_name) + Vector2(4,4), Checkpoint.SPACE)
	assert(front.session.checkpoint(checkpoint, player).status == "ok")
	front._show_park()
	park = front.park
	park.encounter_grace = 100000
	park.camera.zoom = Vector2.ONE
	park.avatar.facing = "sw"
	park._refresh_positions()
	park.camera.reset_smoothing()
	twin_root = Node2D.new()
	park.follower_root.get_parent().add_child(twin_root)
	old = Sprite2D.new()
	twin_root.add_child(old)
	old.texture = load(OLD_SHEET)
	old.region_enabled = true
	old.region_filter_clip_enabled = true
	old.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	old.scale = Vector2.ONE * 1.25
	old.set_meta("overworld_pivots", Vector2(72,72))
	old.set_meta("overworld_cell", OLD_CELL)
	var ui := CanvasLayer.new()
	ui.layer = 200
	add_child(ui)
	var panel := Panel.new()
	panel.position = Vector2(410, 100)
	panel.size = Vector2(815, 94)
	_style_panel(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_" + edge, 10)
	panel.add_child(margin)
	labels = Label.new()
	labels.add_theme_font_size_override("font_size", 16)
	margin.add_child(labels)
	ui.add_child(panel)
	_build_reference(ui)
	old_label = Label.new()
	old_label.add_theme_font_size_override("font_size", 13)
	old_label.position = Vector2(-47,-92)
	twin_root.add_child(old_label)
	var right := Label.new()
	right.text = "XPRITE · 1×"
	right.add_theme_font_size_override("font_size", 13)
	right.position = Vector2(42,-92)
	park.follower_root.add_child(right)
	_update_labels()
	await get_tree().process_frame
	if "--capture-batch" in OS.get_cmdline_user_args():
		for id in ["farpim","papisco","capibaluarte","dobracula","lince-de-cerco-baby","najarcal-baby","glacerol","tramino"]:
			_select_model(id)
			await _capture_sequence()
		get_tree().quit()
	elif "--capture" in OS.get_cmdline_user_args(): await _capture_sequence()

func _build_reference(ui: CanvasLayer) -> void:
	var panel := Panel.new()
	panel.position = Vector2(420, 555)
	panel.size = Vector2(440, 151)
	_style_panel(panel)
	ui.add_child(panel)
	var title := Label.new()
	title.position = Vector2(15,8)
	title.text = "Mesma densidade de pixels · referência Kael de 70 px"
	title.add_theme_font_size_override("font_size",13)
	panel.add_child(title)
	for i in 3:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(76 + i * 142, 126)
		sprite.region_enabled = true
		if i == 0:
			sprite.texture = load(OLD_SHEET)
			sprite.region_rect = Rect2(0,0,80,80)
			sprite.offset = Vector2(0,-32)
			sprite.scale = Vector2.ONE * 1.25
		elif i == 1:
			sprite.texture = Follow.overworld_texture("azulfazo")
			sprite.region_rect = Rect2(0,0,112,112)
			sprite.offset = Vector2(0,-44)
		else:
			sprite.texture = load("res://assets/campaign/overworld-v2/kael-reference.png")
			sprite.region_rect = Rect2(0,96,64,96)
			sprite.offset = Vector2(0,-46)
		panel.add_child(sprite)
		references.append(sprite)
		var label := Label.new()
		label.text = ["Atual","Xprite + acabamento","Kael 70 px"][i]
		label.position = Vector2(i * 142 + 13,130)
		label.add_theme_font_size_override("font_size",12)
		panel.add_child(label)

func _process(_delta: float) -> void:
	if not is_instance_valid(park) or not is_instance_valid(twin_root): return
	park.encounter_grace = 100000
	Follow.orient(old, park.avatar.facing)
	Follow.orient(park.companion, park.avatar.facing)
	twin_root.position = park.follower_root.position + Vector2(-86 if view_mode == 3 else 0, 0)
	old.position = park.companion.position
	old.position.x = 0
	park.companion.position.x = 86 if view_mode == 3 else 0
	twin_root.visible = view_mode != 2
	park.companion.visible = view_mode != 1
	# The source renderer updates the compensation before this process pass.
	_update_labels()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode in [KEY_1,KEY_2,KEY_3]:
		view_mode = int(event.keycode-KEY_0)
	elif event.keycode == KEY_F2:
		park.camera.zoom = Vector2.ONE * (1.15 if park.camera.zoom.x == 1.0 else 1.0)
	elif event.keycode == KEY_F3:
		front.crt_layer.visible = not front.crt_layer.visible
	elif event.keycode == KEY_F4:
		park.avatar.facing = "nw" if park.avatar.facing == "sw" else "sw"
		park._refresh_positions()
	elif event.keycode == KEY_F5:
		old.scale = Vector2.ONE * (1.0 if old.scale.x == 1.25 else 1.25)
	elif event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN]:
		model_index = posmod(model_index + (-1 if event.keycode == KEY_PAGEUP else 1), model_ids.size())
		_select_model(model_ids[model_index])
	else: return
	get_viewport().set_input_as_handled()

func _update_labels() -> void:
	labels.text = model_id.to_upper() + " · " + ["","Atual","Xprite + acabamento","Lado a lado"][view_mode]
	labels.text += "\n1 Atual   2 Xprite   3 Ambos   F4 Frente/costas   F2 Zoom %.2f×   F3 CRT %s" % [park.camera.zoom.x, "ligado" if front.crt_layer.visible else "desligado"]
	old_label.text = "ATUAL · %.2f×" % old.scale.x
	labels.text += "\nPage Up / Page Down · Escolher Soulmonster (%d / %d)   F5 Escala antiga %.2f×" % [model_index + 1, model_ids.size(), old.scale.x]

func _select_model(id: String) -> void:
	model_id = id
	model_index = model_ids.find(id)
	var player: Dictionary = front.session.snapshot().player
	player.equippedPartnerId = "xprite-" + id
	var checkpoint := Checkpoint.make(scene_name, park.player, Checkpoint.SPACE)
	assert(front.session.checkpoint(checkpoint, player).status == "ok")
	park.saved_player = player
	Follow.setup_overworld_art(park.companion, id, park.avatar.scale.y)
	old.texture = load("res://assets/campaign/overworld-companions/" + id + ".png")
	var pivot: Variant = Follow.ground_pivots.get(id, 72)
	old.set_meta("overworld_pivots", Vector2(float(pivot[0]),float(pivot[1])) if pivot is Array else Vector2.ONE * float(pivot))
	references[0].texture = old.texture
	references[1].texture = park.companion.texture
	park.exploration_hud.refresh(player)
	_update_labels()

func _style_panel(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#18252e")
	panel.add_theme_stylebox_override("panel", style)

func _capture_sequence() -> void:
	for pose in ["sw","nw"]:
		park.avatar.facing = pose
		park._refresh_positions()
		for i in 4: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var output := ProjectSettings.globalize_path("res://../art/creatures/soulmonsters-overworld-v2/in-game-" + model_id + "-" + pose + ".png")
		assert(get_viewport().get_texture().get_image().save_png(output) == OK)
	park.avatar.facing = "sw"
	park._refresh_positions()
	old.scale = Vector2.ONE
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var native := ProjectSettings.globalize_path("res://../art/creatures/soulmonsters-overworld-v2/in-game-" + model_id + "-ambos-1x.png")
	assert(get_viewport().get_texture().get_image().save_png(native) == OK)
	old.scale = Vector2.ONE * 1.25
	park.camera.zoom = Vector2.ONE * 1.15
	front.crt_layer.show()
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var filtered := ProjectSettings.globalize_path("res://../art/creatures/soulmonsters-overworld-v2/in-game-" + model_id + "-crt-zoom.png")
	assert(get_viewport().get_texture().get_image().save_png(filtered) == OK)
	park.camera.zoom = Vector2.ONE
	front.crt_layer.hide()
	print("XPRITE COMPARISON captured both directions on the campaign map")
	if "--quit-after-capture" in OS.get_cmdline_user_args() and not "--capture-batch" in OS.get_cmdline_user_args(): get_tree().quit()
