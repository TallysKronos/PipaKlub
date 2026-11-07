shader_type canvas_item;
uniform float detail_strength = 0.20;
uniform bool floor_mode = false;
uniform sampler2D masks;
uniform vec2 map_size = vec2(48.0, 40.0);
uniform int yard = 0;
varying vec4 vertex_tint;

void vertex() { vertex_tint = COLOR; }

float hash_cell(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 at = UV * tex_size;
	vec2 projected = vec2((at.x-at.y)*32.0,(at.x+at.y)*16.0);
	vec4 tex = texture(TEXTURE, floor_mode ? projected*.8/tex_size : UV);
	vec3 base = vec3(.69,.68,.61);
	if (floor_mode) {
		vec4 zones = texture(masks, at/map_size);
		vec3 concrete = vec3(.74,.73,.66);
		vec3 asphalt = vec3(.48,.51,.49);
		if (yard > 0) {
			concrete = vec3(.65,.63,.55);
			asphalt = vec3(.29,.34,.36);
			vec2 slab = at*.5;
			vec2 edge = min(fract(slab),1.0-fract(slab));
			float seam = 1.0-smoothstep(.006,.025,min(edge.x,edge.y));
			concrete += (hash_cell(floor(slab))-.5)*.08 - seam*.075;
			asphalt += (hash_cell(floor(at*13.0))-.5)*.075;
			vec2 brick = at*vec2(2.0,4.0);
			brick.x += mod(floor(brick.y),2.0)*.5;
			vec2 joint = min(fract(brick),1.0-fract(brick));
			float mortar = 1.0-smoothstep(.028,.072,min(joint.x,joint.y));
			vec3 paver = vec3(.65,.43,.30)+(hash_cell(floor(brick))-.5)*.13;
			paver = mix(paver,vec3(.47,.36,.28),mortar*.65);
			float court = smoothstep(4.0,5.0,at.x)*(1.0-smoothstep(18.0,20.0,at.x))
				*smoothstep(17.0,19.0,at.y)*(1.0-smoothstep(26.0,28.0,at.y));
			concrete = mix(concrete,paver,court);
		}
		base = mix(concrete,asphalt,smoothstep(.1,.9,zones.r));
	}
	COLOR = vec4(mix(base,tex.rgb,detail_strength),tex.a)*vertex_tint;
}
