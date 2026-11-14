extends Control
signal finished

const Reveal = preload("res://scripts/campaign/soul_reveal.gd")
const RASTRO_IDLE := preload("res://assets/campaign/evolucoes-v1/rastro-dos-ventos-idle.png")

var before: Texture2D
var after: Texture2D
var target_form := ""
var sound: Node
var done := false

func _ready() -> void:
	custom_minimum_size = Vector2(320, 260)
	size_flags_vertical = SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_IGNORE
	var reveal := Reveal.new()
	reveal.before = before
	reveal.after = after
	if target_form == "rastro-dos-ventos":
		var frame_width := RASTRO_IDLE.get_width() / 4.0
		for index in 4:
			var frame := AtlasTexture.new()
			frame.atlas = RASTRO_IDLE
			frame.region = Rect2(index * frame_width, 94, frame_width, 500)
			frame.filter_clip = true
			reveal.after_frames.append(frame)
	reveal.opened.connect(func():
		if is_instance_valid(sound):
			sound.play_event("workshop.birth"))
	reveal.completed.connect(skip, CONNECT_ONE_SHOT)
	add_child(reveal)
	reveal.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if is_instance_valid(sound):
		sound.play_event("workshop.soul_charge")

func skip() -> void:
	if done:
		return
	done = true
	finished.emit()
