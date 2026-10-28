shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
// One opaque ground surface: the material boundary is not a geometry seam.
uniform sampler2D stone_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D earth_texture : source_color, repeat_enable, filter_linear;
uniform vec4 stone_tone : source_color = vec4(0.16,0.24,0.29,1.0);
uniform vec4 earth_tone : source_color = vec4(0.41,0.39,0.35,1.0);
uniform float surface_contrast = 0.72;
uniform float cells_per_repeat = 8.0;
uniform float path_center = 4.5;
uniform float path_start = 2.5;
uniform float path_end = 10.5;
uniform float half_width = 0.92;
uniform float edge_variation = 0.32;
uniform float blend_width = 0.12;
varying vec2 floor_position;

void vertex() { floor_position = VERTEX; }
void fragment() {
 // Project back into tile space; mask stays anchored when the scene is moved.
 vec2 cell = terrain_cell(floor_position);
 vec2 uv = fract(cell/cells_per_repeat);
 vec3 stone = mix(stone_tone.rgb,texture(stone_texture,uv).rgb,surface_contrast);
 vec3 earth = mix(earth_tone.rgb,texture(earth_texture,uv).rgb,surface_contrast);
 float center = path_center + sin(cell.y*1.3)*0.14;
 vec2 relative = vec2(cell.x-center,cell.y-clamp(cell.y,path_start,path_end));
 float distance_to_edge = length(relative)-half_width;
 float earth_weight = terrain_blend(distance_to_edge,cell,edge_variation,blend_width);
 COLOR = vec4(mix(stone,earth,earth_weight),1.0);
}
