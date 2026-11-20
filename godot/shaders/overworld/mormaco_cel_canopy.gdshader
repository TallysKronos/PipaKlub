shader_type canvas_item;
render_mode unshaded;
uniform float phase=0.0;
void fragment() {
    float frame=floor(TIME*6.0)/6.0;
    float crown=pow(1.0-UV.y,3.0);
    float displacement=floor(sin(frame*1.6+phase)*1.8*crown);
    COLOR=texture(TEXTURE,UV+vec2(displacement,0.0)*TEXTURE_PIXEL_SIZE);
}
