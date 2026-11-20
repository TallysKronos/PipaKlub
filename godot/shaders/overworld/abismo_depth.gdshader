shader_type canvas_item;
render_mode unshaded;
// Camada de fundo do mar sobre o mapa (abaixo da HUD): feixes de luz vindos da superfície,
// partículas de "neve marinha" e escurecimento pela profundidade (0 raso … 3 fundo).
uniform float depth = 0.0;
uniform float still = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment() {
	float t = TIME * (1.0 - still);
	vec2 uv = UV;
	// Feixes inclinados, mais fortes no alto da tela e mais fracos com a profundidade.
	float x = uv.x + uv.y * 0.35;
	float rays = 0.0;
	for (int k = 0; k < 4; k++) {
		float f = float(k);
		rays += smoothstep(0.035, 0.0, abs(fract(x * (1.3 + f * 0.37) + sin(t * 0.21 + f * 1.7) * 0.06 + f * 0.27) - 0.5) - 0.012);
	}
	rays *= (1.0 - uv.y) * (1.0 - depth * 0.22) * 0.075;
	// Neve marinha: grãos claros que descem devagar.
	vec2 grid = vec2(uv.x * 64.0, uv.y * 36.0 - t * 0.35);
	vec2 cell = floor(grid);
	float spark = step(0.985, hash(cell)) * smoothstep(0.32, 0.0, length(fract(grid) - 0.5 - (hash(cell + 3.1) - 0.5) * 0.4));
	// Profundidade: azul que escurece nas bordas e com o nível do mapa.
	float vignette = smoothstep(0.35, 1.05, length((uv - vec2(0.5, 0.45)) * vec2(1.1, 1.35)));
	vec3 deep = mix(vec3(0.02, 0.18, 0.28), vec3(0.0, 0.05, 0.12), clamp(depth / 3.0, 0.0, 1.0));
	float shade = 0.10 + depth * 0.07 + vignette * (0.28 + depth * 0.10);
	vec3 light = vec3(0.70, 0.95, 1.0);
	float glow = rays + spark * 0.35;
	float alpha = clamp(shade + glow, 0.0, 0.75);
	COLOR = vec4((deep * shade + light * glow) / max(alpha, 0.001), alpha);
}
