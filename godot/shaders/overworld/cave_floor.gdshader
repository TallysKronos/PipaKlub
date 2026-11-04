shader_type canvas_item;
render_mode unshaded;
// The atlas supplies geometry; the shared world-space painting supplies colour.
uniform sampler2D surface_texture : source_color, repeat_enable, filter_linear;
uniform float cells_per_repeat = 4.0;
uniform float surface_contrast = 1.0;
uniform vec4 base_tone : source_color = vec4(0.3,0.4,0.45,1.0);
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
    float alpha=texture(TEXTURE,UV).a;
    vec2 p=vec2(world_position.x/64.0+world_position.y/32.0,world_position.y/32.0-world_position.x/64.0)/cells_per_repeat;
    // Explicit wrapping also works on Polygon2D when the canvas sampler clamps.
    // Opposite source texels are matched by the surface preparation pipeline.
    COLOR=vec4(mix(base_tone.rgb,texture(surface_texture,fract(p)).rgb,surface_contrast),alpha);
}

