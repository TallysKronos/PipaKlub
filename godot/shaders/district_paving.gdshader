shader_type canvas_item;
uniform int district;
uniform bool rooftop = false;
float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * vec2(textureSize(TEXTURE, 0));
	vec2 units = vec2(2.0, 3.0);
	vec3 light = vec3(.79, .72, .58);
	vec3 dark = vec3(.53, .49, .40);
	if (district == 1) {
		units = vec2(.85, .85);
		light = vec3(.79, .77, .70);
		dark = vec3(.68, .66, .60);
	} else if (district == 2) {
		units = vec2(.46, .64);
		light = vec3(.62, .67, .66);
		dark = vec3(.50, .55, .54);
	} else if (district == 3) {
		units = vec2(3.6, .65);
		light = vec3(.65, .48, .32);
		dark = vec3(.35, .28, .21);
	}
	vec2 pattern = p * units;
	if (district == 0 || district == 3) pattern.y += mod(floor(pattern.x), 2.0) * .5;
	vec2 edge = min(fract(pattern), 1.0 - fract(pattern));
	float seam = smoothstep(.012, .055, min(edge.x, edge.y));
	float wear = (grain(floor(pattern)) - .5) * .12;
	if (district == 1) wear *= .45;
	vec3 color = mix(dark, light + wear, seam);
	if (district == 2) {
		float cargo_lane = 1.0 - smoothstep(.045,.087,abs(abs(p.x - 24.5) - 2.8));
		color = mix(color, vec3(.77,.65,.40), cargo_lane * step(.34,fract(p.y*.56)));
	}
	if (district == 3) {
		float board = fract(pattern.x);
		float fine = sin(board * 72.0 + sin(p.y * 3.0) * .55);
		color += fine * .013 * seam;
	}
	if (district == 0) {
		float band = smoothstep(.38, .51, sin(p.x*.62 + sin(p.y*.45)*1.5));
		color *= mix(.77, 1.0, band);
	}
	if (rooftop) {
		vec2 local = abs(p - vec2(24.0, 6.7)) / vec2(4.0, 2.35);
		float rim = max(local.x, local.y);
		float inlay = smoothstep(.88, .92, rim) * (1.0 - smoothstep(.96, 1.0, rim));
		color = mix(color, vec3(.35, .49, .51), inlay * .85);
	}
	COLOR = vec4(color, 1.0);
}
