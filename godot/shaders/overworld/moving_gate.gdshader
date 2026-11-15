shader_type canvas_item;
render_mode unshaded;
uniform sampler2D depth_map : filter_nearest, repeat_disable;
uniform vec4 depth_bounds;
uniform vec3 face_plane;
varying vec2 scene_point;
void vertex() {
	scene_point = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}
void fragment() {
	vec2 uv = (scene_point-depth_bounds.xy)/depth_bounds.zw;
	if (all(greaterThanEqual(uv,vec2(0.0))) && all(lessThan(uv,vec2(1.0)))) {
		float ray = dot(face_plane.xy,scene_point)+face_plane.z;
		if (texture(depth_map,uv).r > ray+1.8) COLOR.a = 0.0;
	}
}
