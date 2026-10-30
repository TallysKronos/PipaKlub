extends Control
const Session = preload("res://scripts/campaign/session.gd")
const Opening = preload("res://scripts/campaign/opening.gd")
const Room = preload("res://scripts/campaign/room_view.gd")
const Journey = preload("res://scripts/campaign/journey.gd")
const FlightView = preload("res://scripts/campaign/first_flight_view.gd")
const WorkshopView = preload("res://scripts/campaign/workshop_view.gd")
const TutorialStaging=preload("res://scripts/campaign/tutorial_staging.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const MorroView = preload("res://scripts/campaign/morro_view.gd")
const MorroBattleView = preload("res://scripts/campaign/morro_battle_view.gd")
const ParkOverworldView = preload("res://scripts/campaign/park_overworld_view.gd")
const ParkCheckpoint = preload("res://scripts/campaign/park_checkpoint.gd")
const Exploration = preload("res://scripts/campaign/exploration.gd")
const Encounters = preload("res://scripts/campaign/encounters.gd")
const EncounterView = preload("res://scripts/campaign/encounter_view.gd")
const Preferences = preload("res://scripts/campaign/preferences.gd")
const Backdrop = preload("res://scripts/campaign/hud_backdrop.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const Sound = preload("res://scripts/campaign/sound_director.gd")
var sound := Sound.new()
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
var opening_pages:Array[String]=[]
var opening_page_index:=0
var opening_busy:=false
var flow_busy:=false
var opening_generation:=0
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
var binding_dialog: Control
var pause_overlay: Control
var pause_previous: Dictionary = {}
var last_scene_key := ""
var menu_origin:=""
var binding_rows:Dictionary={}
var controls_focus_action:=""
var team_page:=0
var settings_tab:="Vídeo"
var settings_focus_controls:=false
var team_load_state:="ready"
var scene_loading:CanvasLayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().auto_accept_quit = false
	preferences.load_settings()
	sound.name = "SoundDirector"
	add_child(sound)
	sound.configure(preferences.audio_levels, preferences.dialogue_blips)
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
	session.changed.connect(sound.saved)
	session.storage_failed.connect(func(_reason: String): sound.play_event("progress.save_error"))
	opening = Opening.new(session)
	journey = Journey.new(session)
	exploration = Exploration.new(session)
	encounters = Encounters.new(session)
	morro = Morro.new(session)
	Hud.Recorte.install(self, preferences.reduced_motion)
	get_node("RecorteUX").set_text_scale(preferences.text_scale)
	resized.connect(_layout_stage)
	_title()

func _clear(route: String = "") -> void:
	sound.clear_context()
	if route == "title" or route.begins_with("menu"): sound.play_music("menu")
	elif not route.begins_with("opening:") and route != "page:Configurações": sound.stop_music()
	opening_generation+=1
	opening_busy=false
	flow_busy=false
	if not binding_target.is_empty():_cancel_binding()
	for child in get_children():
		if child != session and child != crt_layer and child != sound and child != scene_loading and child.name != "RecorteUX":
			remove_child(child)
			child.queue_free()
	stage = null
	room = null
	workshop = null
	park = null
	battle = null
	status = null
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
	if not is_instance_valid(scene_loading) and not last_scene_key.is_empty() and scene_key != last_scene_key:
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
	Hud.navigation_button(button)
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

func _title() -> void:
	_clear("title")
	session.close_session()
	var title_view=load("res://scripts/campaign/hud_title_menu.gd").new()
	title_view.mode="title"
	title_view.reduced_motion=preferences.reduced_motion
	add_child(title_view)
	title_view.selected.connect(func(_id:String):_menu())

func _menu() -> void:
	menu_origin=""
	_clear("menu")
	session.close_session()
	var menu=load("res://scripts/campaign/hud_title_menu.gd").new()
	for index in range(1,4):
		if session.inspect_slot("slot-%d"%index).status=="ok":menu.has_saves=true
	menu.reduced_motion=preferences.reduced_motion
	add_child(menu)
	menu.selected.connect(_main_menu_action)

func _main_menu_action(id:String) -> void:
	match id:
		"continue":_show_slots(false)
		"new":_show_slots(true)
		"settings":_show_settings()
		"quit":get_tree().quit()

func _slot_location(snapshot:Dictionary) -> Dictionary:
	var point:Dictionary=snapshot.get("checkpoint",{})
	var scene:String=point.get("scene",snapshot.get("player",{}).get("encounter",{}).get("scene",""))
	var name:String={"quintal":"Vila do Primeiro Vento","professor-home":"Ateliê do Sr. Assis","park-trail":"Jardim dos Ventos","park-clearing":"Clareira do Papel","park-veredas":"Veredas do Encanamento"}.get(scene,"Prólogo" if point.get("kind")=="opening" else "Ateliê do Sr. Assis")
	var texture:Texture2D=load("res://assets/campaign/rooftop-arena-wide-v2.png")
	if scene.begins_with("morro"):
		var data:Dictionary=Morro.maps().get(scene,{})
		name=data.get("name","Morro do Sol")
		if not data.get("images",[]).is_empty():texture=load("res://assets/campaign/morro/"+data.images[0].image)
	elif scene in ["quintal","professor-home"]:
		texture=load("res://assets/campaign/"+content.rooms["street" if scene=="quintal" else "professor"].floorImage)
	elif scene in ["park-trail","park-clearing"]:
		var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
		texture=load("res://assets/campaign/park/"+maps[scene].floorImage)
	elif scene=="park-veredas":texture=load("res://assets/illustrated/veredas-ground.png") if ResourceLoader.exists("res://assets/illustrated/veredas-ground.png") else load("res://assets/campaign/veredas-arena-wide-v2.png")
	return {"name":name,"texture":texture}

func _show_slots(new_journey:bool=false) -> void:
	_clear("menu:slots")
	session.close_session()
	var background=load("res://scripts/campaign/hud_title_menu.gd").new()
	background.mode="slots"
	add_child(background)
	var scroll:=ScrollContainer.new()
	scroll.anchor_left=.5;scroll.anchor_right=.5;scroll.anchor_bottom=1
	scroll.offset_left=-minf(550,size.x*.46);scroll.offset_right=minf(550,size.x*.46)
	scroll.offset_top=32;scroll.offset_bottom=-24
	scroll.follow_focus=true
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	page=VBoxContainer.new()
	page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",14)
	scroll.add_child(page)
	var heading:=PanelContainer.new()
	heading.theme_type_variation="RecorteEmptyPanel"
	heading.set_meta("recorte_decorated",true)
	page.add_child(heading)
	_label("NOVA JORNADA" if new_journey else "SUAS JORNADAS",heading,38)
	status=_label("Escolha um espaço vazio." if new_journey else "Retome de onde parou.",page,18)
	var first:Button
	for index in range(1,4):
		var id:="slot-%d"%index
		var inspection:Dictionary=session.inspect_slot(id)
		var card=load("res://scripts/campaign/hud_journey_slot.gd").new()
		card.slot_id=id;card.inspection=inspection;card.available_for_new=new_journey
		if inspection.status=="ok":
			var location:=_slot_location(inspection.data)
			card.area_name=location.name;card.thumbnail=location.texture
			var saved_player:Dictionary=inspection.data.get("player",{})
			for partner in saved_player.get("partners",[]):
				if partner.id!=saved_player.get("equippedPartnerId",""):continue
				var art_id:String={"rabbito":"rabbito","basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol","lacertubo":"lacertubo"}.get(partner.modelId,"")
				if content.combat.has(art_id):
					card.partner_portrait=load("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/"+content.combat[art_id].image),art_id)
		page.add_child(card)
		card.selected.connect(func():_choose(id,inspection.status=="missing"))
		card.erase_requested.connect(func():_confirm_erase_slot(id,inspection,new_journey))
		if first==null and not card.action.disabled:first=card.action
	var tools:=HBoxContainer.new()
	tools.add_theme_constant_override("separation",18)
	page.add_child(tools)
	var back:=_button("Voltar",tools,_menu)
	var receipt:Dictionary=session._store.latest_removed()
	if not receipt.is_empty():_button("Desfazer exclusão",tools,func():
		if _result(session._store.restore_slot(receipt)):_show_slots(new_journey))
	Hud.input_hint(tools,"accept","Confirmar")
	Hud.input_hint(tools,"back","Voltar")
	Hud.focus_later(first if first!=null else back)

func _confirm_erase_slot(id:String,inspection:Dictionary,new_journey:bool) -> void:
	sound.play_event("ui.warning")
	var dialog:=_confirmation("Excluir jornada", "Excluir a jornada de %s?\n\nVocê poderá desfazer na lista de jornadas enquanto esse espaço continuar vazio."%inspection.data.player.name,"Excluir jornada")
	dialog.confirmed.connect(func():
		if _result(session._store.archive_slot(id,int(inspection.data.revision))):_show_slots(new_journey))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _error(code: String) -> String:
	return {"corrupt": "Save danificado; mantenha os arquivos para recuperação.",
		"future": "Este save precisa de uma versão mais recente do jogo.",
		"unsupported": "Versão do save incompatível.", "occupied": "Esta jornada já existe.",
		"invalid_name": "Use um nome de até 24 caracteres, sem quebras de linha.",
		"stale": "A jornada foi alterada. Volte ao menu e carregue novamente.",
		"repair_needed": "Seu parceiro precisa de reparos. Volte ao professor: ele cuida da equipe gratuitamente.",
		"io_error": "Não foi possível acessar o save. Confira o espaço e a permissão da pasta."}.get(code, "Não foi possível continuar. Seu último save foi mantido.")

func _choose(slot_id: String, create: bool) -> void:
	sound.reset_session()
	var result: Dictionary = session.start(slot_id) if create else session.resume_slot(slot_id)
	if result.status != "ok":
		status.text = _error(result.status)
		return
	_show_saved()
	if not create and is_instance_valid(battle): battle.paused = true
	var wipe=load("res://scripts/campaign/recorte_ink_wipe.gd").new()
	add_child(wipe)
	wipe.z_index=90
	wipe.finished.connect(wipe.queue_free,CONNECT_ONE_SHOT)
	wipe.play(Hud.CYAN,preferences.reduced_motion,false)
	if result.get("recovered", false):
		_notice("Recuperamos sua jornada a partir do backup.")

func _dialog(title: String, text: String, ok: String, cancel: String = "") -> Control:
	sound.play_event("dialogue.open")
	var dialog=load("res://scripts/campaign/hud_dialogue.gd").new()
	dialog.title=title
	dialog.dialog_text=text
	dialog.ok_button_text=ok
	dialog.cancel_button_text=cancel
	dialog.reduced_motion=preferences.reduced_motion
	add_child(dialog)
	return dialog

func _confirmation(title:String,text:String,ok:String) -> Control:
	var dialog=load("res://scripts/campaign/hud_confirmation.gd").new()
	dialog.title=title
	dialog.dialog_text=text
	dialog.ok_button_text=ok
	add_child(dialog)
	return dialog

func _notice(message: String) -> void:
	if is_instance_valid(park) and (message.begins_with("Baú encontrado") or message=="Rabiola do Carcará de Nina recebida."):
		if park.has_method("celebrate_item") and park.celebrate_item(message):return
		park.exploration_hud.push_notice(message,"item")
		return
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
	if not menu_origin.is_empty():_pause_game()

func _show_opening() -> void:
	var saved: Dictionary=session.snapshot()
	var step: int=int(saved.checkpoint.step)
	var room_key := "home" if step>=12 else "bedroom"
	# Detach before clearing UI: the same room and actors survive every line.
	var preserved: Node2D
	if is_instance_valid(room) and room.get_meta("opening_room","")==room_key:
		preserved=room
		room.get_parent().remove_child(room)
	_clear("opening:"+room_key)
	if step >= 2: sound.play_music("opening")
	else: sound.stop_music()
	current_step=step
	next=null
	stage=Node2D.new()
	add_child(stage)
	var map: Dictionary=content.rooms[room_key]
	var point: Array=map.layout.blocking.kaelEntry if room_key=="home" else map.layout.blocking.kaelDesk
	if step<=3:point=map.layout.blocking.kaelTV
	elif step in [6,7,8]:point=map.layout.blocking.kaelTalk
	elif step==14:
		for spot in map.hotspots:
			if spot.id=="exit":point=[spot.x,spot.y]
	if is_instance_valid(preserved):
		room=preserved
		stage.add_child(room)
	else:
		room=Room.new()
		stage.add_child(room)
		room.configure(map,point,false,"",true,false)
		room.set_meta("opening_room",room_key)
		room.interacted.connect(func(_id: String):_advance())
	room.can_walk=false
	room.set_story_paused(false)
	room.target_hotspot="desk" if step==3 else "stairs" if step==11 else "exit"
	room.mother_sprite.visible=step>=5
	if step>=10 and not is_instance_valid(room.companion):
		room.add_companion()
		room.companion_point=Vector2(1145,640) if room_key=="bedroom" else room.actor+Vector2(-60,30)
		room.companion.position=room.project(room.companion_point)
	if step<=1 and not is_instance_valid(room.opening_tv):
		room.opening_tv=load("res://scripts/campaign/opening_tv.gd").new()
		room.opening_tv.content=content
		room.add_child(room.opening_tv)
		room.opening_tv.handoff_requested.connect(func():_finish_opening_film.call_deferred())
	room.opening_pose()
	_layout_stage()
	portrait = load("res://scripts/campaign/hud_dialogue_portrait.gd").new()
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
	var panel=load("res://scripts/campaign/hud_dialogue_surface.gd").new()
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
	var dialogue_tags=load("res://scripts/campaign/hud_dialogue_surface.gd").parse_tags(story.text)
	panel.shouted=dialogue_tags.shout
	portrait.emotion=dialogue_tags.emotion
	portrait.reaction=dialogue_tags.reaction
	var speaker: String = story.speaker
	if content.portraits.has(speaker):
		portrait.texture = load("res://assets/campaign/" + content.portraits[speaker])
	portrait.visible = portrait.texture != null
	var nameplate=load("res://scripts/campaign/hud_result_plate.gd").new()
	nameplate.accent=Hud.CORAL
	nameplate.position = Vector2(22, -34)
	nameplate.custom_minimum_size = Vector2(maxf(180, Hud.font().get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 48), 48)
	nameplate.theme_type_variation = "RecorteNamePanel"
	nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate_holder := Node2D.new()
	panel.add_child(plate_holder)
	plate_holder.add_child(nameplate)
	var heading := _label(speaker, nameplate, 24)
	heading.add_theme_font_override("font",Hud.display())
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	nameplate.visible = not speaker.is_empty()
	heading.theme_type_variation = "Label"
	speech = _label(dialogue_tags.text, page, 22)
	opening_pages.clear()
	opening_page_index=0
	var paginate_opening:=func():
		if not is_instance_valid(speech) or not speech.is_visible_in_tree() or current_step in [3,10,11,13,14]:return
		opening_pages=load("res://scripts/campaign/hud_dialogue_surface.gd").text_pages(dialogue_tags.text,Hud.font(),22,maxf(160,speech.size.x-12))
		speech.text=opening_pages[0]
	paginate_opening.call_deferred()
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
		panel.hide()
		var hint=load("res://scripts/campaign/hud_opening_hint.gd").new()
		hint.subject=room
		add_child(hint)
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
	var menu := _button("", self, _pause_game)
	Hud.pause_glyph(menu)
	menu.anchor_left = 1
	menu.anchor_right = 1
	menu.offset_left = -80
	menu.offset_right = -24
	menu.offset_top = 16
	menu.offset_bottom = 70
	menu.z_index=110
	opening_busy=true
	if is_instance_valid(next):next.disabled=true
	var hide_dialogue: bool=step in [2,4,5,7,8,9,11,12]
	if step<=1 and is_instance_valid(room.opening_tv) and room.opening_tv.cinematic_handoff:hide_dialogue=true
	if hide_dialogue:panel.hide();portrait.hide()
	_present_opening.call_deferred(step,opening_generation,panel,hide_dialogue)

func _present_opening(step: int,generation: int,panel: Control,hidden_for_action: bool) -> void:
	await preload("res://scripts/campaign/opening_staging.gd").play(room,step)
	if generation!=opening_generation or not is_instance_valid(room) or not is_instance_valid(panel):return
	opening_busy=false
	if step<=1 and is_instance_valid(room.opening_tv) and room.opening_tv.cinematic_handoff:return
	if is_instance_valid(next):next.disabled=false
	if hidden_for_action and step not in [3,11,13,14]:
		panel.show()
		portrait.visible=portrait.texture!=null
		# Hidden containers have no final line width until layout has run.
		await get_tree().process_frame
		await get_tree().process_frame
		if generation!=opening_generation or not is_instance_valid(speech):return
		var story: Dictionary=content.opening[mini(step,13)]
		var text: String=load("res://scripts/campaign/hud_dialogue_surface.gd").parse_tags(story.text).text
		opening_pages=load("res://scripts/campaign/hud_dialogue_surface.gd").text_pages(text,Hud.font(),22,maxf(160,speech.size.x-12))
		opening_page_index=0
		speech.text=opening_pages[0]
	if is_instance_valid(next):Hud.focus_later(next)

func _finish_opening_film()->void:
	if opening_busy or is_instance_valid(pause_overlay) or not is_instance_valid(room) or not is_instance_valid(room.opening_tv) or current_step not in [0,1]:return
	opening_busy=true
	var result:Dictionary=opening.finish_broadcast(current_step)
	if result.status=="ok":
		_show_opening()
	else:
		opening_busy=false
		room.opening_tv.handoff_failed(_error(result.status))

func _advance() -> void:
	if opening_busy:return
	sound.play_event("dialogue.advance")
	if opening_page_index<opening_pages.size()-1:
		opening_page_index+=1
		speech.text=opening_pages[opening_page_index]
		return
	var previous_step := current_step
	if previous_step in [11,13]:
		opening_busy=true
		var generation := opening_generation
		await preload("res://scripts/campaign/opening_staging.gd").leave(room,previous_step)
		if generation!=opening_generation:return
	var result: Dictionary = opening.advance(current_step)
	if result.status == "ok":
		if previous_step==13:
			var departure: Dictionary=journey.enter_world("quintal",Vector2(480,768))
			if departure.status=="ok":_show_saved()
			else:
				_show_opening()
				_notice(_error(departure.status))
		else:_show_opening()
	else:
		opening_busy=false
		if is_instance_valid(room):
			room.avatar.modulate.a=1
			room.avatar.set_motion_action("")
			if is_instance_valid(room.companion):room.companion.modulate.a=1
			room.can_walk=previous_step in [3,11,13]
		status.text = _error(result.status)

func _name() -> void:
	if opening_busy:return
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
	if session.snapshot().checkpoint.scene=="quintal":
		_show_neighborhood()
		return
	if Morro.maps().has(session.snapshot().checkpoint.scene):
		_show_morro()
		return
	if session.snapshot().checkpoint.scene in ["park-trail", "park-clearing", "park-veredas"]:
		_load_park()
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
	_equip_room_companion()
	room.interacted.connect(_world_interact)
	var overlay=load("res://scripts/campaign/hud_exploration.gd").new()
	overlay.subject=room
	overlay.area_name="Ateliê do Sr. Assis" if professor else "Bairro dos Ventos"
	overlay.player_data=session.snapshot().player
	add_child(overlay)
	overlay.map=Hud.map_for(room,overlay)
	status=overlay.prompt
	room.set_meta("exploration_hud",overlay)
	overlay.chosen.connect(func(id:String):
		if id=="collection":_show_collection()
		elif id=="bag":_show_bag()
		else:_pause_game())
	if professor and room.actor.distance_to(Vector2(1056,1232))<4:
		TutorialStaging.enter_atelier.call_deferred(self)

func _equip_room_companion()->void:
	for partner in session.snapshot().player.partners:
		if partner.id != session.snapshot().player.get("equippedPartnerId", ""): continue
		var id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}.get(partner.modelId, "rabbito")
		room.companion.texture = load("res://assets/campaign/" + content.combat[id].image)
		room.companion_frames = content.combat[id].animations.idle

