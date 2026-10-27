shader_type canvas_item;
render_mode unshaded;

// Reuse each existing canopy's alpha as an independently projected floor shadow.
// No lighting or garden shadow is baked into the ground material.
void fragment() {
	COLOR = vec4(vec3(.10,.18,.26),texture(TEXTURE,UV).a*.22);
}
