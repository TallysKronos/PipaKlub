shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
void fragment() {
	vec3 source = texture(screen_texture, SCREEN_UV).rgb;
	float line = sin(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y * 2.0943951);
	float mask = sin(SCREEN_UV.x / SCREEN_PIXEL_SIZE.x * 2.0943951);
	COLOR = vec4(source * (0.985 + line * 0.015 + mask * 0.005), 1.0);
}
