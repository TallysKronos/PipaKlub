shader_type canvas_item;
render_mode unshaded;
uniform sampler2D depth_map : filter_nearest, repeat_disable;
uniform sampler2D roofless_depth_map : filter_nearest, repeat_disable;
uniform vec4 depth_bounds;
uniform float ray_constant = 0.0;
uniform bool reveal_under_deck = false;
uniform bool roof_cutaway = false;
varying vec2 scene_point;
void vertex() {
	scene_point = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec2 p = (scene_point-depth_bounds.xy)/depth_bounds.zw;
	if (all(greaterThanEqual(p,vec2(0.0))) && all(lessThan(p,vec2(1.0)))) {
		float geometry_depth = texture(depth_map,p).r;
		if (roof_cutaway) geometry_depth = texture(roofless_depth_map,p).r;
		float actor_depth = ray_constant-scene_point.y;
		if (geometry_depth > actor_depth+1.8) {
			if (reveal_under_deck) COLOR = vec4(0.35,0.80,0.84,COLOR.a*0.20);
			else COLOR.a = 0.0;
		}
	}
}
