shader_type canvas_item;
uniform float sway=0.;
uniform float phase=0.;
uniform bool still=false;
varying vec4 vertex_tint;
void vertex(){
 vertex_tint=COLOR;
 float t=still?0.:TIME;
 VERTEX.x+=sin(t*1.1+phase+UV.y*2.)*sway*pow(max(0.,.94-UV.y),2.);
}
void fragment(){
 vec4 tex=texture(TEXTURE,UV);if(tex.a<.88){discard;}
 COLOR=vec4(tex.rgb,smoothstep(.88,.98,tex.a))*vertex_tint;
}
