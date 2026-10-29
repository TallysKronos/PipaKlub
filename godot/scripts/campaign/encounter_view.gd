extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal save_requested(state: Dictionary)
signal finish_requested
signal leave_requested
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Ink = preload("res://scripts/campaign/battle_ink.gd")
const Field=preload("res://scripts/campaign/battle_field.gd")
const CornerHud=preload("res://scripts/campaign/battle_corner_hud.gd")
var flee_hold:=0.0
var flee_pointer:=false
var flee_release:=true
var flee_button:Button
var launch_age:=0.0
var round_wipe_number:=0
var selected_action := "cut"
var round_caption: Control
const ACTION_COPY := {"cut": "Cortar a linha do oponente em um cruzamento.", "skill": "Usar a habilidade do seu parceiro.", "dodge": "Esquivar e abrir uma oportunidade de contra-ataque.", "line": "Preparar um puxão para disputar a linha.", "guard": "Proteger-se no momento do impacto.", "signature": "Pulo do Elo · Marque o alvo e acerte a área."}
const Hud = preload("res://scripts/campaign/hud.gd")
var pointer_held: Dictionary = {}
var pointer_tapped: Dictionary = {}
var require_action_release := false
var model: RefCounted
var content: Dictionary
var textures: Array[Texture2D] = []
var art_ids: Array[String] = []
var foreground: Texture2D = preload("res://assets/campaign/battle-ink/foreground-veredas-v1.png")
var background: Texture2D
var banner: Texture2D
var paused := false
var blocked := false
var clock := 0.0
var save_clock := 0.0
var controls: Label
var resume_button: Button
var finish_button: Button
var guardian_frame: Texture2D
var panel_styles: Array[StyleBox] = []
var actions: HBoxContainer
var move_cards: Array[Dictionary] = []
var command_row: HBoxContainer
var status_row: HBoxContainer
var bottom_panel: PanelContainer
var footer_contents: VBoxContainer
const ImpactEffects = preload("res://scripts/campaign/hud_impacts.gd")
const RewardPreview = preload("res://scripts/campaign/hud_rewards.gd")
const SkySignals = preload("res://scripts/campaign/battle_signals.gd")
var live_age := 0.0
var impacts := ImpactEffects.new()
var reward_player: Dictionary = {}
var reward_encounter: Dictionary = {}
var reward_card: PanelContainer
var reduced_motion := false
var result_age := 0.0
var result_summary: Dictionary = {}
var result_wipe_started := false
var result_header:Control

