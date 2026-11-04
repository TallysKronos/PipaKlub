@tool
extends "res://scripts/overworld/water_patch.gd"
@export var surface_override: Texture2D
func rebuild() -> void:
 super.rebuild()
 if water_material and surface_override:water_material.set_shader_parameter("surface_texture",surface_override)
