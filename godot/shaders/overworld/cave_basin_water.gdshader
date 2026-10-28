shader_type canvas_item;
render_mode unshaded;
uniform sampler2D surface_texture : source_color, repeat_enable, filter_linear;
uniform float preview_time = -1.0;
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
    float t=fract((preview_time>=0.0 ? preview_time : TIME)/4.0);
    vec2 p=vec2(world_position.x/64.0+world_position.y/32.0,world_position.y/32.0-world_position.x/64.0)/4.0;
    p+=0.014*vec2(sin(t*6.283185+p.y*6.283185),cos(t*6.283185+p.x*6.283185));
    COLOR=vec4(texture(surface_texture,p).rgb,1.0);
}
