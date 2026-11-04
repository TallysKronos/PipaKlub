shader_type canvas_item;
render_mode unshaded;
uniform float wind_strength = 1.4;
void vertex() {
	float root_pin=pow(1.0-UV.y,2.0);
	float phase=MODEL_MATRIX[3].x*0.043+MODEL_MATRIX[3].y*0.017;
	VERTEX.x+=sin(TIME*1.8+phase)*root_pin*wind_strength;
}
