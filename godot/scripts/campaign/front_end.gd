extends Control
const Session = preload("res://scripts/campaign/session.gd")
const Opening = preload("res://scripts/campaign/opening.gd")
const Room = preload("res://scripts/campaign/room_view.gd")
const Journey = preload("res://scripts/campaign/journey.gd")
const FlightView = preload("res://scripts/campaign/first_flight_view.gd")
const WorkshopView = preload("res://scripts/campaign/workshop_view.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const MorroView = preload("res://scripts/campaign/morro_view.gd")
const MorroBattleView = preload("res://scripts/campaign/morro_battle_view.gd")
const ParkView = preload("res://scripts/campaign/park_view.gd")
const ParkRouteView = preload("res://scripts/campaign/park_route_view.gd")
const Exploration = preload("res://scripts/campaign/exploration.gd")
const Encounters = preload("res://scripts/campaign/encounters.gd")
const EncounterView = preload("res://scripts/campaign/encounter_view.gd")
const Preferences = preload("res://scripts/campaign/preferences.gd")
const Backdrop = preload("res://scripts/campaign/hud_backdrop.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
var session := Session.new()
var opening: RefCounted
var content: Dictionary
var stage: Node2D
var room: Node2D
var page: VBoxContainer
var status: Label
var speech: Label
var next: Button
var name_input: LineEdit
var portrait: TextureRect
var current_step := -1
var broadcast: Array[Sprite2D] = []
var clock := 0.0
var journey: RefCounted
var workshop: Control
var park: Node2D
var battle: Control
var exploration: RefCounted
var encounters: RefCounted
var morro: RefCounted
var preferences := Preferences.new()
var crt_layer: CanvasLayer
var quit_after_workshop := false
var binding_target := ""
var binding_dialog: AcceptDialog
var pause_overlay: Control
var pause_previous: Dictionary = {}
var last_scene_key := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().auto_accept_quit = false
	preferences.load_settings()
	Controls.install(preferences.bindings)
	Input.joy_connection_changed.connect(_controller_changed)
	crt_layer = CanvasLayer.new()
	crt_layer.layer = 100
	var filter := ColorRect.new()
	filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/campaign_crt.gdshader")
	filter.material = material
	crt_layer.add_child(filter)
	add_child(crt_layer)
	_apply_preferences()
	content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	add_child(session)
	opening = Opening.new(session)
	journey = Journey.new(session)
	exploration = Exploration.new(session)
	encounters = Encounters.new(session)
	morro = Morro.new(session)
	Hud.Recorte.install(self, preferences.reduced_motion)
	resized.connect(_layout_stage)
	_menu()

func _clear(route: String = "") -> void:
	for child in get_children():
		if child != session and child != crt_layer and child.name != "RecorteUX":
			remove_child(child)
			child.queue_free()
	stage = null
	room = null
	workshop = null
	park = null
	battle = null
	status = null
	broadcast.clear()
	current_step = -1
	pause_overlay = null
	var background := ColorRect.new()
	background.color = Hud.INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	add_child(Backdrop.new())
	var checkpoint: Dictionary = session.snapshot().get("checkpoint", {})
	var scene_key := route if not route.is_empty() else str(checkpoint.get("kind", "menu")) + ":" + str(checkpoint.get("scene", ""))
	if not last_scene_key.is_empty() and scene_key != last_scene_key:
		var layer := CanvasLayer.new()
		layer.layer = 80
		add_child(layer)
		var reveal = load("res://scripts/campaign/hud_ink_transition.gd").new()
		reveal.reduced_motion = preferences.reduced_motion
		layer.add_child(reveal)
	last_scene_key = scene_key

func _label(text: String, target: Node, font_size: int = 22) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if font_size >= 28: label.add_theme_font_override("font", Hud.display())
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target.add_child(label)
	return label

func _button(text: String, target: Node, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text = text
	if text.begins_with("Voltar") or text.begins_with("Salvar") or text in ["Configurações", "Controles", "Sair", "Equipe", "Bolsa", "Menu"]: Hud.secondary_button(button)
	var icon_id := ""
	if text.begins_with("Voltar") or text == "Retomar": icon_id = "back"
	elif text.begins_with("Salvar"): icon_id = "save"
	elif text.begins_with("Configurações") or text.begins_with("Controles"): icon_id = "settings"
	elif text.begins_with("Montar") or text.begins_with("Restaurar"): icon_id = "tail"
	if not icon_id.is_empty():
		button.icon = Hud.icon(icon_id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 28)
	if target is HBoxContainer: button.custom_minimum_size.x = maxf(140, minf(400, Hud.font(true).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + (112 if button.icon != null else 72)))
	target.add_child(button)
	button.pressed.connect(action)
	return button

func _menu() -> void:
	_clear("menu")
	session.close_session()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 110)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 18)
	scroll.add_child(page)
	_label("CAMPANHA  /  SEU PRÓXIMO VENTO", page, 18).theme_type_variation = "RecorteAccentText"
	_label("Soulmonsters", page, 56)
	_label("Elo das Ruínas", page, 24)
	status = _label("Escolha sua jornada. Seu progresso fica neste computador.", page)
	var slots := GridContainer.new()
	slots.columns = 3
	slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots.add_theme_constant_override("h_separation", 20)
	slots.add_theme_constant_override("v_separation", 20)
	page.add_child(slots)
	page.resized.connect(func(): slots.columns = 3 if page.size.x >= 850 else 1)
	var first: Button
	for i in range(1, 4):
		var slot_id := "slot-%d" % i
		var result: Dictionary = session.inspect_slot(slot_id)
		var text := "Jornada %d · Novo jogo" % i
		if result.status == "ok":
			text = "Jornada %d · Continuar — %s" % [i, str(result.data.player.name)]
			if result.recovered:
				text += " · Recuperar backup"
		elif result.status != "missing":
			text = "Jornada %d · %s" % [i, _error(result.status)]
		var card := PanelContainer.new()
		card.theme_type_variation = "RecortePaperPanel"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation",12)
		card.add_child(column)
		slots.add_child(card)
		var card_header := HBoxContainer.new()
		column.add_child(card_header)
		var slot_label := _label("JORNADA  %02d" % i, card_header, 18)
		slot_label.theme_type_variation = "RecortePaperText"
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Hud.decorate(card_header, i % 4, Vector2(48,32))
		var art := TextureRect.new()
		art.texture = load("res://assets/campaign/portrait-kael.png") if result.status == "ok" else Hud.icon("pipa",true)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(96, 96)
		column.add_child(art)
		var detail := "Um novo começo" if result.status == "missing" else str(result.data.player.name) if result.status == "ok" else "Jornada indisponível"
		_label(detail, column, 24).theme_type_variation = "RecortePaperText"
		var action := "Começar jornada" if result.status == "missing" else "Continuar jornada" if result.status == "ok" else "Indisponível"
		var action_space := Hud.focus_space(column)
		var button := _button(action, action_space, _choose.bind(slot_id, result.status == "missing"))
		button.tooltip_text = text
		Hud.secondary_button(button)
		button.disabled = result.status not in ["missing", "ok"]
		if not is_instance_valid(first) and not button.disabled:
			first = button
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation",18)
	page.add_child(tools)
	_button("Configurações", tools, _show_settings)
	_button("Sair", tools, func(): get_tree().quit())
	Hud.input_hint(tools,"accept","Confirmar")
	if is_instance_valid(first):
		Hud.focus_later(first)

func _error(code: String) -> String:
	return {"corrupt": "Save danificado; mantenha os arquivos para recuperação.",
		"future": "Este save precisa de uma versão mais recente do jogo.",
		"unsupported": "Versão do save incompatível.", "occupied": "Esta jornada já existe.",
		"invalid_name": "Use um nome de até 24 caracteres, sem quebras de linha.",
		"stale": "A jornada foi alterada. Volte ao menu e carregue novamente.",
		"repair_needed": "Seu parceiro precisa de reparos. Volte ao professor: ele cuida da equipe gratuitamente.",
		"io_error": "Não foi possível acessar o save. Confira o espaço e a permissão da pasta."}.get(code, "Não foi possível continuar. Seu último save foi mantido.")

func _choose(slot_id: String, create: bool) -> void:
	var result: Dictionary = session.start(slot_id) if create else session.resume_slot(slot_id)
	if result.status != "ok":
		status.text = _error(result.status)
		return
	_show_saved()
	if not create and is_instance_valid(battle): battle.paused = true
	if result.get("recovered", false):
		_notice("Recuperamos sua jornada a partir do backup.")

func _dialog(title: String, text: String, ok: String, cancel: String = "") -> AcceptDialog:
	var dialog: AcceptDialog = AcceptDialog.new() if cancel.is_empty() else ConfirmationDialog.new()
	dialog.title = title if not title.strip_edges().is_empty() else "Aviso"
	dialog.dialog_text = text
	dialog.ok_button_text = ok
	dialog.dialog_autowrap = true
	dialog.get_label().custom_minimum_size.x = 560
	if dialog is ConfirmationDialog:
		dialog.cancel_button_text = cancel
		Hud.secondary_button(dialog.get_cancel_button())
	add_child(dialog)
	return dialog

func _notice(message: String) -> void:
	if is_instance_valid(park): park.paused = true
	var was_walking: bool = is_instance_valid(room) and room.can_walk
	if was_walking: room.can_walk = false
	var dialog := _dialog("Aviso", message, "Entendi")
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		if is_instance_valid(park): park.paused = false
		if is_instance_valid(room) and was_walking: room.can_walk = true)
	dialog.popup_centered(Vector2i(640, 300))

