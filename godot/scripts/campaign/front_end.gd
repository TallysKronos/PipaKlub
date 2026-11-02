extends Control
const Session = preload("res://scripts/campaign/session.gd")
const Opening = preload("res://scripts/campaign/opening.gd")
const Room = preload("res://scripts/campaign/room_view.gd")
const Journey = preload("res://scripts/campaign/journey.gd")
const FlightView = preload("res://scripts/campaign/first_flight_view.gd")
const WorkshopView = preload("res://scripts/campaign/workshop_view.gd")
const ShopData=preload("res://scripts/campaign/shop_data.gd")
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
const DemoFlow = preload("res://scripts/campaign/demo_flow.gd")
const PipeiroIdentity = preload("res://scripts/campaign/pipeiro_identity.gd")
const DistrictBadges = preload("res://scripts/campaign/district_badges.gd")
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
	var name:String={"quintal":"Vila do Primeiro Vento","professor-home":"Ateliê do Sr. Assis","park-trail":"Jardim dos Ventos","park-clearing":"Clareira do Papel","park-veredas":"Veredas do Encanamento","kronasta-bosque-a":"Bosque · Trilha das Copas","kronasta-bosque-b":"Bosque · Desvio do Riacho","kronasta-bosque-c":"Bosque · Clareira do Marco"}.get(scene,"Prólogo" if point.get("kind")=="opening" else "Ateliê do Sr. Assis")
	if scene=="kite-shop":name="Linha & Papel"
	# Region maps carry their own "<Região> · <parte>" name.
	if ParkCheckpoint.is_kronasta(scene) and not ParkCheckpoint.is_bosque(scene):name=str(ParkCheckpoint.data(scene).get("name",name))
	var texture:Texture2D=load("res://assets/campaign/rooftop-arena-wide-v2.png")
	if point.get("kind")=="opening":
		var room_key:String="home" if int(point.get("step",0))>=12 else "bedroom"
		name="Casa do Kael" if room_key=="home" else "Quarto do Kael"
		texture=load("res://assets/campaign/"+content.rooms[room_key].floorImage)
	elif point.get("kind") in ["starter","workshop"]:
		texture=load("res://assets/campaign/workshop-background.png")
	elif point.get("kind")=="practice":
		name="Treino com o Sr. Assis"
	elif ParkCheckpoint.is_regional_preview(scene):
		name=ParkCheckpoint.data(scene).get("name","Kronasta")
		texture=load("res://assets/campaign/maps/kronasta-atlas-v1.png")
	elif scene=="kite-shop":
		texture=ImageTexture.create_from_image(Image.load_from_file("res://assets/campaign/loja-tcg-v1/preview.png"))
	elif scene.begins_with("morro"):
		var data:Dictionary=Morro.maps().get(scene,{})
		name=data.get("name","Morro do Sol")
		if not data.get("images",[]).is_empty():texture=load("res://assets/campaign/morro/"+data.images[0].image)
	elif scene=="professor-home":
		texture=ImageTexture.create_from_image(Image.load_from_file("res://assets/campaign/professor-moderno-v1/preview.png"))
	elif scene=="quintal":
		texture=load("res://assets/campaign/"+content.rooms.street.floorImage)
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
				var art_id:String={"rabbito":"rabbito","basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol","doberman-c":"doberman-c","lacertubo":"lacertubo"}.get(partner.modelId,"")
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
		"feira_no_coins":"O apito custa 20 moedas. Os desafios do bairro ajudam a conseguir moedas.",
		"not_enough_coins":"Você precisa de 12 moedas para descansar aqui. O ateliê do professor continua gratuito.",
		"stale": "A jornada foi alterada. Volte ao menu e carregue novamente.",
		"repair_needed": "Seu parceiro precisa de reparos. Use um Kit de Remendo em Equipe → Cuidar ou procure o professor.",
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
	if not _result(PipeiroIdentity.ensure_legacy(session)): return
	if PipeiroIdentity.pending(session.snapshot()):
		TutorialStaging.resume_documents(self)
		return
	if not _result(DistrictBadges.ensure_legacy(session)):return
	if DistrictBadges.pending(session.snapshot()):
		_resume_first_insignia()
		return
	if preload("res://scripts/campaign/league_promotion.gd").pending(session.snapshot()):
		_show_world();_present_green_promotion.call_deferred();return
	if DemoFlow.pending(session.snapshot()):
		_show_demo_complete()
		return
	match str(session.snapshot().checkpoint.kind):
		"opening": _show_opening()
		"world": _show_world()
		"practice": _show_practice()
		"starter": _show_starter()
		"workshop": _show_workshop()
		"encounter": _show_encounter()

func _show_identity() -> void:
	if not PipeiroIdentity.issued(session.snapshot().get("player",{})):
		_notice("Sua carteira será entregue pelo Sr. Assis ao concluir o treino.")
		return
	_clear("page:CARTEIRA DE PIPEIRO")
	var card = load("res://scripts/campaign/hud_pipeiro_identity.gd").new()
	card.saved = session.snapshot()
	card.backdrop_texture = _slot_location(card.saved).texture
	card.reduced_motion = preferences.reduced_motion
	add_child(card)
	card.closed.connect(_close_identity)

func _resume_first_insignia() -> void:
	_show_world()
	while is_instance_valid(scene_loading) or flow_busy:
		await get_tree().process_frame
	if last_scene_key.begins_with("world:") and DistrictBadges.pending(session.snapshot()):
		_present_first_insignia(false)

func _present_first_insignia(from_mikka:bool) -> void:
	var generation:=opening_generation
	if is_instance_valid(park):
		park.paused=true
		var pending_path:Variant=park.get("path")
		if pending_path!=null:pending_path.clear();park.set("path",pending_path)
	if is_instance_valid(room):room.can_walk=false
	if from_mikka:
		var text:="Mikka: Você conquistou o Morro do Sol! Esta insígnia é sua. É o primeiro bairro de uma longa jornada.\n\nMikka: A rabiola que você ganhou também é o começo de um novo laço. Passe no ateliê do professor para montar seu próximo parceiro."
		var dialog:=_dialog("Mikka",text,"Receber a insígnia")
		dialog.allow_cancel=false
		var accepted:=[false]
		dialog.confirmed.connect(func():accepted[0]=true)
		dialog.popup_centered()
		while TutorialStaging.valid(self,generation) and is_instance_valid(dialog) and not accepted[0]:await get_tree().process_frame
		if is_instance_valid(dialog):dialog.queue_free()
		if not TutorialStaging.valid(self,generation):return
	if not await _present_key_item(DistrictBadges.FIRST_ITEM,DistrictBadges.FIRST_NAME):return
	_complete_first_insignia()

func _complete_first_insignia() -> void:
	var result:Dictionary=DistrictBadges.acknowledge(session)
	if result.status not in ["ok","already_applied"]:
		var retry:=_dialog("Salvar conquista",_error(result.status),"Tentar novamente","Voltar ao menu")
		retry.confirmed.connect(_complete_first_insignia.call_deferred);retry.confirmed.connect(retry.queue_free)
		retry.canceled.connect(_menu.call_deferred);retry.canceled.connect(retry.queue_free);retry.popup_centered()
		return
	var dialog:=_dialog("Primeiro bairro conquistado","Sua primeira insígnia está guardada no primeiro espaço do porta-emblemas.\n\nVocê pode consultá-la em Pausa → Porta-emblemas. A jornada continua: explore Kronasta e cuide dos seus parceiros.","Ver porta-emblemas","Continuar explorando")
	dialog.confirmed.connect(func():
		if is_instance_valid(park):park.paused=false
		if is_instance_valid(room):room.can_walk=true
		_open_emblem_case(0))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(func():
		if is_instance_valid(park):park.paused=false
		if is_instance_valid(room):room.can_walk=true)
	dialog.canceled.connect(dialog.queue_free);dialog.popup_centered()

func _open_emblem_case(index: int = 0) -> void:
	for child in get_children():
		if child.has_meta("emblem_case"): return
	if not PipeiroIdentity.issued(session.snapshot().get("player",{})): return
	var previous_focus:Control=get_viewport().gui_get_focus_owner()
	var previous:WeakRef=weakref(previous_focus) if is_instance_valid(previous_focus) else null
	var park_paused:bool=is_instance_valid(park) and park.paused
	var was_walking:bool=is_instance_valid(room) and room.can_walk
	if is_instance_valid(park):park.paused=true
	if is_instance_valid(room):room.can_walk=false
	var focus_modes: Array = []
	for control in find_children("*","Control",true,false):
		if control.focus_mode!=Control.FOCUS_NONE:
			focus_modes.append({"control":control,"mode":control.focus_mode})
			control.focus_mode=Control.FOCUS_NONE
	if is_instance_valid(pause_overlay): pause_overlay.hide()
	var view = load("res://scripts/campaign/hud_emblem_case.gd").new()
	view.player = session.snapshot().player
	view.initial_slot = index
	add_child(view)
	view.closed.connect(func():
		remove_child(view)
		view.queue_free()
		for entry in focus_modes:
			if is_instance_valid(entry.control):entry.control.focus_mode=entry.mode
		if is_instance_valid(pause_overlay): pause_overlay.show()
		if is_instance_valid(park):park.paused=park_paused
		if is_instance_valid(room):room.can_walk=was_walking
		if previous!=null:
			var focus:Control=previous.get_ref()
			if is_instance_valid(focus): Hud.focus_later(focus))

func _present_key_item(id: String, item_name: String) -> bool:
	var generation := opening_generation
	var was_walking: bool = is_instance_valid(room) and room.can_walk
	var park_paused: bool = is_instance_valid(park) and park.paused
	var battle_paused: bool = is_instance_valid(battle) and battle.paused
	if is_instance_valid(room): room.can_walk=false
	if is_instance_valid(park): park.paused=true
	if is_instance_valid(battle): battle.suspend_actions(); battle.paused=true
	var banner = load("res://scripts/campaign/hud_key_item_banner.gd").new()
	banner.item_name = item_name
	banner.item_texture = Hud.item_art(id)
	banner.reduced_motion = preferences.reduced_motion
	add_child(banner)
	while TutorialStaging.valid(self,generation) and is_instance_valid(banner) and not banner.done:
		await get_tree().process_frame
	if is_instance_valid(banner): banner.queue_free()
	var valid := TutorialStaging.valid(self,generation)
	if valid:
		if is_instance_valid(room): room.can_walk=was_walking
		if is_instance_valid(park): park.paused=park_paused
		if is_instance_valid(battle): battle.paused=battle_paused
	return valid

func _close_identity() -> void:
	if not _result(PipeiroIdentity.acknowledge(session)): return
	_return_to_game()

func _complete_document_delivery() -> void:
	var result: Dictionary = PipeiroIdentity.acknowledge(session)
	if result.status in ["ok","already_applied"]:
		_show_saved()
		return
	var dialog := _dialog("Salvar jornada",_error(result.status),"Tentar novamente","Voltar ao menu")
	dialog.confirmed.connect(_complete_document_delivery.call_deferred)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(_menu.call_deferred)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _show_demo_complete() -> void:
	if not DemoFlow.completed(session.snapshot()): return
	menu_origin = ""
	sound.set_game_paused(false)
	_clear("page:DEMO CONCLUÍDA")
	var ending = load("res://scripts/campaign/hud_demo_complete.gd").new()
	ending.partner_portrait = load("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/" + content.combat.rabbito.image), "rabbito")
	add_child(ending)
	ending.chosen.connect(_finish_demo)

func _finish_demo(action: String) -> void:
	if action not in ["explore", "map", "menu"]: return
	if not _result(DemoFlow.acknowledge(session)): return
	menu_origin = ""
	sound.set_game_paused(false)
	match action:
		"explore": _show_saved()
		"map": _show_kronasta()
		"menu": _menu()

func _nina_homecoming() -> void:
	park.path.clear()
	park.paused = true
	var dialog := _dialog("Nina", "Nina: [emo=brilho]Você encontrou! Eu reconheceria esse nó em qualquer lugar. Obrigada… Agora posso trazer meu Carcará de volta.\n\nKael: Cuida bem dele, Nina.", "Concluir este capítulo")
	dialog.confirmed.connect(func():
		if preload("res://scripts/campaign/league_promotion.gd").pending(session.snapshot()):_present_green_promotion.call_deferred()
		else:_show_demo_complete.call_deferred())
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(640, 300))

