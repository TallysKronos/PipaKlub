shader_type canvas_item;
render_mode unshaded;
uniform float animation_time = 0.0;
uniform float phase = 0.0;
uniform float height_px = 64.0;
uniform float sway_strength = 4.0;
void vertex() {
 float weight = pow(clamp(-VERTEX.y/max(height_px,1.0),0.0,1.0),2.0);
 float wave = sin(animation_time*0.78539816339+phase);
 VERTEX.x += wave*weight*sway_strength;
 VERTEX.y += sin(animation_time*1.57079632679+phase)*weight*sway_strength*0.125;
}