func _result(result: Dictionary) -> bool:
	if result.status in ["ok", "already_applied"]:
		return true
	_notice(_error(result.status))
	return false

func _show_saved() -> void:
	match str(session.snapshot().checkpoint.kind):
		"opening": _show_opening()
		"world": _show_world()
		"practice": _show_practice()
		"starter": _show_starter()
		"workshop": _show_workshop()
		"encounter": _show_encounter()

func _return_to_game() -> void:
	_show_saved()
	# Returning from a page must not restart combat while the player is still orienting.
	if is_instance_valid(battle): battle.paused = true

func _show_opening() -> void:
	_clear()
	var saved: Dictionary = session.snapshot()
	current_step = int(saved.checkpoint.step)
	stage = Node2D.new()
	add_child(stage)
	if current_step < 2:
		_broadcast()
	else:
		room = Room.new()
		stage.add_child(room)
		var home := current_step >= 12
		var map: Dictionary = content.rooms.home if home else content.rooms.bedroom
		var point: Array = map.layout.blocking.kaelEntry if home else map.layout.blocking.kaelDesk
		if current_step in [2, 3]:
			point = map.layout.blocking.kaelTV
		elif current_step in [5, 6, 7]:
			point = map.layout.blocking.kaelTalk
		elif current_step in [8, 9, 10, 11]:
			point = map.layout.blocking.kaelBirth
		var target := "desk" if current_step == 3 else "stairs" if current_step == 11 else "exit"
		room.configure(map, point, current_step in [3, 11, 13], target, current_step >= 5, current_step >= 9)
		room.interacted.connect(func(_id: String): _advance())
	_layout_stage()
	portrait = TextureRect.new()
	portrait.anchor_top = 1
	portrait.anchor_bottom = 1
	portrait.offset_left = 8
	portrait.offset_right = 295
	portrait.offset_top = -380
	portrait.offset_bottom = -18
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	var panel := PanelContainer.new()
	panel.anchor_top = .72
	panel.anchor_right = 1
	panel.anchor_bottom = 1
	panel.offset_left = 230
	panel.offset_right = -40
	panel.offset_top = -12
	panel.offset_bottom = -20
	panel.theme_type_variation = "RecorteDialoguePanel"
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 6)
	row.add_child(page)
	var story: Dictionary = content.opening[mini(current_step, 13)]
	var speaker: String = story.speaker
	if content.portraits.has(speaker):
		portrait.texture = load("res://assets/campaign/" + content.portraits[speaker])
	portrait.visible = portrait.texture != null
	var nameplate := PanelContainer.new()
	nameplate.position = Vector2(22, -34)
	nameplate.custom_minimum_size = Vector2(maxf(180, Hud.font().get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 48), 48)
	nameplate.theme_type_variation = "RecorteNamePanel"
	nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate_holder := Node2D.new()
	panel.add_child(plate_holder)
	plate_holder.add_child(nameplate)
	var heading := _label(speaker, nameplate, 24)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	nameplate.visible = not speaker.is_empty()
	heading.theme_type_variation = "RecortePaperText"
	speech = _label(story.text, page, 22)
	speech.theme_type_variation = "Label"
	status = _label("", page, 16)
	status.theme_type_variation = "RecorteMutedText"
	status.visible = current_step in [3, 11, 13]
	if current_step in [3, 11, 13]:
		speech.text = ""
		speech.hide()
		portrait.hide()
		nameplate.hide()
		panel.offset_left = 40
		panel.anchor_top = 1
		panel.offset_top = -110
		status.text = "WASD / setas · E para interagir"
	if current_step == 10:
		name_input = LineEdit.new()
		name_input.placeholder_text = "Nome do parceiro · Rabbito"
		name_input.max_length = 24
		page.add_child(name_input)
		name_input.text_submitted.connect(func(_value: String): _name())
		next = _button("Confirmar nome", Hud.focus_space(page), _name)
		Hud.focus_later(name_input)
	elif current_step < 14 and current_step not in [3, 11, 13]:
		var next_space := Hud.focus_space(page)
		next_space.size_flags_horizontal = Control.SIZE_SHRINK_END
		next = _button("Avançar", next_space, _advance)
		next.size_flags_horizontal = Control.SIZE_SHRINK_END
		next.custom_minimum_size.x = 180
		Hud.focus_later(next)
	elif current_step == 14:
		speech.text = ""
		_button("Sair para a rua", Hud.focus_space(page), func():
			if _result(journey.enter_world("quintal", Vector2(480, 768))):
				_show_saved())
	var menu := _button("Salvar e voltar ao menu", self, _menu)
	menu.anchor_left = 1
	menu.anchor_right = 1
	menu.offset_left = -355
	menu.offset_right = -64
	menu.offset_top = 16
	menu.offset_bottom = 70