func _show_neighborhood() -> void:
	if is_instance_valid(scene_loading):return
	scene_loading=load("res://scripts/campaign/hud_scene_loading.gd").new()
	scene_loading.reduced_motion=preferences.reduced_motion
	add_child(scene_loading)
	flow_busy=true
	if is_instance_valid(room):room.set_story_paused(true)
	if is_instance_valid(park):park.paused=true
	await scene_loading.cover()
	if not is_inside_tree():return
	_clear()
	var container:=SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch=true
	add_child(container)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(size)
	viewport.handle_input_locally=true
	viewport.world_2d=World2D.new()
	container.add_child(viewport)
	var saved: Dictionary=session.snapshot()
	park=load("res://scripts/campaign/neighborhood_view.gd").new()
	park.saved_player=saved.player
	park.checkpoint_position=Vector2(saved.checkpoint.position[0],saved.checkpoint.position[1])
	park.set_meta("campaign_scene","quintal")
	park.paused=true
	viewport.add_child(park)
	park.action_requested.connect(_neighborhood_action)
	park.menu_requested.connect(_pause_game)
	# Let the SubViewport draw the initialized city before uncovering it.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not is_instance_valid(park) or not is_instance_valid(scene_loading):
		if is_instance_valid(scene_loading):scene_loading.queue_free()
		scene_loading=null
		return
	await scene_loading.reveal()
	scene_loading.queue_free()
	scene_loading=null
	if is_instance_valid(park):park.paused=false

