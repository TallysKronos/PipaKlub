shader_type canvas_item;
render_mode unshaded;
uniform sampler2D water_mask : filter_nearest, repeat_disable;
void fragment() {
    vec4 base=texture(TEXTURE,UV);
    float mask=texture(water_mask,UV).r;
    float water=step(base.r*1.6,base.g)*step(base.r*1.65,base.b)*mask;
    vec2 px=floor(UV/TEXTURE_PIXEL_SIZE);
    float frame=floor(TIME*8.0);
    float shift=floor(sin(px.y*.10-frame*.35)*1.4);
    vec4 current=texture(TEXTURE,UV+vec2(shift,0.0)*TEXTURE_PIXEL_SIZE);
    float glint=step(.94,fract((floor(px.x/18.0)+floor(px.y/7.0)*17.0+floor(frame/2.0))*.618));
    glint*=step(.84,fract(px.y/9.0));
    COLOR=vec4(mix(base.rgb,current.rgb+vec3(.015,.035,.037)*glint,water),base.a);
}
