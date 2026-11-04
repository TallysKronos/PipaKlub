shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
uniform sampler2D sand_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D earth_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D stone_texture : source_color, repeat_enable, filter_linear;
uniform bool show_masks = false;
uniform bool show_geometry = false;
varying vec2 cell;
varying vec2 dune_info;
void vertex() {
 cell = UV;
 dune_info = COLOR.rg;
}
void fragment() {
 vec2 uv = fract(cell/8.0);
 vec3 sand = texture(sand_texture,uv).rgb;
 vec3 earth = mix(texture(earth_texture,uv).rgb,vec3(0.78,0.65,0.44),0.18);
 vec3 stone = mix(texture(stone_texture,uv).rgb,vec3(0.74,0.62,0.43),0.75);
 float center = 7.1+sin(cell.y*0.55)*0.75;
 float earth_weight = terrain_blend(abs(cell.x-center)-0.85,cell,0.30,0.12);
 float stone_distance = min(length((cell-vec2(2.8,7.2))*vec2(0.85,1.0))-1.35,
                            length((cell-vec2(11.4,3.0))*vec2(0.8,1.1))-1.2);
 float stone_weight = terrain_blend(stone_distance,cell+vec2(6.2),0.25,0.12);
 vec3 color = mix(mix(sand,earth,earth_weight),stone,stone_weight);
 // Three deliberate lighting bands on real slopes, rather than a painted hill.
 float slope_light = dune_info.y<0.43 ? 0.93 : (dune_info.y>0.57 ? 1.04 : 1.0);
 color *= slope_light;
 if (show_masks) { color = mix(mix(vec3(0.84,0.72,0.39),vec3(0.65,0.34,0.18),earth_weight),vec3(0.39,0.46,0.52),stone_weight); }
 if (show_geometry) { color = dune_info.x<0.22 ? vec3(0.40,0.49,0.47) : (dune_info.x<0.56 ? vec3(0.66,0.67,0.47) : vec3(0.91,0.77,0.42)); }
 COLOR = vec4(color,1.0);
}
