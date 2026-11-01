shader_type canvas_item;
uniform sampler2D masks : filter_linear;
uniform sampler2D frozen_mask : filter_linear;
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 map_size=vec2(44.,40.);
varying vec2 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){
 vec4 m=texture(masks,UV/map_size);
 vec4 ice=texture(frozen_mask,UV/map_size);
 float grain=texture(noise_texture,world*.0018).g;
 vec3 snow=mix(vec3(.78,.88,.96),vec3(.94,.98,1.),smoothstep(.15,.85,grain));
 vec3 packed=vec3(.64,.79,.89)*mix(.94,1.04,grain);
 snow=mix(snow,packed,smoothstep(.12,.9,m.r)*.75);
 float wind=sin(world.x*.019+world.y*.041+grain*.7)*.5+.5;
 snow+=vec3(.02)*smoothstep(.86,.98,wind);
 snow=mix(snow,vec3(.60,.77,.88),smoothstep(.18,.82,m.a)*.45);
 vec3 lake=mix(vec3(.26,.59,.77),vec3(.55,.80,.91),grain);
 COLOR=vec4(mix(snow,lake,smoothstep(.18,.82,ice.r))*COLOR.rgb,1.);
}
