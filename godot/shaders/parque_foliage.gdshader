shader_type canvas_item;
render_mode unshaded;
varying vec4 item_modulate;
void vertex() {
	item_modulate=COLOR;
}
void fragment() {
	vec4 texel=texture(TEXTURE,UV)*item_modulate;
	float value=dot(texel.rgb,vec3(0.2126,0.7152,0.0722));
	vec3 quieter=mix(texel.rgb,vec3(value),0.28);
	// Keep dark ink and red flowers; restrain the bright yellow canopy masses.
	float leaf=step(texel.r*.78,texel.g)*step(texel.b*1.15,texel.g);
	quieter=mix(quieter,quieter*vec3(.84,.90,.94),leaf);
	quieter=mix(vec3(0.31,0.39,0.28),quieter,0.94);
	COLOR=vec4(quieter,texel.a);
}
