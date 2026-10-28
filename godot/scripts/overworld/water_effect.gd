@tool
extends Sprite2D
## Transparent overlay. Place the pivot at the point where water is disturbed.
@export_enum("respingo-base","espuma-labio","anel-ondulacao","redemoinho") var effect_id := "anel-ondulacao"
@export var preview_time := -1.0
@export_tool_button("Atualizar efeito") var refresh_action: Callable = rebuild
func _ready() -> void:rebuild()
func rebuild() -> void:
	texture = load("res://assets/overworld/kits/aguas-v1/effects/"+effect_id+".png")
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/overworld/water_foam.gdshader")
	mat.set_shader_parameter("preview_time",preview_time)
	material = mat
func set_animation_time(value: float) -> void:
	preview_time = value
	if material:material.set_shader_parameter("preview_time",value)