func _neighborhood_action(id: String) -> void:
	if not _save_park():return
	match id:
		"autosave":return
		"collection":_show_collection()
		"bag":_show_bag()
		"menu":_pause_game()
		"map":_pause_game();menu_origin="map";_show_map()
		"professor-home":
			var entry: Array=content.rooms.professor.layout.blocking.kaelEntry
			if _result(journey.enter_world("professor-home",Vector2(entry[0],entry[1]))):_show_saved.call_deferred()
		"morro":
			if session.snapshot().player.get("journey",{}).get("phase")=="complete" and _result(journey.enter_world("morro",Vector2(528,752))):_show_saved.call_deferred()
		"park":
			if session.snapshot().player.get("journey",{}).get("phase")=="complete" and _result(journey.enter_world("park-trail",Vector2(208,816))):_show_saved.call_deferred()

func _world_interact(id: String) -> void:
	if flow_busy:return
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
		TutorialStaging.leave_atelier(self)
	elif id == "professor":
		TutorialStaging.meet_professor(self)
	elif id == "workbench":
		TutorialStaging.open_workbench(self)
	else:
		_notice("Estudos sobre pipas, almas e o vento.")

func _show_practice() -> void:
	_clear()
	var view := FlightView.new()
	view.reduced_motion=preferences.reduced_motion
	var index: int = session.snapshot().checkpoint.lesson
	view.configure(content, index)
	add_child(view)
	view.continue_lesson.connect(_continue_practice.bind(view))
	view.leave.connect(_menu)

func _continue_practice(view:Control)->void:
	if flow_busy or not is_instance_valid(view) or not view.model.complete:return
	flow_busy=true
	var generation:int=opening_generation
	var index:int=view.model.lesson
	if not _result(journey.lesson_completed(index)):
		flow_busy=false
		return
	if index<4:
		view.prepare_lesson(index+1)
		flow_busy=false
	else:
		view.suspend_actions()
		if await TutorialStaging.talk(self,"Sr. Assis: É isso! Recolha sua linha com calma. Vamos voltar ao ateliê; tenho uma surpresa para você.","Recolher a pipa"):
			if not TutorialStaging.valid(self,generation):return
			await view.reel_in()
			if TutorialStaging.valid(self,generation):TutorialStaging.after_practice(self)

func _simple_page(title: String, illustrated:bool=false) -> void:
	sound.play_event("ui.open")
	_clear("page:" + title)
	if illustrated:
		var backdrop=load("res://scripts/campaign/hud_title_menu.gd").new()
		backdrop.mode="slots"
		add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	if illustrated:
		for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,maxi(48,int((size.x-1100)/2)))
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

