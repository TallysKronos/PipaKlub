shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
uniform sampler2D grass_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D earth_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D stone_texture : source_color, repeat_enable, filter_linear;
uniform float edge_variation = 0.32;
uniform float blend_width = 0.12;
uniform float path_width = 0.9;
uniform bool show_masks = false;
varying vec2 floor_position;
void vertex() { floor_position = VERTEX; }
void fragment() {
 vec2 cell = terrain_cell(floor_position);
 vec2 uv = fract(cell/8.0);
 vec3 grass = texture(grass_texture,uv).rgb;
 vec3 earth = texture(earth_texture,uv).rgb;
 vec3 stone = mix(texture(stone_texture,uv).rgb,vec3(0.51,0.55,0.46),0.58);
 float center = 7.2 + sin(cell.y*0.55+0.3)*1.25;
 float path_distance = abs(cell.x-center)-path_width;
 float clearing = length((cell-vec2(7.7,5.4))*vec2(0.85,1.0))-1.55;
 float earth_weight = terrain_blend(min(path_distance,clearing),cell,edge_variation,blend_width);
 float rocky_distance = min(length((cell-vec2(3.2,2.4))*vec2(0.9,1.1))-1.2,
                            length((cell-vec2(11.8,8.5))*vec2(0.8,1.0))-1.35);
 float stone_weight = terrain_blend(rocky_distance,cell+vec2(5.0),edge_variation,blend_width);
 vec3 color = mix(mix(grass,earth,earth_weight),stone,stone_weight);
 if (show_masks) { color = mix(mix(vec3(0.25,0.55,0.25),vec3(0.85,0.55,0.18),earth_weight),vec3(0.35,0.45,0.65),stone_weight); }
 COLOR = vec4(color,1.0);
}