func configure(data: Dictionary, state: Dictionary) -> void:
	content = data
	model = Model.new()
	model.restore(state)
	var assets := {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}
	art_ids.assign([assets.get(model.model_id, "rabbito"), assets.get(model.enemy_model_id, "lacertubo")])
	for id in art_ids: textures.append(load("res://assets/campaign/" + content.combat[id].image))
	background = load("res://assets/campaign/veredas-arena-wide-v2.png")
	guardian_frame = load("res://assets/campaign/guardian-frame.png")
	panel_styles.assign([_panel("dark"), _panel("danger")])

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	impacts.reduced_motion = reduced_motion
	model.damage_applied.connect(impacts.add)
	model.combat_feedback.connect(impacts.add)
	var bottom := VBoxContainer.new()
	footer_contents=bottom
	bottom.add_theme_constant_override("separation", 6)
	bottom_panel = PanelContainer.new()
	bottom_panel.anchor_top = .70 if size.x >= 1100 else .63
	bottom_panel.anchor_right = 1
	bottom_panel.anchor_bottom = 1
	bottom_panel.offset_left = 24
	bottom_panel.offset_right = -24
	bottom_panel.offset_bottom = -12
	bottom_panel.theme_type_variation = "RecorteEmptyPanel"
	add_child(bottom_panel)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	bottom_panel.add_child(scroll)
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bottom)
	command_row = HBoxContainer.new()
	command_row.alignment = BoxContainer.ALIGNMENT_END
	command_row.add_theme_constant_override("separation", 8)
	resized.connect(_layout_actions)
	bottom.add_child(command_row)
	var entries := [["Espaço", "Cortar", "attack", "attackCooldown", 12], ["Q", "Habilidade", "energy", "skillCooldown", 25], ["Shift", "Esquiva", "dodge", "dodgeCooldown", 18], ["R", "Puxão", "puxao", "lineCooldown", 28], ["G", "Guarda", "line", "guardCooldown", 0]]
	if model.model_id == "rabbito": entries.append(["F", "Especial", "team", "signatureCooldown", 40])
	for entry in entries:
		var command := VBoxContainer.new()
		command.add_theme_constant_override("separation", 2)
		command.size_flags_horizontal = Control.SIZE_SHRINK_END
		command_row.add_child(command)
		var art = load("res://scripts/campaign/hud_action.gd").new()
		art.icon_id = entry[2]
		art.title = entry[1]
		art.cost = entry[4]
		command.add_child(art)
		var action_id: String = {"attackCooldown": "cut", "skillCooldown": "skill", "dodgeCooldown": "dodge", "lineCooldown": "line", "guardCooldown": "guard", "signatureCooldown": "signature"}[entry[3]]
		art.action_id = action_id
		art.mouse_entered.connect(func(): selected_action = action_id)
		art.focus_entered.connect(func(): selected_action = action_id)
		art.tooltip_text = "" # Combat tips belong to pause/lesson, not hover popups.
		art.held_changed.connect(func(held: bool):
			if paused or blocked: return
			pointer_held[action_id] = held
			if held: pointer_tapped[action_id] = true)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.hide()
		command.add_child(label)
		move_cards.append({"label": label, "tile": art, "key": entry[0], "name": entry[1], "cooldown": entry[3], "cost": entry[4], "node": command})
	controls = Label.new()
	controls.add_theme_font_size_override("font_size", 18)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_row = HBoxContainer.new()
	bottom.add_child(status_row)
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var description_panel := PanelContainer.new()
	description_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_panel.theme_type_variation = "RecorteBattlePanel"
	status_row.add_child(description_panel)
	description_panel.add_child(controls)
	resume_button = Button.new()
	resume_button.text = "Pausar"
	resume_button.pressed.connect(func():
		if blocked:
			save_requested.emit(model.snapshot())
			if blocked: return
		paused = not paused
		if paused:require_action_release=true
		pointer_held.clear()
		pointer_tapped.clear()
		if not paused: resume_button.release_focus()
		resume_button.text = "Retomar" if paused else "Pausar")
	resume_button.theme_type_variation = "RecorteSecondaryButton"
	resume_button.custom_minimum_size.x = 150
	# Board chips: the bound key as a glyph next to a short label.
	resume_button.icon = Controls.glyph("pause")
	resume_button.expand_icon = true
	resume_button.add_theme_constant_override("icon_max_width",26)
	resume_button.add_theme_font_size_override("font_size",18)
	add_child(resume_button)
	flee_button=Button.new()
	Hud.navigation_button(flee_button,true)
	flee_button.add_theme_font_size_override("font_size",16)
	flee_button.button_down.connect(func():flee_pointer=true)
	flee_button.button_up.connect(func():flee_pointer=false)
	add_child(flee_button)
	resume_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	resume_button.offset_left = 20
	resume_button.offset_top = -58
	resume_button.offset_right = 150
	resume_button.offset_bottom = -18
	resume_button.custom_minimum_size.y = 40
	finish_button = Button.new()
	finish_button.text = "Continuar"
	Hud.navigation_button(finish_button,false,"back")
	finish_button.icon=Controls.glyph("accept")
	Controls.events.changed.connect(func():finish_button.icon=Controls.glyph("accept"))
	for state in ["normal","hover","pressed","disabled"]:
		var style:StyleBoxFlat=finish_button.get_theme_stylebox(state).duplicate()
		style.bg_color=Tokens.SOL.darkened(.15) if state=="pressed" else Tokens.PAPEL if state=="hover" else Tokens.SOL
		finish_button.add_theme_stylebox_override(state,style)
	finish_button.add_theme_color_override("font_color",Tokens.NANQUIM)
	finish_button.add_theme_color_override("font_hover_color",Tokens.NANQUIM)
	finish_button.add_theme_color_override("font_pressed_color",Tokens.NANQUIM)
	finish_button.visible = false
	finish_button.pressed.connect(func(): finish_requested.emit())
	bottom.add_child(finish_button)
	var row := HBoxContainer.new()
	actions = row
	bottom.add_child(row)
	for option in [["Salvar e voltar ao menu", "menu"], ["Fugir sem recompensa", "flee"]]:
		var button := Button.new()
		button.text = option[0]
		Hud.navigation_button(button,true,"save" if option[1]=="menu" else "back")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var id: String = option[1]
		button.pressed.connect(func():
			paused = true
			if id == "flee" and model.outcome.is_empty(): model.outcome = "fled"
			save_requested.emit(model.snapshot())
			if not blocked:
				if id == "menu": leave_requested.emit()
				else: finish_requested.emit())
		row.add_child(button)
	_layout_actions()
	footer_contents.minimum_size_changed.connect(_layout_actions.call_deferred)

