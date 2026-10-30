shader_type canvas_item;
render_mode unshaded;
uniform sampler2D grass_paint : source_color, repeat_enable, filter_linear;
uniform sampler2D dirt_paint : source_color, repeat_enable, filter_linear;
uniform sampler2D square_paint : source_color, repeat_enable, filter_linear;
uniform sampler2D grass_details : source_color, repeat_enable, filter_linear;
uniform sampler2D dirt_details : source_color, repeat_enable, filter_linear;
uniform float details_strength = 0.82;
uniform bool geometry_only = false;
uniform float painting_strength : hint_range(0.0,1.0) = 0.28;
uniform vec2 mask_origin;
uniform vec2 mask_extent;
uniform vec2 pilot_min;
uniform vec2 pilot_max;
void fragment() {
    vec3 mask=texture(TEXTURE,UV).rgb;
    // Use the original ground plane, so raising the terrain does not shift
    // the painting's phase between ramp, landing and connected flat cells.
    vec2 cell=mask_origin+UV*mask_extent;
    vec2 ground_position=vec2((cell.x-cell.y)*32.0,(cell.x+cell.y)*16.0);
    vec2 phase=vec2(1.0)-abs(mod(ground_position/448.0,vec2(2.0))-vec2(1.0));
    vec3 grass=mix(vec3(0.53,0.66,0.33),texture(grass_paint,phase).rgb,painting_strength);
    vec2 grass_phase=vec2(1.0)-abs(mod((ground_position+vec2(29.0,211.0))/576.0,vec2(2.0))-vec2(1.0));
    grass=mix(grass,texture(grass_details,grass_phase).rgb,0.84);
    grass*=mix(1.0,0.92,smoothstep(0.2,0.8,mask.b));
    vec3 dirt=mix(vec3(0.83,0.69,0.45),texture(dirt_paint,phase).rgb,painting_strength);
    // Shared world-space painting crosses cell edges and ramps without restarting.
    vec2 detail_phase=vec2(1.0)-abs(mod((ground_position+vec2(137.0,83.0))/512.0,vec2(2.0))-vec2(1.0));
    dirt=mix(dirt,texture(dirt_details,detail_phase).rgb,details_strength);
    vec3 square=mix(vec3(0.90,0.84,0.68),texture(square_paint,phase).rgb,0.65);
    if (geometry_only) { grass=vec3(0.53,0.66,0.33); dirt=vec3(0.83,0.69,0.45); square=vec3(0.90,0.84,0.68); }
    vec3 result=mix(grass,dirt,smoothstep(0.38,0.62,mask.r));
    result=mix(result,square,smoothstep(0.38,0.62,mask.g));
    vec2 edge=min(cell-pilot_min,pilot_max-cell);
    // Fade only the outside of this opt-in experiment into the unchanged scene.
    // The fully opaque center is the actual material/contour proposal.
    float coverage=smoothstep(0.0,1.4,min(edge.x,edge.y));
    COLOR=vec4(result,coverage);
}
