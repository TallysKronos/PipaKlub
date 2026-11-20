shader_type canvas_item;

uniform vec4 ink : source_color = vec4(0.11, 0.08, 0.20, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 sprite = COLOR;
	COLOR = vec4(mix(sprite.rgb, ink.rgb, strength), sprite.a);
}
