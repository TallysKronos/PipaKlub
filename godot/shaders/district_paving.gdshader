shader_type canvas_item;
uniform int district;
float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * vec2(textureSize(TEXTURE, 0));
	vec2 units = vec2(2.0, 3.0);
	vec3 light = vec3(.79, .72, .58);
	vec3 dark = vec3(.53, .49, .40);
	if (district == 1) {
		units = vec2(.65, .65);
		light = vec3(.79, .77, .68);
		dark = vec3(.55, .55, .51);
	} else if (district == 2) {
		units = vec2(.46, .64);
		light = vec3(.62, .67, .66);
		dark = vec3(.37, .44, .45);
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
	vec3 color = mix(dark, light + wear, seam);
	if (district == 0) {
		float band = smoothstep(.38, .51, sin(p.x*.62 + sin(p.y*.45)*1.5));
		color *= mix(.77, 1.0, band);
	}
	COLOR = vec4(color, 1.0);
}
