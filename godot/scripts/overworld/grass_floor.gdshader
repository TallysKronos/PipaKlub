shader_type canvas_item;
// The Polygon2D supplies the exact diamond boundary. Its interior is opaque
// even when fractional camera zoom samples the PNG's transparent staircase.
// RGB outside the PNG diamond is the same neutral lawn colour, not black.
void fragment() {
	COLOR.a = 1.0;
}