func _layout_actions() -> void:
	if not is_instance_valid(bottom_panel): return
	var fighting: bool = model.outcome.is_empty() and not paused and not blocked
	if is_instance_valid(resume_button):
		var target:Node=status_row if paused or blocked else self
		if resume_button.get_parent()!=target:
			var focused:=resume_button.has_focus()
			resume_button.reparent(target,false)
			resume_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if target==status_row else Control.PRESET_BOTTOM_LEFT)
			if target==self:
				resume_button.offset_left=20;resume_button.offset_top=-size.y+88
				resume_button.offset_right=150;resume_button.offset_bottom=-size.y+128
			if focused and get_parent().get("pause_overlay")==null:Hud.focus_later(resume_button)
	bottom_panel.anchor_top = 1
	if resume_button.get_parent()==self:
		resume_button.offset_top=-size.y+88
		resume_button.offset_bottom=-size.y+128
	var result:bool=not model.outcome.is_empty()
	if is_instance_valid(flee_button):
		flee_button.visible=not result and model.get("actors")==null and not paused and not blocked
		var flee_glyph:=Controls.glyph("interact")
		flee_button.icon=flee_glyph
		flee_button.expand_icon=flee_glyph!=null
		flee_button.add_theme_constant_override("icon_max_width",26)
		flee_button.text="Segure para fugir" if flee_glyph!=null else "Segure %s para fugir"%Controls.prompt("interact")
		flee_button.position=Vector2(20,size.y-184)
		flee_button.size=Vector2(250,40)
	# Decorative strokes extend outside the content box. Only item lists scroll/clip.
	footer_contents.get_parent().clip_contents=not result
	var panel_width:=minf(1180,size.x-80) if result else size.x-48
	bottom_panel.offset_left=(size.x-panel_width)/2
	bottom_panel.offset_right=-(size.x-panel_width)/2
	finish_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	finish_button.custom_minimum_size=Vector2(240,48)
	if is_instance_valid(reward_card):reward_card.custom_minimum_size.y=clampf(size.y*.56,390,490)
	bottom_panel.offset_bottom = -8 if fighting else -12
	status_row.visible = paused or blocked
	# The illustrated action discs need 16.5% of the height (user-approved HUD board; was 12%).
	var height:=size.y*.165 if fighting else maxf(140,footer_contents.get_combined_minimum_size().y+8)
	bottom_panel.offset_top=bottom_panel.offset_bottom-height
	var unit := size.y / 1080.0
	command_row.add_theme_constant_override("separation", roundi(8 * unit))
	for command in move_cards:
		command.tile.custom_minimum_size = command.tile.SIZE * unit
		command.tile.size = command.tile.custom_minimum_size


