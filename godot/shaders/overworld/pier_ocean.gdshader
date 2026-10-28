shader_type canvas_item;
render_mode unshaded;
uniform float preview_time = 0.0;
varying vec2 plane;
void vertex(){plane=VERTEX;}
void fragment(){
 vec2 p=plane/110.0;
 float band=sin(p.x*.55+p.y*.85)+.45*sin(p.y*1.8-p.x*.3);
 vec3 color=band>.6 ? vec3(.20,.43,.54) : vec3(.18,.40,.52);
 vec2 cell=floor(plane/86.0);
 vec2 local=fract(plane/86.0);
 float random=fract(sin(dot(cell,vec2(127.1,311.7)))*43758.5453);
 float arc=.45+.035*sin(local.x*9.0+preview_time*.6);
 if(random>.75 && local.x>.18 && local.x<.55 && abs(local.y-arc)<.009)color=vec3(.43,.65,.68);
 COLOR=vec4(color,1.0);
}