func _return_to_game() -> void:
	var point:Dictionary=session.snapshot().get("checkpoint",{})
	# Returning to the lobby is not a map transition. Reuse the loaded park assets
	# synchronously, so a loading cover cannot clear the newly restored lobby.
	if point.get("kind","")=="world" and ParkCheckpoint.MAPS.has(point.get("scene","")):_show_park()
	else:_show_saved()
	while is_instance_valid(scene_loading):await get_tree().process_frame
	if not is_inside_tree():return
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
	if ParkCheckpoint.MAPS.has(session.snapshot().checkpoint.scene):
		_load_park()
		return
	_clear()
	_stage_container()
	var point: Dictionary = session.snapshot().checkpoint
	var professor: bool = point.scene == "professor-home"
	var shop:bool=point.scene=="kite-shop"
	var home:bool=point.scene=="kael-home"
	var data: Dictionary = ShopData.room() if shop else (content.rooms.home if home else content.rooms.professor if professor else content.rooms.street).duplicate(true)
	if not professor and not shop and not home and not data.hotspots.any(func(h: Dictionary): return h.id == "morro"):
		data.hotspots.append({"id": "morro", "name": "Morro do Sol", "x": 2592, "y": 1040})
	if professor and preload("res://scripts/campaign/expedition_photo.gd").available(session.snapshot().player):
		for spot:Dictionary in data.hotspots:
			if spot.id=="study":spot.name="Arquivo de expedições"
	if professor:data=preload("res://scripts/campaign/retalho_care.gd").room_data(data,session.snapshot().player)
	room = Room.new()
	stage.add_child(room)
	room.configure(data, point.position, true, "*", professor or home, true)
	if professor:preload("res://scripts/campaign/retalho_care.gd").build(room,session.snapshot().player)
	_equip_room_companion()
	room.interacted.connect(_world_interact)
	var overlay=load("res://scripts/campaign/hud_exploration.gd").new()
	overlay.subject=room
	overlay.area_name="Casa do Kael" if home else "Linha & Papel" if shop else "Ateliê do Sr. Assis" if professor else "Bairro dos Ventos"
	overlay.player_data=session.snapshot().player
	add_child(overlay)
	if home:
		overlay.objective.text="Converse com Heleana." if preload("res://scripts/campaign/heleana_confession.gd").available(session.snapshot().player) else "Sua casa · converse com sua mãe ou saia pela porta."
		if preload("res://scripts/campaign/heleana_confession.gd").available(session.snapshot().player):
			var night:=CanvasModulate.new();night.color=Color("9aabc7");room.add_child(night)
	if professor and preload("res://scripts/campaign/retalho_care.gd").available(session.snapshot().player):overlay.objective.text=preload("res://scripts/campaign/retalho_care.gd").objective(session.snapshot().player)
	if professor and preload("res://scripts/campaign/blue_exam_preparation.gd").eligible(session.snapshot().player) and not preload("res://scripts/campaign/blue_exam_preparation.gd").prepared(session.snapshot().player):overlay.objective.text=preload("res://scripts/campaign/blue_exam_preparation.gd").data().pending
	overlay.map=Hud.map_for(room,overlay)
	status=overlay.prompt
	room.set_meta("exploration_hud",overlay)
	if home and preload("res://scripts/campaign/heleana_confession.gd").refused(session.snapshot().player) and not session.snapshot().player.flags.get("heleanaReconheceuRetalho",false):
		_show_heleana_confession.call_deferred()
	overlay.chosen.connect(func(id:String):
		if id=="collection":_show_collection()
		elif id=="bag":_show_bag()
		else:_pause_game())
	if professor and room.actor.distance_to(Vector2(1056,1232))<4:
		TutorialStaging.enter_atelier.call_deferred(self)

func _equip_room_companion()->void:
	for partner in session.snapshot().player.partners:
		if partner.id != session.snapshot().player.get("equippedPartnerId", ""): continue
		var id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "doberman-c": "doberman-c", "retalho-original":"retalho-original", "lacertubo": "lacertubo"}.get(partner.modelId, "rabbito")
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
	if DisplayServer.get_name()=="headless":await get_tree().process_frame
	else:await RenderingServer.frame_post_draw
	if not is_instance_valid(park) or not is_instance_valid(scene_loading):
		if is_instance_valid(scene_loading):scene_loading.queue_free()
		scene_loading=null
		return
	await scene_loading.reveal()
	scene_loading.queue_free()
	scene_loading=null
	if is_instance_valid(park):park.paused=false
	var reunion=preload("res://scripts/campaign/heleana_confession.gd")
	if reunion.outside(saved.player) and not saved.player.flags.get("heleanaReconheceuRetalho",false):
		park.build_heleana_reunion()
		_show_heleana_confession.call_deferred()

func _neighborhood_action(id: String) -> void:
	if flow_busy:return
	if not _save_park(true):return
	if id.begins_with("mount-quest:"):
		_mount_quest_talk(id.trim_prefix("mount-quest:"));return
	match id:
		"heleana-confession":_show_heleana_confession()
		"autosave":return
		"collection":_show_collection()
		"bag":_show_bag()
		"menu":_pause_game()
		"map":_pause_game();menu_origin="map";_show_map()
		"professor-home":
			var entry: Array=content.rooms.professor.layout.blocking.kaelEntry
			if _result(journey.enter_world("professor-home",Vector2(entry[0],entry[1]))):_show_saved.call_deferred()
		"kite-shop":
			if _result(journey.enter_world("kite-shop",ShopData.ENTRY)):_show_saved.call_deferred()
		"kael-home":
			if _result(session.checkpoint({"kind":"world","scene":"kael-home","position":[432,1008]},session.snapshot().player)):_show_saved.call_deferred()
		"morro":
			if session.snapshot().player.get("journey",{}).get("phase")=="complete" and _result(journey.enter_world("morro",Vector2(528,752))):_show_saved.call_deferred()
		"park":
			if session.snapshot().player.get("journey",{}).get("phase")=="complete" and _result(journey.enter_world("park-trail",Vector2(208,816))):_show_saved.call_deferred()

func _mount_quest_talk(npc:String) -> void:
	var quest=preload("res://scripts/campaign/mount_quest.gd")
	var player:Dictionary=session.snapshot().player
	if not quest.available(player):
		_notice("Zeca: Termine seu treino com o professor. Depois, passe na pracinha: tenho um companheiro para você conhecer.");return
	var step:=quest.stage(player)
	if step==3:
		if npc=="zeca":
			quest.new(session).talk(npc)
			park.saved_player=session.snapshot().player
		_notice("Zeca: O apito chama seu companheiro. Vá com calma nas curvas e deixe as passagens estreitas para atravessar a pé." if npc=="zeca" else "Lia: O fecho ficou firme! Agora é cuidar da guia e do seu companheiro.");return
	if npc=="zeca" and step==1:
		_notice("Zeca: A Lia está na rua alta, ao lado da Linha & Papel. Diga que é o fecho da guia; ela já sabe a medida.");return
	if npc=="lia" and step!=1:
		_notice("Lia: Leve o fecho de volta ao Zeca, na pracinha." if step==2 else "Lia: O Zeca está na pracinha. Ele anda precisando de uma mão com uma guia.");return
	var text:String="Estou cuidando de uma montaria de papel. Ela é veloz, mas a guia ficou com o fecho solto. Não vou deixar ninguém montar assim. A Lia tem a peça certa. Pode buscar para mim?" if step==0 else "O Zeca mandou você? Separei um fecho de linha encerada: segura bem sem machucar a armação. Aqui está. Leve para ele conferir o ajuste." if npc=="lia" else "É o fecho certo! Agora a guia está segura. Você cuidou do que ela precisava antes de pensar em correr. Fique com este Apito de Elo: ele chama seu novo companheiro de estrada. O Dóber de papel vai entrar no seu grupo e também poderá batalhar."
	flow_busy=true;park.paused=true;park.avatar.moving=false;park.avatar.running=false
	var dialog:=_dialog("Zeca" if npc=="zeca" else "Lia",text,"Vou buscar" if step==0 else "Receber o fecho" if npc=="lia" else "Receber o apito","Agora não" if step==0 else "")
	dialog.confirmed.connect(func():_complete_mount_quest(npc,dialog))
	dialog.canceled.connect(func():dialog.queue_free();_finish_mount_conversation())
	dialog.popup_centered()

func _finish_mount_conversation() -> void:
	flow_busy=false
	if is_instance_valid(park):park.paused=false

func _complete_mount_quest(npc:String,dialog:Control) -> void:
	var quest=preload("res://scripts/campaign/mount_quest.gd")
	var result:Dictionary=quest.new(session).talk(npc)
	dialog.queue_free()
	if result.status not in ["ok","already_applied"]:
		_finish_mount_conversation();_result(result);return
	if is_instance_valid(park):
		park.saved_player=session.snapshot().player
		park.exploration_hud.refresh(park.saved_player)
		park._update_hint()
	var player:Dictionary=session.snapshot().player
	if quest.owned(player):
		await _present_key_item(quest.ITEM,"Apito de Elo")
		_finish_mount_conversation()
		_notice("Dóber de papel entrou no grupo. Para montar, ele precisa estar no grupo, com ao menos 1 HP e sem estar derrotado. Apito guardado na mochila. Use B ou o direcional para cima para montar e desmontar nas áreas abertas. Segure Shift ou ative Correr para a montaria correr. Também pode chamar pela mochila → Apito de Elo.")
	else:
		_finish_mount_conversation()
		if is_instance_valid(park):park.exploration_hud.push_notice(quest.objective(player),"item")

func _use_mount_item() -> void:
	var saved:Dictionary=session.snapshot()
	if not preload("res://scripts/campaign/mount_quest.gd").eligible(saved.player):
		_notice("Para montar, mantenha uma montaria no grupo com pelo menos 1 HP e sem estar derrotada.");return
	if not _remember_world_position():return
	menu_origin="";sound.set_game_paused(false);_show_saved()
	while is_instance_valid(scene_loading):await get_tree().process_frame
	if not is_inside_tree():return
	if is_instance_valid(park) and park.has_method("toggle_mount"):park.toggle_mount()

func _world_interact(id: String) -> void:
	if session.snapshot().checkpoint.get("scene")=="kael-home":
		if id=="mother":_show_heleana_confession();return
		if id=="exit":
			if _result(journey.enter_world("quintal",preload("res://scripts/campaign/neighborhood_checkpoint.gd").HOME)):_show_saved.call_deferred()
			return
		if id=="seat" or id=="upstairs":_notice("Kael: Vou ficar um pouco aqui embaixo.");return
	if flow_busy:return
	if id=="retalho-care":
		_show_retalho_care();return
	var point: Dictionary = session.snapshot().checkpoint
	if point.scene=="kite-shop":
		_shop_interact(id);return
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
		var preparation=preload("res://scripts/campaign/blue_exam_preparation.gd")
		if preparation.eligible(session.snapshot().player) and not preparation.prepared(session.snapshot().player):_show_blue_preparation()
		else:TutorialStaging.meet_professor(self)
	elif id=="study" and point.scene=="professor-home" and preload("res://scripts/campaign/expedition_photo.gd").available(session.snapshot().player):
		_show_expedition_photo()
	elif id == "workbench":
		TutorialStaging.open_workbench(self)
	else:
		_notice("Estudos sobre pipas, almas e o vento.")

