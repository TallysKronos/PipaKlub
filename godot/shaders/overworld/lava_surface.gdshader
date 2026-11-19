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
 float phase = animation_time * .78539816;
 vec2 warp = vec2(sin(cell.y*2.0+phase),cos(cell.x*1.8+phase))*.14;
 vec2 uv = (cell+warp)/4. + vec2(0.,-animation_time/8.);
 vec3 source = texture(lava_texture,uv).rgb;
 float heat = dot(source,vec3(.22,.69,.09));
 float bank = abs(cell.x-(7.7+sin(cell.y*.55)*1.15));
 vec3 glow = mix(vec3(.55,.155,.145),vec3(.91,.345,.145),smoothstep(.16,.55,heat));
 glow = mix(glow,vec3(1.,.675,.29),smoothstep(.55,.78,heat)*.85);
 glow *= 1.-.20*smoothstep(.95,1.72,bank);
 COLOR = vec4(glow,1.);
}
