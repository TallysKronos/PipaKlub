extends Control
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
signal save_requested(state: Dictionary)
signal finish_requested
signal leave_requested
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Ink = preload("res://scripts/campaign/battle_ink.gd")
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
	add_child(resume_button)
	resume_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	resume_button.offset_left = 20
	resume_button.offset_top = -58
	resume_button.offset_right = 150
	resume_button.offset_bottom = -18
	resume_button.custom_minimum_size.y = 40
	finish_button = Button.new()
	finish_button.text = "Voltar ao parque"
	finish_button.visible = false
	finish_button.pressed.connect(func(): finish_requested.emit())
	bottom.add_child(finish_button)
	var row := HBoxContainer.new()
	actions = row
	bottom.add_child(row)
	for option in [["Salvar e voltar ao menu", "menu"], ["Fugir sem recompensa", "flee"]]:
		var button := Button.new()
		button.text = option[0]
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
				resume_button.offset_left=20;resume_button.offset_top=-58
				resume_button.offset_right=150;resume_button.offset_bottom=-18
			if focused and get_parent().get("pause_overlay")==null:Hud.focus_later(resume_button)
	bottom_panel.anchor_top = 1
	bottom_panel.offset_bottom = -8 if fighting else -12
	status_row.visible = paused or blocked
	var height:=size.y*.12 if fighting else maxf(140,footer_contents.get_combined_minimum_size().y+8)
	bottom_panel.offset_top=bottom_panel.offset_bottom-height
	var unit := size.y / 1080.0
	command_row.add_theme_constant_override("separation", roundi(12 * unit))
	for command in move_cards:
		command.tile.custom_minimum_size = Vector2(112,128) * unit
		command.tile.size = command.tile.custom_minimum_size


func _physics_process(delta: float) -> void:
	_layout_actions()
	if paused or blocked:
		pointer_held.clear()
		pointer_tapped.clear()
		require_action_release=true
	elif require_action_release:
		var held:bool=ACTION_COPY.keys().any(func(action:String):return Controls.held(action) or bool(pointer_held.get(action,false)))
		if not held:require_action_release=false
	clock += delta
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

func _update_result(delta: float) -> void:
	if model.outcome.is_empty(): return
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
	draw_rect(Rect2(0, 128, size.x, maxf(0, bottom_panel.position.y - 128)), Tokens.alpha(Tokens.NANQUIM, .17))
	var fraction := 1.0 if reduced_motion else clampf(result_age / .24, 0, 1)
	# Uniform scaling keeps illustrated corners and knots proportional.
	var zoom := 1.0 if reduced_motion else .92 + .08 * sin(fraction * PI / 2)
	var center := Vector2(500, 450)
	var factor := minf(1.1,minf(size.x*.72/760,maxf(80,bottom_panel.position.y-180)/240))
	var target := Vector2(size.x/2,(180+bottom_panel.position.y)/2)
	draw_set_transform(target-center*factor*zoom,0,Vector2.ONE*factor*zoom)
	Hud.draw_result(self, model.outcome == "won", model.outcome == "fled")

func _arena_factor() -> float:
	var floor_y := bottom_panel.position.y - 30 if is_instance_valid(bottom_panel) else size.y * .73
	return maxf(.32, (floor_y - _field_top()) / 585)

func _field_scale() -> Vector2:
	return Vector2(maxf(.5, (size.x - 100) / 1000), _arena_factor())

func _field_top() -> float:
	return maxf(240,size.y*.28) if model.get("actors") != null and model.actors.size() > 2 else maxf(210,size.y*.24)

func _field_origin() -> Vector2:
	return Vector2(50, _field_top())

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
		var width := 260 if index == 1 and model.q.boss else 220
		Ink.live_sprite(self, textures[index], art_ids[index], frame, Vector2(actor.x, actor.y), width, Tokens.UNTINTED, _field_scale())

	_draw_feedback()
	if model.intro > 0 and model.q.boss and model.outcome.is_empty():
		draw_set_transform(Vector2.ZERO)
		var warning := Rect2(size.x / 2 - 350, 225, 700, 112)
		Ink.plate(self, warning, Ink.BLACK, Ink.WHITE)
		draw_string(Hud.font(true), warning.position + Vector2(30, 48), "LACERTUBO", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Ink.WHITE)
		draw_string(Hud.font(), warning.position + Vector2(32, 84), "O GUARDIÃO DOS CANOS · PREPARE-SE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Hud.CORAL)

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
	var actors: Array = model.actors if model.get("actors") != null else [model.p, model.q]
	var width := minf(464, (size.x - (220 if actors.size() == 2 else 48)) / actors.size() - 12)
	for index in actors.size():
		var actor: Dictionary = actors[index]
		var title: String = {"rabbito": "Rabbito", "basic-carcara": "Carcará", "basic-mata-verde": "Mata verde", "basic-azulao": "Azulão", "basic-raio-de-sol": "Raio de sol", "lacertubo": "Lacertubo"}.get(art_ids[index], "Pipamon")
		var level: int = model.enemy_level if index > 0 and model.get("enemy_level") != null else 1
		if index == 0:
			for partner in reward_player.get("partners", []):
				if partner.id != reward_player.get("equippedPartnerId", ""): continue
				title = partner.get("personalName", title)
				level = Model.level_for_xp(partner.get("xp", 0))
		var subtitle := "Nv. %d" % level
		if actor.has("rounds"): subtitle = "%s · %d / %d vitórias" % [actor.name, actor.rounds, model.rounds_to_win]
		var x := 20.0 + index * (size.x - 40 - width) / maxf(1, actors.size() - 1)
		Ink.status(self, Rect2(x, 10, width, 150), title, subtitle, actor, Ink.portrait(textures[index], art_ids[index]), index > 0)
	if actors.size() == 2:
		var rect := Rect2(size.x / 2 - 100, 18, 200, 82)
		Ink.plate(self, rect, Ink.BLACK, Ink.WHITE)
		var label := "RODADA %d" % model.round_number if model.get("round_number") != null else "ENCONTRO"
		draw_string(Hud.font(true), rect.position + Vector2(23, 34), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Ink.WHITE)
		var caption := "%02d:%02d" % [int(model.duration) / 60, int(model.duration) % 60]
		draw_string(Hud.font(true), rect.position + Vector2(70, 61), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Hud.GOLD)

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