func _shop_interact(id:String)->void:
	if id=="exit":
		var previous:Array=session.snapshot().player.get("cityPosition",[ShopData.CITY_ENTRY.x,ShopData.CITY_ENTRY.y])
		if _result(journey.enter_world("quintal",Vector2(previous[0],previous[1]))):_show_saved.call_deferred()
		return
	var title:="Dono da loja" if id=="counter" else "Linha & Papel"
	var text:String={"counter":"Bem-vindo à Linha & Papel! Pode olhar os mostruários com calma. As mesas são o ponto de encontro de quem gosta de montar, colecionar e conversar sobre Soulmonsters.","showcase":"Mostruários de papéis, linhas e kits de montagem. Cada cor ajuda a dar personalidade a uma pipa.","gondola":"Kits, pastas e acessórios organizados para os colecionadores.","table-a":"Mesas da comunidade, com espaço para abrir pastas, mostrar coleções e conhecer outros jogadores.","table-b":"Um segundo espaço de convivência para os jogadores do bairro."}.get(id,"Fique à vontade para explorar a loja.")
	room.can_walk=false
	if id=="counter":room.face_actor(ShopData.OWNER)
	var dialog:=_dialog(title,text,"Continuar")
	dialog.name="ShopConversation"
	if id=="counter":
		var owner_art:Sprite2D=room.get_node("ShopOwner/Art")
		dialog._portraits[title]=owner_art.texture
		dialog.portrait.material=owner_art.material
	dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		if is_instance_valid(room):room.can_walk=true)
	dialog.popup_centered()

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
	var art_id:String={"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol","doberman-c":"doberman-c","lacertubo":"lacertubo"}.get(job.modelId,"rabbito")
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
		status.text = Controls.prompt("interact") + " · " + {"desk": "Montar Rabbito", "stairs": "Descer para a sala", "exit": "Sair", "professor": "Conversar com Sr. Assis", "professor-home": "Entrar no ateliê", "morro": "Entrar no Morro do Sol", "park": "Entrar no parque", "workbench": "Usar bancada", "retalho-care":"Cuidar de Retalho"}.get(room.near, "Interagir") if not room.near.is_empty() and (room.near == room.target_hotspot or room.target_hotspot == "*") else ("Analógico · Mover" if Controls.gamepad else "Setas · Mover")
		if status.get_parent() is PanelContainer and status.get_parent().theme_type_variation == "RecortePromptPanel":
			status.text = status.text.trim_prefix(Controls.prompt("interact")+" · ")
		if room.has_meta("exploration_hud"):
			status.text=status.text.trim_prefix(Controls.prompt("interact")+" · ")
			if room.near.is_empty():status.text=""
		elif status.get_parent().has_meta("contextual"): status.get_parent().visible = not room.near.is_empty()
		elif current_step in [3, 11, 13] and room.near != room.target_hotspot:
			status.text = ("Analógico · Mover" if Controls.gamepad else "WASD / setas · Mover") + "  ·  " + {3: "Aproxime-se da mesa de desenho.", 11: "Aproxime-se da escada para descer.", 13: "Aproxime-se da porta para sair."}[current_step]

func _unhandled_input(event: InputEvent) -> void:
	var mount_key:bool=event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_B
	var mount_pad:bool=event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_DPAD_UP
	if (mount_key or mount_pad) and not flow_busy and not is_instance_valid(scene_loading) and last_scene_key.begins_with("world:") and is_instance_valid(park) and park.has_method("toggle_mount") and not park.paused and get_tree().get_nodes_in_group("manga_dialogue").is_empty():
		park.toggle_mount();get_viewport().set_input_as_handled();return
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
		if last_scene_key=="page:CARTEIRA DE PIPEIRO": _close_identity()
		elif last_scene_key=="page:DEMO CONCLUÍDA": _finish_demo("explore")
		elif last_scene_key=="page:CUIDAR DO PARCEIRO":_leave_partner_care()
		elif last_scene_key in ["page:Controles · Teclado","page:CONTROLES · TECLADO"]: _return_controls_settings()
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
	pause_overlay.focus_action=menu_origin if not menu_origin.is_empty() else "team"
	for partner in pause_overlay.player.get("partners",[]):
		if partner.id!=pause_overlay.player.get("equippedPartnerId",""):continue
		var art_id:String={"rabbito":"rabbito","basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol","doberman-c":"doberman-c","lacertubo":"lacertubo"}.get(partner.modelId,"")
		if content.combat.has(art_id):pause_overlay.partner_portrait=load("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/"+content.combat[art_id].image),art_id)
	if is_instance_valid(battle):
		pause_overlay.battle_paused=true
		# Presentation copy only: conditions are settled into the save by the combat flow.
		for partner in pause_overlay.player.get("partners",[]):
			if partner.id==pause_overlay.player.get("equippedPartnerId",""):
				partner.condition={"line":clampf(battle.model.p.hp/battle.model.p.stats.line*100,0,100),"structure":clampf(battle.model.p.hull/battle.model.p.stats.line*100,0,100)}
	add_child(pause_overlay)
	pause_overlay.chosen.connect(func(action: String):
		if action in ["team", "bag", "settings","map","save","identity","emblems","missions","workshop"] and not _remember_world_position(): return
		if action in ["team","bag","settings","map","identity","emblems","missions","workshop"]:menu_origin=action
		match action:
			"resume": _resume_game()
			"team": _show_collection()
			"bag": _show_bag()
			"identity": _show_identity()
			"emblems": _open_emblem_case()
			"missions": _show_missions()
			"workshop": _show_lobby_workshop()
			"settings": _show_settings()
			"map":_show_map()
			"save":
				menu_origin="save"
				sound.play_event("progress.save_ok")
				pause_overlay.buttons.save.text="Jornada salva"
				pause_overlay.description.text="Jornada salva. Pode continuar sua aventura."
				pause_overlay.buttons.save.queue_redraw()
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
	if DisplayServer.get_name()=="headless":await get_tree().process_frame
	else:await RenderingServer.frame_post_draw
	if is_instance_valid(scene_loading):
		await scene_loading.reveal()
		scene_loading.queue_free()
	scene_loading=null
	flow_busy=false
	if is_instance_valid(park): park.paused=false

func _show_park() -> void:
	if session.snapshot().player.has("marisolRowTrip"):
		if not _result(load("res://scripts/campaign/marisol_row_trip.gd").new(session).recover()):return
	if session.snapshot().player.has("ninaGlideFlight"):
		if not _result(load("res://scripts/campaign/nina_glide.gd").new(session).recover()):return
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
	var resolved: Vector2=ParkCheckpoint.resolve(saved.checkpoint)
	if saved.checkpoint.get("space","")!=ParkCheckpoint.SPACE or not resolved.is_equal_approx(Vector2(saved.checkpoint.position[0],saved.checkpoint.position[1])):
		if not _result(journey.enter_world(saved.checkpoint.scene,resolved,ParkCheckpoint.SPACE)): return
		saved=session.snapshot()
	if ParkCheckpoint.is_kronasta(saved.checkpoint.scene):
		var discovery: Dictionary=load("res://scripts/campaign/bosque_campaign.gd").new(session).arrive()
		if discovery.status not in ["ok","already_applied"]:
			_result(discovery)
			return
		saved=session.snapshot()
	park = load("res://scripts/campaign/park_row_view.gd").new() if saved.checkpoint.scene=="kronasta-pantano-a" else load("res://scripts/campaign/park_glide_view.gd").new() if saved.checkpoint.scene in ["park-veredas","kronasta-beira-canal-b"] else ParkOverworldView.new()
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

func _save_park(quiet:bool=false) -> bool:
	var space: String = park.get("checkpoint_space") if park.get("checkpoint_space")!=null else ""
	var at:Vector2=park.checkpoint_point() if park.has_method("checkpoint_point") else park.player
	var result: Dictionary = journey.enter_world(park.get_meta("campaign_scene"), at,space)
	if result.status != "ok":
		park.paused = true
		_notice(_error(result.status))
		return false
	if is_instance_valid(park.exploration_hud):
		park.exploration_hud.refresh(session.snapshot().player)
		if not quiet:park.exploration_hud.push_notice("Progresso salvo","saved")
	return true

func _park_exit(event: Dictionary) -> void:
	if not _save_park(): return
	var saved: Dictionary = session.snapshot()
	if ParkCheckpoint.is_kronasta(saved.checkpoint.scene) and event.props.get("destino","")=="kronasta":
		_show_kronasta()
		return
	var destination: Dictionary = ParkCheckpoint.exit_target(saved.checkpoint,str(int(event.id)),saved.player)
	if destination.status=="story_gate":_notice("A passagem para a Clareira abre depois de conquistar o Bambuzal. Vença o Lohan e volte por aqui.");return
	if not _result(destination): return
	park.paused=true
	if _result(journey.enter_world(destination.scene,destination.point,destination.space)): _show_saved.call_deferred()
	else: park.paused=false

func _park_event(id: String) -> void:
	var player: Dictionary = session.snapshot().player
	for event in park.interaction_events:
		if str(int(event.id))!=id or not ParkCheckpoint.allowed(event,player,park.area_id): continue
		if park.player.distance_to(Vector2(event.u+.5,event.v+.5))>1.8: return
		var action: String = event.props.get("acao","")
		if action=="blueExam":
			_blue_station(str(event.props.blueAction));return
		if action in ["mormacoSignals","mormacoStory","mormacoRest"]:
			_request_mormaco(action);return
		if action=="retalhoTrust":
			_show_retalho_trust();return
		if action=="retalhoTrustRest":
			_confirm_park("Descanso das docas","Recuperar linha e armação da equipe? Este ponto de apoio é gratuito.","Descansar",func():
				if _result(load("res://scripts/campaign/retalho_trust.gd").new(session).rest(park.player)):park.refresh(session.snapshot().player))
			return
		if action in ["warehouseGollia","warehouseStory"]:
			_request_warehouse(action=="warehouseGollia");return
		if action=="warehouseRest":
			_confirm_park("Banco de manutenção","Recuperar a linha e a armação da equipe?","Descansar",func():
				if _result(load("res://scripts/campaign/warehouse_story.gd").new(session).rest(park.player)):park.refresh(session.snapshot().player))
			return
		if action=="retalhoStory":
			_confirm_park("Retalho","Quem tem dono é fraco.\n\nRetalho estica as orelhas de papel e desafia Rabbito. Adversário Nv.22. Você pode recuar ou tentar novamente após uma derrota.","Aceitar desafio",func():
				if _result(load("res://scripts/campaign/retalho_story.gd").new(session).begin(park.player)):_show_saved.call_deferred())
			return
		if action=="muralStory":
			_show_mural_story();return
		if action=="muralRest":
			_confirm_park("Pausa na galeria","Descansar e recuperar linha e armação de toda a equipe?","Descansar",func():
				if _result(load("res://scripts/campaign/mural_story.gd").new(session).rest(park.player)):park.refresh(session.snapshot().player))
			return
		if action=="feiraStory":
			_request_feira_story(str(event.props.feiraAction));return
		if action=="districtRest" and event.props.get("district")=="cais":
			_confirm_park("Descansar nas docas","Recuperar toda a equipe por 12 moedas? Se todos estiverem bem, nada será cobrado.","Descansar",func():
				if _result(load("res://scripts/campaign/district_campaign.gd").new(session).rest(park.player)):park.refresh(session.snapshot().player))
			return
		if action=="districtRest" and event.props.get("district")=="feira":
			_confirm_park("Descansar no mercado","Recuperar toda a equipe por 12 moedas? Se todos estiverem bem, nada será cobrado.","Descansar",func():
				if _result(load("res://scripts/campaign/feira_story.gd").new(session).rest(park.player)):park.refresh(session.snapshot().player))
			return
		if action=="canalClue":
			_notice(event.props.texto);return
		if action=="districtRest" and event.props.get("district")=="beira-canal":
			_confirm_park("Descansar na oficina","Recuperar toda a equipe por 12 moedas? Se todos estiverem bem, nada será cobrado.","Descansar",func():
				if _result(load("res://scripts/campaign/canal_gate.gd").new(session).rest(park.player)):park.refresh(session.snapshot().player))
			return
		if action=="canalGate":
			_request_canal_gate();return
		if action=="marisolRow":
			_request_marisol_row(str(event.props.rowLink));return
		if action=="ninaGlide":
			_request_nina_glide(str(event.props.glideLink));return
		if action in ["tylerClareira","tylerRai"]:
			_show_tyler_clareira();return
		if action=="districtDuel":
			_district_action(str(event.props.duel))
			return
		if action=="bambuzalClue":
			var found:Dictionary=load("res://scripts/campaign/district_campaign.gd").new(session).inspect_clue(id,park.player)
			if found.status in ["ok","already_applied"]:_notice("Os cortes ainda estão claros. Há feixes escondidos para vender ao Bando do Cerol. Alguém está levando o bambu durante a noite.")
			else:_result(found)
			return
		if ParkCheckpoint.is_kronasta(park.saved_checkpoint.scene) and event.type=="npc" and action!="wildRest":
			_notice(event.name+": "+str(event.props.get("texto","")))
			return
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
	if id.begins_with("row-land:"):
		var result:Dictionary=load("res://scripts/campaign/marisol_row_trip.gd").new(session).finish(id.trim_prefix("row-land:"),park.row_motion)
		if _result(result):park.finish_row();park.refresh(session.snapshot().player)
		return
	if id=="blue-exam-checkpoint":
		var result:Dictionary=load("res://scripts/campaign/blue_exam.gd").new(session).escort_checkpoint(park.blue_guide.course,park.player)
		if _result(result):
			park.blue_guide.course.accept();park.blue_guide.running=not park.blue_guide.course.complete;park.refresh(session.snapshot().player)
		else:
			park.blue_guide.course=load("res://scripts/campaign/blue_escort_model.gd").new(int(load("res://scripts/campaign/blue_exam.gd").record(session.snapshot().player).escort))
			park.exploration_hud.objective.text="Não foi possível gravar o marco. O Carcará voltou ao último marco salvo; inicie a condução ali."
		return
	if id.begins_with("glide-land:"):
		var result:Dictionary=load("res://scripts/campaign/nina_glide.gd").new(session).finish(id.trim_prefix("glide-land:"))
		if _result(result):park.finish_glide();park.refresh(session.snapshot().player)
		return
	if id == "autosave":
		_save_park()
		return
	if not _save_park(): return
	var point: Vector2 = park.player
	var player: Dictionary = session.snapshot().player
	if id=="guardian-approach":
		if park.guardian_focus:return
		var movie_available:bool=not preferences.reduced_motion and FileAccess.file_exists("res://assets/campaign/cinematics/lacertubo-patio-h3-v1.ogv")
		var presentation=load("res://scripts/campaign/lacertubo_movie.gd" if movie_available else "res://scripts/campaign/lacertubo_cinematic.gd").new()
		presentation.park=park
		presentation.reduced_motion=preferences.reduced_motion
		presentation.cue.connect(func(event_id:String):sound.play_event(event_id))
		var cinema_layer:=CanvasLayer.new()
		cinema_layer.layer=30
		add_child(cinema_layer)
		cinema_layer.add_child(presentation)
		await presentation.finished
		cinema_layer.queue_free()
		if not is_instance_valid(park):return
		var presented:Dictionary=exploration.introduce_guardian(point)
		if _result(presented):park.refresh(session.snapshot().player)
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
		elif result.status == "repair_needed": _notice("Seu parceiro precisa se recuperar. Use um Kit de Remendo em Equipe → Cuidar, descanse em um banco ou procure o professor.")
	elif id.begins_with("chest:"):
		var chest_id := id.trim_prefix("chest:")
		var result: Dictionary = exploration.chest(chest_id, point)
		if result.status == "guardian": _notice("O guardião protege esse baú.")
		elif _result(result):
			park.refresh(session.snapshot().player)
			_notice("Baú encontrado · " + {"lookout": "Rabiola de Azulão", "woodland": "25 moedas", "canal": "Rabiola de Mata verde", "ridge": "Rabiola de Raio de sol", "courtyard": "60 moedas"}[chest_id])
	elif id == "nina":
		if not preload("res://scripts/campaign/kronasta_story.gd").mikka_defeated(player) and not player.flags.get("ninaAccepted",false):
			_notice("Nina: A Mikka está esperando os novos pipeiros no Morro do Sol. Depois passa aqui para conversar comigo.");return
		if player.flags.get("ninaReturned",false) and preload("res://scripts/campaign/league_promotion.gd").eligible(player) and not preload("res://scripts/campaign/league_promotion.gd").promoted(player):
			if _result(preload("res://scripts/campaign/league_promotion.gd").claim(session,point)):_present_green_promotion()
			return
		if player.flags.get("ninaReturned", false): _notice("Nina: O Carcará está comigo de novo. Ainda quero te mostrar a pipa que eu estava construindo!")
		elif player.flags.get("ninaTail", false):
			if _result(exploration.return_tail(point)):
				park.refresh(session.snapshot().player)
				_nina_homecoming()
		elif not player.flags.get("ninaAccepted", false):
			_confirm_park("Nina", "[emo=suor]Cortaram a linha do meu Carcará com cerol… Ele se recolheu na rabiola e o vento levou ela. Achei pegadas palmadas seguindo para os canos. Você pode procurar por ele?", "Vou recuperar a rabiola", func():
				if _result(exploration.accept_nina(point)): park.refresh(session.snapshot().player))
		elif player.flags.get("ninaBambuzalOrder",false) and not preload("res://scripts/campaign/kronasta_story.gd").park_access(player,"park-clearing"):_notice("Nina: A passagem para a Clareira abre depois do campeonato do Bambuzal. Vá pelo Bosque e fale com o Lohan. Eu espero você aqui.")
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
	var text: String=(introduction+"\n\n" if not introduction.is_empty() else "")+"%s\n\nDuelo opcional · adversário Nv. %d · +%d XP para o parceiro (igual ao selvagem), %d moedas e +%d XP extra de tamer. Seu parceiro está no Nv. %d. Não há rabiola como prêmio." % [entry.tip,entry.level,entry.xp,entry.coins,entry.tamerXp,Training.level(player)]
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
	var is_district:bool=session.snapshot().player.encounter.get("kind","")=="district"
	var is_morro: bool = session.snapshot().player.encounter.get("kind", "") == "morro"
	battle = MorroBattleView.new() if is_morro or is_district else EncounterView.new()
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
		if is_district:
			if _result(load("res://scripts/campaign/district_campaign.gd").new(session).settle()):_return_district_result.call_deferred()
		elif is_morro:
			if _result(morro.settle()): _return_morro_result.call_deferred()
		elif session.snapshot().player.encounter.kind=="mormaco-story":
			if _result(load("res://scripts/campaign/mormaco_story.gd").new(session).settle()):_return_mormaco.call_deferred()
		elif session.snapshot().player.encounter.kind=="retalho-rescue":
			if _result(load("res://scripts/campaign/retalho_trust.gd").new(session).settle()):_show_saved.call_deferred()
		elif session.snapshot().player.encounter.kind=="warehouse-story":
			if _result(load("res://scripts/campaign/warehouse_story.gd").new(session).settle()):_return_warehouse.call_deferred()
		elif session.snapshot().player.encounter.kind=="retalho-story":
			if _result(load("res://scripts/campaign/retalho_story.gd").new(session).settle()):_return_retalho.call_deferred()
		elif session.snapshot().player.encounter.kind=="feira-story":
			if _result(load("res://scripts/campaign/feira_story.gd").new(session).settle()):_return_feira_story.call_deferred()
		elif session.snapshot().player.encounter.kind=="canal-gate":
			if _result(load("res://scripts/campaign/canal_gate.gd").new(session).settle()):_show_saved.call_deferred()
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
	var team_capacity:=maxi(1,floori((size.y-300)/(260*preferences.text_scale)))
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
		var art_id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "doberman-c": "doberman-c", "retalho-original":"retalho-original", "lacertubo": "lacertubo"}.get(partner.modelId, "rabbito")
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
		if preload("res://scripts/campaign/mount_quest.gd").capable(partner):
			var mount_icon:=TextureRect.new()
			mount_icon.name="MountCapability"
			mount_icon.texture=load("res://assets/ui/mount-capability.svg")
			mount_icon.custom_minimum_size=Vector2(30,30)
			mount_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			mount_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mount_icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			mount_icon.tooltip_text="Pode ser montado · requer 1 HP e armação intacta" if preload("res://scripts/campaign/mount_quest.gd").healthy(partner) else "Montaria derrotada · repare Linha e Armação antes de montar"
			if not preload("res://scripts/campaign/mount_quest.gd").healthy(partner):mount_icon.modulate=Color(.45,.45,.45)
			row.add_child(mount_icon)
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
		var care_id:String=partner.id
		_button("Cuidar",details,func():_show_partner_care(care_id)).disabled=session.snapshot().checkpoint.get("kind","")!="world"
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
	footer.add_theme_constant_override("separation",32) # the focused button shifts right and grows its rabiola (see Hud.focus_space)
	page.add_child(footer)
	_button("Voltar", footer, _return_to_game).custom_minimum_size.x=180
	if team_pages>1:
		_button("Anterior",footer,func():team_page-=1;_show_collection()).disabled=team_page==0
		_button("Próxima",footer,func():team_page+=1;_show_collection()).disabled=team_page==team_pages-1
		var page_number:=_label("%d / %d"%[team_page+1,team_pages],footer,16)
		page_number.autowrap_mode=TextServer.AUTOWRAP_OFF
		page_number.custom_minimum_size.x=90
		page_number.size_flags_vertical=Control.SIZE_SHRINK_CENTER

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

