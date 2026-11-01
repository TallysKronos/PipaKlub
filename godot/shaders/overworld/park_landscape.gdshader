shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
uniform sampler2D grass_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D earth_texture : source_color, repeat_enable, filter_linear;
uniform vec4 paths[32];
uniform int path_count = 0;
uniform vec4 habitats[16];
uniform int habitat_count = 0;
uniform bool geometry_only = false;
uniform bool veredas = false;
float rounded_box(vec2 p, vec4 box) {
 vec2 q = abs(p-box.xy)-max(box.zw-vec2(12.0),vec2(0.0));
 return length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-12.0;
}
void fragment() {
 vec2 p=UV;
 vec2 cell=veredas ? vec2(p.x/64.0+p.y/32.0,p.y/32.0-p.x/64.0) : p/39.0;
 float distance_to_path=10000.0;
 for(int i=0;i<32;i++){if(i>=path_count)break;distance_to_path=min(distance_to_path,rounded_box(p,paths[i]));}
 float distance_to_grass=10000.0;
 for(int i=0;i<16;i++){if(i>=habitat_count)break;distance_to_grass=min(distance_to_grass,rounded_box(p,habitats[i]));}
 float path_weight=terrain_blend(distance_to_path/39.0,cell,.22,.10);
 float tall_weight=terrain_blend(distance_to_grass/39.0,cell,.18,.08);
 vec3 grass=texture(grass_texture,fract(cell/8.0)).rgb;
 vec3 earth=texture(earth_texture,fract(cell/8.0)).rgb;
 grass=mix(grass,grass*vec3(.66,.82,.74),tall_weight*.55);
 COLOR=vec4(mix(grass,earth,path_weight),1.0);
 if(geometry_only)COLOR=vec4(mix(vec3(.45,.64,.53),vec3(.83,.66,.40),path_weight),1.0);
}