func _advance() -> void:
	var result: Dictionary = opening.advance(current_step)
	if result.status == "ok":
		_show_opening()
	else:
		status.text = _error(result.status)

func _name() -> void:
	var result: Dictionary = opening.name_partner(name_input.text)
	if result.status == "ok":
		_show_opening()
	else:
		status.text = _error(result.status)

func _layout_stage() -> void:
	if is_instance_valid(stage):
		var factor := minf(size.x / 960, size.y * .72 / 640)
		stage.scale = Vector2.ONE * factor
		stage.position = Vector2((size.x - 960 * factor) / 2, (size.y * .72 - 640 * factor) / 2)

func _stage_container() -> void:
	var clip := Control.new()
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.anchor_bottom = .72
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	stage = Node2D.new()
	clip.add_child(stage)
	_layout_stage()

func _show_world() -> void:
	if Morro.maps().has(session.snapshot().checkpoint.scene):
		_show_morro()
		return
	if session.snapshot().checkpoint.scene in ["park-trail", "park-clearing", "park-veredas"]:
		_show_park()
		return
	_clear()
	_stage_container()
	var point: Dictionary = session.snapshot().checkpoint
	var professor: bool = point.scene == "professor-home"
	var data: Dictionary = (content.rooms.professor if professor else content.rooms.street).duplicate(true)
	if not professor and not data.hotspots.any(func(h: Dictionary): return h.id == "morro"):
		data.hotspots.append({"id": "morro", "name": "Morro do Sol", "x": 2592, "y": 1040})
	room = Room.new()
	stage.add_child(room)
	room.configure(data, point.position, true, "*", professor, true)
	for partner in session.snapshot().player.partners:
		if partner.id != session.snapshot().player.get("equippedPartnerId", ""): continue
		var id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}.get(partner.modelId, "rabbito")
		room.companion.texture = load("res://assets/campaign/" + content.combat[id].image)
		room.companion_frames = content.combat[id].animations.idle
	room.interacted.connect(_world_interact)
	var overlay := VBoxContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 20
	overlay.offset_top = 20
	overlay.offset_right = -20
	overlay.offset_bottom = -20
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var tools := HBoxContainer.new()
	overlay.add_child(tools)
	var location := Hud.card("Ateliê do Sr. Assis" if professor else "Bairro dos Ventos")
	location.custom_minimum_size.x = 300
	tools.add_child(location)
	Hud.retract_after(location, 3)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tools.add_child(spacer)
	_button("Equipe", tools, func(): _show_collection())
	_button("Bolsa", tools, func(): _show_bag())
	_button("Menu", tools, _pause_game)
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.add_child(gap)
	var prompt := PanelContainer.new()
	prompt.set_meta("contextual", true)
	prompt.theme_type_variation = "PanelContainer"
	prompt.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(prompt)
	status = _label("", prompt, 20)
	Hud.interaction_glyph(prompt)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	prompt.visible = false

func _world_interact(id: String) -> void:
	var point: Dictionary = session.snapshot().checkpoint
	if point.scene == "quintal":
		if id == "morro" and session.snapshot().player.get("journey", {}).get("phase") == "complete":
			if _result(journey.enter_world("morro", Vector2(528, 752))): _show_saved()
		elif id == "park" and session.snapshot().player.get("journey", {}).get("phase") == "complete":
			if _result(journey.enter_world("park-trail", Vector2(208, 816))): _show_saved()
		elif id == "professor-home":
			var entry: Array = content.rooms.professor.layout.blocking.kaelEntry
			if _result(journey.enter_world("professor-home", Vector2(entry[0], entry[1]))):
				_show_saved()
		elif id == "kael-home":
			_notice("Kael: Vou ver o professor primeiro.")
		else:
			_notice("Kael: eu preciso ver o professor primeiro")
	elif id == "exit":
		if _result(journey.enter_world("quintal", Vector2(1376, 740))):
			_show_saved()
	elif id == "professor":
		if session.snapshot().player.get("journey", {}).get("phase") == "complete":
			if _result(exploration.repair()): _notice("Sr. Assis: Pronto! Reforcei a linha e a armação dos seus parceiros. Estão novos em folha.")
		elif _result(journey.practice()):
			_show_saved()
	elif id == "workbench":
		var player: Dictionary = session.snapshot().player
		if player.get("journey", {}).get("lesson", 0) < 5:
			_notice("Sr. Assis: Vamos treinar com o Nozinho primeiro.")
		elif player.get("starter", {}).get("completed", false):
			_show_tail_workshop()
		elif _result(journey.practice()):
			_show_saved()
	else:
		_notice("Estudos sobre pipas, almas e o vento.")

