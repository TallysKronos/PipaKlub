shader_type canvas_item;

uniform float waterline = 30.0;
uniform bool jets_visible = true;
uniform bool possessed = false;
uniform float jet_clock = 0.0;
varying vec2 sprite_point;
varying vec4 tint;

void vertex() {
	sprite_point = VERTEX;
	tint = COLOR;
}

void fragment() {
	float wave = round(sin(floor(sprite_point.x / 3.0) * .29) * 2.0);
	if (sprite_point.y > waterline + wave) {
		discard;
	}
	// Local pixels in one 320px atlas cell. Keep both nozzles anchored.
	vec2 p = floor(sprite_point + vec2(160.0, 302.0));
	if (!jets_visible) {
		// Use the resting pose while the vents are quiet. Its fin and shell
		// already have a finished contour; only the two streams need removing.
		vec4 body = texture(TEXTURE, (p + vec2(0.5)) * TEXTURE_PIXEL_SIZE);
		vec2 left = possessed ? vec2(116.0,192.0) : vec2(118.0,188.0);
		vec2 right = possessed ? vec2(162.0,192.0) : vec2(167.0,188.0);
		vec2 nozzle = p.x < 142.0 ? left : right;
		bool fin = p.x >= (possessed ? 184.0 : 186.0) && p.y >= (possessed ? 181.0 : 178.0);
		if (!fin && p.y < nozzle.y) {
			body.a = 0.0;
		}
		vec2 aperture = (p-nozzle)/vec2(8.0,3.0);
		float radius = dot(aperture,aperture);
		if (radius <= 1.0) {
			body = vec4(radius > 0.57 ? vec3(.10,.49,.58) : vec3(.035,.19,.27),1.0);
		}
		COLOR = body*tint;
	}
	float height = 188.0 - p.y;
	if (jets_visible && jet_clock > 0.0 && height > 0.0 && p.y > 45.0 && p.x > 45.0 && p.x < 244.0
			&& !(p.x > 184.0 && p.y >= 176.0)) {
		float t = floor(jet_clock * 12.0) / 12.0;
		float side = smoothstep(145.0, 160.0, p.x);
		float pulse = mix(sin(t*4.2), sin(t*3.5+2.4), side);
		float lift = height * (0.095*pulse + 0.035*sin(t*6.2+side*2.0));
		float sway = smoothstep(0.0, 63.0, height)*3.0*sin(t*3.2+height*.045+side*2.7);
		vec2 shift = round(vec2(sway, lift));
		vec4 jet = texture(TEXTURE, UV + shift*TEXTURE_PIXEL_SIZE);
		float stream = smoothstep(.72, 1.0, sin(height*.43-t*9.0+p.x*.21));
		jet.rgb = mix(jet.rgb, vec3(.74,.96,1.0), stream*.27*step(jet.r+.15,jet.b));
		COLOR = jet*tint;
	}
}
