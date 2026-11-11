shader_type canvas_item;
render_mode unshaded;
// Queda de lava dos mapas do Vulcão: a textura escorre para baixo; o centro da cortina
// é mais claro e as bordas escurecem como lava esfriando na pedra.
uniform sampler2D lava_texture : source_color, repeat_enable, filter_linear;
uniform float flow = 1.0;
void fragment() {
	vec2 uv = vec2(UV.x, UV.y * 0.55 - TIME * 0.42 * flow);
	vec3 color = texture(lava_texture, uv).rgb;
	float streak = 0.82 + 0.18 * sin(UV.x * 37.0 + sin(UV.y * 9.0 - TIME * 3.0 * flow));
	COLOR = vec4(color * streak * 1.18, 1.0);
}