func _show_practice() -> void:
	_clear()
	var view := FlightView.new()
	view.reduced_motion=preferences.reduced_motion
	var index: int = session.snapshot().checkpoint.lesson
	view.configure(content, index)
	add_child(view)
	view.continue_lesson.connect(func():
		if view.model.complete and _result(journey.lesson_completed(index)):
			_show_saved())
	view.leave.connect(_menu)

func _simple_page(title: String) -> void:
	_clear("page:" + title)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)
	var heading_row := HBoxContainer.new()
	page.add_child(heading_row)
	var heading := _label(title, heading_row, 36)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Hud.input_hint(heading_row,"accept","Confirmar")
	Hud.input_hint(heading_row,"back","Voltar")
	_focus_first.call_deferred(page)

func _focus_first(node: Node) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree(): return false
	for child in node.get_children():
		if child is Button and not child.disabled and child.visible:
			child.grab_focus()
			return true
		if _focus_first(child): return true
	return false

func _show_starter() -> void:
	_simple_page("Sr. Assis · Oficina das Almas")
	var player: Dictionary = session.snapshot().player
	if player.has("starter"):
		_label("Sua rabiola: " + Journey.STARTERS[player.starter.modelId], page)
		if player.starter.status == "damaged":
			_button("Restaurar rabiola", page, func():
				if _result(journey.restore_tail()): _show_saved())
		else:
			_button("Começar a montagem", page, func():
				if _result(journey.start_workshop()): _show_saved())
	else:
		_label("Escolha a rabiola do seu próximo parceiro. Esta escolha é única.", page)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation",20)
		grid.add_theme_constant_override("v_separation",16)
		page.add_child(grid)
		for model_id in Journey.STARTERS:
			var chosen: String = model_id
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.theme_type_variation = "PanelContainer"
			grid.add_child(card)
			var row := HBoxContainer.new()
			card.add_child(row)
			var portrait := TextureRect.new()
			portrait.texture = _partner_portrait(chosen)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.custom_minimum_size = Vector2(120, 106)
			row.add_child(portrait)
			var detail := VBoxContainer.new()
			detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(detail)
			var description := {"basica": "Reforça o próximo corte.", "mata": "Reduz o dano recebido por um instante.", "azulao": "Favorece o ângulo no cruzamento.", "raio": "Rajada veloz de curta duração."}
			_label(description[chosen] + "\nHabilidade · 25 energia", detail, 18)
			var choose := _button(Journey.STARTERS[chosen], Hud.focus_space(detail), func(): _confirm_starter(chosen))
			Hud.secondary_button(choose)

	_button("Salvar e voltar ao menu", page, _menu)

func _confirm_starter(model_id: String) -> void:
	var dialog := _dialog("Escolher parceiro", "Escolher a rabiola de %s? A escolha será guardada nesta jornada." % Journey.STARTERS[model_id], "Escolher rabiola", "Continuar escolhendo") as ConfirmationDialog
	dialog.confirmed.connect(func():
		if _result(journey.choose(model_id)): _show_saved()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(640,240))

func _show_workshop() -> void:
	_clear()
	var job: Dictionary = session.snapshot().player.workshop
	workshop = WorkshopView.new()
	workshop.configure(job.state.kind, int(job.seed), job.state)
	add_child(workshop)
	workshop.progress_changed.connect(_save_workshop)
	workshop.finished.connect(func(_outcome: Dictionary):
		if _result(journey.finish_workshop()):
			_show_saved.call_deferred()
		else:
			workshop.paused = true
			workshop.sent_outcome = false
			workshop.storage_blocked = true
			workshop.resume_button.show())
	workshop.leave_requested.connect(_confirm_cancel_workshop)

func _save_workshop(state: Dictionary) -> void:
	var result: Dictionary = journey.save_workshop(state)
	if result.status == "ok":
		workshop.storage_blocked = false
	else:
		workshop.paused = true
		workshop.storage_blocked = true
		workshop.resume_button.show()
		_notice(_error(result.status))

func _confirm_cancel_workshop() -> void:
	var dialog := _dialog("Sair da bancada", "Sair da bancada? A montagem será reiniciada quando voltar. Sua rabiola continuará disponível.", "Sair da bancada", "Ficar na bancada") as ConfirmationDialog
	dialog.confirmed.connect(func():
		if _result(journey.cancel_workshop()):
			if quit_after_workshop: get_tree().quit()
			else: _show_saved()
		dialog.queue_free())
	dialog.canceled.connect(func(): quit_after_workshop = false)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(640,240))
	dialog.get_cancel_button().grab_focus()

func _broadcast() -> void:
	var background := Sprite2D.new()
	background.texture = load("res://assets/campaign/broadcast-background.png")
	background.centered = false
	background.scale = Vector2(960, 640) / background.texture.get_size()
	stage.add_child(background)
	for i in 2:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/campaign/" + content.broadcast[i].image)
		sprite.region_enabled = true
		sprite.scale = Vector2(-.8 if i == 1 else .8, .8)
		stage.add_child(sprite)
		broadcast.append(sprite)
	var score := PanelContainer.new()
	score.position = Vector2(24, 12)
	score.size = Vector2(620, 84)
	score.theme_type_variation = "RecorteBroadcastPanel"
	stage.add_child(score)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 2)
	score.add_child(lines)
	_label("FINAL REGIONAL  ·  AO VIVO", lines, 20)
	_label("Jamile / Carcará  ×  Gollia / Azulão", lines, 18)
	var station := PanelContainer.new()
	station.position = Vector2(760, 544)
	station.size = Vector2(160, 64)
	station.theme_type_variation = "PanelContainer"
	stage.add_child(station)
	_label("PIPA TV", station, 24)