func _workshop_page(title:String)->void:
	_clear("page:oficina")
	var backdrop:=TextureRect.new()
	backdrop.texture=load("res://assets/campaign/workshop-background.png")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var shade:=ColorRect.new()
	shade.color=Color(.025,.07,.1,.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var host:=TextureRect.new()
	host.texture=load("res://assets/campaign/portrait-assis.png")
	host.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	host.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.anchor_top=.18;host.anchor_right=.32;host.anchor_bottom=1
	host.offset_left=8;host.offset_bottom=80
	host.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(host)
	var host_label:=Label.new()
	host_label.text="SR. ASSIS\nCada pipa começa com um cuidado."
	host_label.add_theme_font_override("font",Hud.display())
	host_label.add_theme_font_size_override("font_size",24)
	host_label.add_theme_color_override("font_outline_color",Hud.INK)
	host_label.add_theme_constant_override("outline_size",8)
	host_label.anchor_top=1;host_label.anchor_bottom=1
	host_label.offset_left=28;host_label.offset_top=-92
	add_child(host_label)
	var panel:=PanelContainer.new()
	panel.anchor_left=.33;panel.anchor_right=1;panel.anchor_bottom=1
	panel.offset_left=0;panel.offset_right=-28
	panel.offset_top=38;panel.offset_bottom=-32
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("20333e")
	style.border_color=Color("e8bc58")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left=24;style.content_margin_right=24
	style.content_margin_top=20;style.content_margin_bottom=20
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",16)
	panel.add_child(stack)
	_label(title,stack,32)
	_label("Escolha sua rabiola. Na bancada, suas mãos dão forma ao novo elo.",stack,18)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	stack.add_child(scroll)
	page=VBoxContainer.new()
	page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",16)
	scroll.add_child(page)
	var hints:=HBoxContainer.new()
	stack.add_child(hints)
	Hud.input_hint(hints,"accept","Escolher")
	Hud.input_hint(hints,"back","Voltar")
	_focus_first.call_deferred(page)

func _show_starter() -> void:
	_workshop_page("OFICINA DAS ALMAS")
	var player: Dictionary = session.snapshot().player
	if player.has("starter"):
		_label("Sua rabiola: " + Journey.STARTERS[player.starter.modelId], page)
		if player.starter.status == "damaged":
			_button("Restaurar rabiola", page, func():
				if _result(journey.restore_tail()): _show_saved())
		else:
			_button("Começar a montagem", page, func():
				if _result(journey.start_workshop()): TutorialStaging.handoff(self,false))
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
			portrait.custom_minimum_size = Vector2(88, 96)
			row.add_child(portrait)
			var detail := VBoxContainer.new()
			detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(detail)
			var description := {"basica": "Reforça o próximo corte.", "mata": "Reduz o dano recebido por um instante.", "azulao": "Favorece o ângulo no cruzamento.", "raio": "Rajada veloz de curta duração."}
			_label(description[chosen] + "\nHabilidade · 25 energia", detail, 16)
			var choose := _button(Journey.STARTERS[chosen], Hud.focus_space(detail), func(): _confirm_starter(chosen))
			Hud.secondary_button(choose)

	_button("Salvar e voltar ao menu", page, _menu)

func _confirm_starter(model_id: String) -> void:
	sound.play_event("workshop.select_tail")
	var dialog := _dialog("Escolher parceiro", "Escolher a rabiola de %s? A escolha será guardada nesta jornada." % Journey.STARTERS[model_id], "Escolher rabiola", "Continuar escolhendo")
	dialog.confirmed.connect(func():
		if flow_busy:return
		flow_busy=true
		if _result(journey.choose(model_id)):
			dialog.queue_free()
			TutorialStaging.handoff(self)
		else:flow_busy=false;dialog.queue_free()
	)
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
		_finish_workshop_presentation.call_deferred(_outcome))
	workshop.leave_requested.connect(_confirm_cancel_workshop)
	workshop.pause_requested.connect(_pause_game)

func _finish_workshop_presentation(outcome:Dictionary)->void:
	if not is_instance_valid(workshop) or flow_busy:return
	flow_busy=true
	workshop.paused=true
	var job:Dictionary=session.snapshot().player.workshop.duplicate(true)
	if not _result(journey.finish_workshop()):
		flow_busy=false
		workshop.sent_outcome=false
		workshop.storage_blocked=true
		workshop.resume_button.show()
		return
	if outcome.get("type")=="broken":
		_show_saved()
		await TutorialStaging.talk(self,"Sr. Assis: O elo não se firmou desta vez. Sua rabiola foi preservada para reparo. Vamos cuidar dela e tentar de novo.","Cuidar da rabiola")
		return
	_clear("workshop:birth")
	flow_busy=true
	var birth:Control=load("res://scripts/campaign/workshop_birth_view.gd").new()
	var art_id:String={"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol","lacertubo":"lacertubo"}.get(job.modelId,"rabbito")
	birth.partner_name=Journey.CATALOG.get(job.modelId,job.modelId)
	birth.partner_texture=load("res://assets/campaign/"+content.combat[art_id].image)
	birth.frames=content.combat[art_id].animations.idle
	birth.outcome=outcome.duplicate(true)
	birth.variant=job.get("variant",false)
	birth.reduced_motion=preferences.reduced_motion
	add_child(birth)
	birth.continued.connect(func():TutorialStaging.return_after_birth(self,job.get("source","")!="inventory"),CONNECT_ONE_SHOT)

func _show_workshop_quality(outcome:Dictionary) -> void:
	var badge=load("res://scripts/campaign/hud_result_plate.gd").new()
	badge.accent=Hud.GOLD
	badge.anchor_left=1;badge.anchor_right=1
	badge.offset_left=-430;badge.offset_right=-24
	badge.offset_top=88;badge.offset_bottom=160
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	var stars:int=outcome.get("stars",1)
	var quality:String="RARA" if stars>=4 else "BOA" if stars>=3 else "COMUM"
	var broken:bool=outcome.get("type","")=="broken"
	if broken:badge.accent=Hud.Tokens.TINTA_3
	_label("ELO ROMPIDO" if broken else quality+" · ELO CRIADO",badge,26).add_theme_color_override("font_color",Hud.MUTED if broken else Hud.GOLD)
	badge.create_tween().tween_interval(2.5).finished.connect(badge.queue_free)

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
	var dialog := _dialog("Sair da bancada", "Sair da bancada? A montagem será reiniciada quando voltar. Sua rabiola continuará disponível.", "Sair da bancada", "Ficar na bancada")
	dialog.confirmed.connect(func():
		if _result(journey.cancel_workshop()):
			sound.play_event.call_deferred("workshop.abort")
			if quit_after_workshop: get_tree().quit()
			else: _show_saved()
		dialog.queue_free())
	dialog.canceled.connect(func(): quit_after_workshop = false)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(640,240))
	dialog.get_cancel_button().grab_focus()

func _process(_delta: float) -> void:
	if is_instance_valid(room) and room.can_walk and is_instance_valid(status):
		status.text = Controls.prompt("interact") + " · " + {"desk": "Montar Rabbito", "stairs": "Descer para a sala", "exit": "Sair", "professor": "Conversar com Sr. Assis", "professor-home": "Entrar no ateliê", "morro": "Entrar no Morro do Sol", "park": "Entrar no parque", "workbench": "Usar bancada"}.get(room.near, "Interagir") if not room.near.is_empty() and (room.near == room.target_hotspot or room.target_hotspot == "*") else ("Analógico · Mover" if Controls.gamepad else "Setas · Mover")
		if status.get_parent() is PanelContainer and status.get_parent().theme_type_variation == "RecortePromptPanel":
			status.text = status.text.trim_prefix(Controls.prompt("interact")+" · ")
		if room.has_meta("exploration_hud"):
			status.text=status.text.trim_prefix(Controls.prompt("interact")+" · ")
			if room.near.is_empty():status.text=""
		elif status.get_parent().has_meta("contextual"): status.get_parent().visible = not room.near.is_empty()
		elif current_step in [3, 11, 13] and room.near != room.target_hotspot:
			status.text = ("Analógico · Mover" if Controls.gamepad else "WASD / setas · Mover") + "  ·  " + {3: "Aproxime-se da mesa de desenho.", 11: "Aproxime-se da escada para descer.", 13: "Aproxime-se da porta para sair."}[current_step]

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(scene_loading):
		get_viewport().set_input_as_handled();return
	if flow_busy and event.is_action_pressed("campaign_map"):
		get_viewport().set_input_as_handled();return
	if flow_busy and last_scene_key=="workshop:birth" and Controls.cancel(event):
		get_viewport().set_input_as_handled();return
	if event.is_action_pressed("campaign_map") and last_scene_key.begins_with("world:") and get_tree().get_nodes_in_group("manga_dialogue").is_empty():
		if _remember_world_position():
			_pause_game();menu_origin="map";_show_map()
		get_viewport().set_input_as_handled();return
	if last_scene_key=="page:Configurações" and event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
		var categories:=["Vídeo","Áudio","Acessibilidade","Controles"]
		settings_tab=categories[posmod(categories.find(settings_tab)+(-1 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 1),categories.size())]
		_show_settings();get_viewport().set_input_as_handled();return
	if event.is_action_pressed("ui_cancel") and last_scene_key=="menu":
		_title();get_viewport().set_input_as_handled();return
	if event.is_action_pressed("ui_cancel") and last_scene_key=="menu:slots":
		_menu();get_viewport().set_input_as_handled();return
	if (Controls.cancel(event) or event.is_action_pressed("ui_cancel")) and last_scene_key.begins_with("page:"):
		if last_scene_key in ["page:Controles · Teclado","page:CONTROLES · TECLADO"]: _return_controls_settings()
		elif session.snapshot().is_empty(): _menu()
		else: _return_to_game()
		get_viewport().set_input_as_handled()
		return
	if Controls.cancel(event) and not session.snapshot().is_empty():
		if is_instance_valid(pause_overlay):
			_resume_game()
		elif is_instance_valid(workshop):
			_pause_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	if is_instance_valid(pause_overlay): return
	sound.play_event("ui.pause")
	sound.set_game_paused(true)
	get_tree().call_group("exploration_hud","reveal_objective")
	get_viewport().set_input_as_handled()
	pause_previous = {"battle": battle.paused if is_instance_valid(battle) else false, "park": park.paused if is_instance_valid(park) else false, "room": room.can_walk if is_instance_valid(room) else false}
	if is_instance_valid(workshop):
		pause_previous.workshop=false
		workshop._pause()
	var practice := _practice_view()
	if is_instance_valid(practice):
		pause_previous.practice = practice.paused
		practice.cinematic_paused=true
		practice.suspend_actions()
	if is_instance_valid(battle): battle.suspend_actions()
	if is_instance_valid(park): park.paused = true
	if is_instance_valid(room):
		room.can_walk = false
		if room.has_method("set_story_paused"):room.set_story_paused(true)
	pause_overlay = load("res://scripts/campaign/hud_pause.gd").new()
	pause_overlay.z_index=200
	pause_overlay.player = session.snapshot().player
	pause_overlay.focus_action=menu_origin if not menu_origin.is_empty() else "resume"
	for partner in pause_overlay.player.get("partners",[]):
		if partner.id!=pause_overlay.player.get("equippedPartnerId",""):continue
		var art_id:String={"rabbito":"rabbito","basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol","lacertubo":"lacertubo"}.get(partner.modelId,"")
		if content.combat.has(art_id):pause_overlay.partner_portrait=load("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/"+content.combat[art_id].image),art_id)
	if is_instance_valid(battle):
		pause_overlay.battle_paused=true
		# Presentation copy only: conditions are settled into the save by the combat flow.
		for partner in pause_overlay.player.get("partners",[]):
			if partner.id==pause_overlay.player.get("equippedPartnerId",""):
				partner.condition={"line":clampf(battle.model.p.hp/battle.model.p.stats.line*100,0,100),"structure":clampf(battle.model.p.hull/battle.model.p.stats.line*100,0,100)}
	add_child(pause_overlay)
	pause_overlay.chosen.connect(func(action: String):
		if action in ["team", "bag", "settings","map","save"] and not _remember_world_position(): return
		if action in ["team","bag","settings","map"]:menu_origin=action
		match action:
			"resume": _resume_game()
			"team": _show_collection()
			"bag": _show_bag()
			"settings": _show_settings()
			"map":_show_map()
			"save":
				menu_origin="save"
				sound.play_event("progress.save_ok")
				pause_overlay.buttons.save.text="Jornada salva"
			"menu": _return_to_menu()
	)