func _physics_process(delta: float) -> void:
	_layout_actions()
	_step_flee(delta)
	if paused or blocked:
		pointer_held.clear()
		pointer_tapped.clear()
		require_action_release=true
	elif require_action_release:
		var held:bool=ACTION_COPY.keys().any(func(action:String):return Controls.held(action) or bool(pointer_held.get(action,false)))
		if not held:require_action_release=false
	clock += delta
	if model.get("intermission")!=null and model.intermission>0 and round_wipe_number!=model.round_number:
		round_wipe_number=model.round_number
		var wipe=load("res://scripts/campaign/recorte_ink_wipe.gd").new()
		add_child(wipe)
		wipe.z_index=50
		wipe.finished.connect(wipe.queue_free,CONNECT_ONE_SHOT)
		wipe.play(Tokens.CEU if model.round_message.begins_with(model.p.name+" venceu") else Tokens.RABIOLA,reduced_motion,false)
	if not paused and not blocked:
		if model.intro>0 or (model.get("intermission")!=null and model.intermission>0):launch_age=0
		else:launch_age+=delta
	if not paused and not blocked and model.intro <= 0: live_age += delta
	impacts.step(delta) # Paint expires even while gameplay is paused.
	if not paused and not blocked and model.outcome.is_empty():
		var direction := Controls.direction()
		model.tick(delta, {"x": direction.x, "y": direction.y, "cut": _action_held("cut"), "skill": _action_held("skill"), "dodge": _action_held("dodge"), "line": _action_held("line"), "guard": _action_held("guard"), "signature": _action_held("signature")})
		pointer_tapped.clear()
		save_clock += delta
		if save_clock >= 5 or not model.outcome.is_empty():
			save_clock = 0
			save_requested.emit(model.snapshot())
	finish_button.visible = not model.outcome.is_empty()
	_update_result(delta)
	for command in move_cards:
		command.node.visible = model.outcome.is_empty() and not paused
		var cooldown: float = model.p[command.cooldown]
		var action: String = {"attackCooldown": "cut", "skillCooldown": "skill", "dodgeCooldown": "dodge", "lineCooldown": "line", "guardCooldown": "guard", "signatureCooldown": "signature"}[command.cooldown]
		command.label.text = "%s · %d energia" % [command.name, command.cost]
		command.tile.selected = action == selected_action
		command.tile.key_text = Controls.prompt(action)
		command.tile.cooldown = cooldown
		command.tile.charge = clampf(float(model.p.lineMove.get("elapsed",0)) / 1.05,0,1) if action == "line" else 0.0
		command.tile.active = model.p.guardTime > 0 if action == "guard" else model.p.signatureWindup > 0 if action == "signature" else false
		command.tile.reduced_motion = reduced_motion
		command.tile.lock_reason = "PREPARE-SE" if model.intro > 0 else "NOVA RODADA" if model.get("intermission") != null and model.intermission > 0 else "FORA DA RODADA" if model.p.hp <= 0 or model.p.hull <= 0 else ""
		command.tile.enough_energy = model.p.energy >= command.cost
		command.tile.queue_redraw()
		command.node.modulate = Tokens.UNTINTED
		command.label.theme_type_variation = "RecorteMutedText" if cooldown > 0 or model.p.energy < command.cost else "Label"
	resume_button.visible = model.outcome.is_empty() or blocked
	resume_button.text = "Tentar salvar novamente" if blocked else "Retomar" if paused else "Pausar"
	actions.visible = model.outcome.is_empty() and paused
	controls.text = ("Analógico · Mover" if Controls.gamepad else "Mover: %s %s %s %s / setas" % [Controls.prompt("up"), Controls.prompt("left"), Controls.prompt("down"), Controls.prompt("right")]) + (" · %s: Pulo do Elo" % Controls.prompt("signature") if model.model_id == "rabbito" else "")
	if paused: controls.text = "Jogo pausado. " + ACTION_COPY[selected_action] if not blocked else "Não foi possível salvar. Tente novamente antes de continuar."
	elif model.intro > 0: controls.text = "Lacertubo · O guardião dos canos — Leia o vento. Espere a abertura." if model.q.boss else "Um Pipamon selvagem apareceu no mato!"
	elif model.q.signatureWindup > 0: controls.text = "Ruptura dos Canos! Saia do círculo ou proteja-se no impacto."
	elif model.q.recovery > 0: controls.text = "O guardião está vulnerável!"
	elif model.q.telegraph > .6: controls.text = "Ele vai puxar!"
	elif model.intro <= 0 and model.q.signatureWindup <= 0 and model.q.recovery <= 0 and model.q.telegraph <= .6:
		controls.text = ACTION_COPY[selected_action]
	if not model.outcome.is_empty():
		controls.text = ("Vitória · +120 XP · Rabiola de Lacertubo" if model.q.boss else "Vitória · Recompensas serão guardadas ao voltar às Veredas.") if model.outcome == "won" else "Seu parceiro continua com você. Repare-o com o professor antes de tentar novamente."
	if blocked: controls.text = "Não foi possível salvar. Tente novamente antes de continuar."
	_layout_actions()
	queue_redraw()

