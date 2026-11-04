shader_type canvas_item;

uniform bool arena = false;

float hash_tile(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

uniform float elevation = 0.0;
varying vec2 grid_point;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	grid_point = vec2(world.x / 64.0, -world.x / 64.0) + (world.y + elevation) / 32.0;
}

float meadow_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 blend = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	return mix(
		mix(hash_tile(cell), hash_tile(cell + vec2(1.0, 0.0)), blend.x),
		mix(hash_tile(cell + vec2(0.0, 1.0)), hash_tile(cell + vec2(1.0, 1.0)), blend.x),
		blend.y);
}

float paved_corner(vec2 p) {
	float lane = abs(p.x - 24.5 - sin(p.y * .39) * .64) - 2.45;
	float recess = length((p - vec2(18.8, 21.4)) * vec2(.83, 1.0)) - 3.2;
	float court = length((p - vec2(24.5, 13.8)) * vec2(.85, 1.0)) - 6.1;
	return step(min(lane, arena ? court : recess), 0.0);
}

// Four shared corner labels encode the 16 Wang cases. Bilinear coverage
// reconstructs each case, including both diagonal saddles, with matching edges.
float wang_paving(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	float top = mix(paved_corner(cell), paved_corner(cell + vec2(1.0, 0.0)), local.x);
	float bottom = mix(paved_corner(cell + vec2(0.0, 1.0)), paved_corner(cell + vec2(1.0)), local.x);
	return mix(top, bottom, local.y);
}

void fragment() {
	vec2 p = grid_point;
	float wobble = sin(p.x * 2.3 + p.y * 1.5) * .15 + sin(p.y * 5.1) * .055;
	float ring = length((p - vec2(24.5, 13.8)) * vec2(.85, 1.0));
	float coverage = wang_paving(p);
	vec2 block = p * vec2(1.30, 2.05);
	block.x += mod(floor(block.y), 2.0) * .5;
	vec2 offset = fract(block) - .5;
	float joint = .5 - max(abs(offset.x), abs(offset.y));
	float wear = hash_tile(floor(block));
	vec3 sand = mix(vec3(.59,.47,.34), vec3(.68,.55,.39), .5 + wobble);
	vec3 grass = mix(vec3(.37,.43,.23), vec3(.49,.51,.29), .5 + wobble);
	vec2 patch = floor(p * 2.4);
	float meadow = smoothstep(.27, .75, meadow_noise(p * 1.6));
	grass = mix(grass, vec3(.29,.37,.20), meadow * .43);
	vec2 blade = fract(p * 2.4) - vec2(.53,.51);
	float tuft = 1.0 - smoothstep(.74, 1.0, length((blade + vec2(blade.y * .30, 0.0)) * vec2(23.0, 7.0)));
	grass = mix(grass, vec3(.29,.37,.19), tuft * step(.57,hash_tile(patch + 21.0)) * .48);
	float verge = 1.0 - smoothstep(.02, .32, coverage + wobble * .15);
	vec3 ground = mix(sand, grass, verge);
	vec3 stone = mix(vec3(.69,.60,.45), vec3(.79,.71,.55), wear);
	stone = mix(vec3(.43,.36,.27), stone, smoothstep(.016, .052, joint));
	stone += .045 * (1.0 - smoothstep(.055,.105, offset.y + .5)) * step(.053,joint);
	float rim = arena ? 1.0 - smoothstep(.09,.19,abs(ring - 5.42)) : 0.0;
	stone = mix(stone, vec3(.55,.45,.32), rim * .72);
	COLOR = vec4(mix(ground, stone, smoothstep(.46, .55, coverage + wobble * .15)),1.0);
}