func _resume_game() -> void:
	if not is_instance_valid(pause_overlay): return
	sound.set_game_paused(false)
	sound.play_event("ui.resume")
	remove_child(pause_overlay)
	pause_overlay.queue_free()
	pause_overlay = null
	menu_origin=""
	if is_instance_valid(battle): battle.paused = pause_previous.get("battle", false)
	if is_instance_valid(park): park.paused = pause_previous.get("park", false)
	if is_instance_valid(room):
		room.can_walk = pause_previous.get("room", false)
		if room.has_method("set_story_paused"):room.set_story_paused(false)
	if is_instance_valid(workshop):
		workshop.paused=pause_previous.get("workshop",false)
		workshop.resume_button.visible=workshop.storage_blocked
	var practice := _practice_view()
	if is_instance_valid(practice):
		practice.paused = pause_previous.get("practice", false)
		practice.cinematic_paused=false

func _practice_view() -> Control:
	for child in get_children():
		if child.get_script() == FlightView: return child
	return null

func _return_to_menu() -> void:
	if is_instance_valid(workshop) and not _result(journey.save_workshop(workshop.model.run.duplicate(true))):return
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
	if what==NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(scene_loading):
		# The destination checkpoint is already committed; don't save a half-built view.
		get_tree().quit();return
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(room) and (flow_busy or opening_busy or room.has_meta("opening_room")):
		room.set_story_paused(true)
	if what==NOTIFICATION_WM_WINDOW_FOCUS_IN and is_instance_valid(room) and not is_instance_valid(pause_overlay):
		room.set_story_paused(false)
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

func _load_park() -> void:
	if DisplayServer.get_name()=="headless": _show_park(); return
	if is_instance_valid(scene_loading): return
	scene_loading=load("res://scripts/campaign/hud_scene_loading.gd").new()
	scene_loading.reduced_motion=preferences.reduced_motion
	add_child(scene_loading)
	flow_busy=true
	if is_instance_valid(park): park.paused=true
	await scene_loading.cover()
	if not is_inside_tree(): return
	_show_park()
	flow_busy=true
	if is_instance_valid(park): park.paused=true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if is_instance_valid(scene_loading):
		await scene_loading.reveal()
		scene_loading.queue_free()
	scene_loading=null
	flow_busy=false
	if is_instance_valid(park): park.paused=false

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
	if saved.checkpoint.get("space","")!=ParkCheckpoint.SPACE:
		if not _result(journey.enter_world(saved.checkpoint.scene,ParkCheckpoint.resolve(saved.checkpoint),ParkCheckpoint.SPACE)): return
		saved=session.snapshot()
	park = ParkOverworldView.new()
	park.ui_theme = theme
	park.content = content
	park.saved_checkpoint = saved.checkpoint
	park.set_meta("campaign_scene", saved.checkpoint.scene)
	park.saved_player = saved.player
	park.reduced_motion = preferences.reduced_motion
	viewport.add_child(park)
	park.action_requested.connect(_park_action)
	park.menu_requested.connect(_pause_game)
	park.exit_requested.connect(_park_exit)

func _save_park() -> bool:
	var space: String = park.get("checkpoint_space") if park.get("checkpoint_space")!=null else ""
	var result: Dictionary = journey.enter_world(park.get_meta("campaign_scene"), park.player,space)
	if result.status != "ok":
		park.paused = true
		_notice(_error(result.status))
		return false
	if is_instance_valid(park.exploration_hud):
		park.exploration_hud.refresh(session.snapshot().player)
		park.exploration_hud.push_notice("Progresso salvo","saved")
	return true

func _park_exit(event: Dictionary) -> void:
	if not _save_park(): return
	var saved: Dictionary = session.snapshot()
	var destination: Dictionary = ParkCheckpoint.exit_target(saved.checkpoint,str(int(event.id)),saved.player)
	if not _result(destination): return
	park.paused=true
	if _result(journey.enter_world(destination.scene,destination.point,destination.space)): _show_saved.call_deferred()
	else: park.paused=false

func _park_event(id: String) -> void:
	var player: Dictionary = session.snapshot().player
	for event in park.model.data.events:
		if str(int(event.id))!=id or not ParkCheckpoint.allowed(event,player,park.area_id): continue
		if park.player.distance_to(Vector2(event.u+.5,event.v+.5))>1.8: return
		var action: String = event.props.get("acao","")
		if action=="parkMap": _show_map()
		elif action=="wildGuide" and park.area_id=="jardim-das-pipas": _park_training("assis")
		elif action=="wildGuide": _notice("Sr. Assis: Pipamons podem aparecer enquanto você caminha pelo parque. No capim alto os encontros são mais frequentes. Pontes e lugares de conversa são tranquilos. Os bancos recuperam linha e estrutura; o professor também pode ajudar.")
		elif action=="wildRest":
			_confirm_park("Um respiro no parque", "Descanse no banco para recuperar a linha e a estrutura de toda a equipe. Não custa moedas e não concede experiência.", "Descansar", func():
				if _result(exploration.rest(park.player)):
					park.path.clear()
					park.refresh(session.snapshot().player)
					park.encounter_grace=6.0
					park.exploration_hud.push_notice("Equipe recuperada · linha e estrutura completas","item"))
		else: _notice(event.props.get("texto",{"parkBossGuide":"Há papel preso nos galhos e marcas seguindo para o canal. Nina disse que a rabiola foi levada para os canos. Siga a trilha; o pátio fica na parte alta.","veredasTrace":"Um pedaço da linha de Nina está preso aqui. As marcas continuam em direção aos canos, na parte alta das Veredas.","veredasPipes":"Os canos vibram em intervalos… e há uma rabiola presa logo adiante. O Lacertubo está no pátio. Há um banco atrás de você para recuperar sua equipe antes de se aproximar."}.get(action,event.name)))
		return

