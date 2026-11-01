shader_type canvas_item;
uniform sampler2D masks : filter_linear;
uniform sampler2D frozen_mask : filter_linear;
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 map_size=vec2(56.,48.);
varying vec2 world;
vec2 hash2(vec2 p){return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);}
// Stable, flat-colour ice plates. Continuous map coordinates keep cracks joined across tiles.
vec2 plates(vec2 p){
 vec2 cell=floor(p),f=fract(p);float first=8.,second=8.,shade=0.;
 for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
  vec2 offset=vec2(float(x),float(y)),jitter=hash2(cell+offset);
  float d=length(offset+.2+jitter*.6-f);
  if(d<first){second=first;first=d;shade=jitter.x;}else if(d<second){second=d;}
 }
 return vec2(second-first,shade);
}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){
 vec4 m=texture(masks,UV/map_size);
 float frozen=texture(frozen_mask,UV/map_size).r;
 float grain=texture(noise_texture,world*.0018).g;
 vec3 snow=mix(vec3(.79,.88,.96),vec3(.96,.98,1.),smoothstep(.15,.85,grain));
 vec3 packed=vec3(.64,.78,.88)*mix(.97,1.03,grain);
 snow=mix(snow,packed,smoothstep(.12,.9,m.r)*.68);
 float wind=sin(world.x*.012+world.y*.029+grain*.9)*.5+.5;
 snow+=vec3(.025)*smoothstep(.77,.98,wind);
 snow=mix(snow,vec3(.49,.66,.80),smoothstep(.12,.8,m.g)*.5);
 snow=mix(snow,vec3(.60,.76,.89),smoothstep(.18,.82,m.a)*.48);
 vec2 warp=.13*vec2(sin(UV.y*1.1),sin(UV.x*.9));
 vec2 plate=plates(UV*.38+warp);
 vec3 lake=mix(vec3(.48,.73,.86),vec3(.61,.82,.93),smoothstep(.2,.8,plate.y));
 lake=mix(lake,vec3(.16,.40,.63),(1.-smoothstep(.008,.023,plate.x))*.6);
 float frost=(1.-smoothstep(.025,.055,plate.x))*smoothstep(.013,.025,plate.x);
 lake=mix(lake,vec3(.84,.95,1.),frost*.58);
 float interior=smoothstep(.44,.72,frozen);
 float coast=smoothstep(.20,.44,frozen)*(1.-smoothstep(.44,.64,frozen));
 vec3 col=mix(snow,lake,interior);
 col=mix(col,vec3(.94,.98,1.),coast*.65);
 COLOR=vec4(col*COLOR.rgb,1.);
}
