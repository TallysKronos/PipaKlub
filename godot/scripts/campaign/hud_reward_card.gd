extends PanelContainer
const Hud = preload("res://scripts/campaign/hud.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
var summary: Dictionary = {}
var portrait_texture: AtlasTexture
var reduced_motion := false
var elapsed := 0.0
var shown := -1
var earned: Label
var levels: Label
var progress: ProgressBar
var progress_caption: Label

func _ready() -> void:
	theme_type_variation = "PanelContainer"
	theme = Hud.make_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var body := HBoxContainer.new()
	add_child(body)
	if portrait_texture != null:
		var portrait := TextureRect.new()
		portrait.texture = portrait_texture
		portrait.custom_minimum_size = Vector2(140, 118)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		body.add_child(portrait)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	levels = Label.new()
	levels.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(levels)
	earned = Label.new()
	earned.theme_type_variation = "RecorteGoldText"
	earned.add_theme_font_override("font", Hud.display())
	row.add_child(earned)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 12
	progress.theme_type_variation = "RecorteXPBar"
	column.add_child(progress)
	progress_caption = Label.new()
	progress_caption.add_theme_font_size_override("font_size", 16)
	progress_caption.theme_type_variation = "RecorteMutedText"
	column.add_child(progress_caption)
	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 17)
	var parts: Array[String] = []
	if summary.get("coins", 0) > 0: parts.append("+%d moedas" % summary.coins)
	if summary.get("stars", 0) > 0: parts.append("%d estrelas" % summary.stars)
	for item in summary.get("items", []): parts.append(str(item))
	details.text = " · ".join(parts) + ("\n" if not parts.is_empty() else "") + "Ao continuar, seu progresso será guardado."
	if summary.get("outcome", "") == "lost": details.text += "\nSeu parceiro continua com você. Procure o Sr. Assis no ateliê para reparar a linha e a armação."
	column.add_child(details)
	advance(0)

func advance(delta: float) -> void:
	elapsed += delta
	var fraction := 1.0 if reduced_motion else 1.0 - pow(1.0 - clampf(elapsed / 1.1, 0, 1), 3)
	var amount := roundi(summary.get("xp", 0) * fraction)
	if amount == shown: return
	shown = amount
	var total: int = summary.get("before", 0) + amount
	var level := Model.level_for_xp(total)
	var before_level := Model.level_for_xp(summary.get("before", 0))
	levels.text = "%s · Nv. %d" % [summary.get("name", "Seu parceiro"), before_level] + (" → %d" % level if level > before_level else "")
	earned.text = "+%d XP" % amount if summary.get("xp", 0) > 0 else "Sem XP"
	earned.theme_type_variation = "RecorteGoldText" if summary.get("xp", 0) > 0 else "RecorteMutedText"
	var base := 40 * (level - 1) + 10 * (level - 1) * (level - 1)
	var threshold := 40 * level + 10 * level * level
	progress.max_value = threshold - base
	progress.value = total - base if level < 50 else progress.max_value
	progress_caption.text = "%d / %d XP para o próximo nível" % [total - base, threshold - base] if level < 50 else "Nível máximo"
