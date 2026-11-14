extends Control
## The transaction is complete before this screen opens.
signal continued

const Hud = preload("res://scripts/campaign/hud.gd")
const Dialogue = preload("res://scripts/campaign/hud_opening_dialogue.gd")
const Reveal = preload("res://scripts/campaign/soul_reveal.gd")
const Sound = preload("res://scripts/campaign/sound_director.gd")

var partner_name := "Parceiro"
var partner_texture: Texture2D
var frames: Array = []
var outcome: Dictionary = {}
var variant := false
var reduced_motion := false
var accepted := false
var action: Button
var reveal: Control
var portrait: TextureRect
var panel: PanelContainer
var bonus_panel: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Dialogue.make_backdrop(self, 2)
	reveal = Reveal.new()
	reveal.reduced_motion = reduced_motion
	for frame: Dictionary in frames:
		var texture := AtlasTexture.new()
		texture.atlas = partner_texture
		texture.region = Rect2(frame.x, frame.y, frame.w, frame.h)
		texture.filter_clip = true
		reveal.after_frames.append(texture)
	reveal.opened.connect(func(): Sound.cue(self, "workshop.birth"))
	reveal.completed.connect(_finish_reveal)
	add_child(reveal)

	portrait = TextureRect.new()
	portrait.texture = load("res://assets/campaign/soul-reveal-v1/kael-alegria.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(portrait)

	bonus_panel = Control.new()
	bonus_panel.mouse_filter = MOUSE_FILTER_IGNORE
	bonus_panel.draw.connect(_draw_bonus)
	add_child(bonus_panel)

	panel = Dialogue.new()
	panel.speaker = "Kael"
	panel.portrait_present = true
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	var speech := Label.new()
	speech.text = "%s nasceu! Que massa!\nVamos juntos, parceiro!" % partner_name
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.size_flags_vertical = SIZE_EXPAND_FILL
	speech.add_theme_font_override("font", Hud.font())
	speech.add_theme_font_size_override("font_size", 23)
	speech.add_theme_color_override("font_color", Dialogue.ICE)
	content.add_child(speech)
	action = Button.new()
	action.text = "Conhecer meu parceiro"
	action.disabled = true
	action.size_flags_horizontal = SIZE_SHRINK_END
	action.pressed.connect(_continue)
	content.add_child(action)
	Dialogue.style_button(action, "accept")
	panel.hide()
	bonus_panel.hide()
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	var safe := Dialogue.Layout.safe_rect(size)
	reveal.size = Vector2(safe.size.x * .57, size.y * .64)
	reveal.position = Vector2(safe.position.x + safe.size.x * .22, safe.position.y - 5)
	var portrait_height := size.y * .81
	portrait.size = Vector2(portrait_height * .67, portrait_height)
	portrait.position = Vector2(safe.position.x - portrait_height * .13, size.y - portrait_height)
	bonus_panel.size = Vector2(390, 54)
	bonus_panel.position = Vector2(safe.end.x - bonus_panel.size.x, safe.position.y + safe.size.y * .58)
	bonus_panel.queue_redraw()

func _draw_bonus() -> void:
	var canvas := bonus_panel
	Dialogue.plate(canvas, Rect2(Vector2.ZERO, canvas.size), Dialogue.NAVY, Dialogue.CYAN, 24, 2)
	var bonus: float = outcome.get("craftBonus", {}).get("totalPercent", 0.0)
	var amount := ("%+.1f%%" % bonus).replace(".", ",")
	canvas.draw_string(Hud.font(), Vector2(35, 33), "Bônus da montagem", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Dialogue.ICE)
	canvas.draw_line(Vector2(210, 14), Vector2(210, 40), Color("#355a8b"), 1, true)
	canvas.draw_string(Hud.Tokens.text(true), Vector2(224, 33), amount + " nos atributos",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Dialogue.ICE)
	if variant:
		canvas.draw_string(Hud.Tokens.text(true), Vector2(26, -10), "Variante rara",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Hud.GOLD)

func _finish_reveal() -> void:
	panel.show()
	bonus_panel.show()
	action.disabled = false
	Hud.focus_later(action)

func _continue() -> void:
	if accepted or action.disabled:
		return
	accepted = true
	action.disabled = true
	continued.emit()