func _park_action(id: String) -> void:
	if id == "autosave":
		_save_park()
		return
	if not _save_park(): return
	var point: Vector2 = park.player
	var player: Dictionary = session.snapshot().player
	if id=="guardian-approach":
		var presented: Dictionary=exploration.introduce_guardian(point)
		if not _result(presented): park.paused=false; return
		park.refresh(session.snapshot().player)
		await park.focus_guardian()
		if not is_instance_valid(park): return
		var presentation:=_dialog("Kael","Os canos estão tremendo… É o Lacertubo!\n\nA rabiola da Nina ficou atrás dele. Preciso esperar a vela baixar para encontrar uma abertura.","Voltar ao Kael")
		presentation.confirmed.connect(presentation.queue_free)
		presentation.canceled.connect(presentation.queue_free)
		presentation.tree_exiting.connect(func():
			if is_instance_valid(park): park.restore_guardian_focus())
		presentation.popup_centered(Vector2i(640,300))
		return
	if park.get("checkpoint_space")==null and park.get_meta("campaign_scene") != "park-veredas" and id not in ["collection", "bag", "wild"]:
		_route_action(id)
		return
	if id.begins_with("training:"):
		_park_training(id.trim_prefix("training:"))
		return
	if id.begins_with("park-loot:"):
		var reward: Dictionary = exploration.park_loot(id.trim_prefix("park-loot:"),point)
		if reward.status=="already_applied": _notice("Você já recolheu isso."); return
		if _result(reward):
			park.refresh(session.snapshot().player)
			park.celebrate_item("Recebido · "+reward.get("reward","Item"))
		return
	if id.begins_with("park-event:"):
		_park_event(id.trim_prefix("park-event:"))
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
		elif result.status == "repair_needed": _notice("Seu parceiro precisa se recuperar. Descanse em um banco do parque ou procure o professor.")
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
				_notice("Nina: [emo=brilho]Você encontrou! Eu reconheceria esse nó em qualquer lugar. Obrigada… Agora posso trazer meu Carcará de volta.\n\nJornada: Missão concluída · A rabiola de Nina")
		elif not player.flags.get("ninaAccepted", false):
			_confirm_park("Nina", "[emo=suor]Meu Carcará tentou me proteger daquele lagarto. A linha rompeu e ele se recolheu na rabiola… O vento levou ela para os canos. Você consegue trazer a rabiola dele?", "Vou recuperar a rabiola", func():
				if _result(exploration.accept_nina(point)): park.refresh(session.snapshot().player))
		else: _notice("Nina: Siga pelo Jardim até a Clareira e procure os canos nas Veredas. Os pipeiros pelo caminho podem treinar com você. Ele arma a vela antes de puxar… Depois fica parado por um instante.")
	elif id == "tail":
		if _result(exploration.collect_tail(point)):
			park.refresh(session.snapshot().player)
			_notice("Rabiola do Carcará de Nina recebida.")
	elif id == "boss":
		if _training_needs_recovery(player):
			_notice("Seu parceiro está sem condições de lutar. Recue até o banco junto à subida dos canos para recuperar a equipe.")
			return
		if not player.flags.get("ninaAccepted", false):
			_notice("Converse com Nina no Jardim das Pipas antes de enfrentar o guardião.")
			return
		var Training=preload("res://scripts/campaign/park_training.gd")
		var current: int=Training.level(player)
		var preparation: String="A rabiola de Nina está atrás dele. Seu parceiro está no Nv. %d. Recomendado: Nv. 8. " % current
		if current<8: preparation+="Ainda será uma luta difícil: os duelos opcionais dos pipeiros dão experiência na primeira vitória. Você pode se preparar e voltar. "
		preparation+="Observe a preparação do golpe e ataque quando ele baixar a guarda. Se perder, seu parceiro continua com você; recupere-o em um banco."
		_confirm_park("Lacertubo · Guardião dos canos", preparation, "Enfrentar Lacertubo", func():
			if _result(encounters.start_boss(point)): _show_saved.call_deferred())

func _training_needs_recovery(player: Dictionary) -> bool:
	return preload("res://scripts/campaign/park_training.gd").needs_rest(player)

func _park_training(id: String) -> void:
	var Training=preload("res://scripts/campaign/park_training.gd")
	var entry: Dictionary=Training.duel(id)
	if entry.is_empty(): return
	var player: Dictionary=session.snapshot().player
	if Training.completed(player,id):
		_notice("%s: %s Já concluímos nosso duelo. Siga explorando; os bancos recuperam sua equipe." % [entry.name,entry.tip])
		return
	var introduction: String=str(entry.get("intro",""))
	var text: String=(introduction+"\n\n" if not introduction.is_empty() else "")+"%s\n\nDuelo opcional · adversário Nv. %d · +%d XP na primeira vitória. Seu parceiro está no Nv. %d. Não há rabiola como prêmio." % [entry.tip,entry.level,entry.xp,Training.level(player)]
	_confirm_park(entry.name,text,"Vamos treinar",func():
		var result: Dictionary=encounters.start_training(id,park.player)
		if _result(result) and result.status=="ok": _show_saved.call_deferred())

func _confirm_park(title: String, text: String, accept: String, callback: Callable) -> void:
	park.path.clear()
	park.paused = true
	var dialog := _dialog(title, text, accept, "Agora não")
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
	if is_instance_valid(workshop):return _result(journey.save_workshop(workshop.model.run.duplicate(true)))
	if is_instance_valid(battle): return _result(encounters.save_battle(battle.model.snapshot()))
	if is_instance_valid(park): return _save_park()
	if is_instance_valid(room): return _result(journey.enter_world(session.snapshot().checkpoint.scene, room.actor))
	return true

func _show_collection() -> void:
	sound.play_event("inventory.inspect")
	if not _remember_world_position(): return
	var player: Dictionary = session.snapshot().player
	_simple_page("EQUIPE",true)
	_label("Escolha quem vai voar ao seu lado.",page,17).add_theme_color_override("font_color",Hud.MUTED)
	if team_load_state!="ready":
		var state_view=load("res://scripts/campaign/hud_list_state.gd").new()
		state_view.state=team_load_state
		state_view.reduced_motion=preferences.reduced_motion
		page.add_child(state_view)
		state_view.retry_requested.connect(func():team_load_state="ready";_show_collection())
		_button("Voltar",page,_return_to_game)
		return
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation",16)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var team_capacity:=maxi(1,floori((size.y-250)/(190*preferences.text_scale)))
	var team_pages:=maxi(1,ceili(float(player.partners.size())/team_capacity))
	team_page=clampi(team_page,0,team_pages-1)
	for partner in player.partners.slice(team_page*team_capacity,(team_page+1)*team_capacity):
		var card=load("res://scripts/campaign/hud_result_plate.gd").new()
		var selected:bool=partner.id==player.get("equippedPartnerId", "")
		card.accent=Hud.CYAN if selected else Hud.Tokens.TINTA_3
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
		portrait.texture = load("res://scripts/campaign/battle_ink.gd").portrait(texture.atlas,art_id)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(144, 118)
		row.add_child(portrait)
		var details := VBoxContainer.new()
		details.add_theme_constant_override("separation",6)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var condition: Dictionary = partner.get("condition", {"line": 100, "structure": 100})
		var level: int = EncounterView.Model.level_for_xp(partner.get("xp", 0))
		if selected:
			_label("PARCEIRO ATIVO",details,16).theme_type_variation="RecorteAccentText"
		var partner_title:=_label("%s · Nv. %d" % [partner.get("personalName", partner.modelId), level], details,26)
		partner_title.autowrap_mode=TextServer.AUTOWRAP_OFF
		partner_title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		partner_title.tooltip_text=partner_title.text
		for stat in [["Linha",condition.line,Hud.LINE],["Armação",condition.structure,Hud.GOLD]]:
			var stat_row:=HBoxContainer.new()
			details.add_child(stat_row)
			_label("%s · %d%%"%[stat[0],stat[1]],stat_row,15).custom_minimum_size.x=140
			var bar:=ProgressBar.new()
			bar.value=clampf(stat[1],0,100)
			bar.show_percentage=false
			bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			bar.custom_minimum_size.y=8
			var fill:=StyleBoxFlat.new()
			fill.bg_color=stat[2]
			bar.add_theme_stylebox_override("fill",fill)
			stat_row.add_child(bar)
		var progress := ProgressBar.new()
		progress.theme_type_variation="RecorteXPBar"
		var xp: int = partner.get("xp", 0)
		var previous: int = EncounterView.Model.xp_for_level(level)
		var threshold: int = EncounterView.Model.xp_for_level(level+1) if level<50 else previous+1
		progress.max_value = threshold - previous
		progress.value = xp - previous if level<50 else progress.max_value
		progress.show_percentage = false
		progress.custom_minimum_size.y = 12
		details.add_child(progress)
		_label("Nível máximo" if level == 50 else "%d / %d XP para o próximo nível" % [xp - previous, threshold - previous], details, 16).theme_type_variation="RecorteMutedText"
		var id: String = partner.id
		var action_space := Hud.focus_space(row)
		action_space.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var button := _button("Selecionado" if id == player.get("equippedPartnerId", "") else "Escolher parceiro", action_space, func():
			if _result(exploration.equip(id)): _show_collection())
		button.custom_minimum_size.x = 256
		Hud.secondary_button(button)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.disabled = id == player.get("equippedPartnerId", "")
	if player.partners.is_empty():_label("Sua equipe começa com o primeiro elo. Continue sua história com o professor.",list,22)
	var footer:=HBoxContainer.new()
	page.add_child(footer)
	_button("Voltar", footer, _return_to_game).custom_minimum_size.x=180
	if team_pages>1:
		_button("Anterior",footer,func():team_page-=1;_show_collection()).disabled=team_page==0
		_button("Próxima",footer,func():team_page+=1;_show_collection()).disabled=team_page==team_pages-1
		_label("%d / %d"%[team_page+1,team_pages],footer,16)

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
	sound.play_event("inventory.bag")
	var player: Dictionary = session.snapshot().player
	_simple_page("MOCHILA",true)
	_label("%d moedas · Materiais e lembranças da sua jornada"%player.coins,page,18).add_theme_color_override("font_color",Hud.GOLD)
	var inventory_view = load("res://scripts/campaign/hud_inventory.gd").new()
	inventory_view.inventory = player.inventory
	inventory_view.reduced_motion=preferences.reduced_motion
	page.add_child(inventory_view)
	inventory_view.retry_requested.connect(func():
		var fresh:Dictionary=session.snapshot().get("player",{})
		if not fresh.get("inventory") is Dictionary:inventory_view.set_load_state("error");return
		inventory_view.inventory=fresh.inventory
		inventory_view.set_load_state("ready"))
	var footer:=HBoxContainer.new()
	page.add_child(footer)
	_button("Voltar", footer, _return_to_game).custom_minimum_size.x=180
	Hud.input_hint(footer,"guard","Aba anterior")
	Hud.input_hint(footer,"line","Próxima aba")

