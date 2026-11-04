shader_type canvas_item;
render_mode unshaded;
uniform vec4 outline_color : source_color = vec4(0.045,0.067,0.11,1.0);
uniform float outline_width = 0.8;
uniform vec4 body_tint : source_color = vec4(1.0);
void fragment(){
    vec4 body=texture(TEXTURE,UV);
    vec2 d=TEXTURE_PIXEL_SIZE*outline_width;
    float edge=0.0;
    edge=max(edge,texture(TEXTURE,UV+vec2(d.x,0.0)).a);
    edge=max(edge,texture(TEXTURE,UV-vec2(d.x,0.0)).a);
    edge=max(edge,texture(TEXTURE,UV+vec2(0.0,d.y)).a);
    edge=max(edge,texture(TEXTURE,UV-vec2(0.0,d.y)).a);
    edge=max(edge,texture(TEXTURE,UV+d).a);
    edge=max(edge,texture(TEXTURE,UV-d).a);
    edge=max(edge,texture(TEXTURE,UV+vec2(d.x,-d.y)).a);
    edge=max(edge,texture(TEXTURE,UV+vec2(-d.x,d.y)).a);
    float alpha=max(body.a,step(0.35,edge)*outline_color.a);
    COLOR=vec4(mix(outline_color.rgb,body.rgb*body_tint.rgb,body.a),alpha);
}
