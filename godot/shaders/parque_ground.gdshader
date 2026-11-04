shader_type canvas_item;
render_mode unshaded;
uniform sampler2D surfaces : source_color, repeat_enable, filter_linear;
uniform float material_id = 0.0;
uniform vec4 edge_ids = vec4(0.0);
uniform vec4 corner_ids = vec4(0.0);
varying vec2 ground_uv;
varying vec2 cell_uv;

vec3 paint(float id) {
	vec2 uv=(fract(ground_uv/8.0)*511.0+0.5)/512.0;
	vec3 color=texture(surfaces,vec2((floor(id+0.5)+uv.x)/5.0,uv.y)).rgb;
	return color;
}
void vertex() {
	vec2 world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;
	ground_uv=vec2(world.x/64.0+world.y/32.0,world.y/32.0-world.x/64.0);
	cell_uv=vec2(VERTEX.x/64.0+VERTEX.y/32.0,VERTEX.y/32.0-VERTEX.x/64.0)+0.5;
}
void fragment() {
	vec2 uv=clamp(cell_uv,vec2(0.0),vec2(1.0));
	vec3 color=paint(material_id);
	// Equal blending at the shared edge, with organic width in world coordinates.
	float width=0.13+0.025*sin(ground_uv.x*8.0+sin(ground_uv.y*11.0));
	color=mix(color,paint(edge_ids.x),0.5*(1.0-smoothstep(0.0,width,uv.x)));
	color=mix(color,paint(edge_ids.y),0.5*(1.0-smoothstep(0.0,width,1.0-uv.x)));
	color=mix(color,paint(edge_ids.z),0.5*(1.0-smoothstep(0.0,width,uv.y)));
	color=mix(color,paint(edge_ids.w),0.5*(1.0-smoothstep(0.0,width,1.0-uv.y)));
	color=mix(color,paint(corner_ids.x),1.0-smoothstep(0.0,0.20,length(uv)));
	color=mix(color,paint(corner_ids.y),1.0-smoothstep(0.0,0.20,length(uv-vec2(1.0,0.0))));
	color=mix(color,paint(corner_ids.z),1.0-smoothstep(0.0,0.20,length(uv-vec2(1.0))));
	color=mix(color,paint(corner_ids.w),1.0-smoothstep(0.0,0.20,length(uv-vec2(0.0,1.0))));
	COLOR=vec4(color,1.0);
}
