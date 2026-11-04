shader_type canvas_item;
uniform sampler2D splat_mask : filter_linear, repeat_disable;
uniform vec4 ink : source_color;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.001, 0.1) = 0.012;
void fragment() {
    float threshold = texture(splat_mask, UV).r;
    float alpha = smoothstep(threshold - softness, threshold + softness, progress);
    if (progress <= 0.0) { alpha = 0.0; }
    if (progress >= 1.0) { alpha = 1.0; }
    COLOR = vec4(ink.rgb, ink.a * alpha) * COLOR;
}
