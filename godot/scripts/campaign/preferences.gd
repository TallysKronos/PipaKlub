extends RefCounted
## Device preferences are separate from campaign slots and are never uploaded.
var crt := true
var fullscreen := false
var reduced_motion := false
var text_scale:=1.0
var pad_family := "auto"
var storage_path := "user://settings.cfg"
const Controls = preload("res://scripts/campaign/controls.gd")
var bindings: Dictionary = Controls.DEFAULTS.duplicate()

func load_settings(path: String = "") -> void:
	if path.is_empty(): path = storage_path
	var config := ConfigFile.new()
	if config.load(path) != OK: return
	var value: Variant = config.get_value("video", "crt", true)
	crt = value if value is bool else true
	value = config.get_value("video", "fullscreen", false)
	fullscreen = value if value is bool else false
	value = config.get_value("video", "reduced_motion", false)
	reduced_motion = value if value is bool else false
	value=config.get_value("accessibility","text_scale",1.0)
	text_scale=float(value) if (value is float or value is int) and float(value) in [1.0,1.15,1.3] else 1.0
	value = config.get_value("controls", "keys", Controls.DEFAULTS)
	bindings = value.duplicate() if Controls.validate(value) else Controls.DEFAULTS.duplicate()
	value = config.get_value("controls","glyph_family","auto")
	pad_family = value if value in ["auto","xbox","ps","switch"] else "auto"

func save_settings(path: String = "") -> Error:
	if path.is_empty(): path = storage_path
	var config := ConfigFile.new()
	config.set_value("video", "crt", crt)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "reduced_motion", reduced_motion)
	config.set_value("accessibility","text_scale",text_scale)
	config.set_value("controls", "keys", bindings)
	config.set_value("controls","glyph_family",pad_family)
	return config.save(path)
