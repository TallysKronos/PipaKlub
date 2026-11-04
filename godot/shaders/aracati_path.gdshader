shader_type canvas_item;

float distance_to_segment(vec2 point, vec2 start, vec2 end) {
	vec2 direction = end - start;
	float along = clamp(dot(point - start, direction) / dot(direction, direction), 0.0, 1.0);
	return length(point - start - direction * along);
}

uniform int area_part = 0;
uniform int part = 0;
uniform float elevation = 64.0;
varying vec2 ground_point;

void vertex() {
	vec2 screen = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	ground_point = vec2(screen.x / 64.0 + (screen.y + elevation) / 32.0,
		-screen.x / 64.0 + (screen.y + elevation) / 32.0);
}

void fragment() {
	vec2 p = ground_point;
	float broad = sin(p.x * .71 + p.y * .38) + sin(p.y * .63 - p.x * .29);
	float detail = sin(p.x * 4.1 + p.y * 2.9) * sin(p.y * 3.7);
	float width = 1.85 + .18 * broad + .10 * detail;
	float track = min(distance_to_segment(p, vec2(25.5, 31.0), vec2(25.2, 24.5)),
		distance_to_segment(p, vec2(25.2, 24.5), vec2(18.0, 20.0)));
	track = min(track, distance_to_segment(p, vec2(18.0, 20.0), vec2(18.0, 17.2)));
	float east = min(distance_to_segment(p, vec2(25.2, 24.5), vec2(30.0, 22.5)),
		distance_to_segment(p, vec2(30.0, 22.5), vec2(25.5, 8.0)));
	east = min(east, distance_to_segment(p, vec2(25.5, 8.0), vec2(25.5, -1.0)));
	track = min(track, east + .45);
	float mainland = distance_to_segment(p, vec2(25.5, 35.0), vec2(25.5, 41.0));
	track = min(track, mainland);
	float plaza = length((p - vec2(25.5, 26.0)) * vec2(.80, 1.0));
	float terrace = distance_to_segment(p, vec2(18.0, 19.0), vec2(18.0, 11.8));
	float edge = elevation > 64.0 ? terrace - width : min(track - width, plaza - 2.7 - .12 * broad);
	if (area_part == 1) {
		float main_path = min(distance_to_segment(p, vec2(25.5, 40.0), vec2(26.5, 21.0)),
			distance_to_segment(p, vec2(26.5, 21.0), vec2(25.5, 0.0)));
		float lookout = distance_to_segment(p, vec2(26.5, 24.0), vec2(12.0, 23.5));
		float ridge = distance_to_segment(p, vec2(12.0, 22.0), vec2(12.0, 12.0));
		edge = (elevation > 64.0 ? ridge : min(main_path, lookout + .45)) - width;
	}
	if (area_part == 2) {
		float arrival = distance_to_segment(p, vec2(25.5, 40.0), vec2(24.0, 22.0));
		float upper_path = distance_to_segment(p, vec2(24.0, 22.0), vec2(24.0, 10.0));
		float arena = length((p - vec2(24.0, 10.0)) * vec2(.68, 1.0));
		edge = elevation > 64.0 ? min(upper_path - width, arena - 4.5 - .12 * broad) : arrival - width;
	}
	if (part == 1) {
		float coastal_trail = min(distance_to_segment(p, vec2(25.5,41.0),vec2(20.0,27.0)),
			distance_to_segment(p,vec2(20.0,27.0),vec2(28.0,17.0)));
		coastal_trail = min(coastal_trail, distance_to_segment(p,vec2(28.0,17.0),vec2(25.5,-1.0)));
		coastal_trail = min(coastal_trail, distance_to_segment(p,vec2(20.0,27.0),vec2(12.0,23.0)));
		float bench_path = distance_to_segment(p,vec2(12.0,23.0),vec2(13.0,10.0));
		edge = (elevation > 64.0 ? bench_path : coastal_trail) - width;
	} else if (part == 2) {
		float rise = distance_to_segment(p,vec2(25.5,41.0),vec2(24.0,21.0));
		float approach = distance_to_segment(p,vec2(24.0,22.0),vec2(24.0,14.0));
		float court = length((p-vec2(24.0,12.0))*vec2(.76,1.0)) - 5.6 - .12*broad;
		edge = elevation > 64.0 ? min(court,approach-width) : rise-width;
	}
	vec3 grass = broad > .45 ? vec3(.61,.64,.31) : vec3(.55,.58,.27);
	vec3 soil = broad > .3 ? vec3(.83,.65,.40) : vec3(.79,.60,.36);
	float wear = smoothstep(-.13, .13, edge);
	float rim = smoothstep(.13, .36, edge);
	vec3 ground = mix(soil, vec3(.67,.61,.34), wear);
	ground = mix(ground, grass, rim);
	COLOR = vec4(ground, 1.0);
}
