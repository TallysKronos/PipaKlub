shader_type canvas_item;
render_mode unshaded;
uniform vec4 roof_color : source_color = vec4(0.64,0.39,0.26,1.0);
void fragment() {
	vec4 source = texture(TEXTURE,UV);
	float tone = max(max(source.r,source.g),source.b);
	vec3 paint = mix(roof_color.rgb*0.69,min(roof_color.rgb*1.19,vec3(1.0)),smoothstep(0.22,0.68,tone));
	paint = mix(vec3(0.12,0.20,0.23),paint,smoothstep(0.17,0.29,tone));
	COLOR = vec4(paint,source.a*COLOR.a);
}
