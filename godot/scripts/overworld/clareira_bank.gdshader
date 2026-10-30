shader_type canvas_item;
render_mode unshaded;
uniform bool geometry_only = false;
uniform float face_shade = 1.0;
uniform bool wet = false;
void fragment() {
    vec2 phase=vec2(1.0-abs(mod(UV.x,2.0)-1.0),clamp(UV.y,0.002,0.998));
    vec3 soil=texture(TEXTURE,phase).rgb;
    soil=mix(vec3(0.72,0.57,0.36),soil,0.68)*face_shade;
    if (wet) soil=mix(soil,soil*vec3(0.70,0.79,0.79),smoothstep(0.76,1.0,UV.y)*0.35);
    if (geometry_only) soil=vec3(0.70,0.55,0.35)*face_shade;
    COLOR=vec4(soil,1.0);
}