func _step_flee(delta:float) -> void:
	var held:bool=Controls.held("interact") or flee_pointer
	if paused or blocked or model.intro>0 or not model.outcome.is_empty() or model.get("actors")!=null:
		flee_hold=0;flee_pointer=false;flee_release=true
		return
	if not held:flee_release=false
	if flee_release:return
	flee_hold=minf(1,flee_hold+delta) if held else 0.0
	if flee_hold>=1:
		flee_hold=0;flee_pointer=false;flee_release=true
		model.outcome="fled"
		save_requested.emit(model.snapshot())

func _update_result(delta: float) -> void:
	if model.outcome.is_empty(): return
	if not is_instance_valid(result_header):
		result_header=load("res://scripts/campaign/hud_result_header.gd").new()
		add_child(result_header)
	result_header.outcome=model.outcome
	result_header.left=bottom_panel.position.x+12
	result_header.queue_redraw()
	if not result_wipe_started:
		result_wipe_started = true
		if model.outcome != "fled":
			var winner: Dictionary = model.p if model.outcome == "won" else model.q
			if model.get("actors") != null and model.outcome != "won":
				for actor: Dictionary in model.actors:
					if actor.get("rounds",0)>winner.get("rounds",0): winner=actor
			var wipe = load("res://scripts/campaign/recorte_ink_wipe.gd").new()
			add_child(wipe)
			wipe.z_index=50
			wipe.finished.connect(wipe.queue_free,CONNECT_ONE_SHOT)
			wipe.play([Tokens.CEU,Tokens.SOL,Tokens.FOLHA,Tokens.RABIOLA][int(winner.color)%4],reduced_motion,false)
	result_age += delta
	if not is_instance_valid(reward_card):
		reward_card = load("res://scripts/campaign/hud_reward_card.gd").new()
		result_summary = RewardPreview.preview(reward_player, reward_encounter, model)
		result_summary.outcome = model.outcome
		reward_card.portrait_texture = AtlasTexture.new()
		reward_card.portrait_texture.atlas = textures[0]
		reward_card.summary = result_summary
		reward_card.reduced_motion = reduced_motion
		var column := finish_button.get_parent()
		column.add_child(reward_card)
		column.move_child(reward_card, finish_button.get_index())
		reward_card.visible = true
	controls.get_parent().get_parent().visible = blocked
	reward_card.advance(delta)
	var poses: Array = content.combat[art_ids[0]].animations["victory" if model.outcome == "won" else "defeat"]
	var pose: Dictionary = poses[0 if reduced_motion else int(clock * 12) % poses.size()]
	reward_card.portrait_texture.region = Rect2(pose.x, pose.y, pose.w, pose.h)