func _show_partner_care(partner_id:String="") -> void:
	if flow_busy or is_instance_valid(scene_loading):return
	if not _remember_world_position():return
	var care=load("res://scripts/campaign/partner_care.gd").new(session)
	var saved:Dictionary=session.snapshot()
	if not care.available(saved):_notice("Os cuidados ficam disponíveis durante a exploração.");return
	var chosen:Dictionary={}
	var wanted:String=partner_id if not partner_id.is_empty() else str(saved.player.get("equippedPartnerId",""))
	for entry in saved.player.partners:
		if entry.id==wanted:chosen=entry;break
	if chosen.is_empty():chosen=saved.player.partners[0]
	# Leave the menu first: camping belongs to the real map and its camera.
	if ParkCheckpoint.MAPS.has(saved.checkpoint.get("scene","")):_show_park()
	else:_show_world()
	while is_instance_valid(scene_loading):await get_tree().process_frame
	if not is_inside_tree():return
	var subject:Node2D=park if is_instance_valid(park) else room
	if not is_instance_valid(subject) or not is_instance_valid(subject.get("avatar")):
		_notice("Não foi possível preparar o acampamento aqui. Tente novamente.");return
	flow_busy=true
	if is_instance_valid(park):
		park.paused=true
		# The city uses the dock controller, which has no point-path property.
		var pending_path:Variant=park.get("path")
		if pending_path!=null:
			pending_path.clear();park.set("path",pending_path)
	if is_instance_valid(room):room.can_walk=false
	var camp=load("res://scripts/campaign/care_camp_transition.gd").new()
	camp.avatar=subject.avatar;camp.companion=subject.get("companion");camp.reduced_motion=preferences.reduced_motion
	if camp.companion==null:camp.companion=subject.get("partner")
	add_child(camp)
	var generation:int=opening_generation
	await camp.play()
	if not TutorialStaging.valid(self,generation):return
	remove_child(camp)
	_open_partner_care(chosen)
	add_child(camp)
	flow_busy=true
	await camp.reveal()
	if is_instance_valid(camp):camp.queue_free()
	flow_busy=false

func _open_partner_care(chosen:Dictionary) -> void:
	var care=load("res://scripts/campaign/partner_care.gd").new(session)
	var saved:Dictionary=session.snapshot()
	_clear("page:CUIDAR DO PARCEIRO")
	page=VBoxContainer.new()
	add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view=load("res://scripts/campaign/partner_care_view.gd").new()
	view.partner=chosen.duplicate(true)
	view.kits=int(saved.player.inventory.get(care.ITEM,0))
	view.coins=int(saved.player.coins)
	view.welcome=not saved.player.flags.get("careWelcomeKit",false)
	view.reduced_motion=preferences.reduced_motion
	page.add_child(view)
	var operation:String="partner-care-"+preload("res://scripts/campaign/state.gd").new_id()
	var id:String=chosen.id
	view.supplies_requested.connect(func():
		var result:Dictionary=care.supplies()
		if result.status=="ok":
			var player:Dictionary=session.snapshot().player
			view.refresh_stock(int(player.inventory.get(care.ITEM,0)),int(player.coins),false)
			view.stage.grab_focus()
		else:view.message.text="Moedas insuficientes para outro kit." if result.status=="not_enough_coins" else "Não foi possível guardar o kit. Tente novamente.")
	view.completed.connect(func(steps:Array):
		var result:Dictionary=care.finish(id,operation,steps)
		var ok:bool=result.status in ["ok","already_applied"]
		view.finish_result(ok,"Não foi possível salvar o reparo. Seu kit foi preservado; tente novamente.")
		if ok:
			view.refresh_stock(int(session.snapshot().player.inventory.get(care.ITEM,0)),int(session.snapshot().player.coins),false)
			view.supply.disabled=true
			view.pet.grab_focus())
	view.back_requested.connect(_leave_partner_care)

func _leave_partner_care() -> void:
	if flow_busy:return
	menu_origin=""
	_show_saved()

