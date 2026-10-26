shader_type canvas_item;
uniform vec4 ink : source_color;
uniform float spacing : hint_range(4.0, 24.0) = 8.0;
uniform float strength : hint_range(0.0, 0.25) = 0.10;
uniform float max_radius : hint_range(0.0, 0.5) = 0.25;
uniform bool ramp = true;
void fragment() {
    vec2 pixel = mat2(vec2(0.7071068, -0.7071068), vec2(0.7071068, 0.7071068)) * FRAGCOORD.xy;
    vec2 cell = fract(pixel / spacing) - 0.5;
    float radius = max_radius * (ramp ? clamp(dot(UV, vec2(0.6, 0.8)), 0.0, 1.0) : 1.0);
    float edge = 0.65 / spacing;
    float alpha = 1.0 - smoothstep(radius - edge, radius + edge, length(cell));
    if (radius <= 0.0) { alpha = 0.0; }
    COLOR = vec4(ink.rgb, ink.a * alpha * strength) * COLOR;
}
