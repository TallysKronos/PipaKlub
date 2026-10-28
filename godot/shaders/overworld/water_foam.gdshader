shader_type canvas_item;
render_mode unshaded;
uniform float preview_time = -1.0;
uniform float cycle_seconds = 4.0;
uniform float strength = 0.01;
void fragment(){
    float t=fract((preview_time>=0.0 ? preview_time : TIME)/cycle_seconds);
    vec2 uv=UV+strength*vec2(sin(UV.y*10.0+t*6.283185),sin(UV.x*8.0+t*6.283185));
    vec4 color=texture(TEXTURE,uv);
    COLOR=vec4(color.rgb,color.a*(0.88+0.12*sin(t*12.56637)));
}