func _process(delta: float) -> void:
	clock += delta
	for i in broadcast.size():
		var frames: Array = content.broadcast[i].frames
		var frame: Dictionary = frames[int(clock * 12) % frames.size()]
		broadcast[i].region_rect = Rect2(frame.x, frame.y, frame.w, frame.h)
		broadcast[i].position = Vector2(300 + 350 * i + sin(clock * 1.7 + i) * 35, 280 + sin(clock * 2 + i) * 20)
	if is_instance_valid(room) and room.can_walk:
		status.text = Controls.prompt("interact") + " · " + {"desk": "Montar Rabbito", "stairs": "Descer para a sala", "exit": "Sair", "professor": "Conversar com Sr. Assis", "professor-home": "Entrar no ateliê", "morro": "Entrar no Morro do Sol", "park": "Entrar no parque", "workbench": "Usar bancada"}.get(room.near, "Interagir") if not room.near.is_empty() and (room.near == room.target_hotspot or room.target_hotspot == "*") else ("Analógico · Mover" if Controls.gamepad else "Setas · Mover")
		if status.get_parent() is PanelContainer and status.get_parent().theme_type_variation == "RecortePromptPanel":
			status.text = status.text.trim_prefix(Controls.prompt("interact")+" · ")
		if status.get_parent().has_meta("contextual"): status.get_parent().visible = not room.near.is_empty()
		elif current_step in [3, 11, 13] and room.near != room.target_hotspot:
			status.text = ("Analógico · Mover" if Controls.gamepad else "WASD / setas · Mover") + "  ·  " + {3: "Aproxime-se da mesa de desenho.", 11: "Aproxime-se da escada para descer.", 13: "Aproxime-se da porta para sair."}[current_step]

func _unhandled_input(event: InputEvent) -> void:
	if Controls.cancel(event) and last_scene_key.begins_with("page:"):
		if last_scene_key == "page:Controles · Teclado": _show_settings()
		elif session.snapshot().is_empty(): _menu()
		else: _return_to_game()
		get_viewport().set_input_as_handled()
		return
	if Controls.cancel(event) and not session.snapshot().is_empty():
		if is_instance_valid(pause_overlay):
			_resume_game()
		elif is_instance_valid(workshop):
			quit_after_workshop = false
			workshop._pause()
			_confirm_cancel_workshop()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	if is_instance_valid(pause_overlay): return
	get_viewport().set_input_as_handled()
	pause_previous = {"battle": battle.paused if is_instance_valid(battle) else false, "park": park.paused if is_instance_valid(park) else false, "room": room.can_walk if is_instance_valid(room) else false}
	var practice := _practice_view()
	if is_instance_valid(practice):
		pause_previous.practice = practice.paused
		practice.suspend_actions()
	if is_instance_valid(battle): battle.suspend_actions()
	if is_instance_valid(park): park.paused = true
	if is_instance_valid(room): room.can_walk = false
	pause_overlay = load("res://scripts/campaign/hud_pause.gd").new()
	pause_overlay.player = session.snapshot().player
	if is_instance_valid(battle):
		pause_overlay.battle_paused=true
		# Presentation copy only: conditions are settled into the save by the combat flow.
		for partner in pause_overlay.player.get("partners",[]):
			if partner.id==pause_overlay.player.get("equippedPartnerId",""):
				partner.condition={"line":clampf(battle.model.p.hp/battle.model.p.stats.line*100,0,100),"structure":clampf(battle.model.p.hull/battle.model.p.stats.line*100,0,100)}
	add_child(pause_overlay)
	pause_overlay.chosen.connect(func(action: String):
		if action in ["team", "bag", "settings"] and not _remember_world_position(): return
		match action:
			"resume": _resume_game()
			"team": _show_collection()
			"bag": _show_bag()
			"settings": _show_settings()
			"menu": _return_to_menu()
	)

func _resume_game() -> void:
	if not is_instance_valid(pause_overlay): return
	remove_child(pause_overlay)
	pause_overlay.queue_free()
	pause_overlay = null
	if is_instance_valid(battle): battle.paused = pause_previous.get("battle", false)
	if is_instance_valid(park): park.paused = pause_previous.get("park", false)
	if is_instance_valid(room): room.can_walk = pause_previous.get("room", false)
	var practice := _practice_view()
	if is_instance_valid(practice): practice.paused = pause_previous.get("practice", false)

func _practice_view() -> Control:
	for child in get_children():
		if child.get_script() == FlightView: return child
	return null

func _return_to_menu() -> void:
	if is_instance_valid(battle):
		battle.paused = true
		if not _result(encounters.save_battle(battle.model.snapshot())): return
	if is_instance_valid(park) and not _save_park(): return
	var saved: Dictionary = session.snapshot()
	if not saved.is_empty() and saved.checkpoint.kind == "world" and is_instance_valid(room):
		if not _result(journey.enter_world(saved.checkpoint.scene, room.actor)):
			return
	_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(battle) and not _result(encounters.save_battle(battle.model.snapshot())): return
		if is_instance_valid(park) and not _save_park(): return
		if is_instance_valid(workshop):
			quit_after_workshop = true
			workshop._pause()
			_confirm_cancel_workshop()
			return
		var saved: Dictionary = session.snapshot()
		if not saved.is_empty() and saved.checkpoint.kind == "world" and is_instance_valid(room):
			if not _result(journey.enter_world(saved.checkpoint.scene, room.actor)):
				return
		get_tree().quit()

func _show_park() -> void:
	_clear()
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(size)
	viewport.handle_input_locally = true
	viewport.world_2d = World2D.new()
	container.add_child(viewport)
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.scene != "park-veredas":
		park = ParkRouteView.new()
		park.ui_theme = theme
		var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
		park.data = maps[saved.checkpoint.scene]
		park.content = content
		park.player = Vector2(saved.checkpoint.position[0], saved.checkpoint.position[1])
	else:
		park = ParkView.new()
		park.ui_theme = theme
		park.spawn_point = Vector2(saved.checkpoint.position[0], saved.checkpoint.position[1])
	park.set_meta("campaign_scene", saved.checkpoint.scene)
	park.saved_player = saved.player
	viewport.add_child(park)
	park.action_requested.connect(_park_action)
	park.menu_requested.connect(_pause_game)

func _save_park() -> bool:
	var result: Dictionary = journey.enter_world(park.get_meta("campaign_scene"), park.player)
	if result.status != "ok":
		park.paused = true
		_notice(_error(result.status))
		return false
	return true

