extends RefCounted
## Shared material factory for the dry floor and the actual clipped basin floor.
const BASE := "res://assets/overworld/kits/cavernas-v3/"
const SHADER = preload("res://shaders/overworld/cave_ground_blend.gdshader")

static func material(wet: bool) -> ShaderMaterial:
 var result := ShaderMaterial.new()
 result.shader = SHADER
 result.set_shader_parameter("stone_texture",load(BASE+"surfaces/"+("rocha-umida" if wet else "rocha-cinza")+".png"))
 result.set_shader_parameter("earth_texture",load(BASE+"surfaces/"+("cascalho-gruta" if wet else "terra-gruta")+".png"))
 result.set_shader_parameter("stone_tone",Color("293E49") if wet else Color("344453"))
 result.set_shader_parameter("earth_tone",Color("69635A") if wet else Color("7C624C"))
 return result
