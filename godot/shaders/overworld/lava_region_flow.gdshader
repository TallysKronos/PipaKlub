shader_type canvas_item;
render_mode unshaded;
// Lava dos mapas jogáveis do Vulcão: UV já em repetições da textura; ela escorre devagar
// para a frente da tela. `flow` 0 congela (movimento reduzido).
uniform sampler2D lava_texture : source_color, repeat_enable, filter_linear;
uniform float flow = 1.0;
void fragment() {
	vec2 uv = UV + vec2(0.0, TIME * 0.035 * flow);
	vec3 color = texture(lava_texture, uv).rgb;
	float pulse = 0.94 + 0.06 * sin(TIME * 1.3 * flow + UV.x * 4.2 + UV.y * 3.0);
	COLOR = vec4(color * pulse, 1.0);
}
