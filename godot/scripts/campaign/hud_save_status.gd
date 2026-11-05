extends CanvasLayer
## Event-driven status; never holds focus or blocks input.
const Hud = preload("res://scripts/campaign/hud.gd")
var label: Label
var generation := 0
func _ready() -> void:
	layer = 110
	label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -330; label.offset_right = -24
	label.offset_top = 24; label.offset_bottom = 62
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.hide()
func started() -> void:
	generation += 1
	label.text = "◈ Gravando…"
	label.modulate = Hud.CYAN
	label.show()
func finished(status: String) -> void:
	generation += 1
	var ticket := generation
	label.text = "✓ Jornada salva" if status == "ok" else "! Falha ao salvar"
	label.modulate = Hud.PAPER
	label.show()
	await get_tree().create_timer(2.5).timeout
	if ticket == generation: label.hide()
