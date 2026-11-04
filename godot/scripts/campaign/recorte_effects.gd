extends RefCounted
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
const SHADERS := {
	"halftone":preload("res://assets/ui/recorte-v1/shaders/halftone.gdshader"),
	"speedlines":preload("res://assets/ui/recorte-v1/shaders/speedlines.gdshader"),
	"ink_wipe":preload("res://assets/ui/recorte-v1/shaders/ink_wipe.gdshader")}

static func surface(kind: String, ink: Color = Tokens.NANQUIM) -> ColorRect:
	var node := ColorRect.new()
	node.color = Tokens.UNTINTED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADERS[kind]
	material.set_shader_parameter("ink",ink)
	if kind == "ink_wipe": material.set_shader_parameter("splat_mask",Ink.texture("splat_mask"))
	node.material = material
	return node