func _show_map() -> void:
	if not _remember_world_position(): return
	sound.play_event("ui.map")
	var subject:Node2D=park if is_instance_valid(park) else room
	var polygons:Array[PackedVector2Array]=[]
	var point:=Vector2.ZERO
	if is_instance_valid(subject):
		point=subject.get("player") if subject.get("player")!=null else subject.actor
		if subject.has_method("map_polygons"):
			for raw in subject.map_polygons():
				var projected := PackedVector2Array()
				for at in raw: projected.append(subject.project(at))
				polygons.append(projected)
			point=subject.project(point)
		elif subject.get("ground")!=null:polygons.assign(subject.ground.floors)
		else:
			for raw in subject.data.get("walkable",[]):
				var rect:=Rect2(raw[0],raw[1],raw[2],raw[3]) if raw is Array else Rect2(raw.x,raw.y,raw.w,raw.h)
				polygons.append(PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]))
	_simple_page("MAPA DA ÁREA",true)
	_label(_slot_location(session.snapshot()).name+" · Você está aqui",page,18)
	var map=load("res://scripts/campaign/hud_area_map.gd").new()
	map.polygons=polygons
	map.player=point
	page.add_child(map)
	if polygons.is_empty():_label("O mapa desta área ainda não está disponível.",page,18)
	_label("Os caminhos orientam sua exploração. Descobertas ficam por sua conta.",page,16)
	var footer:=HBoxContainer.new()
	page.add_child(footer)
	_button("Voltar",footer,_return_to_game).custom_minimum_size.x=180

func _show_tail_workshop() -> void:
	if not _remember_world_position(): return
	var player: Dictionary = session.snapshot().player
	_workshop_page("SUAS RABIOLAS")
	var found := false
	for model_id in Journey.CATALOG:
		var chosen: String = model_id
		if player.inventory.get("rabiola-" + chosen, 0) > 0:
			found = true
			_button("Montar %s · %d rabiola(s)" % [Journey.CATALOG[chosen], player.inventory["rabiola-" + chosen]], page, func():
				if flow_busy:return
				flow_busy=true
				if _result(journey.start_summon(chosen)):TutorialStaging.handoff(self,false)
				else:flow_busy=false)
		if player.inventory.get("damaged-rabiola-" + chosen, 0) > 0:
			found = true
			_button("Restaurar rabiola de " + Journey.CATALOG[chosen], page, func():
				if _result(journey.restore_inventory_tail(chosen)): _show_tail_workshop())
	if not found: _label("Traga uma rabiola encontrada no parque para construir um novo parceiro.", page)
	_button("Voltar", page, _show_saved)

func _apply_preferences() -> void:
	if sound.is_inside_tree(): sound.configure(preferences.audio_levels, preferences.dialogue_blips)
	Controls.set_family(preferences.pad_family)
	var recorte := get_node_or_null("RecorteUX")
	if recorte != null: recorte.set_reduced_motion(preferences.reduced_motion)
	if recorte!=null:recorte.set_text_scale(preferences.text_scale)
	crt_layer.visible = preferences.crt
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if preferences.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _show_settings() -> void:
	_clear("page:Configurações")
	var background=load("res://scripts/campaign/hud_title_menu.gd").new()
	background.mode="slots"
	add_child(background)
	var scroll:=ScrollContainer.new()
	scroll.anchor_left=.5;scroll.anchor_right=.5;scroll.anchor_bottom=1
	scroll.offset_left=-minf(510,size.x*.44);scroll.offset_right=minf(510,size.x*.44)
	scroll.offset_top=32;scroll.offset_bottom=-24
	scroll.follow_focus=true
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	page=VBoxContainer.new()
	page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",12)
	scroll.add_child(page)
	_label("CONFIGURAÇÕES",page,38)
	_label("Seu jeito de jogar. As alterações são salvas automaticamente.",page,17)
	var category_row:=HBoxContainer.new()
	var active_tab:Button
	category_row.add_theme_constant_override("separation",20)
	page.add_child(category_row)
	for category in ["Vídeo","Áudio","Acessibilidade","Controles"]:
		var tab:=Button.new();tab.text=category;Hud.navigation_button(tab,true)
		tab.theme_type_variation="RecorteTabButton"
		tab.toggle_mode=true;tab.button_pressed=category==settings_tab
		tab.custom_minimum_size=Vector2(200,48)
		category_row.add_child(tab)
		if category==settings_tab:active_tab=tab
		tab.pressed.connect(func():sound.play_event("ui.tab");settings_tab=category;_show_settings())
	_label(settings_tab.to_upper(),page,20).add_theme_color_override("font_color",Hud.CYAN)
	if settings_tab == "Áudio": _audio_settings()
	for item in [["Filtro de TV (CRT)", "crt", "Linhas suaves de uma TV de tubo sobre o jogo."], ["Tela cheia", "fullscreen", "Use toda a tela para explorar e batalhar."], ["Reduzir animações da interface", "reduced_motion", "Suaviza transições e mantém os avisos estáticos."]]:
		if settings_tab == "Áudio": continue
		if (settings_tab=="Vídeo" and item[1]=="reduced_motion") or (settings_tab=="Acessibilidade" and item[1]!="reduced_motion") or settings_tab=="Controles":continue
		var toggle := CheckButton.new()
		toggle.tooltip_text=item[0]+" — "+item[2]
		toggle.text="Ligado" if preferences.get(item[1]) else "Desligado"
		toggle.custom_minimum_size.x=170
		toggle.custom_minimum_size.y=56
		toggle.add_theme_font_size_override("font_size",20)
		var toggle_row := HBoxContainer.new()
		toggle_row.add_theme_constant_override("separation",24)
		var setting_card=load("res://scripts/campaign/hud_result_plate.gd").new()
		page.add_child(setting_card)
		setting_card.add_child(toggle_row)
		var copy:=VBoxContainer.new()
		copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		copy.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		toggle_row.add_child(copy)
		_label(item[0],copy,20)
		_label(item[2],copy,15).add_theme_color_override("font_color",Hud.MUTED)
		toggle_row.add_child(toggle)
		var key: String = item[1]
		toggle.button_pressed = preferences.get(key)
		toggle.toggled.connect(func(enabled: bool):
			var old: bool = preferences.get(key)
			preferences.set(key, enabled)
			if preferences.save_settings() != OK:
				preferences.set(key, old)
				_notice("Não foi possível guardar a configuração.")
			toggle.text = "Ligado" if preferences.get(key) else "Desligado"
			toggle.set_pressed_no_signal(preferences.get(key))
			_apply_preferences())
	var text_row:=HBoxContainer.new()
	text_row.visible=settings_tab=="Acessibilidade"
	page.add_child(text_row)
	_label("Tamanho do texto",text_row,20).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var text_size:=OptionButton.new()
	Hud.navigation_button(text_size,true)
	text_size.custom_minimum_size=Vector2(260,48)
	for caption in ["Padrão · 100%","Ampliado · 115%","Grande · 130%"]:text_size.add_item(caption)
	text_size.select([1.0,1.15,1.3].find(preferences.text_scale))
	text_row.add_child(text_size)
	text_size.item_selected.connect(func(index:int):
		var old:float=preferences.text_scale
		preferences.text_scale=[1.0,1.15,1.3][index]
		if preferences.save_settings()!=OK:preferences.text_scale=old;text_size.select([1.0,1.15,1.3].find(old))
		_apply_preferences())
	var controls_card=load("res://scripts/campaign/hud_result_plate.gd").new()
	controls_card.visible=settings_tab=="Controles"
	page.add_child(controls_card)
	var controls_content:=VBoxContainer.new()
	controls_content.add_theme_constant_override("separation",10)
	controls_card.add_child(controls_content)
	var family_row := HBoxContainer.new()
	controls_content.add_child(family_row)
	var family_copy:=VBoxContainer.new()
	family_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	family_row.add_child(family_copy)
	_label("Símbolos do controle",family_copy,20)
	_label("Escolha os botões exibidos nas instruções.",family_copy,15).add_theme_color_override("font_color",Hud.MUTED)
	var family_choice := OptionButton.new()
	Hud.navigation_button(family_choice,true)
	family_choice.custom_minimum_size=Vector2(260,56)
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
	var keyboard_row:=HBoxContainer.new()
	controls_content.add_child(keyboard_row)
	_label("Personalize as teclas de movimento e de batalha.",keyboard_row,15).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var keyboard_button:=_button("Controles · Teclado",keyboard_row,_show_controls)
	keyboard_button.custom_minimum_size.x=260
	Hud.secondary_button(keyboard_button)
	var footer:=HBoxContainer.new()
	footer.add_theme_constant_override("separation",20)
	page.add_child(footer)
	_button("Voltar", footer, _menu if session.snapshot().is_empty() else _return_to_game).custom_minimum_size.x=180
	Hud.input_hint(footer,"accept","Alterar")
	Hud.input_hint(footer,"back","Voltar")
	_label("LB / RB · Trocar seção",footer,16).autowrap_mode=TextServer.AUTOWRAP_OFF
	_focus_first.call_deferred(page)
	Hud.focus_later(active_tab)
	if settings_focus_controls:
		settings_focus_controls=false
		Hud.focus_later(keyboard_button)

