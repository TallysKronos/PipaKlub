shader_type canvas_item;

uniform vec4 ink : source_color = vec4(0.91, 0.98, 1.0, 1.0);
uniform float light_amount : hint_range(0.0, 1.0);
uniform float coverage : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 sprite = COLOR;
	vec2 local_uv = FRAGCOORD.xy / 12.0;
	vec2 facet = floor(local_uv);
	facet.y += step(1.0, fract(local_uv.x) + fract(local_uv.y)) * 0.5;
	float threshold = fract(sin(dot(facet, vec2(127.1, 311.7))) * 43758.5453);
	float visible_facet = smoothstep(threshold - 0.04, threshold + 0.04, coverage);
	float edge = (1.0 - smoothstep(0.01, 0.13, abs(coverage - threshold))) * (1.0 - step(0.999, coverage));
	COLOR = vec4(mix(sprite.rgb, ink.rgb, max(light_amount, edge)), sprite.a * visible_facet);
}
