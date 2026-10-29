shader_type canvas_item;
render_mode unshaded;
uniform sampler2D painting : repeat_enable, filter_linear;
varying vec2 ground_position;
varying vec4 surface_tint;
void vertex() {
    ground_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
    surface_tint = COLOR;
}
void fragment() {
    vec4 base = texture(TEXTURE, UV) * surface_tint;
    vec3 detail = texture(painting, ground_position / vec2(512.0,256.0)).rgb;
    float value = dot(detail,vec3(0.299,0.587,0.114));
    // Quiet painted marks, retaining the approved flat terrain palette.
    float marks = clamp((value-0.502)*0.42,-0.10,0.07);
    COLOR = vec4(clamp(base.rgb+marks,vec3(0.0),vec3(1.0)),base.a);
}
