shader_type canvas_item;
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
void fragment(){
 vec4 tex=texture(TEXTURE,UV);
 if(tex.a<0.88){discard;}
 COLOR=vec4(tex.rgb,smoothstep(0.88,0.98,tex.a))*vertex_tint;
}
