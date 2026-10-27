shader_type canvas_item;
render_mode unshaded;

// World-space UVs keep the painting continuous across all navigation cells.
uniform sampler2D surface_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform float repeat_cells = 8.0;
uniform vec4 surface_tint : source_color = vec4(1.0);
varying vec2 ground_uv;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
	ground_uv = vec2(world.x/64.0+world.y/32.0,world.y/32.0-world.x/64.0);
}

void fragment() {
	vec3 color = texture(surface_tex,ground_uv/repeat_cells).rgb*surface_tint.rgb;

	COLOR = vec4(color,1.0);
}
