shader_type canvas_item;
render_mode unshaded;
uniform sampler2D surfaces : source_color, repeat_enable, filter_linear;
uniform float material_id = 0.0;
uniform vec4 edge_ids = vec4(0.0);
uniform vec4 corner_ids = vec4(0.0);
uniform vec2 cell_origin = vec2(0.0);
vec3 paint(float id, vec2 ground) {
	vec2 uv=(fract(ground/8.0)*511.0+0.5)/512.0;
	return texture(surfaces,vec2((floor(id+0.5)+uv.x)/7.0,uv.y)).rgb;
}
void fragment() {
	vec2 uv=clamp(UV,vec2(0.0),vec2(1.0));
	vec2 ground=cell_origin+uv;
	vec3 color=paint(material_id,ground);
	float width=.13+.025*sin(ground.x*8.0+sin(ground.y*11.0));
	color=mix(color,paint(edge_ids.x,ground),.5*(1.0-smoothstep(0.0,width,uv.x)));
	color=mix(color,paint(edge_ids.y,ground),.5*(1.0-smoothstep(0.0,width,1.0-uv.x)));
	color=mix(color,paint(edge_ids.z,ground),.5*(1.0-smoothstep(0.0,width,uv.y)));
	color=mix(color,paint(edge_ids.w,ground),.5*(1.0-smoothstep(0.0,width,1.0-uv.y)));
	color=mix(color,paint(corner_ids.x,ground),1.0-smoothstep(0.0,.20,length(uv)));
	color=mix(color,paint(corner_ids.y,ground),1.0-smoothstep(0.0,.20,length(uv-vec2(1.0,0.0))));
	color=mix(color,paint(corner_ids.z,ground),1.0-smoothstep(0.0,.20,length(uv-vec2(1.0))));
	color=mix(color,paint(corner_ids.w,ground),1.0-smoothstep(0.0,.20,length(uv-vec2(0.0,1.0))));
	COLOR=vec4(color,1.0);
}