func _show_bag() -> void:
	if not _remember_world_position(): return
	sound.play_event("inventory.bag")
	var player: Dictionary = session.snapshot().player
	_simple_page("MOCHILA",true)
	_label("%d moedas · Materiais e lembranças da sua jornada"%player.coins,page,18).add_theme_color_override("font_color",Hud.GOLD)
	var inventory_view = load("res://scripts/campaign/hud_inventory.gd").new()
	inventory_view.care_available=session.snapshot().checkpoint.get("kind","")=="world"
	inventory_view.mount_available=session.snapshot().checkpoint.get("kind","")=="world" and session.snapshot().checkpoint.get("scene","") not in ["professor-home","kite-shop","kael-home"]
	inventory_view.care_requested.connect(func():_show_partner_care())
	inventory_view.mount_requested.connect(_use_mount_item)
	inventory_view.inventory = player.inventory
	inventory_view.reduced_motion=preferences.reduced_motion
	page.add_child(inventory_view)
	inventory_view.retry_requested.connect(func():
		var fresh:Dictionary=session.snapshot().get("player",{})
		if not fresh.get("inventory") is Dictionary:inventory_view.set_load_state("error");return
		inventory_view.inventory=fresh.inventory
		inventory_view.set_load_state("ready"))
	var footer:=HBoxContainer.new()
	footer.add_theme_constant_override("separation",32) # the focused button shifts right and grows its rabiola (see Hud.focus_space)
	page.add_child(footer)
	_button("Voltar", footer, _return_to_game).custom_minimum_size.x=180
	var care_button:=_button("Cuidar do parceiro",footer,func():_show_partner_care())
	care_button.disabled=player.partners.is_empty() or session.snapshot().checkpoint.get("kind","")!="world"
	Hud.input_hint(footer,"guard","Aba anterior")
	Hud.input_hint(footer,"line","Próxima aba")

func _show_map() -> void:
	if load("res://scripts/campaign/bosque_campaign.gd").available(session.snapshot().get("player",{})):
		_show_kronasta()
	else:_show_local_map()

func _show_local_map() -> void:
	if not _remember_world_position(): return
	sound.play_event("ui.map")
	var subject:Node2D=park if is_instance_valid(park) else room
	var polygons:Array[PackedVector2Array]=[]
	var regions:Array[Dictionary]=[]
	var landmarks:Array[Dictionary]=[]
	var point:=Vector2.ZERO
	if is_instance_valid(subject):
		point=subject.get("player") if subject.get("player")!=null else subject.actor
		if subject.has_method("map_polygons"):
			for raw in subject.map_polygons():
				var projected := PackedVector2Array()
				for at in raw: projected.append(subject.project(at))
				polygons.append(projected)
			point=subject.project(point)
			if subject.has_method("map_regions"):
				for region in subject.map_regions():
					var outline:=PackedVector2Array()
					for at in region.polygon:outline.append(subject.project(at))
					regions.append({"polygon":outline,"color":region.color})
			if subject.has_method("map_landmarks"):
				for marker in subject.map_landmarks():
					landmarks.append({"point":subject.project(marker.point),"text":marker.text})
		elif subject.get("ground")!=null:polygons.assign(subject.ground.floors)
		else:
			for raw in subject.data.get("walkable",[]):
				var rect:=Rect2(raw[0],raw[1],raw[2],raw[3]) if raw is Array else Rect2(raw.x,raw.y,raw.w,raw.h)
				polygons.append(PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]))
	_simple_page("MAPA DA ÁREA",true)
	_label(_slot_location(session.snapshot()).name+" · Você está aqui",page,18)
	var map=load("res://scripts/campaign/hud_area_map.gd").new()
	map.polygons=polygons
	map.regions=regions
	map.landmarks=landmarks
	map.player=point
	page.add_child(map)
	if polygons.is_empty():_label("O mapa desta área ainda não está disponível.",page,18)
	_label("Os caminhos orientam sua exploração. Descobertas ficam por sua conta.",page,16)
	var footer:=HBoxContainer.new()
	footer.add_theme_constant_override("separation",32) # the focused button shifts right and grows its rabiola (see Hud.focus_space)
	page.add_child(footer)
	_button("Voltar",footer,_return_to_game).custom_minimum_size.x=180
	if load("res://scripts/campaign/bosque_campaign.gd").available(session.snapshot().player):
		_button("Região de Kronasta",footer,_show_kronasta)

func _show_kronasta() -> void:
	if not _remember_world_position(): return
	var saved: Dictionary=session.snapshot()
	var region=load("res://scripts/campaign/bosque_campaign.gd")
	if not region.available(saved.player): return
	_clear("page:REGIÃO DE KRONASTA")
	var atlas=load("res://scripts/campaign/hud_kronasta_map.gd").new()
	atlas.current_scene=saved.checkpoint.get("scene","")
	atlas.saved_player=saved.player.duplicate(true)
	add_child(atlas)
	atlas.travel_requested.connect(_travel_kronasta)
	atlas.local_requested.connect(_show_local_map)
	atlas.closed.connect(func():
		menu_origin=""
		sound.set_game_paused(false)
		_show_saved())

func _travel_kronasta(destination: String) -> void:
	if not _result(load("res://scripts/campaign/bosque_campaign.gd").new(session).travel(destination)): return
	menu_origin=""
	sound.set_game_paused(false)
	_show_saved()

func _show_missions() -> void:
	var player:Dictionary=session.snapshot().player
	_simple_page("MISSÕES",true)
	_label("Objetivos da sua jornada",page,24).add_theme_color_override("font_color",Hud.CYAN)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",16);scroll.add_child(list)
	var trained:bool=int(player.get("journey",{}).get("lesson",0))>=5
	var entries:Array=[["Os primeiros elos","Conclua o treinamento com o Sr. Assis.",trained]]
	var mount_quest=preload("res://scripts/campaign/mount_quest.gd")
	if mount_quest.available(player):entries.append([mount_quest.TITLE,mount_quest.objective(player),mount_quest.owned(player)])
	if trained:
		entries.append(["Seu primeiro parceiro","Monte seu primeiro Pipamon na oficina.",not player.get("partners",[]).is_empty()])
		var victories:int=player.get("morro",{}).get("stars",{}).size()
		entries.append(["Desafios do Morro do Sol","%d / 5 desafios concluídos. Converse com os pipeiros para avançar."%victories,player.get("districtEmblems",{}).has("bairro-01")])
	if player.get("flags",{}).get("ninaAccepted",false):
		var instruction:="Explore as Veredas e recupere a rabiola de Nina."
		if player.flags.get("guardianDefeated",false):instruction="Recolha a rabiola nas Veredas e leve-a de volta à Nina."
		if player.flags.get("ninaTail",false):instruction="Volte e entregue a rabiola à Nina."
		entries.append(["O pedido de Nina",instruction,bool(player.flags.get("ninaReturned",false))])
	for entry in entries:
		var plate=load("res://scripts/campaign/hud_result_plate.gd").new();list.add_child(plate)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);plate.add_child(column)
		_label(("CONCLUÍDA · " if entry[2] else "EM ANDAMENTO · ")+entry[0],column,25).add_theme_color_override("font_color",Hud.GOLD if entry[2] else Hud.CYAN)
		_label(entry[1],column,21)
	_button("Voltar ao lobby",page,_return_to_game).custom_minimum_size.y=48

func _show_lobby_workshop() -> void:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.get("scene","")=="professor-home":
		_show_tail_workshop()
		return
	_simple_page("OFICINA",true)
	_label("Novos parceiros começam com uma rabiola.",page,26).add_theme_color_override("font_color",Hud.GOLD)
	_label("A montagem e a restauração acontecem no ateliê do Sr. Assis. Aqui você pode consultar o que já encontrou.",page,22)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",12);scroll.add_child(list)
	var found:=false
	for id in Journey.CATALOG:
		var intact:=int(saved.player.inventory.get("rabiola-"+id,0))
		var damaged:=int(saved.player.inventory.get("damaged-rabiola-"+id,0))
		if intact+damaged==0:continue
		found=true
		_label("%s · %d pronta(s) para montar · %d para restaurar"%[Journey.CATALOG[id],intact,damaged],list,23)
	if not found:_label("Você ainda não encontrou rabiolas. Explore o mundo e converse com seus moradores.",list,22)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",32);page.add_child(footer)
	_button("Voltar ao lobby",footer,_return_to_game)

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
	_button("Voltar", page, func():
		if menu_origin=="workshop":_return_to_game()
		else:_show_saved())

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
	category_row.add_theme_constant_override("separation",32) # the focused button shifts right and grows its rabiola (see Hud.focus_space)
	var active_tab:Button
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
	keyboard_row.add_theme_constant_override("separation",32) # the focused button shifts right and grows its rabiola (see Hud.focus_space)
	controls_content.add_child(keyboard_row)
	_label("Personalize as teclas de movimento e de batalha.",keyboard_row,15).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var keyboard_button:=_button("Controles · Teclado",keyboard_row,_show_controls)
	keyboard_button.custom_minimum_size.x=260
	Hud.secondary_button(keyboard_button)
	var footer:=HBoxContainer.new()
	footer.add_theme_constant_override("separation",32) # the focused button shifts right and grows its rabiola (see Hud.focus_space)
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
	footer.add_theme_constant_override("separation",32) # the focused button shifts right and grows its rabiola (see Hud.focus_space)
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
		var names := " e ".join(Morro.Rules.stage(data.stage).foes.map(func(f): return f.name))
		var districts=preload("res://scripts/campaign/district_rules.gd")
		var player:Dictionary=session.snapshot().player
		var title:Dictionary=districts.entry(player,"morro")
		if not title.pendingDefense.is_empty():
			if title.pendingDefense.scene==session.snapshot().checkpoint.scene:_show_title_defense()
			else:_notice(districts.objective(player,"morro"))
			return
		if title.champion=="player" and data.stage!="morro-5":
			if _result(morro.offer_defense(park.player)):_show_title_defense()
			return
		var planned:Dictionary=districts.prepare(player,"morro",data.stage)
		if planned.status=="already_applied":
			_notice("Você já venceu %s aqui. Este desafio está concluído; o caminho segue aberto." % names)
			return
		if planned.status!="ok":
			_notice(districts.objective(player,"morro") if title.completed else "Vença os desafios anteriores antes de enfrentar este pipeiro.")
			return
		var story: Dictionary = Morro.Rules.content().stories[data.stage]
		var text := "\n\n".join(story.before.map(func(line): return "%s: %s" % [line[0], line[1]]))
		if planned.context.mode in ["requalify","reclaim"]:
			text="Este duelo faz parte da reconquista do título. A primeira recompensa e a insígnia não serão concedidas novamente."
			if data.stage=="morro-5":names=districts.opponent_name(player,"morro")
		text += "\n\nDica de voo: " + story.tactic
		_confirm_park(names, text, "Vamos voar!", func():
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

func _show_title_defense() -> void:
	var player:Dictionary=session.snapshot().player
	var districts=preload("res://scripts/campaign/district_rules.gd")
	var opponent:String=districts.opponent_name(player,"morro")
	var text:="%s desafia você pelo título do Morro do Sol.\n\nSe perder ou desistir da luta, ele fica com o título e você precisa vencer os quatro desafios novamente para recuperá-lo. Sua insígnia e os caminhos já abertos continuam seus.\n\nVocê pode responder depois: o desafio permanece salvo."%opponent
	_confirm_park("Defesa de título · "+opponent,text,"Defender meu título",func():
		if _result(morro.start_defense(park.player)):_show_saved.call_deferred())
	if is_instance_valid(park.goal):park.goal.text=districts.objective(player,"morro")

func _return_morro_result() -> void:
	if not _result(DistrictBadges.ensure_legacy(session)):return
	if DistrictBadges.pending(session.snapshot()):
		_show_world()
		_present_first_insignia.call_deferred(bool(session.snapshot().player.lastMorro.get("insignia",false)))
		return
	_show_saved()
	var result: Dictionary = session.snapshot().player.lastMorro
	var lines: Array = Morro.Rules.content().stories[result.stage].won if result.outcome == "won" else Morro.Rules.content().stories[result.stage].lost
	# The shared illustrated battle result is the sole reward presentation.
	# Returning to the map preserves the NPC's voice without repeating a receipt.
	var text:="Você pode conversar com o pipeiro para tentar novamente quando quiser." if result.outcome=="fled" else "\n\n".join(lines.map(func(line): return "%s: %s" % [line[0], line[1]]))
	var title:=" e ".join(Morro.Rules.stage(result.stage).foes.map(func(foe):return foe.name))
	if result.get("districtMode","progress")!="progress":
		title="Disputa pelo título"
		text=preload("res://scripts/campaign/district_rules.gd").objective(session.snapshot().player,"morro")
	if is_instance_valid(park):park.paused=true
	var dialog:=_dialog(title,text,"Continuar explorando")
	dialog.set_meta("morro_epilogue",true)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		if is_instance_valid(park):park.paused=false)
	dialog.popup_centered()

