shader_type canvas_item;
varying vec2 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=world*.008;
 float patches=noise(p*.7);
 vec3 col=mix(vec3(.055,.16,.14),vec3(.15,.29,.22),noise(p*1.7));
 vec2 leaves=world*vec2(.16,.24);
 vec2 leaf_id=floor(leaves),leaf=fract(leaves)-.5;
 float ellipse=dot(leaf/vec2(.44,.29),leaf/vec2(.44,.29));
 float duck=smoothstep(.58,.73,patches)*(1.-smoothstep(.65,1.,ellipse))*step(.43,hash(leaf_id));
 col=mix(col,vec3(.37,.45,.21),duck*.7);
 float ripple=smoothstep(.985,.999,sin(world.y*.065+sin(world.x*.018)*1.7+TIME*.2));
 col+=ripple*.035;
 COLOR=vec4(col,1.);
}
