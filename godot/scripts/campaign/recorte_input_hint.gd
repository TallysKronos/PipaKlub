extends HBoxContainer
## Live input hint. Changed by device/remap events, never a per-frame input poll.
const Controls = preload("res://scripts/campaign/controls.gd")
var action := "interact"
var caption := ""
var image: TextureRect
var label: Label
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	image = TextureRect.new()
	image.custom_minimum_size = Vector2(40,40)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(image)
	label = Label.new()
	label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(label)
	Controls.events.changed.connect(_sync)
	_sync()
func _sync() -> void:
	image.texture = Controls.glyph(action)
	image.visible = image.texture != null
	label.text = caption if image.visible else Controls.prompt(action)+(" · "+caption if not caption.is_empty() else "")
	tooltip_text = Controls.prompt(action)+(" · "+caption if not caption.is_empty() else "")
