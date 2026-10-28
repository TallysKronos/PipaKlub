@tool
extends "res://scripts/overworld/waterfall.gd"
@export var surface_override: Texture2D
func rebuild() -> void:
 super.rebuild()
 if not materials.is_empty() and surface_override:materials[0].set_shader_parameter("surface_texture",surface_override)