func _park_action(id: String) -> void:
	if id == "autosave":
		_save_park()
		return
	if not _save_park(): return
	var point: Vector2 = park.player
	var player: Dictionary = session.snapshot().player
	if park.get_meta("campaign_scene") != "park-veredas" and id not in ["collection", "bag", "wild"]:
		_route_action(id)
		return
	if id == "exit":
		if _result(journey.enter_world("park-clearing", Vector2(1232, 400))): _show_saved.call_deferred()
	elif id == "collection": _show_collection()
	elif id == "bag": _show_bag()
	elif id == "wild":
		var result: Dictionary = encounters.start_wild(point)
		if result.status == "ok":
			park.paused = true
			_show_saved.call_deferred()
		elif result.status == "repair_needed": _notice("Seu parceiro precisa de reparos. O professor pode ajudar.")
	elif id.begins_with("chest:"):
		var chest_id := id.trim_prefix("chest:")
		var result: Dictionary = exploration.chest(chest_id, point)
		if result.status == "guardian": _notice("O guardião protege esse baú.")
		elif _result(result):
			park.refresh(session.snapshot().player)
			_notice("Baú encontrado · " + {"lookout": "Rabiola de Azulão", "woodland": "25 moedas", "canal": "Rabiola de Mata verde", "ridge": "Rabiola de Raio de sol", "courtyard": "60 moedas"}[chest_id])
	elif id == "nina":
		if player.flags.get("ninaReturned", false): _notice("Nina: O Carcará está comigo de novo. Ainda quero te mostrar a pipa que eu estava construindo!")
		elif player.flags.get("ninaTail", false):
			if _result(exploration.return_tail(point)):
				park.refresh(session.snapshot().player)
				_notice("Nina: Você encontrou! Eu reconheceria esse nó em qualquer lugar. Obrigada… Agora posso trazer meu Carcará de volta.\n\nMissão concluída · A rabiola de Nina")
		elif not player.flags.get("ninaAccepted", false):
			_confirm_park("Nina", "Meu Carcará tentou me proteger daquele lagarto. A linha rompeu e ele se recolheu na rabiola… O vento levou ela para os canos. Você consegue trazer a rabiola dele?", "Vou recuperar a rabiola", func():
				if _result(exploration.accept_nina(point)): park.refresh(session.snapshot().player))
		else: _notice("Nina: Ele arma a vela antes de puxar… Depois fica parado por um instante.")
	elif id == "tail":
		if _result(exploration.collect_tail(point)):
			park.refresh(session.snapshot().player)
			_notice("Rabiola do Carcará de Nina recebida.")
	elif id == "boss":
		if not player.flags.get("ninaAccepted", false):
			_notice("Há alguém na clareira, perto dos canos.")
			return
		_confirm_park("Lacertubo · Guardião dos canos", "Parceiro recomendado: Nv. 15. Você pode fugir e continua com seu parceiro se perder.", "Enfrentar Lacertubo", func():
			if _result(encounters.start_boss(point)): _show_saved.call_deferred())

func _confirm_park(title: String, text: String, accept: String, callback: Callable) -> void:
	park.paused = true
	var dialog := _dialog(title, text, accept, "Conversar depois") as ConfirmationDialog
	dialog.confirmed.connect(callback)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		if is_instance_valid(park): park.paused = false)
	dialog.popup_centered(Vector2i(620, 200))

func _show_encounter() -> void:
	_clear()
	var is_morro: bool = session.snapshot().player.encounter.get("kind", "") == "morro"
	battle = MorroBattleView.new() if is_morro else EncounterView.new()
	battle.configure(content, session.snapshot().player.encounter.state)
	battle.reward_player = session.snapshot().player
	battle.reward_encounter = session.snapshot().player.encounter
	battle.reduced_motion = preferences.reduced_motion
	add_child(battle)
	battle.save_requested.connect(func(state: Dictionary):
		var result: Dictionary = encounters.save_battle(state)
		battle.blocked = result.status != "ok"
		if battle.blocked: battle.suspend_actions())
	battle.leave_requested.connect(_menu)
	battle.finish_requested.connect(func():
		if not _result(encounters.save_battle(battle.model.snapshot())): return
		if is_morro:
			if _result(morro.settle()): _return_morro_result.call_deferred()
		elif _result(encounters.settle()): _show_saved.call_deferred())

func _remember_world_position() -> bool:
	if is_instance_valid(battle): return _result(encounters.save_battle(battle.model.snapshot()))
	if is_instance_valid(park): return _save_park()
	if is_instance_valid(room): return _result(journey.enter_world(session.snapshot().checkpoint.scene, room.actor))
	return true

func _show_collection() -> void:
	if not _remember_world_position(): return
	var player: Dictionary = session.snapshot().player
	_simple_page("Equipe")
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for partner in player.partners:
		var card := PanelContainer.new()
		card.theme_type_variation = "PanelContainer"
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		card.add_child(row)
		var art_id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}.get(partner.modelId, "rabbito")
		var art: Dictionary = content.combat[art_id]
		var frame: Dictionary = art.animations.idle[0]
		var texture := AtlasTexture.new()
		texture.atlas = load("res://assets/campaign/" + art.image)
		texture.region = Rect2(frame.x, frame.y, frame.w, frame.h)
		var portrait := TextureRect.new()
		portrait.texture = texture
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(144, 118)
		row.add_child(portrait)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var condition: Dictionary = partner.get("condition", {"line": 100, "structure": 100})
		var level: int = EncounterView.Model.level_for_xp(partner.get("xp", 0))
		_label("%s · Nv. %d" % [partner.get("personalName", partner.modelId), level], details)
		_label("Linha %d%% · Armação %d%%" % [condition.line, condition.structure], details, 18)
		var progress := ProgressBar.new()
		var xp: int = partner.get("xp", 0)
		var previous: int = 40 * (level - 1) + 10 * (level - 1) * (level - 1)
		var threshold: int = 40 * level + 10 * level * level
		progress.max_value = threshold - previous
		progress.value = xp - previous
		progress.show_percentage = false
		progress.custom_minimum_size.y = 12
		details.add_child(progress)
		_label("Nível máximo" if level == 50 else "%d / %d XP para o próximo nível" % [xp - previous, threshold - previous], details, 16)
		var id: String = partner.id
		var action_space := Hud.focus_space(row)
		action_space.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var button := _button("Selecionado" if id == player.get("equippedPartnerId", "") else "Escolher parceiro", action_space, func():
			if _result(exploration.equip(id)): _show_collection())
		button.custom_minimum_size.x = 256
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.disabled = id == player.get("equippedPartnerId", "")
	_button("Voltar", page, _return_to_game)