func _draw_feedback() -> void:
	draw_set_transform(Vector2.ZERO)
	if model.outcome.is_empty() and model.intro<=0 and model.p.hp>0 and model.p.hull>0 and (model.get("intermission")==null or model.intermission<=0):
		SkySignals.draw_on(self,model,_project_field,live_age,reduced_motion)
	impacts.protected_points.clear()
	var actors: Array = model.actors if model.get("actors")!=null else [model.p,model.q]
	for actor: Dictionary in actors: impacts.protected_points.append(_project_field(Vector2(actor.x,actor.y)))
	impacts.visible_rect=Rect2(10,_field_top()-20,size.x-20,maxf(80,bottom_panel.position.y-_field_top()+10))
	impacts.suppress_secondary=actors.slice(1).any(func(actor:Dictionary):return actor.get("signatureWindup",0)>0 or model.attack_notice(actor).active)
	impacts.draw_on(self, _project_field)
	draw_set_transform(_field_origin(), 0, _field_scale())

func _draw_result() -> void:
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(Vector2.ZERO,size),Tokens.alpha(Tokens.NANQUIM,.42))
func _arena_factor() -> float:
	return Field.scale_for(size).y

func _field_scale() -> Vector2:
	return Field.scale_for(size)

func _field_top() -> float:
	return Field.origin(size).y

func _field_origin() -> Vector2:
	return Field.origin(size)

func _project_field(point: Vector2) -> Vector2:
	return _field_origin() + point * _field_scale()

func _draw_foreground() -> void:
	var source: Texture2D = foreground
	var cap := source.get_width() / 4.0
	var height := size.y * .15
	var base_y := size.y * .96
	var base := PackedVector2Array([Vector2(0, base_y - 4), Vector2(size.x * .15, base_y + 5), Vector2(size.x * .33, base_y - 7), Vector2(size.x * .5, base_y + 3), Vector2(size.x * .74, base_y - 5), Vector2(size.x, base_y), Vector2(size.x, size.y), Vector2(0, size.y)])
	draw_colored_polygon(base, Tokens.TINTA)
	var factor := height / source.get_height()
	var width := cap * factor
	var center_width := cap * 2 * factor
	var x := width
	while x < size.x - width:
		draw_texture_rect_region(source, Rect2(x, base_y - height, center_width, height), Rect2(cap, 0, cap * 2, source.get_height()))
		x += center_width
	draw_texture_rect_region(source, Rect2(0, base_y - height, width, height), Rect2(0, 0, cap, source.get_height()))
	draw_texture_rect_region(source, Rect2(size.x - width, base_y - height, width, height), Rect2(cap * 3, 0, cap, source.get_height()))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		suspend_actions()
		if is_instance_valid(resume_button): resume_button.text = "Retomar"

func suspend_actions() -> void:
	paused=true
	require_action_release=true
	pointer_held.clear()
	pointer_tapped.clear()

