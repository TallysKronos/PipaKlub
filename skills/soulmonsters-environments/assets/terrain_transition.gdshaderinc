// Shared by cave and plains: static, locally anchored, narrow material transitions.
float terrain_hash(vec2 p) {
 return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float terrain_noise(vec2 p) {
 vec2 c = floor(p);
 vec2 f = fract(p);
 f = f*f*(3.0-2.0*f);
 return mix(mix(terrain_hash(c),terrain_hash(c+vec2(1.0,0.0)),f.x),
            mix(terrain_hash(c+vec2(0.0,1.0)),terrain_hash(c+vec2(1.0)),f.x),f.y);
}
vec2 terrain_cell(vec2 point) {
 return vec2(point.x/64.0+point.y/32.0,point.y/32.0-point.x/64.0);
}
float terrain_blend(float distance_to_edge,vec2 cell,float variation,float blend_width) {
 float coarse = terrain_noise(cell*2.1+vec2(8.3,2.7));
 float chips = terrain_noise(cell*7.0+vec2(2.8,9.1));
 float irregularity = (coarse-0.5)*variation*2.0+(chips-0.5)*0.15;
 float weight = 1.0-smoothstep(-blend_width,blend_width,distance_to_edge+irregularity);
 float shoulder = smoothstep(-0.58,-0.12,distance_to_edge);
 return weight*(1.0-smoothstep(0.60,0.76,chips)*shoulder*0.85);
}
