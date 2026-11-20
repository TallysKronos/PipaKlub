shader_type canvas_item;
render_mode unshaded;
uniform sampler2D terrain : source_color, filter_nearest, repeat_disable;
varying vec2 map_pixel;
void vertex() {
    map_pixel=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;
}
void fragment() {
    vec4 base=texture(TEXTURE,UV);
    vec2 p=floor(UV/TEXTURE_PIXEL_SIZE);
    float t=floor(TIME*12.0);
    float lane=fract(floor(p.x/7.0)*.3819);
    float stream=step(.88,fract((p.y-t*3.0)/37.0+lane));
    // The splash extends sideways into the bank in the isolated render.
    // Only the falling column can cover rock.
    vec3 ground=texture(terrain,map_pixel/vec2(textureSize(terrain,0))).rgb;
    bool column=p.x>=97.0 && p.x<=156.0 && p.y<226.0;
    bool lake=ground.g>ground.r*1.6 && ground.b>ground.r*1.65;
    COLOR=vec4(mix(base.rgb,vec3(.65,.88,.94),stream*.12),base.a*float(column || lake || p.y<196.0));
}
