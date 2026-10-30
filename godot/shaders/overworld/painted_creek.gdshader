shader_type canvas_item;
render_mode unshaded;
uniform float motion = 1.0;
uniform float preview_time = -1.0;
void fragment() {
 float t=(preview_time<0.0 ? TIME : preview_time)*0.62831853;
 vec2 ripple=vec2(sin(t+UV.y*68.0),sin(t+UV.x*57.0))*TEXTURE_PIXEL_SIZE*0.45*motion;
 COLOR=texture(TEXTURE,UV+ripple);
}