func _partner_portrait(model_id: String) -> Texture2D:
	var id: String = {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "doberman-c": "doberman-c", "retalho-original":"retalho-original", "lacertubo": "lacertubo"}.get(model_id, "rabbito")
	var art: Dictionary = content.combat[id]
	var frame: Dictionary = art.animations.idle[0]
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/campaign/" + art.image)
	texture.region = Rect2(frame.x, frame.y, frame.w, frame.h)
	return texture

func _district_action(id:String,skip_row:bool=false)->void:
	if id=="cais-5" and not skip_row and load("res://scripts/campaign/marisol_row.gd").eligible(session.snapshot().player):
		var origin:Vector2=park.player
		if not load("res://scripts/campaign/marisol_row.gd").new(session).near(origin):return
		_simple_page("Marisol · Cais Velho",true)
		_label("Você veio pela água ou pelo emblema?",page,26)
		_button("Conversar sobre Remar",page,func():_show_row_lesson(load("res://scripts/campaign/marisol_row.gd").new(session),origin))
		_button("Assuntos do campeonato",page,func():
			_return_row_championship(id))
		_button("Voltar ao Cais",page,_show_saved)
		return
	var service=load("res://scripts/campaign/district_campaign.gd").new(session)
	var rules=load("res://scripts/campaign/district_rules.gd")
	var player:Dictionary=session.snapshot().player
	var entry:Dictionary=service.stage(id)
	var district:String=entry.get("district","")
	var title:Dictionary=rules.entry(player,district)
	if entry.is_empty():return
	if title.champion=="player" and id!=district+"-5" and title.pendingDefense.is_empty():
		if not _result(service.offer_defense(id,park.player)):return
		player=session.snapshot().player;title=rules.entry(player,district)
	if not title.pendingDefense.is_empty():
		if title.pendingDefense.challenger!=entry.npcId:
			_notice(rules.objective(player,district));return
		_confirm_park("Defender "+rules.definition(district).name,entry.name+" quer disputar seu título. Derrota ou fuga entrega o título ao desafiante e exige quatro novas vitórias para a reconquista. Você pode responder depois; o desafio permanece salvo.","Defender meu título",func():
			if _result(service.start(id,park.player,true)):_show_saved.call_deferred())
		return
	var planned:Dictionary=rules.prepare(player,district,id)
	if planned.status=="already_applied":_notice("Este duelo já foi concluído. Você pode continuar explorando o bairro.");return
	if planned.status!="ok":
		if rules.status(player,district)=="prerequisite":_notice(service.objective(player,district));return
		_notice("Vença os quatro pipeiros na ordem do percurso antes do campeão." if id==district+"-5" else "Conclua o desafio anterior para continuar.");return
	var speaker:String=rules.opponent_name(player,district) if id==district+"-5" and title.completed else entry.name
	var text:String=entry.before[0][1] if planned.context.mode=="progress" else "Vamos disputar mais uma vez. O caminho para recuperar o título passa por estes quatro desafios."
	_confirm_park(speaker,text+"\n\nAdversário Nv. %d · vence quem conquistar %d rodadas."%[entry.level,entry.rounds],"Disputar",func():
		if _result(service.start(id,park.player)):_show_saved.call_deferred())

func _return_district_result()->void:
	_show_saved()
	var player:Dictionary=session.snapshot().player
	var result:Dictionary=player.get("lastDistrict",{})
	if result.is_empty():return
	var service=load("res://scripts/campaign/district_campaign.gd")
	var entry:Dictionary=service.stage(result.duel)
	var text:String=""
	if result.mode=="progress":text=entry.won[0][1] if result.outcome=="won" else entry.lost[0][1]
	else:text=service.objective(player,result.district)
	if result.get("emblem",false):text+="\n\nInsígnia recebida · "+str(result.district)+". O próximo destino está no mapa de Kronasta."
	_notice(text)

func _show_tyler_clareira()->void:
	var service=load("res://scripts/campaign/tyler_clareira.gd").new(session)
	if not service.available(park.player):return
	if service.done(session.snapshot().player):
		_notice("Tyler: Rai e eu vamos conferir este lado. O banco está livre se vocês precisarem descansar.");return
	var index:int=service.step(session.snapshot().player)
	var line:Dictionary=service.nodes()[index]
	park.path.clear();park.paused=true
	var camera_start:Vector2=park.camera.position
	park.camera.zoom=Vector2.ONE*(1.35 if line.get("cue","")=="reel" else 1.15)
	var focus:Vector2=park.model.project(service.point())
	if line.get("cue","")=="rai":focus=park.model.project(Vector2(26.5,20.5))
	if preferences.reduced_motion:park.camera.position=focus
	else:park.create_tween().tween_property(park.camera,"position",focus,.45)
	var scene_dialog:=_dialog(line.speaker,line.text,"Continuar","Continuar depois")
	scene_dialog.allow_cancel=false
	scene_dialog._portraits["Tyler"]=load("res://assets/campaign/tyler-clareira-v1/tyler.png")
	scene_dialog._portraits["Rai"]=load("res://assets/campaign/tyler-clareira-v1/rai.png")
	scene_dialog.confirmed.connect(func():
		var result:Dictionary=service.advance(index,park.player)
		if result.status!="ok":_result(result);return
		scene_dialog.queue_free()
		if not service.done(session.snapshot().player):_show_tyler_clareira.call_deferred()
		else:
			park.paused=false;park.camera.zoom=Vector2.ONE*1.15;park.camera.position=camera_start;park.refresh(session.snapshot().player);park.encounter_grace=6.0)
	scene_dialog.canceled.connect(func():
		scene_dialog.queue_free();park.paused=false;park.camera.zoom=Vector2.ONE*1.15;park.camera.position=camera_start)
	scene_dialog.popup_centered()

func _present_green_promotion()->void:
	while is_instance_valid(scene_loading):await get_tree().process_frame
	if not is_inside_tree() or not preload("res://scripts/campaign/league_promotion.gd").pending(session.snapshot()):return
	if is_instance_valid(park):park.paused=true;park.path.clear()
	var promotion_dialog:=_dialog("Rabiola Verde","Nina: [emo=brilho]Você trouxe meu Carcará de volta. Venceu os dois bairros e ajudou alguém fora da arena. Isso também é ser pipeiro.\n\nCarteira de Pipeiro: Exame da categoria Branca concluído. Categoria Rabiola Verde registrada.\n\nNina: Quando meu Carcará estiver pronto para a travessia, pode contar com ele. Guarde esta autorização de empréstimo.\n\nJornada: Experimente Planar nas setas azuis junto ao rio das Veredas. O próximo bairro é Beira-Canal.","Guardar e continuar")
	promotion_dialog.allow_cancel=false
	promotion_dialog._portraits["Carteira de Pipeiro"]=null
	promotion_dialog.confirmed.connect(func():
		if not _result(preload("res://scripts/campaign/league_promotion.gd").acknowledge(session)):return
		promotion_dialog.queue_free()
		if is_instance_valid(park):park.paused=false;park.refresh(session.snapshot().player)
		if DemoFlow.pending(session.snapshot()):_show_demo_complete.call_deferred())
	promotion_dialog.popup_centered()

func _request_nina_glide(id:String)->void:
	var glide=load("res://scripts/campaign/nina_glide.gd")
	if not glide.allowed(session.snapshot().player):
		_notice("A seta marca um ponto de Planar. Devolva a rabiola da Nina e conclua o primeiro exame para contar com o Carcará dela.");return
	var text:="Nina emprestou seu Carcará para este trecho. Aproxime-se da seta azul e confirme: ele leva você e seu parceiro até a outra margem. A ponte normal continua disponível. Se interromper a travessia, vocês retomam no ponto de partida seguro."
	if session.snapshot().player.flags.get("ninaGlideTutorialDone",false):text="Planar até a outra margem com o Carcará da Nina?"
	_confirm_park("Planar · Carcará da Nina",text,"Planar",func():
		var result:Dictionary=glide.new(session).begin(id,park.player)
		if _result(result):park.play_glide(session.snapshot().player.ninaGlideFlight))

func _request_canal_gate()->void:
	var service=load("res://scripts/campaign/canal_gate.gd").new(session)
	if session.snapshot().player.flags.get("grampoVeredasVencido",false):
		_confirm_park("Comporta das Veredas","O Lacertubo já deixou este lugar. A Rabiola Antiga vibra perto da entrada fechada das Ruínas. O controle do canal está ao alcance: destrancar a comporta?","Destrancar",func():
			if _result(service.open(park.player)):
				park.refresh(session.snapshot().player);park.exploration_hud.push_notice("Comporta aberta · volte ao pátio de Kleie","item"))
	else:
		_confirm_park("Grampo","Vai mexer no controle? Achei essas peças primeiro! Platyx, segura a linha.\n\nDuelo de história · adversário Nv. 14. Derrota ou fuga permitem tentar novamente.","Enfrentar Grampo",func():
			if _result(service.begin(park.player)):_show_saved.call_deferred())

func _request_feira_story(who:String)->void:
	var service=load("res://scripts/campaign/feira_story.gd").new(session)
	var player:Dictionary=session.snapshot().player
	var phase:String=service.phase(player)
	if who=="door":
		if phase=="buy":_notice("A fechadura das Ruínas responde a um apito de vento. Talvez alguém na Feira saiba onde encontrar um.");return
		if phase=="door":
			_confirm_park("A porta das Ruínas","Kael aproxima o apito da fechadura antiga. Experimentar?","Soprar o apito",func():
				if _result(service.test_door(park.player)):
					park.refresh(session.snapshot().player)
					_notice("O apito solta um chiado fino. É de plástico! A fechadura não se move. Kael: Lalau vai ter que explicar isso."))
		elif phase=="complete":
			if preload("res://scripts/campaign/mural_story.gd").available(player):
				_confirm_park("A porta das Ruínas","O apito verdadeiro ressoa com a Rabiola Antiga. A passagem para a Caverna do Mural está aberta.","Entrar",func():
					if _result(load("res://scripts/campaign/bosque_campaign.gd").new(session).travel("caverna-mural-a")):_show_park.call_deferred())
			else:_notice("O apito verdadeiro responde à porta. Antes de seguir, conclua o campeonato da Feira do Largo.")
		else:_notice(service.objective(player))
		return
	if who=="lalau" and phase=="buy":
		_confirm_park("Seu Lalau","Apito de vento original! Vinte moedas. Com ele, porta nenhuma resiste!

Comprar por 20 moedas?","Comprar apito",func():
			if _result(service.buy(park.player)):
				park.refresh(session.snapshot().player);park.celebrate_item("Recebido · Apito anunciado como original"))
		return
	if phase==who:
		var message:String="Eu devolvo suas moedas, mas primeiro quero ver se você sabe voar. O verdadeiro? Pode estar com o Grampo…" if who=="lalau" else "Lalau falou demais. Platyx, vamos!

Platyx recolhe as patas e olha para Grampo, inseguro."
		_confirm_park("Seu Lalau" if who=="lalau" else "Grampo",message+"

Duelo de história · Nv. "+("16" if who=="lalau" else "17")+". Derrota ou fuga permitem tentar novamente.","Disputar",func():
			if _result(service.begin(who,park.player)):_show_saved.call_deferred())
	else:_notice(service.objective(player))

