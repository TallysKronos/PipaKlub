extends ColorRect
signal finished
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
var reduced_motion := false
var progress := 0.0
var _tween: Tween
var _cover := false
var _ink := Tokens.TINTA

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	add_to_group("recorte_motion")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func play(ink: Color = Tokens.TINTA, reduce: bool = false, cover: bool = false) -> void:
	reduced_motion = reduce
	_ink = ink
	_cover = cover
	if _tween != null: _tween.kill()
	color = Tokens.UNTINTED
	modulate.a = 1
	_tween = create_tween()
	if reduce:
		material = null
		color = ink
		modulate.a = 0 if cover else 1
		_tween.tween_property(self,"modulate:a",1.0 if cover else 0.0,.08)
	else:
		var shader_material := ShaderMaterial.new()
		shader_material.shader = preload("res://assets/ui/recorte-v1/shaders/ink_wipe.gdshader")
		shader_material.set_shader_parameter("splat_mask",Ink.texture("splat_mask"))
		shader_material.set_shader_parameter("ink",ink)
		material = shader_material
		progress = 0 if cover else 1
		shader_material.set_shader_parameter("progress",progress)
		_tween.tween_method(func(value: float):
			progress = value
			shader_material.set_shader_parameter("progress",value),progress,1.0 if cover else 0.0,.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func(): finished.emit())

func set_reduced_motion(value: bool) -> void:
	if value and not reduced_motion: play(_ink,true,_cover)
	else: reduced_motion = value
