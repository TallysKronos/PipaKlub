shader_type canvas_item;
// The silhouette is rendered once across two layers, never duplicated opaque.
uniform vec2 region_origin=vec2(0.0);
uniform vec2 atlas_size=vec2(1536.0,1024.0);
uniform bool far_layer=false;
uniform vec2 leg_polygon[12];
uniform int leg_count=0;
uniform bool depth_enabled=false;
uniform sampler2D depth_map : filter_nearest, repeat_disable;
uniform sampler2D roofless_depth_map : filter_nearest, repeat_disable;
uniform vec4 depth_bounds;
uniform float ray_constant=0.0;
uniform bool reveal_under_deck=false;
uniform bool roof_cutaway=false;
varying vec2 scene_point;
void vertex(){scene_point=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	vec2 point=UV*atlas_size-region_origin;
	bool distant=false;
	for(int i=0;i<12;i++){
		if(i>=leg_count){break;}
		int j=i==0?leg_count-1:i-1;
		vec2 a=leg_polygon[i];vec2 b=leg_polygon[j];
		if((a.y>point.y)!=(b.y>point.y)){
			if(point.x<(b.x-a.x)*(point.y-a.y)/(b.y-a.y)+a.x){distant=!distant;}
		}
	}
	if(distant!=far_layer){discard;}
	// COLOR already contains texture * inherited modulation in canvas_item.
	if(depth_enabled){
		vec2 p=(scene_point-depth_bounds.xy)/depth_bounds.zw;
		if(all(greaterThanEqual(p,vec2(0.0))) && all(lessThan(p,vec2(1.0)))){
			float geometry_depth=texture(depth_map,p).r;
			if(roof_cutaway){geometry_depth=texture(roofless_depth_map,p).r;}
			if(geometry_depth>ray_constant-scene_point.y+1.8){
				if(reveal_under_deck){COLOR=vec4(0.35,0.80,0.84,COLOR.a*0.20);}
				else{COLOR.a=0.0;}
			}
		}
	}
}
