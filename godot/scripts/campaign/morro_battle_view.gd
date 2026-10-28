extends "res://scripts/campaign/encounter_view.gd"
const TrailModel = preload("res://scripts/campaign/morro_model.gd")
const Rules = preload("res://scripts/campaign/morro_rules.gd")

func configure(data: Dictionary, state: Dictionary) -> void:
	content = data
	model = TrailModel.new()
	model.restore(state)
	var assets := {"rabbito": "rabbito", "basica": "basic-carcara", "mata": "basic-mata-verde", "azulao": "basic-azulao", "raio": "basic-raio-de-sol", "lacertubo": "lacertubo"}
	art_ids.append(assets.get(model.model_id, "rabbito"))
	for actor in model.actors.slice(1): art_ids.append(["basic-carcara", "basic-raio-de-sol", "basic-mata-verde", "basic-azulao"][int(actor.color)])
	for id in art_ids: textures.append(load("res://assets/campaign/" + content.combat[id].image))
	background = load("res://assets/campaign/rooftop-arena-wide-v2.png")
	for role in ["dark", "danger", "danger"]: panel_styles.append(_panel(role))

func _ready() -> void:
	super._ready()
	finish_button.text = "Continuar"

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var entry := Rules.stage(model.stage_id)
	if not paused and model.outcome.is_empty():
		if model.intermission > 0: controls.text = model.round_message + " · Próxima rodada em %.0f" % ceilf(model.intermission)
		elif model.intro > 0: controls.text = "%s · Vence quem conquistar %d rodadas." % [entry.name, model.rounds_to_win]
		elif not model.alive(model.p): controls.text = "Seu parceiro caiu nesta rodada. Acompanhe a disputa dos rivais."
	if not model.outcome.is_empty():
		if model.outcome == "won":
			var result := Rules.settle(Rules.defaults(), model.stage_id, true, model.rounds_lost())
			controls.text = "Vitória · %d estrelas · Volte ao bairro para guardar as recompensas." % result.stars
		elif model.outcome == "fled": controls.text = "Você saiu do desafio. Seu progresso anterior continua guardado."
		else: controls.text = "O desafio continua disponível. O professor repara seu parceiro gratuitamente."
	if blocked: controls.text = "Não foi possível salvar. Tente novamente antes de continuar."

func _draw() -> void:
	if model == null: return
	_draw_field_background()
	var factor := _arena_factor()
	draw_set_transform(_field_origin(), 0, _field_scale())

	for index in model.actors.size():
		var actor: Dictionary = model.actors[index]
		var eliminated: bool = not model.alive(actor)
		if not eliminated:
			draw_line(Vector2(actor.anchor, 585), Vector2(actor.x, actor.y), Hud.BLACK, 6)
			draw_line(Vector2(actor.anchor, 585), Vector2(actor.x, actor.y), [Hud.CYAN, Hud.CORAL, Tokens.FOLHA][index], 3)
		if not eliminated: _draw_anchor(actor.anchor, [Hud.CYAN, Hud.CORAL, Tokens.FOLHA][index])
		var animation := "idle"
		if eliminated: animation = "defeat"
		elif not model.outcome.is_empty(): animation = "victory" if (index == 0 and model.outcome == "won") or (index > 0 and actor.rounds >= model.rounds_to_win) else "defeat"
		elif actor.attackCooldown > .5 or actor.signatureWindup > 0: animation = "attack"
		var frames: Array = content.combat[art_ids[index]].animations[animation]
		var frame: Dictionary = frames[int(clock * 12) % frames.size()]
		var target:Dictionary=model.q if index==0 else model.p
		Ink.live_sprite(self, textures[index], art_ids[index], frame, Vector2(actor.x, actor.y), 180, Tokens.alpha(Tokens.UNTINTED, .45 if eliminated else 1), _field_scale(),Ink.facing_flip(art_ids[index],actor.x,target.x))

	_draw_feedback()
	draw_set_transform(Vector2.ZERO)

	if not model.outcome.is_empty():
		_draw_result()
	draw_set_transform(Vector2.ZERO)
	_draw_foreground()
	_draw_status()
	# Persistent special indicators are rendered in the sky.

