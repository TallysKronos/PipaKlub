shader_type canvas_item;
render_mode unshaded;
uniform sampler2D painting : source_color, repeat_enable, filter_linear;
uniform vec4 paint_tint : source_color = vec4(1.0);
varying vec2 ground_position;
varying vec4 surface_tint;
void vertex() {
    ground_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
    surface_tint = COLOR;
}
void fragment() {
    vec4 base = texture(TEXTURE, UV) * surface_tint;
    // One shared world phase across cells, corner patches and ramps. The
    // original painted colour masses must survive instead of becoming grain.
    // Mirrored sampling joins imperfect source edges without a visible seam.
    vec2 p = vec2(1.0)-abs(mod(ground_position / vec2(448.0),vec2(2.0))-vec2(1.0));
    vec3 paint = texture(painting, p).rgb;
    COLOR = vec4(paint * paint_tint.rgb, base.a);
}
