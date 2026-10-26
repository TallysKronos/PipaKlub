shader_type canvas_item;

// Vertex colours carry the canonical material at each shared map corner.
// UVs are world u/v: neither the texture nor the joint pattern restarts per cell.
varying vec3 material_weights;

void vertex() {
	material_weights = COLOR.rgb;
}

vec3 surface(sampler2D source_texture, vec2 p, float column) {
	vec2 texel_uv = (fract(p) * 511.0 + 0.5) / 512.0;
	texel_uv.x = (texel_uv.x + column) / 3.0;
	return texture(source_texture, texel_uv).rgb;
}

void fragment() {
	vec2 ground_uv = UV * vec2(3.0, 1.0);
	vec3 grass = surface(TEXTURE, ground_uv, 0.0);
	vec3 stone = surface(TEXTURE, ground_uv, 1.0);
	vec3 earth = surface(TEXTURE, ground_uv, 2.0);
	vec3 weights = max(material_weights, vec3(0.0));
	// A narrow soft transition, with organic variation from the same world
	// texture on both sides of every joint; no floating border decal is used.
	float irregularity = (grass.g-grass.r)*0.18 - 0.01;
	weights.r = max(0.0, weights.r + irregularity*4.0*weights.r*(1.0-weights.r));
	weights = pow(weights, vec3(5.0));
	weights /= max(dot(weights,vec3(1.0)),0.0001);
	COLOR = vec4(grass*weights.r + stone*weights.g + earth*weights.b, 1.0);
}
