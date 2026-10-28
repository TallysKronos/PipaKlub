extends RefCounted
## Static per-pixel ray depth, shared by moving actors. No per-frame terrain sort.
const Visibility = preload("res://scripts/overworld/pier_visibility.gd")
var bounds := Rect2()
var texture: ImageTexture
var bake_ms := 0

func bake(parts: Array[Dictionary],hide_roof: bool=false) -> void:
	var start := Time.get_ticks_msec()
	for item in parts:
		bounds = bounds.merge(item.bounds) if bounds.has_area() else item.bounds
	bounds = Rect2(bounds.position.floor()-Vector2(2,2), bounds.size.ceil()+Vector2(5,5))
	var width := int(bounds.size.x)
	var height := int(bounds.size.y)
	var depths := PackedFloat32Array()
	depths.resize(width*height)
	depths.fill(-1000000.0)
	var images: Dictionary = {}
	for item in parts:
		var poly: PackedVector2Array = item.polygon
		if hide_roof and item.surface=="tower_roof":continue
		if poly.size()<3:continue
		var alpha: Image
		var pu := Vector3.ZERO
		var pv := Vector3.ZERO
		if item.get("transparent",false):
			var mesh_node: MeshInstance2D = item.node
			if not is_instance_valid(mesh_node) or mesh_node.mesh==null:continue
			var key: int = mesh_node.texture.get_instance_id()
			if not images.has(key):images[key] = mesh_node.texture.get_image()
			alpha = images[key]
			var arrays: Array = mesh_node.mesh.surface_get_arrays(0)
			pu = Visibility.uv_plane(arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_TEX_UV],0)
			pv = Visibility.uv_plane(arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_TEX_UV],1)
		var y0 := maxi(0,floori(item.bounds.position.y-bounds.position.y))
		var y1 := mini(height,ceili(item.bounds.end.y-bounds.position.y))
		for row in range(y0,y1):
			var y := bounds.position.y+float(row)+.5
			var crossings: Array[float] = []
			for i in range(poly.size()):
				var a := poly[i]
				var b := poly[(i+1)%poly.size()]
				if (a.y<=y and b.y>y) or (b.y<=y and a.y>y):
					crossings.append(lerpf(a.x,b.x,(y-a.y)/(b.y-a.y)))
			crossings.sort()
			for pair in range(0,crossings.size()-1,2):
				var x0 := maxi(0,ceili(crossings[pair]-bounds.position.x-.5))
				var x1 := mini(width,ceili(crossings[pair+1]-bounds.position.x-.5))
				for column in range(x0,x1):
					var point := Vector2(bounds.position.x+float(column)+.5,y)
					if alpha!=null:
						var tx := clampi(int(Visibility.value(point,pu)*alpha.get_width()),0,alpha.get_width()-1)
						var ty := clampi(int(Visibility.value(point,pv)*alpha.get_height()),0,alpha.get_height()-1)
						if alpha.get_pixel(tx,ty).a<.5:continue
					var index := row*width+column
					var ray_depth := Visibility.value(point,item.plane)
					if item.has("foundation_height"):
						# Foreground illustrated steps rest on the same ground plane.
						ray_depth = maxf(ray_depth,point.y*2.0+float(item.foundation_height)*3.0+.4)
					depths[index] = maxf(depths[index],ray_depth)
	var image := Image.create_from_data(width,height,false,Image.FORMAT_RF,depths.to_byte_array())
	texture = ImageTexture.create_from_image(image)
	bake_ms = Time.get_ticks_msec()-start

func material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = load("res://shaders/overworld/pier_actor.gdshader")
	result.set_shader_parameter("depth_map",texture)
	result.set_shader_parameter("depth_bounds",Vector4(bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y))
	return result