func _return_feira_story()->void:
	_show_saved()
	var result:Dictionary=session.snapshot().player.get("lastFeira",{})
	if result.get("outcome")!="won":return
	if result.opponent=="lalau":_notice("Seu Lalau devolve as 20 moedas: Está bem! Troquei o apito verdadeiro com o Grampo por cerol. Ele está no beco da parte B do mercado.")
	else:_notice("Grampo: Leva esse apito e sai do meu caminho.

Recebido · Apito de vento verdadeiro. Platyx se esconde nas dobras da cabeça, aliviado por parar de lutar.")

func _show_mural_story()->void:
	var service=load("res://scripts/campaign/mural_story.gd").new(session)
	if not service.near("caverna-mural-c",service.AT,park.player):return
	var index:int=service.step(session.snapshot().player)
	if index>=3:_notice("Tyler: A ponta da linha foi oferecida. Vamos lembrar disso quando encontrarmos outras marcas.");return
	var node:Dictionary=service.nodes()[index]
	park.path.clear();park.paused=true
	var scene_dialog:=_dialog(node.title,node.text,"Guardar esta lembrança","Continuar depois")
	var cinematic:Control=get_tree().get_first_node_in_group("mural_cinematic")
	if not is_instance_valid(cinematic):
		cinematic=load("res://scripts/campaign/mural_cinematic.gd").new()
		cinematic.reduced_motion=preferences.reduced_motion
		add_child(cinematic)
	scene_dialog.confirmed.connect(func():
		var result:Dictionary=service.advance(index,park.player)
		if not _result(result):return
		scene_dialog.queue_free()
		if service.step(session.snapshot().player)<3:_show_mural_story.call_deferred()
		else:
			if is_instance_valid(cinematic):cinematic.queue_free()
			park.paused=false;park.refresh(session.snapshot().player)
			park.celebrate_item("A Rabiola Antiga respondeu ao mural"))
	scene_dialog.canceled.connect(func():
		scene_dialog.queue_free()
		if is_instance_valid(cinematic):cinematic.queue_free()
		park.paused=false)
	scene_dialog.show_portraits=false
	scene_dialog.popup_centered()
	scene_dialog.portrait.hide();scene_dialog.other_portrait.hide()

func _return_retalho()->void:
	_show_saved()
	while is_instance_valid(scene_loading):await get_tree().process_frame
	if session.snapshot().player.flags.get("retalhoBosqueVencido",false):
		_notice("Retalho recua entre as copas antes que Kael se aproxime. Na base da rabiola, há um nó bem diferente dos outros.\n\nKael: Esse nó… parece feito para uma expedição.")

func _request_warehouse(gollia:bool=false)->void:
	var service=load("res://scripts/campaign/warehouse_story.gd").new(session)
	var player:Dictionary=session.snapshot().player
	if not service.available(player):
		_notice("Antes de seguir: conclua o Cais Velho, encontre Retalho no Bosque e examine a foto da expedição no arquivo do ateliê.");return
	if gollia:
		if player.flags.get("golliaCarretelVencida",false):_notice("Gollia: Eu só aceitei o Carretel Negro para testar. Tem alguma coisa acontecendo no galpão, pela porta do depósito.");return
		_confirm_park("Gollia · Nv. 23","Só vou testar esse Carretel Negro. Uma disputa, Kael?\n\nAzulão se prepara. Você pode recuar; derrota ou fuga permitem tentar novamente.","Disputar",func():
			if _result(service.begin("gollia",park.player)):_show_saved.call_deferred())
		return
	if player.flags.get("pipaDragaoDesatadaVencida",false):_notice("As rabiolas já não estão presas juntas. Retalho precisa de cuidados no ateliê. O duelo com Bruno Solda está liberado.");return
	if not player.flags.get("golliaCarretelVencida",false):_notice("Encontre Gollia junto ao depósito, na parte B.");return
	var index:int=service.step(player)
	var tableau=load("res://scripts/campaign/warehouse_tableau.gd").new()
	tableau.beat=index;tableau.reduced_motion=preferences.reduced_motion;add_child(tableau)
	park.path.clear();park.paused=true
	var entry:Dictionary=service.nodes()[index] if index<3 else {"title":"Pipa-Dragão desatada · Nv. 25","text":"Tyler: As duas almas estão livres. Agora mantenha a linha firme, sem cortar a rabiola.\n\nO confronto pode ser vencido. Derrota ou fuga permitem tentar novamente, sem repetir a intervenção. A Agulha de desatar é uma recompensa única."}
	var dialog:=_dialog(entry.title,entry.text,"Continuar" if index<3 else "Iniciar confronto","Continuar depois")
	dialog.show_portraits=false
	dialog.confirmed.connect(func():
		var result:Dictionary=service.advance(index,park.player) if index<3 else service.begin("dragon",park.player)
		if not _result(result):return
		dialog.queue_free()
		if index<3:_request_warehouse.call_deferred(false)
		else:_show_saved.call_deferred())
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		if is_instance_valid(tableau):tableau.queue_free()
		if is_instance_valid(park):park.paused=false)
	dialog.popup_centered()

func _return_warehouse()->void:
	_show_saved()
	while is_instance_valid(scene_loading):await get_tree().process_frame
	var result:Dictionary=session.snapshot().player.get("lastWarehouse",{})
	if result.get("outcome")!="won":return
	if result.opponent=="gollia":_notice("Gollia recua. A porta do galpão está adiante, na frente do depósito.")
	else:
		if is_instance_valid(park):park.celebrate_item("Recebido · Agulha de desatar")
		_notice("As almas estão livres. Kael se aproxima de Retalho, ainda ferido.\n\nTyler: Vamos levá-lo ao ateliê.\n\nAgulha de desatar guardada. Sua função de remontagem será integrada depois. Bruno Solda já pode ser desafiado.")

func _show_expedition_photo()->void:
	if not is_instance_valid(room) or room.actor.distance_to(preload("res://scripts/campaign/expedition_photo.gd").AT)>110:return
	var service=preload("res://scripts/campaign/expedition_photo.gd").new(session)
	room.can_walk=false;flow_busy=true
	var photo:=preload("res://scripts/campaign/expedition_photo_view.gd").new()
	photo.name="ExpeditionPhotograph";add_child(photo)
	var dialog:=_dialog("Uma foto entre os arquivos",service.pages(),"Guardar lembrança","Fechar por enquanto")
	dialog.name="ExpeditionPhotoDialogue"
	dialog.confirmed.connect(func():
		var result:Dictionary=service.read(room.actor)
		if result.status in ["ok","already_applied"]:dialog.queue_free()
		else:_result(result))
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		if is_instance_valid(photo):photo.queue_free()
		if is_instance_valid(room):room.can_walk=true
		flow_busy=false)
	dialog.popup_centered()

func _show_retalho_care()->void:
	if flow_busy or not is_instance_valid(room):return
	var service=preload("res://scripts/campaign/retalho_care.gd").new(session)
	if not service.near(room.actor):return
	var index:int=service.step(session.snapshot().player)
	if index>=service.nodes().size():
		_show_retalho_trust();return
	var node:Dictionary=service.nodes()[index]
	flow_busy=true;room.can_walk=false;room.set_story_paused(true)
	room.face_actor(service.AT);room.face_mother(service.AT)
	var generation:=opening_generation
	var dialog:=_dialog(node.title,node.text,"Continuar","Continuar depois")
	dialog.name="RetalhoCareDialogue"
	var continue_scene:=[false]
	dialog.confirmed.connect(func():
		if not TutorialStaging.valid(self,generation) or not is_instance_valid(room):return
		if not _result(service.advance(node.id,room.actor)):return
		continue_scene[0]=true
		dialog.queue_free()
		)
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		flow_busy=false
		if is_instance_valid(room):
			room.can_walk=true;room.set_story_paused(false)
			var overlay:Control=room.get_meta("exploration_hud",null)
			if is_instance_valid(overlay):overlay.objective.text=service.objective(session.snapshot().player)
		if continue_scene[0] and index<service.nodes().size()-1 and TutorialStaging.valid(self,generation):_show_retalho_care.call_deferred())
	dialog.popup_centered()

func _show_heleana_confession()->void:
	if flow_busy or (not is_instance_valid(room) and not is_instance_valid(park)):return
	var service=load("res://scripts/campaign/heleana_confession.gd").new(session)
	if not service.available(session.snapshot().player):_notice("Heleana: Vá com cuidado. Estarei aqui quando voltar.");return
	var p:Dictionary=session.snapshot().player
	var outdoors:bool=service.outside(p)
	var point:Vector2=park.cell if outdoors and is_instance_valid(park) else room.actor if is_instance_valid(room) else Vector2.INF
	if not service.near(point):return
	if service.done(p) and not service.recognition(p):_notice("Heleana: Obrigada por me escutar. Você e seus parceiros sempre terão lugar aqui.");return
	var step:int=service.index(p)
	if service.refused(p) and not service.done(p) and step==0:service.play_grunt(self)
	var node:Array=service.nodes(p)[step]
	flow_busy=true
	if is_instance_valid(room):
		room.can_walk=false;room.set_story_paused(true)
		room.face_actor(Vector2(960,864));room.face_mother(room.actor)
	if is_instance_valid(park):park.paused=true
	var generation:=opening_generation
	var dialog:=_dialog(node[0],node[1],"Continuar","Continuar depois")
	dialog.name="HeleanaConfessionDialogue"
	dialog._portraits["Heleana"]=load("res://assets/campaign/"+content.portraits["Mãe"])
	var follow:=[false]
	var leave_house:=[false]
	dialog.confirmed.connect(func():
		if not TutorialStaging.valid(self,generation):return
		if _result(service.advance(step,point)):
			follow[0]=true
			leave_house[0]=not outdoors and service.outside(session.snapshot().player)
			dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		flow_busy=false
		if is_instance_valid(room):room.can_walk=true;room.set_story_paused(false)
		if is_instance_valid(park):park.paused=false
		if not follow[0] or not TutorialStaging.valid(self,generation):return
		if leave_house[0]:_show_saved.call_deferred()
		elif not service.done(session.snapshot().player) or service.recognition(session.snapshot().player):_show_heleana_confession.call_deferred())
	dialog.popup_centered()

func _show_blue_preparation()->void:
	if flow_busy or not is_instance_valid(room):return
	var preparation=preload("res://scripts/campaign/blue_exam_preparation.gd")
	if not preparation.eligible(session.snapshot().player) or not preparation.near(session,room.actor):return
	if preparation.prepared(session.snapshot().player):
		_notice("Sr. Assis: A orientação está registrada. Dona Cida aplica a prova no Pátio da Liga, junto ao Parque.");return
	var entry:Dictionary=preparation.data()
	flow_busy=true;room.can_walk=false;room.set_story_paused(true)
	var generation:=opening_generation
	var dialog:=_dialog(entry.title,entry.text,"Registrar preparação","Conversar depois")
	dialog.name="BlueExamPreparationDialogue"
	dialog.confirmed.connect(func():
		if not TutorialStaging.valid(self,generation) or not is_instance_valid(room):return
		if _result(preparation.confirm(session,room.actor)):dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		flow_busy=false
		if is_instance_valid(room):
			room.can_walk=true;room.set_story_paused(false)
			var overlay:Control=room.get_meta("exploration_hud",null)
			if is_instance_valid(overlay):overlay.objective.text=preload("res://scripts/campaign/kronasta_story.gd").objective(session.snapshot().player))
	dialog.popup_centered()

