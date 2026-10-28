shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
uniform sampler2D lava_texture : source_color, repeat_enable, filter_linear;
uniform float animation_time = 0.0;
varying vec2 floor_position;
void vertex() { floor_position = VERTEX; }
void fragment() {
 vec2 cell = terrain_cell(floor_position);
 // Integer texture travel per eight-second cycle, no TIME clock or moving banks.
 vec2 uv = fract(cell/6.0-vec2(0.0,animation_time/8.0));
 vec3 color = texture(lava_texture,uv).rgb;
 float pulse = 0.985+0.015*sin(animation_time*1.57079632679);
 COLOR = vec4(color*pulse,1.0);
}
