shader_type canvas_item;
uniform sampler2D masks : filter_linear;
uniform sampler2D sand_mask : filter_linear;
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 map_size=vec2(56.,48.);
uniform bool still=false;
varying vec2 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){
 float t=still?0.:TIME*.17;
 vec4 m=texture(masks,UV/map_size);
 float sand=texture(sand_mask,UV/map_size).r;
 float grain=texture(noise_texture,world*.0017).g;
 vec3 bed=mix(vec3(.15,.46,.48),vec3(.26,.60,.55),smoothstep(.2,.85,grain));
 bed=mix(bed,vec3(.32,.65,.59),smoothstep(.2,.8,m.r)*.75);
 bed=mix(bed,vec3(.46,.73,.65),smoothstep(.2,.8,sand)*.72);
 bed=mix(bed,vec3(.06,.24,.33),smoothstep(.15,.8,m.g)*.65);
 bed=mix(bed,vec3(.15,.36,.34),smoothstep(.2,.8,m.a)*.6);
 vec2 p=world*.008+vec2(sin(world.y*.005+t),cos(world.x*.006-t))*.65;
 float ripple=sin(p.x*1.31+p.y*.49+t)*sin(p.y*1.72-p.x*.32-t*.8);
 float caustic=pow(max(0.,1.-abs(ripple)*9.),3.);
 bed+=vec3(.10,.18,.16)*caustic*.23;
 COLOR=vec4(bed*COLOR.rgb,1.);
}
