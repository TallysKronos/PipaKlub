shader_type canvas_item;
// Chão do bioma "floresta" (REGIOES-E-PARTES.md, seção 6): grama em dois tons com manchas grandes,
// chão sombreado sob a mata, trilha de terra com borda orgânica e grama escurecida junto dela.
// UV = coordenadas do mapa (u, v); as texturas usam a posição na tela, contínuas entre células.
uniform sampler2D masks : filter_linear; // R terra, G mata, B manchas, A mato
uniform sampler2D grass_a : repeat_enable, filter_linear;
uniform sampler2D grass_b : repeat_enable, filter_linear;
uniform sampler2D dirt : repeat_enable, filter_linear;
uniform vec2 map_size = vec2(1.0);
uniform float tex_scale = 0.0026;
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 m = texture(masks, UV / map_size);
	vec2 tuv = world * tex_scale;
	float grain = texture(grass_a, tuv * 3.7 + vec2(.21, .63)).g;
	float patch = smoothstep(.40, .60, m.b + (grain - .5) * .10);
	vec3 grass = mix(texture(grass_a, tuv).rgb * vec3(1.07, 1.05, .90), texture(grass_b, tuv + vec2(.37, .11)).rgb * vec3(.84, .95, .86), patch);
	// Mato de encontro: grama mais funda e saturada.
	grass = mix(grass, grass * vec3(.80, .98, .78), smoothstep(.10, .85, m.a + (grain-.5)*.12));
	// Sob as copas: chão em sombra profunda e fria.
	grass = mix(grass, grass * vec3(.48, .58, .55), smoothstep(.30, .80, m.g));
	float edge = m.r + (grain - .5) * .26;
	float path = smoothstep(.47, .55, edge);
	float rim = smoothstep(.28, .47, edge) * (1.0 - path);
	grass *= 1.0 - rim * .20;
	vec3 soil = texture(dirt, tuv * 1.15).rgb;
	soil *= mix(.86, 1.04, smoothstep(.55, .85, edge)); // centro da trilha mais claro
	vec3 col = mix(grass, soil, path);
	COLOR = vec4(col * COLOR.rgb, 1.0);
}
