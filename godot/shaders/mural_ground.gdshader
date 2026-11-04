shader_type canvas_item;
uniform sampler2D masks : filter_linear;
uniform sampler2D rock_mask : filter_nearest;
uniform sampler2D stone : repeat_enable, filter_linear;
uniform sampler2D earth : repeat_enable, filter_linear;
uniform vec2 map_size=vec2(40.);
varying vec2 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){
 vec4 m=texture(masks,UV/map_size);
 float rock=texture(rock_mask,UV/map_size).r;
 float grain=dot(texture(stone,world*.002).rgb,vec3(.3,.5,.2));
 vec3 floor_tone=mix(vec3(.40,.34,.25),vec3(.56,.46,.32),smoothstep(.1,.85,m.r));
 floor_tone*=mix(.8,1.16,texture(earth,world*.0025).g);
 floor_tone=mix(floor_tone,vec3(.25,.21,.18),smoothstep(.2,.8,m.a)*.5);
 vec3 ceiling=texture(stone,world*.0018).rgb*vec3(.47,.40,.32);
 ceiling=mix(ceiling,vec3(.12,.10,.09),.45);
 COLOR=vec4(mix(floor_tone,ceiling,rock)*COLOR.rgb,1.);
}
