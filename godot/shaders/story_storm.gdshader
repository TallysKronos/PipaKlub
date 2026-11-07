shader_type canvas_item;
uniform bool motion = true;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float time = motion ? TIME : 0.0;
	vec2 rain = vec2(UV.x + UV.y * .26, UV.y) * vec2(113.0, 17.0);
	float column = floor(rain.x);
	float seed = fract(sin(column * 29.71) * 31415.91);
	float drop = fract(rain.y - time * (13.0 + seed * 5.0) + seed);
	float streak = (1.0 - smoothstep(.035, .11, abs(fract(rain.x) - .5)))
		* smoothstep(.73, .84, drop) * (1.0 - smoothstep(.89, .98, drop));
	float flash = motion ? max(0.0, 1.0 - abs(mod(time, 7.0) - 5.0) * 6.0) : 0.0;
	COLOR = vec4(.66, .79, .94, (streak * .28 + flash * .12) * strength);
}
