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
uniform bool swamp = false;
uniform bool boss_arena = false;
uniform bool mountain = false;
uniform sampler2D terrain_mask : filter_nearest;
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
	if(mountain){
		float rock=texture(terrain_mask,UV/map_size).r;
		vec3 turf=mix(vec3(.34,.43,.27),vec3(.44,.50,.33),patch);
		vec3 trail=mix(vec3(.64,.55,.38),vec3(.76,.67,.47),smoothstep(.3,.75,edge));
		turf *= mix(.90,1.08,grain);
        turf=mix(turf,turf*vec3(.72,.89,.67),smoothstep(.12,.8,m.a));
        trail *= mix(.86,1.09,texture(dirt,tuv*1.15).g);
        col=mix(turf,trail,path);
		col=mix(col,mix(vec3(.30,.36,.37),vec3(.42,.47,.45),patch),rock);
	}
	if(swamp){
		float lum=dot(col,vec3(.299,.587,.114));
		vec3 moss=mix(vec3(.20,.29,.15),vec3(.43,.49,.28),clamp(lum,0.,1.));
		vec3 mud=mix(vec3(.32,.26,.17),vec3(.64,.55,.36),clamp(lum,0.,1.));
		col=mix(moss,mud,path);
		if(boss_arena)col*=vec3(.72,.79,.82);
	}
	COLOR = vec4(col * COLOR.rgb, 1.0);
}
