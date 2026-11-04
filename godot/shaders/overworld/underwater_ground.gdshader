shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
uniform sampler2D sand_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D rock_texture : source_color, repeat_enable, filter_linear;
uniform float animation_time = 0.0;
uniform bool show_masks = false;
uniform bool effects_enabled = true;
uniform bool use_cell_uv = false;
uniform int ramp_mode = 0;
uniform float layer_height = 0.0;
varying vec2 floor_cell;
void vertex() { floor_cell = use_cell_uv ? UV : terrain_cell(VERTEX); }
void fragment() {
 vec2 cell = floor_cell;
 float elevation = layer_height;
 if (ramp_mode==1) { elevation = 32.0*(7.5-cell.x)/3.0; }
 if (ramp_mode==2) { elevation = -24.0*(cell.y-3.0)/2.5; }
 vec2 uv = fract(cell/8.0);
 float sand_value = dot(texture(sand_texture,uv).rgb,vec3(0.2126,0.7152,0.0722));
 vec3 sand = mix(vec3(0.19,0.34,0.35),vec3(0.39,0.57,0.53),smoothstep(0.18,0.70,sand_value));
 float rock_value = dot(texture(rock_texture,uv).rgb,vec3(0.2126,0.7152,0.0722));
 vec3 rock = mix(vec3(0.10,0.20,0.27),vec3(0.21,0.37,0.42),clamp(rock_value/0.35,0.0,1.0));
 float reef_distance = min(length((cell-vec2(2.8,3.2))*vec2(0.7,0.9))-1.8,
                           length((cell-vec2(11.3,6.1))*vec2(0.7,0.85))-1.8);
 float rock_weight = max(terrain_blend(reef_distance,cell,0.3,0.12),max(elevation,0.0)/32.0*0.65);
 float meadow_distance = min(length((cell-vec2(3.0,8.2))*vec2(0.7,1.1))-1.45,
                             length((cell-vec2(11.1,1.6))*vec2(0.7,1.0))-1.35);
 float meadow_weight = terrain_blend(meadow_distance,cell+vec2(4.0),0.35,0.12);
 vec3 color = mix(mix(sand,rock,rock_weight),vec3(0.14,0.30,0.29),meadow_weight*0.8);
 color *= elevation<0.0 ? mix(vec3(1.0),vec3(0.72,0.86,0.94),-elevation/24.0) : mix(vec3(1.0),vec3(0.90,0.97,1.0),elevation/32.0);
 if (effects_enabled) {
  float t = animation_time*0.78539816339;
  float a = sin(cell.x*2.4+sin(cell.y*1.8+t)*0.9);
  float b = sin(cell.y*2.1+sin(cell.x*1.4-t)*0.7);
  float light = max(smoothstep(0.94,0.995,a),smoothstep(0.94,0.995,b));
  color = mix(color,vec3(0.58,0.79,0.72),light*0.10);
 }
 if (show_masks) { color = mix(mix(vec3(0.62,0.68,0.48),vec3(0.20,0.35,0.48),rock_weight),vec3(0.14,0.38,0.28),meadow_weight); }
 COLOR = vec4(color,1.0);
}
