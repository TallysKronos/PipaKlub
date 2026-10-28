shader_type canvas_item;
render_mode unshaded;
uniform float wind_time = 0.0;
uniform float wind_strength = 0.0;
uniform float phase = 0.0;
uniform vec2 wind_direction = vec2(-0.9, 0.45);
uniform float reach_px = 48.0;
uniform bool anchored_top = false;
void vertex() {
 float reach = max(reach_px, 1.0);
 float free_distance = anchored_top ? max(VERTEX.y, 0.0) : max(-VERTEX.y, 0.0);
 float weight = pow(clamp(free_distance / reach, 0.0, 1.0), 2.0);
 float bend = sin(wind_time * 3.14159265 + phase) * 0.45 + 0.55;
 VERTEX += wind_direction * wind_strength * weight * bend;
}
