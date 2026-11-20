shader_type canvas_item;
// Contorno de 1 texel em volta dos companheiros do overworld (companion_follow.gd): separa a
// silhueta do chão (grama, terra, pedra escura) sem mexer na arte. A cor é um marrom quase
// preto, como a linha das folhas de modelo, e não um preto puro.
uniform vec4 outline_color : source_color = vec4(0.10, 0.07, 0.09, 0.92);
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// COLOR já chega com a textura aplicada; só os texels vazios vizinhos da silhueta mudam.
	if (texture(TEXTURE, UV).a < 0.5 && strength > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float near = 0.0;
		near = max(near, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
		near = max(near, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
		near = max(near, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
		near = max(near, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
		if (near > 0.5) COLOR = vec4(outline_color.rgb, outline_color.a * strength);
	}
}