func _audio_settings() -> void:
	for item in [["master", "Volume geral"], ["music", "Música"], ["sfx", "Efeitos do jogo"], ["ui", "Menus e diálogos"], ["ambience", "Ambientes"]]:
		var key: String = item[0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		page.add_child(row)
		_label(item[1], row, 20).custom_minimum_size.x = 240
		var slider := HSlider.new()
		slider.min_value = 0; slider.max_value = 100; slider.step = 5
		slider.value = float(preferences.audio_levels[key]) * 100
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(160, 48)
		slider.tooltip_text = item[1]
		row.add_child(slider)
		var value_label := _label("%d%%" % slider.value, row, 18)
		value_label.custom_minimum_size.x = 70
		slider.value_changed.connect(func(value: float):
			preferences.audio_levels[key] = value / 100.0
			value_label.text = "%d%%" % value
			_apply_preferences())
		slider.value_changed.connect(func(_value: float): sound.play_event("ui.slider"))
		# Persist on commit, not every drag tick. Keyboard/joypad edits are committed below.
		slider.drag_ended.connect(func(_changed: bool): _save_audio_settings())
		slider.focus_exited.connect(_save_audio_settings)
	var blips := CheckButton.new()
	blips.text = "Sinal breve ao exibir cada fala"
	blips.button_pressed = preferences.dialogue_blips
	blips.custom_minimum_size.y = 48
	page.add_child(blips)
	blips.toggled.connect(func(enabled: bool):
		preferences.dialogue_blips = enabled
		_apply_preferences()
		_save_audio_settings())
	_button("Ouvir efeito de exemplo", page, func(): sound.play_event("battle.block"))
	_label("Volume zero silencia a categoria. As vozes da abertura seguem o volume geral.", page, 16)

func _save_audio_settings() -> void:
	if preferences.save_settings() != OK: sound.play_event("ui.deny")

func _return_controls_settings() -> void:
	settings_tab="Controles"
	settings_focus_controls=true
	_show_settings()

func _show_controls() -> void:
	binding_rows.clear()
	_simple_page("CONTROLES · TECLADO",true)
	_label("Selecione uma ação e pressione a nova tecla.",page,17).add_theme_color_override("font_color",Hud.MUTED)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var columns:=HBoxContainer.new()
	columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",28)
	scroll.add_child(columns)
	for group in [["EXPLORAÇÃO",["left","right","up","down","interact","map"]],["BATALHA",["cut","skill","dodge","line","guard","signature"]]]:
		var card=load("res://scripts/campaign/hud_result_plate.gd").new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		columns.add_child(card)
		var list:=VBoxContainer.new()
		list.add_theme_constant_override("separation",8)
		card.add_child(list)
		_label(group[0],list,18).add_theme_color_override("font_color",Hud.CYAN)
		for action in group[1]:
			var id:String=action
			var binding_button:=_button("%s   ·   %s"%[Controls.LABELS[id],OS.get_keycode_string(int(preferences.bindings[id]))],list,func():_capture_binding(id))
			binding_button.custom_minimum_size.y=46
			binding_button.set_meta("binding_action",id)
			Hud.secondary_button(binding_button)
			binding_button.icon=Controls.glyph(id,true)
			binding_button.expand_icon=true
			binding_button.add_theme_constant_override("icon_max_width",32)
			var feedback:=_label("",list,15)
			feedback.visible=false
			feedback.add_theme_color_override("font_color",Hud.GOLD)
			binding_rows[id]={"button":binding_button,"feedback":feedback}
	_label("Setas e Enter continuam disponíveis para navegar. Esc cancela a troca de tecla. A bancada usa mouse e teclado.",page,16).add_theme_color_override("font_color",Hud.MUTED)
	var footer:=HBoxContainer.new()
	footer.add_theme_constant_override("separation",24)
	page.add_child(footer)
	_button("Voltar",footer,_return_controls_settings).custom_minimum_size.x=180
	var restore:=_button("Restaurar padrão", footer, _confirm_restore_controls)
	restore.custom_minimum_size.x=320
	Hud.secondary_button(restore)
	if binding_rows.has(controls_focus_action):Hud.focus_later(binding_rows[controls_focus_action].button)

func _confirm_restore_controls() -> void:
	var dialog:=_confirmation("Restaurar teclas", "Substituir suas teclas personalizadas pelo padrão?\n\nSua jornada e os símbolos do controle serão mantidos.","Restaurar teclas")
	dialog.confirmed.connect(func():
		var old:Dictionary=preferences.bindings.duplicate()
		preferences.bindings=Controls.DEFAULTS.duplicate()
		if preferences.save_settings()!=OK:
			preferences.bindings=old
			_notice("Não foi possível salvar os controles.")
		else:
			Controls.install(preferences.bindings)
			_show_controls())
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

func _capture_binding(action: String) -> void:
	if not binding_target.is_empty():_cancel_binding()
	binding_target = action
	controls_focus_action=action
	if binding_rows.has(action):
		binding_rows[action].feedback.text="Pressione a nova tecla. Esc cancela."
		binding_rows[action].feedback.show()

func _cancel_binding() -> void:
	if binding_rows.has(binding_target) and is_instance_valid(binding_rows[binding_target].feedback):binding_rows[binding_target].feedback.hide()
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
		if binding_rows.has(binding_target):binding_rows[binding_target].feedback.text="Tecla reservada à navegação. Escolha outra." if conflict=="reserved" else "Já usada para %s. Escolha outra."%Controls.LABELS[conflict]
		return
	var next: Dictionary = preferences.bindings.duplicate()
	next[binding_target] = event.physical_keycode
	var old: Dictionary = preferences.bindings
	preferences.bindings = next
	if preferences.save_settings() != OK:
		preferences.bindings = old
		if binding_rows.has(binding_target):binding_rows[binding_target].feedback.text="Não foi possível salvar. Tente novamente."
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
		text += "\n\nDica de voo: " + story.tactic
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
	text += "\n\nRecompensas: +%d XP" % result.partnerXp
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
