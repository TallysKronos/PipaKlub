shader_type canvas_item;
uniform float detail_strength = 0.20;
uniform bool floor_mode = false;
uniform sampler2D masks;
uniform vec2 map_size=vec2(48.0,40.0);
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
void fragment(){
 vec2 at=UV*vec2(textureSize(TEXTURE,0));
 vec2 projected=vec2((at.x-at.y)*32.0,(at.x+at.y)*16.0);
 vec4 tex=texture(TEXTURE,floor_mode?projected*.8/vec2(textureSize(TEXTURE,0)):UV);
 vec3 base=vec3(0.69,0.68,0.61);
 if(floor_mode){
  float road=texture(masks,at/map_size).r;
  base=mix(vec3(.74,.73,.66),vec3(.48,.51,.49),smoothstep(.1,.9,road));
 }
 COLOR=vec4(mix(base,tex.rgb,detail_strength),tex.a)*vertex_tint;
}