func _route_action(id: String) -> void:
	for place in park.data.places:
		if place.id != id: continue
		if place.action == "street_scene":
			var destination: String = place.target
			var point := Vector2(208, 816)
			if destination == "quintal": point = Vector2(1792, 1808)
			elif destination == "park-veredas": point = Vector2(224, 810)
			elif destination == "park-trail": point = Vector2(1232, 400)
			if _result(journey.enter_world(destination, point)): _show_saved.call_deferred()
		elif place.action == "wildGuide": _notice("Sr. Assis: Procure Pipamons no capim alto. O caminho de terra e os bancos são seguros. Você pode fugir sem perder seu parceiro.")
		elif place.action == "wildRest": _notice("Uma pausa no caminho. Aqui podemos baixar a guarda.")
		elif place.action == "parkMap": _notice("Parque dos Ventos\n\nA trilha segue até a Clareira do Papel. Além dela ficam as Veredas.")

func _show_bag() -> void:
	if not _remember_world_position(): return
	var player: Dictionary = session.snapshot().player
	_simple_page("Bolsa · %d moedas" % player.coins)
	var inventory_view = load("res://scripts/campaign/hud_inventory.gd").new()
	inventory_view.inventory = player.inventory
	page.add_child(inventory_view)
	_button("Voltar", page, _return_to_game)

func _show_tail_workshop() -> void:
	if not _remember_world_position(): return
	var player: Dictionary = session.snapshot().player
	_simple_page("Sr. Assis · Rabiolas encontradas")
	var found := false
	for model_id in Journey.CATALOG:
		var chosen: String = model_id
		if player.inventory.get("rabiola-" + chosen, 0) > 0:
			found = true
			_button("Montar %s · %d rabiola(s)" % [Journey.CATALOG[chosen], player.inventory["rabiola-" + chosen]], page, func():
				if _result(journey.start_summon(chosen)): _show_saved())
		if player.inventory.get("damaged-rabiola-" + chosen, 0) > 0:
			found = true
			_button("Restaurar rabiola de " + Journey.CATALOG[chosen], page, func():
				if _result(journey.restore_inventory_tail(chosen)): _show_tail_workshop())
	if not found: _label("Traga uma rabiola encontrada no parque para construir um novo parceiro.", page)
	_button("Voltar", page, _show_saved)

func _apply_preferences() -> void:
	Controls.set_family(preferences.pad_family)
	var recorte := get_node_or_null("RecorteUX")
	if recorte != null: recorte.set_reduced_motion(preferences.reduced_motion)
	crt_layer.visible = preferences.crt
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if preferences.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _show_settings() -> void:
	_simple_page("Configurações")
	for item in [["Filtro de TV (CRT)", "crt"], ["Tela cheia", "fullscreen"], ["Reduzir animações da interface", "reduced_motion"]]:
		var toggle := CheckButton.new()
		toggle.text = item[0]
		var state_label := Label.new()
		state_label.custom_minimum_size.x = 110
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state_label.text = "Ligado" if preferences.get(item[1]) else "Desligado"
		var toggle_row := HBoxContainer.new()
		page.add_child(toggle_row)
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle_row.add_child(toggle)
		toggle_row.add_child(state_label)
		var key: String = item[1]
		toggle.button_pressed = preferences.get(key)
		toggle.toggled.connect(func(enabled: bool):
			var old: bool = preferences.get(key)
			preferences.set(key, enabled)
			if preferences.save_settings() != OK:
				preferences.set(key, old)
				_notice("Não foi possível guardar a configuração.")
			state_label.text = "Ligado" if preferences.get(key) else "Desligado"
			toggle.set_pressed_no_signal(preferences.get(key))
			_apply_preferences())
	_button("Controles", page, _show_controls)
	var family_row := HBoxContainer.new()
	page.add_child(family_row)
	_label("Símbolos do controle",family_row,20).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var family_choice := OptionButton.new()
	var families := ["auto","xbox","ps","switch"]
	for caption in ["Automático","Xbox","PlayStation","Nintendo Switch"]: family_choice.add_item(caption)
	family_choice.select(families.find(preferences.pad_family))
	family_row.add_child(family_choice)
	family_choice.item_selected.connect(func(index: int):
		var old: String = preferences.pad_family
		preferences.pad_family = families[index]
		if preferences.save_settings() != OK:
			preferences.pad_family = old
			family_choice.select(families.find(old))
			_notice("Não foi possível guardar a configuração.")
		_apply_preferences())
	_button("Voltar", page, _menu if session.snapshot().is_empty() else _return_to_game)

func _show_controls() -> void:
	_simple_page("Controles · Teclado")
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for action in Controls.DEFAULTS:
		var id: String = action
		var binding_button := _button("%s · %s" % [Controls.LABELS[id], OS.get_keycode_string(int(preferences.bindings[id]))], list, func(): _capture_binding(id))
		binding_button.icon = Controls.glyph(id,true)
		binding_button.expand_icon = true
		binding_button.add_theme_constant_override("icon_max_width",40)
	_button("Restaurar padrão", page, func():
		var old: Dictionary = preferences.bindings.duplicate()
		preferences.bindings = Controls.DEFAULTS.duplicate()
		if preferences.save_settings() != OK:
			preferences.bindings = old
			_notice("Não foi possível salvar os controles.")
		else: Controls.install(preferences.bindings)
		_show_controls())
	_label("Setas e Enter continuam disponíveis. O botão de pausa abre o menu durante o jogo. Os símbolos abaixo acompanham seu controle e as teclas remapeadas. A bancada usa mouse e teclado.",page,17)
	var live_hints := HBoxContainer.new()
	page.add_child(live_hints)
	for item in [["interact","Interagir"],["cut","Cortar"],["skill","Habilidade"],["dodge","Esquiva"],["guard","Guarda"],["signature","Assinatura"]]: Hud.input_hint(live_hints,item[0],item[1])
	_button("Voltar", page, _show_settings)

