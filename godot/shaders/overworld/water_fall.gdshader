shader_type canvas_item;
render_mode unshaded;
uniform sampler2D surface_texture : source_color, repeat_enable, filter_linear;
uniform float flow_speed = 1.0;
uniform float cycle_seconds = 4.0;
uniform float preview_time = -1.0;
void fragment(){
    float t=fract((preview_time>=0.0 ? preview_time : TIME)/cycle_seconds);
    vec2 p=UV;
    p.y-=t*flow_speed;
    p.x+=0.008*sin(UV.y*8.0+t*6.283185);
    vec3 water=texture(surface_texture,p).rgb;
    COLOR=vec4(water,1.0);
}