func _draw() -> void:
	if model == null: return
	_draw_field_background()
	var factor := _arena_factor()
	draw_set_transform(_field_origin(), 0, _field_scale())

	for index in 2:
		var actor: Dictionary = model.p if index == 0 else model.q
		draw_line(Vector2(actor.anchor, 585), Vector2(actor.x, actor.y), Hud.BLACK, 6)
		draw_line(Vector2(actor.anchor, 585), Vector2(actor.x, actor.y), Hud.CYAN if index == 0 else Hud.CORAL, 3)
		_draw_anchor(actor.anchor, Hud.CYAN if index == 0 else Hud.CORAL)
		var action := "idle"
		if not model.outcome.is_empty(): action = "victory" if (model.outcome == "won") == (index == 0) else "defeat"
		elif actor.attackCooldown > .5 or actor.signatureWindup > 0: action = "attack"
		var frames: Array = content.combat[art_ids[index]].animations[action]
		var frame: Dictionary = frames[int(clock * 12) % frames.size()]
		var width := 230 if index == 1 and model.q.boss else 180
		var opponent:Dictionary=model.q if index==0 else model.p
		var flip:bool=Ink.facing_flip(art_ids[index],actor.x,opponent.x)
		Ink.live_sprite(self, textures[index], art_ids[index], frame, Vector2(actor.x, actor.y), width, Tokens.UNTINTED, _field_scale(),flip)

	_draw_feedback()

	if not model.outcome.is_empty():
		_draw_result()
	draw_set_transform(Vector2.ZERO)
	_draw_foreground()
	_draw_status()
	# Specials are signalled beside their source kite, without a blocking panel.

func _panel(role: String = "dark") -> StyleBox:
	return Hud.panel(role)

func _action_held(action: String) -> bool:
	if paused or blocked or require_action_release:return false
	return Controls.held(action) or bool(pointer_held.get(action, false)) or bool(pointer_tapped.get(action, false))

func _draw_field_background() -> void:
	var height := size.y
	var bounds := Rect2(0, 0, size.x, height)
	var scale := maxf(bounds.size.x / background.get_width(), bounds.size.y / background.get_height())
	var source := Rect2((background.get_size() - bounds.size / scale) / 2, bounds.size / scale)
	draw_texture_rect_region(background, bounds, source)

func _draw_status() -> void:
	if not model.outcome.is_empty():return
	var actors:Array=model.actors if model.get("actors")!=null else [model.p,model.q]
	var faces:Array=[]
	var names:Array=[]
	for index in actors.size():
		faces.append(Ink.portrait(textures[index],art_ids[index]))
		var title:String={"rabbito":"Rabbito","basic-carcara":"Carcará","basic-mata-verde":"Mata verde","basic-azulao":"Azulão","basic-raio-de-sol":"Raio de sol","lacertubo":"Lacertubo"}.get(art_ids[index],"Parceiro")
		var level:int=model.enemy_level if index>0 else 1
		if index==0:
			for partner in reward_player.get("partners",[]):
				if partner.id==reward_player.get("equippedPartnerId",""):
					title=partner.get("personalName",title)
					level=Model.level_for_xp(partner.get("xp",0))
		names.append("%s · Nv. %d"%[title,level])
	var cost:int=0
	for command in move_cards:
		if _action_held(command.tile.action_id):cost=command.cost
	_draw_phase()
	CornerHud.draw_on(self,actors,faces,names,reward_player,model.duration,model.round_number if model.get("round_number")!=null else 1,model.rounds_to_win if model.get("rounds_to_win")!=null else 1,model.wind_strength(),cost,-1,_footer_top())
	if flee_hold>0:
		draw_arc(Vector2(286,size.y-160),14,-PI/2,-PI/2+TAU*flee_hold,32,Tokens.SOL,3,true)

# While the pause/result footer is open the partner card rises above it instead of sitting under it.
func _footer_top() -> float:
	var fighting: bool = model.outcome.is_empty() and not paused and not blocked
	return -1.0 if fighting or not is_instance_valid(bottom_panel) else bottom_panel.position.y-8

