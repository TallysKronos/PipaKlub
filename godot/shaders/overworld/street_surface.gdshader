shader_type canvas_item;
render_mode unshaded;
uniform sampler2D asphalt_texture : source_color, repeat_enable, filter_linear;
uniform int surface_kind = 0;
uniform bool show_geometry = false;
varying vec2 cell;
void vertex() { cell = UV; }
void fragment() {
 vec3 color;
 if (surface_kind==0) {
  color = texture(asphalt_texture,fract(cell/8.0)).rgb;
 } else if (surface_kind==1) {
  vec2 p = vec2(cell.x,cell.y/1.5);
  p.x += mod(floor(p.y),2.0)*0.5;
  vec2 f = fract(p);
  float edge = min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
  color = mix(vec3(0.42,0.44,0.42),vec3(0.60,0.61,0.56),smoothstep(0.009,0.024,edge));
 } else { color = vec3(0.12,0.16,0.18); }
 if (show_geometry) { color = surface_kind==0 ? vec3(0.20,0.32,0.39) : (surface_kind==1 ? vec3(0.55,0.68,0.50) : vec3(0.10,0.18,0.24)); }
 COLOR = vec4(color,1.0);
}
