shader_type canvas_item;
render_mode unshaded;

uniform sampler2D sprite_texture : filter_nearest, repeat_disable;
uniform vec4 source_rect;
uniform vec4 body_rect;
uniform vec2 flip_axis = vec2(1.0);
uniform float stroke_width = 1.5;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

float sprite_alpha(vec2 point) {
	vec2 relative = (point - body_rect.xy) / body_rect.zw;
	if (any(lessThan(relative, vec2(0.0))) || any(greaterThanEqual(relative, vec2(1.0)))) {
		return 0.0;
	}
	relative = (relative - vec2(0.5)) * flip_axis + vec2(0.5);
	vec2 pixel = clamp(floor(relative * source_rect.zw), vec2(0.0), source_rect.zw - vec2(1.0));
	vec2 uv = (source_rect.xy + pixel + vec2(0.5)) / vec2(textureSize(sprite_texture, 0));
	return texture(sprite_texture, uv).a;
}

void fragment() {
	float edge = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.78539816;
		vec2 direction = vec2(cos(angle), sin(angle));
		edge = max(edge, sprite_alpha(local_position + direction * stroke_width));
	}
	float body = sprite_alpha(local_position);
	COLOR = vec4(vec3(1.0), COLOR.a * step(0.35, edge) * (1.0 - step(0.35, body)));
}
