shader_type canvas_item;
render_mode unshaded;
// Separate static R=shore foam and A=terrain mask. Never scroll alpha.
uniform sampler2D shore_texture : filter_nearest;
uniform sampler2D surface_texture : source_color, repeat_enable, filter_linear;
uniform vec2 flow_direction = vec2(0.0,1.0);
uniform float cycle_seconds = 4.0;
uniform float preview_time = -1.0;
uniform float ripple_strength = 0.014;
// Illustrated sheets keep their drawn proportions in screen space. Existing
// isometric water atlases retain the original projection by default.
uniform bool screen_space_surface = false;
varying vec2 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment(){
    vec4 mask=texture(shore_texture,UV);
    float t=(preview_time>=0.0 ? preview_time : TIME)/cycle_seconds;
    vec2 p=vec2(world_position.x/64.0+world_position.y/32.0,world_position.y/32.0-world_position.x/64.0)/4.0;
    if(screen_space_surface){ p=world_position/512.0; }
    vec2 ripple=ripple_strength*vec2(sin(t*6.283185+p.y*6.283185),cos(t*6.283185+p.x*6.283185));
    vec3 water=texture(surface_texture,p-flow_direction*t+ripple).rgb;
    float foam=mask.r*(0.62+0.12*sin(t*6.283185+p.x*8.0));
    COLOR=vec4(mix(water,vec3(0.81,0.96,0.91),foam),mask.a);
}
