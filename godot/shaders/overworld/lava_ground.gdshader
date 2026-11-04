shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
uniform sampler2D basalt_texture : source_color, repeat_enable, filter_linear;
uniform bool show_masks = false;
varying vec2 floor_position;
void vertex() { floor_position = VERTEX; }
void fragment() {
 vec2 cell = terrain_cell(floor_position);
 vec3 rock = texture(basalt_texture,fract(cell/8.0)).rgb;
 float center = 7.7 + sin(cell.y*0.55)*1.15;
 float width = 1.55+sin(cell.y*1.2)*0.18;
 float shore_distance = abs(cell.x-center)-width;
 float crust = terrain_blend(shore_distance-0.42,cell,0.18,0.10);
 vec3 crust_color = mix(rock,vec3(0.48,0.24,0.22),0.62);
 COLOR = vec4(show_masks ? mix(vec3(0.27,0.39,0.47),vec3(0.76,0.34,0.16),crust) : mix(rock,crust_color,crust),1.0);
}
