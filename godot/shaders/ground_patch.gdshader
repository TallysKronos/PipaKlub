shader_type canvas_item;
// Background and legacy occluders sample the SAME corrected ground.
// The rest of the approved illustration remains byte-for-byte the original texture.
uniform sampler2D corrected_plate : source_color, filter_linear, repeat_disable;
uniform vec4 patch_uv;
void fragment() {
	vec4 base = texture(TEXTURE,UV);
	bool inside_patch = UV.x >= patch_uv.x && UV.y >= patch_uv.y && UV.x <= patch_uv.z && UV.y <= patch_uv.w;
	COLOR = inside_patch ? texture(corrected_plate,UV) : base;
}