func _draw_phase() -> void:
	var message:=""
	if model.get("intermission")!=null and model.intermission>0:
		message="EMPATE" if "empatada" in model.round_message else "CORTOU!" if model.round_message.begins_with(model.p.name+" venceu") else "RODADA PERDIDA"
	elif model.intro>0:
		message="LACERTUBO" if model.q.boss else "RODADA %d · %d"%[model.round_number if model.get("round_number")!=null else 1,mini(3,ceili(model.intro))]
	elif launch_age<.6:message="JÁ!"
	if message.is_empty():return
	if message=="JÁ!":
		_draw_shout(message,launch_age/.6)
		return
	var rect:=_phase_rect()
	if not rect.has_area():return
	Ink.plate(self,rect,Tokens.TINTA,Tokens.TINTA)
	var font_size:=28
	var width:=Hud.lettering().get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(Hud.lettering(),Vector2(size.x/2-width/2,rect.position.y+32),message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Tokens.RABIOLA)
	if model.get("intermission")!=null and model.intermission>0:
		for index in model.actors.size():
			var actor_name:String=Ink.ellipsis(model.actors[index].name,Hud.font(true),14,70)
			draw_string(Hud.font(true),Vector2(rect.position.x+16+index*180,rect.end.y-11),actor_name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Tokens.PAPEL)
			CornerHud.diamonds(self,Vector2(rect.position.x+90+index*180,rect.end.y-15),model.actors[index].rounds,model.rounds_to_win,Tokens.CEU if index==0 else Tokens.RABIOLA)

# Manga shout for the launch: Bangers in coral, thick ink outline, solid shadow, tilted, with a
# short pop that reduced motion turns off. No plate, so it reads as lettering over the sky.
func _draw_shout(message:String,t:float) -> void:
	var font:=Hud.lettering()
	var font_size:=roundi(size.y*.1)
	var pop:=1.0 if reduced_motion else lerpf(1.35,1.0,clampf(t*4,0,1))
	var width:=font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var center:=Vector2(size.x/2,size.y*.33)
	draw_set_transform(center,deg_to_rad(-8),Vector2.ONE*pop)
	var origin:=Vector2(-width/2,font_size*.35)
	draw_string_outline(font,origin+Vector2(5,6),message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,maxi(8,font_size/6),Tokens.NANQUIM)
	draw_string(font,origin+Vector2(5,6),message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Tokens.NANQUIM)
	draw_string_outline(font,origin,message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,maxi(8,font_size/6),Tokens.NANQUIM)
	draw_string(font,origin,message,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Tokens.RABIOLA)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _phase_rect() -> Rect2:
	var actors:Array=model.actors if model.get("actors")!=null else [model.p,model.q]
	var extent:=Vector2(560,72) if model.get("intermission")!=null and model.intermission>0 else Vector2(360,48)
	for y in [174.0,size.y*.67]:
		var candidate:=Rect2(Vector2(size.x/2-extent.x/2,y),extent)
		var blocked:=false
		for actor:Dictionary in actors:
			var point:=_project_field(Vector2(actor.x,actor.y))
			if candidate.grow(10).intersects(Rect2(point-Vector2(100,85),Vector2(200,170))):blocked=true
		for rival:Dictionary in actors.slice(1):
			var crossing:Dictionary=model.contact_hint(model.p,rival)
			if not crossing.is_empty() and candidate.grow(36).has_point(_project_field(crossing.point)):blocked=true
		if not blocked:return candidate
	return Rect2()


func _draw_anchor(x: float, color: Color) -> void:
	var point := _project_field(Vector2(x, 585))
	draw_set_transform(Vector2.ZERO)
	draw_ellipse_stub(point)
	draw_colored_polygon(PackedVector2Array([point + Vector2(-12, 1), point + Vector2(3, -7), point + Vector2(14, 1), point + Vector2(-2, 5)]), color)
	draw_arc(point, 6, 0, TAU, 12, Ink.BLACK, 3, true)
	draw_line(point + Vector2(-13, 5), point + Vector2(13, 2), Ink.BLACK, 2, true)
	draw_set_transform(_field_origin(), 0, _field_scale())

func draw_ellipse_stub(point: Vector2) -> void:
	draw_set_transform(point, 0, Vector2(1, .25))
	draw_circle(Vector2.ZERO, 18, Tokens.alpha(Tokens.NANQUIM, .25))
	draw_set_transform(Vector2.ZERO)
