shader_type canvas_item;
render_mode unshaded;
float ridge(float x) {
 return .54*abs(fract(x)-.5)+.28*abs(fract(x*2.7+.23)-.5)+.15*abs(fract(x*5.3)-.5);
}
void fragment(){
 vec2 p=UV;
 vec3 sky=mix(vec3(.145,.122,.172),vec3(.36,.217,.224),smoothstep(.05,.94,p.y));
 float distant=.24+ridge(p.x*1.7)*.71;
 float middle=.47+ridge(p.x*2.1+.42)*.7;
 float near_line=.70+ridge(p.x*1.3+.7)*.50;
 sky=mix(sky,vec3(.235,.167,.205),smoothstep(distant,distant+.005,p.y));
 sky=mix(sky,vec3(.185,.143,.184),smoothstep(middle,middle+.004,p.y));
 sky=mix(sky,vec3(.133,.112,.154),smoothstep(near_line,near_line+.003,p.y));
 COLOR=vec4(sky,1.);
}
