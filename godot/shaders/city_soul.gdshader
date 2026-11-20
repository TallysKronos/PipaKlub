shader_type canvas_item;
uniform float life : hint_range(0.0,1.0) = 0.0;
void fragment(){
	vec4 ink=texture(TEXTURE,UV)*COLOR;
	float gray=dot(ink.rgb,vec3(.299,.587,.114));
	COLOR=vec4(mix(vec3(gray*.65),ink.rgb,life),ink.a);
}
