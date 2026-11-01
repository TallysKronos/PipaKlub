shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/overworld/terrain_transition.gdshaderinc"
uniform sampler2D grass_texture : source_color, repeat_enable, filter_linear;
uniform sampler2D earth_texture : source_color, repeat_enable, filter_linear;
uniform vec4 paths[64];
uniform int path_count=0;
uniform bool geometry_only=false;
void fragment(){
 vec2 p=UV;
 vec2 cell=vec2(p.x/64.0+p.y/32.0,p.y/32.0-p.x/64.0);
 float d=10000.0;
 for(int i=0;i<64;i++){
  if(i>=path_count)break;
  vec2 a=paths[i].xy,b=paths[i].zw,v=b-a;
  float t=clamp(dot(p-a,v)/max(dot(v,v),.001),0.0,1.0);
  d=min(d,length(p-a-v*t)-18.0);
 }
 float blend=terrain_blend(d/39.0,cell,.18,.12);
 vec3 grass=texture(grass_texture,fract(cell/8.0)).rgb;
 vec3 earth=texture(earth_texture,fract(cell/8.0)).rgb;
 COLOR=vec4(mix(grass,earth,blend),1.0);
 if(geometry_only)COLOR=vec4(mix(vec3(.44,.63,.48),vec3(.80,.66,.43),blend),1.0);
}