func _show_retalho_trust()->void:
	if flow_busy:return
	var service=load("res://scripts/campaign/retalho_trust.gd").new(session)
	var p:Dictionary=session.snapshot().player
	if not service.available(p):return
	var n:int=service.stage(p)
	if n==8:
		_notice("Retalho escolheu acompanhar você. Ele está no banco de parceiros deste save.");return
	var at:Vector2=room.actor if is_instance_valid(room) else park.player if is_instance_valid(park) else Vector2.INF
	var scene:String=session.snapshot().checkpoint.get("scene","")
	if not service.near(scene,at):return
	if n<2 and scene!="professor-home" or n in [2,4] and scene!=service.A or n==3 and scene!=service.B or n>=5 and scene!=service.C:
		_notice(service.objective(p));return
	if is_instance_valid(park):
		var subject:Vector2=service.SICK if scene==service.A else service.HERB if scene==service.B else service.RESCUE
		if at.distance_to(subject)<.7:
			for offset in [Vector2(0,1),Vector2(1,0),Vector2(0,-1),Vector2(-1,0)]:
				var candidate:Vector2=subject+offset
				if not park.model.clear_segment(at,candidate) or not service.near(scene,candidate):continue
				park.player=candidate;at=candidate;park._refresh_positions();break
	if n==7 and p.partners.size()>=service.CAPACITY:
		_show_retalho_bank();return
	var entry:Dictionary=service.nodes()[n]
	flow_busy=true
	if is_instance_valid(room):room.can_walk=false;room.set_story_paused(true)
	if is_instance_valid(park):park.path.clear();park.paused=true
	if n==6 and is_instance_valid(park) and not preferences.reduced_motion:
		var companion_spot:Vector2=at+Vector2(2,0)
		if park.model.point_walkable(companion_spot) and absf(park.model.height_at(companion_spot)-park.model.height_at(at))<.25:
			park.follower=companion_spot;park._refresh_positions()
		for actor:Dictionary in park.npc_nodes:
			if actor.root.get_meta("event",{}).get("props",{}).get("acao","")!="retalhoTrust":continue
			var original:Vector2=actor.root.position
			var toward:Vector2=park.model.project(at,false)-original
			var approach:=toward.limit_length(6)
			var tween:Tween=actor.root.create_tween()
			tween.tween_property(actor.root,"position",original-approach*.4,.45)
			tween.tween_interval(.4)
			tween.tween_property(actor.root,"position",original+approach,.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var generation:=opening_generation
	var dialog:=_dialog(entry.title,entry.text,"Proteger Retalho" if n==5 else "Acolher Retalho" if n==7 else "Continuar","Continuar depois")
	if n==7:
		dialog.options=[{"id":"accept","text":"Acolher Retalho"},{"id":"refuse","text":"Não formar esse laço"},{"id":"later","text":"Decidir depois","safe":true}]
		dialog.choice_selected.connect(func(id:String):
			if not TutorialStaging.valid(self,generation):return
			if id=="accept":dialog.confirmed.emit()
			elif id=="later":dialog.canceled.emit()
			elif id=="refuse" and _result(service.refuse(at)):dialog.queue_free();_show_saved.call_deferred())
	dialog.name="RetalhoTrustDialogue"
	var committed:=[false]
	dialog.confirmed.connect(func():
		if not TutorialStaging.valid(self,generation):return
		var result:Dictionary=service.begin(at) if n==5 else service.claim(at) if n==7 else service.advance(n,at)
		if not _result(result):return
		committed[0]=true;dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.tree_exiting.connect(func():
		flow_busy=false
		if is_instance_valid(room):room.can_walk=true;room.set_story_paused(false)
		if is_instance_valid(park):park.paused=false
		if committed[0] and TutorialStaging.valid(self,generation):_after_retalho_trust.call_deferred(n)
		elif n==6 and TutorialStaging.valid(self,generation):_show_world.call_deferred())
	dialog.popup_centered()

func _after_retalho_trust(n:int)->void:
	_show_saved()
	while is_instance_valid(scene_loading):await get_tree().process_frame
	if n==7 and is_instance_valid(park):park.celebrate_item("Retalho escolheu acompanhar você")

func _show_retalho_bank()->void:
	var service=load("res://scripts/campaign/retalho_trust.gd").new(session)
	var p:Dictionary=session.snapshot().player
	if service.stage(p)!=7:return
	_simple_page("Banco cheio · Retalho está esperando",true)
	_label("Retalho já escolheu você. Libere uma vaga quando quiser; ele não será perdido.",page,22)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.follow_focus=true;page.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	for partner:Dictionary in p.partners:
		var id:String=partner.id
		if id==p.get("equippedPartnerId","") or partner.get("origin","")==service.ORIGIN:continue
		var partner_name:String=partner.get("personalName",partner.modelId)
		_button("Liberar "+partner_name+" · Nv. "+str(preload("res://scripts/campaign/partner_levels.gd").level_for_xp(partner.get("xp",0))),list,func():
			var dialog:=_dialog("Liberar parceiro?",partner_name+" sairá permanentemente do banco deste save. Esta ação não pode ser desfeita. Nenhum outro parceiro será alterado.","Liberar permanentemente","Manter parceiro")
			dialog.name="RetalhoBankReleaseDialogue"
			dialog.confirmed.connect(func():
				if _result(service.release(id)):
					dialog.queue_free();_show_retalho_bank.call_deferred())
			dialog.canceled.connect(dialog.queue_free);dialog.popup_centered())
	_button("Voltar sem liberar ninguém",page,_show_saved)
	if p.partners.size()<service.CAPACITY:_button("Voltar para acolher Retalho",page,_show_saved)

func _blue_station(action:String)->void:
	if flow_busy or not is_instance_valid(park):return
	var exam=load("res://scripts/campaign/blue_exam.gd").new(session)
	var p:Dictionary=session.snapshot().player
	var point:Vector2=park.player
	if action=="register":
		if not exam.near(point,exam.CIDA):return
		if exam.promoted(p):_notice("Dona Cida: Sua categoria Rabiola Azul está registrada. O campo de controle continua disponível para treino, sem novas recompensas.");return
		if exam.stage(p)==3:
			_confirm_park("Dona Cida · resultado da avaliação","Você observou o parceiro, respeitou seu ritmo e demonstrou controle. Posso registrar sua aprovação na categoria Rabiola Azul.","Registrar aprovação",func():
				if _result(exam.claim(park.player)):
					park.refresh(session.snapshot().player);park.celebrate_item("Categoria Rabiola Azul conquistada"))
		else:_notice("Dona Cida: A avaliação tem três competências: observação, condução e controle. Todos usam o Carcará da Liga. Nenhum item ou recurso da sua equipe será gasto.\n\n"+exam.objective(p))
	elif action=="observe":
		if not _result(exam.observe(point)):return
		_show_blue_observation(point)
	elif action=="escort":
		if not exam.near(point,exam.escort_start(p)):return
		if not exam.record(p).care:_notice("Dona Cida: Primeiro, examine o Carcará e escolha o cuidado adequado na bancada elevada.");return
		if exam.record(p).escort==3 and not exam.promoted(p):_notice("Dona Cida: Condução aprovada. Siga ao campo de controle.");return
		park.blue_guide.begin();park.exploration_hud.objective.text="Acompanhe o Carcará. Ele vai parar se você se afastar demais."
	elif action=="control":
		if not exam.near(point,exam.CONTROL):return
		if int(exam.record(p).escort)!=3:_notice("Dona Cida: Conclua primeiro a condução pelos três marcos.");return
		_clear("page:EXAME AZUL · CONTROLE")
		var view=load("res://scripts/campaign/blue_control_view.gd").new();view.name="BlueControlView";add_child(view)
		view.left.connect(_show_saved)
		view.finished.connect(func():
			if _result(exam.control(view.model,point)):_show_saved())

func _show_blue_observation(point:Vector2)->void:
	var exam=load("res://scripts/campaign/blue_exam.gd").new(session)
	_simple_page("OBSERVAÇÃO · Carcará da Liga",true)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",24);page.add_child(row)
	var content_art:Dictionary=content.combat["basic-carcara"];var frame:Dictionary=content_art.animations.idle[0]
	var texture:=AtlasTexture.new();texture.atlas=load("res://assets/campaign/"+content_art.image);texture.region=Rect2(frame.x,frame.y,frame.w,frame.h)
	var art:=TextureRect.new();art.texture=texture;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(220,190);row.add_child(art)
	_label("Armação íntegra. Linha íntegra. Movimentos lentos e sinais de cansaço.\n\nQual cuidado atende ao que você observou?",row,24).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var feedback:=_label("Escolha o cuidado. Nenhum material da sua bolsa será utilizado.",page,22)
	for option in [["rest","Oferecer descanso · respeitar o cansaço"],["frame","Reparar a armação"],["line","Trocar a linha"]]:
		var id:String=option[0]
		_button(option[1],page,func():
			var result:Dictionary=exam.care(id,point)
			if result.status=="try_again":feedback.text=result.hint
			elif _result(result):_show_saved())
	_button("Voltar sem concluir o cuidado",page,_show_saved)

func _show_row_lesson(lesson:RefCounted,origin:Vector2)->void:
	if not lesson.near(origin):return
	_simple_page(lesson.data().title,true)
	if lesson.learned(session.snapshot().player):
		_label(lesson.data().done,page,24)
		_button("Voltar ao Cais",page,_show_saved)
		return
	if lesson.step==lesson.data().lessons.size():
		_label("Corrente, ritmo e margem. Registre a orientação para praticar com a capivara de Marisol na Entrada alagada, no Pântano.",page,24)
		var feedback:=_label("Registre a orientação antes de sair.",page,22)
		_button("Registrar orientação",page,func():
			var result:Dictionary=lesson.finish(origin)
			if _result(result):_show_row_lesson(lesson,origin)
			else:feedback.text="Não foi possível salvar. Tente registrar novamente; suas respostas continuam nesta tela.")
	else:
		var entry:Dictionary=lesson.data().lessons[lesson.step]
		_label(lesson.data().intro if lesson.step==0 else "Marisol · corrente, ritmo e margem",page,22)
		_label("%d / %d · %s"%[lesson.step+1,lesson.data().lessons.size(),entry.prompt],page,26)
		var feedback:=_label("Escolha como você conduziria a travessia.",page,22)
		for option:Dictionary in entry.options:
			var choice:String=option.id
			_button(option.text,page,func():
				var result:Dictionary=lesson.answer(choice,origin)
				if result.status=="try_again":feedback.text=result.hint
				elif _result(result):_show_row_lesson(lesson,origin))
	_button("Sair sem registrar",page,_show_saved)

func _return_row_championship(id:String)->void:
	_show_saved()
	for frame in 900:
		await get_tree().process_frame
		if is_instance_valid(park) and not is_instance_valid(scene_loading):
			_district_action(id,true)
			return

func _request_marisol_row(id:String)->void:
	var row=load("res://scripts/campaign/marisol_row_trip.gd")
	if not row.allowed(session.snapshot().player):
		_notice("A seta marca Remar. Após o Exame Azul, converse com Marisol no Cais Velho para aprender a conduzir a travessia.");return
	_confirm_park("Remar · capivara de Marisol","A capivara de apoio acompanha sua pequena balsa. Segure "+Controls.prompt("interact")+" ou o botão Remar para avançar; solte para descansar. A ponte continua disponível. Interromper e carregar o save devolve você à margem de partida. Nenhum parceiro é transferido ao seu banco.","Embarcar",func():
		var result:Dictionary=row.new(session).begin(id,park.player)
		if _result(result):park.play_row(session.snapshot().player.marisolRowTrip))

func _request_mormaco(action:String)->void:
	var story=load("res://scripts/campaign/mormaco_story.gd").new(session)
	var point:Vector2=park.player
	if action=="mormacoSignals":
		_confirm_park("O vento parou","A água está imóvel. As rabiolas pendem sem força e o ar pesa entre as árvores.\n\nKael: Até aqui… O que está prendendo o vento?\n\nUm som de pressão vem do lago, no fundo do Pântano.","Seguir o som",func():
			if _result(story.observe(point)):park.refresh(session.snapshot().player))
	elif action=="mormacoRest":
		_confirm_park("Pouso da margem","Descansar e recuperar linha e armação da equipe? Sem custo ou experiência.","Descansar",func():
			if _result(story.rest(point)):park.refresh(session.snapshot().player))
	elif story.freed(session.snapshot().player):_notice("Mormaço: O frio sabe onde estão os outros. Não confunda pressa com vento, pequeno pipeiro.")
	elif story.won(session.snapshot().player):
		_confirm_park("O primeiro Vento livre","Os cordões perdem a tensão. O brilho violeta desaparece dos olhos de Mormaço; a água volta a subir clara. Ele respira fundo e observa Kael.\n\nMormaço: Enfim… Achou que eu estava dormindo?\n\nKael: Os outros Ventos também estão presos?\n\nMormaço: O frio sabe onde estão os outros.","Escutar o Vento",func():
			if _result(story.release(point)):park.refresh(session.snapshot().player))
	elif not session.snapshot().player.flags.get("mormacoVentosPararam",false):_notice("O ar parado chamou sua atenção na entrada. Examine o sinal junto ao caminho da parte A antes de enfrentar o guardião.")
	else:
		_confirm_park("Mormaço · amarrado","Os olhos do guardião brilham contra sua vontade. O mesmo fio negro do galpão aperta as placas e as saídas de água quente.\n\nKael: Não é ele que está escolhendo lutar. Precisamos desfazer esse controle.\n\nDuelo Nv.27. O jato marca o ponto de impacto antes de disparar. Você pode recuar e descansar na margem.","Enfrentar",func():
			if _result(story.begin(point)):_show_saved.call_deferred())
func _return_mormaco()->void:
	_show_saved()
	if session.snapshot().player.get("lastMormaco","")=="won":_notice.call_deferred("Os nós do Carretel Negro cederam. Mormaço continua vivo. Aproxime-se da margem para escutar o guardião.")