func _capture_binding(action: String) -> void:
	binding_target = action
	binding_dialog = _dialog(Controls.LABELS[action], "Pressione a nova tecla. Esc cancela.", "Cancelar")
	binding_dialog.window_input.connect(_input)
	binding_dialog.confirmed.connect(_cancel_binding)
	binding_dialog.canceled.connect(_cancel_binding)
	binding_dialog.popup_centered(Vector2i(500, 140))

func _cancel_binding() -> void:
	binding_target = ""
	if is_instance_valid(binding_dialog): binding_dialog.queue_free()

func _input(event: InputEvent) -> void:
	Controls.observe(event)
	if binding_target.is_empty() or not event is InputEventKey or not event.pressed or event.echo: return
	get_viewport().set_input_as_handled()
	if event.physical_keycode == KEY_ESCAPE:
		_cancel_binding()
		return
	var conflict := Controls.conflict(binding_target, event.physical_keycode)
	if not conflict.is_empty():
		binding_dialog.dialog_text = "Tecla reservada à navegação. Escolha outra." if conflict == "reserved" else "Esta tecla já é usada para %s. Escolha outra." % Controls.LABELS[conflict]
		return
	var next: Dictionary = preferences.bindings.duplicate()
	next[binding_target] = event.physical_keycode
	var old: Dictionary = preferences.bindings
	preferences.bindings = next
	if preferences.save_settings() != OK:
		preferences.bindings = old
		binding_dialog.dialog_text = "Não foi possível salvar. Tente novamente."
		return
	Controls.install(next)
	_cancel_binding()
	_show_controls.call_deferred()

func _controller_changed(device: int, connected: bool) -> void:
	if connected:
		Controls.configure_device(device,Input.get_joy_name(device),int(Input.get_joy_info(device).get("vendor_id",0)))
	else: Controls.remove_device(device)
	if connected or not Controls.gamepad: return
	Controls.use_keyboard()
	if is_instance_valid(battle): battle.paused = true
	if is_instance_valid(workshop): workshop._pause()
	for child in get_children():
		if child.get_script() == FlightView:
			child.paused = true
			child.resume_button.show()
	if not session.snapshot().is_empty(): _notice("Controle desconectado. Conecte novamente ou continue pelo teclado.")

func _show_morro() -> void:
	_clear()
	var saved: Dictionary = session.snapshot()
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(size)
	viewport.handle_input_locally = true
	viewport.world_2d = World2D.new()
	container.add_child(viewport)
	park = MorroView.new()
	park.ui_theme = theme
	park.data = Morro.maps()[saved.checkpoint.scene]
	park.content = content
	park.player = Vector2(saved.checkpoint.position[0], saved.checkpoint.position[1])
	park.saved_player = saved.player
	park.set_meta("campaign_scene", saved.checkpoint.scene)
	viewport.add_child(park)
	park.action_requested.connect(_morro_action)
	park.menu_requested.connect(_pause_game)
	container.modulate.a = 0
	create_tween().tween_property(container, "modulate:a", 1.0, .18)

func _morro_action(id: String) -> void:
	if not _save_park(): return
	if id == "autosave": return
	if id == "collection":
		_show_collection()
		return
	if id == "bag":
		_show_bag()
		return
	var data: Dictionary = park.data
	var place: Dictionary = {}
	for entry in data.places:
		if entry.id == id: place = entry
	if place.is_empty(): return
	if park.player.distance_to(Vector2(place.point[0], place.point[1])) > 90: return
	if place.has("stage"):
		var story: Dictionary = Morro.Rules.content().stories[data.stage]
		var text := "\n\n".join(story.before.map(func(line): return "%s: %s" % [line[0], line[1]]))
		text += "\n\n" + story.tactic
		_confirm_park(" e ".join(Morro.Rules.stage(data.stage).foes.map(func(f): return f.name)), text, "Vamos voar!", func():
			if _result(morro.start(park.player)): _show_saved.call_deferred())
		return
	if place.action == "pilot_story":
		_notice(place.story)
		return
	if place.action == "quintal":
		if _result(journey.enter_world("quintal", Vector2(2592, 1040))): _show_saved.call_deferred()
		return
	if place.action in ["road_next", "road_gate"]:
		if not session.snapshot().player.get("morro", Morro.Rules.defaults()).stars.has(data.stage):
			_notice("Converse com os pipeiros deste lugar e vença o desafio para seguir.")
			return
		if place.action == "road_gate":
			for entry in data.places:
				if entry.get("action", "") == "road_next":
					park.walk_to(Vector2(entry.point[0], entry.point[1]))
			return
		if not place.has("target"):
			if _result(journey.enter_world("quintal", Vector2(2592, 1040))): _show_saved.call_deferred()
			return
	if place.has("target"):
		var next_data: Dictionary = Morro.maps()[place.target]
		var point := Vector2(next_data.spawn[0], next_data.spawn[1])
		if place.action == "road_back":
			for exit_place in next_data.places:
				if exit_place.get("action", "") == "road_next": point = Vector2(exit_place.point[0], exit_place.point[1])
		if _result(journey.enter_world(place.target, point)): _show_saved.call_deferred()

func _return_morro_result() -> void:
	_show_saved()
	var result: Dictionary = session.snapshot().player.lastMorro
	var lines: Array = Morro.Rules.content().stories[result.stage].won if result.outcome == "won" else Morro.Rules.content().stories[result.stage].lost
	if result.outcome == "fled":
		_notice("Você pode conversar com o pipeiro para tentar novamente quando quiser.")
		return
	var text := "\n\n".join(lines.map(func(line): return "%s: %s" % [line[0], line[1]]))
	text += "\n\n+%d XP" % result.partnerXp
	if result.outcome == "won": text += " · %d estrelas · +%d moedas" % [result.stars, result.coins]
	if result.get("drop") != null: text += "\nRabiola de Raio de sol recebida!"
	_notice(text)

func _partner_portrait(model_id: String) -> Texture2D:
	var id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}.get(model_id, "rabbito")
	var art: Dictionary = content.combat[id]
	var frame: Dictionary = art.animations.idle[0]
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/campaign/" + art.image)
	texture.region = Rect2(frame.x, frame.y, frame.w, frame.h)
	return texture
