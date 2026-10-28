shader_type canvas_item;
uniform vec4 ink : source_color;
uniform vec2 focal_point = vec2(0.5);
uniform float aspect_ratio = 1.777778;
uniform float strength : hint_range(0.0, 1.0) = 0.8;
uniform float line_count : hint_range(24.0, 60.0) = 40.0;
uniform bool parallel = false;
// No TIME: the caller starts and removes a single bounded event.
void fragment() {
    vec2 p = (UV - focal_point) * vec2(aspect_ratio, 1.0);
    float phase;
    float amount;
    if (parallel) {
        vec2 q = mat2(vec2(0.978148, 0.207912), vec2(-0.207912, 0.978148)) * p;
        phase = abs(fract(q.y * line_count) - 0.5);
        amount = (1.0 - smoothstep(0.015, 0.07, phase)) * smoothstep(0.08, 0.65, abs(q.x));
    } else {
        float angle = atan(p.y, p.x);
        phase = abs(fract(angle * line_count / 6.2831853) - 0.5);
        float taper = smoothstep(0.18, 0.8, length(p));
        amount = (1.0 - smoothstep(0.005, 0.025 + taper * 0.035, phase)) * taper;
    }
    COLOR = vec4(ink.rgb, ink.a * strength * amount) * COLOR;
}
