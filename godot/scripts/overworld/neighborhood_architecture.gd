extends RefCounted
## Two calibrated image planes retain the painted architectural detail.
## Their base edges meet the real lot, not an arbitrary centered PNG pivot.
const BASE := "res://assets/overworld/kits/bairro-inicial-v2/"

static func place(world: Node2D,b: Array,id: String,variant: String) -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"architecture.json"))
	var model := variant if variant in ["kael","professor","shop"] else "neighbor-north" if id=="vizinha-norte" else "neighbor-south"
	var info: Dictionary=manifest.models[model]
	var corners: Array=info.groundCorners
	var left := Vector2(corners[0][0],corners[0][1])
	var front := Vector2(corners[1][0],corners[1][1])
	var right := Vector2(corners[2][0],corners[2][1])
	var total: float=(b[2]-b[0])+(b[3]-b[1])
	var width_cells := total*(front.x-left.x)/(right.x-left.x)
	var depth_cells := total-width_cells
	var footprint: Array=[b[2]-width_cells,b[3]-depth_cells,b[2],b[3]]
	var ground: float=world.support(Vector2(footprint[0]+.5,footprint[3]-.5))
	var texture: Texture2D=load(BASE+str(info.file))
	var kind := "painted-building-"+model
	world.textures[kind]=texture
	var pixels:=texture.get_size()
	# A single affine transform must apply to the entire painting.
	# Independent vertical scaling of the two halves folds the roof at front.x.
	var left_slope: float=(front.y-left.y)/(front.x-left.x)
	var right_slope: float=(right.y-front.y)/(right.x-front.x)
	var z_scale: float=total*32.0/(right.x-left.x)/(left_slope-right_slope)
	for side in [0,1]:
		var x0 := 0.0 if side==0 else front.x
		var x1 := front.x if side==0 else pixels.x
		var source := [Vector2(x0,0),Vector2(x1,0),Vector2(x1,pixels.y),Vector2(x0,pixels.y)]
		var points: Array=[]
		var uv:=PackedVector2Array()
		for pixel: Vector2 in source:
			var t := (pixel.x-left.x)/(front.x-left.x) if side==0 else (pixel.x-front.x)/(right.x-front.x)
			var u := lerpf(footprint[0],footprint[2],t) if side==0 else float(footprint[2])
			var v := float(footprint[3]) if side==0 else lerpf(footprint[3],footprint[1],t)
			var baseline := lerpf(left.y,front.y,t) if side==0 else lerpf(front.y,right.y,t)
			points.append(Vector3(u,v,ground+(baseline-pixel.y)*z_scale))
			uv.append(pixel/pixels)
		world.face(points,uv,kind)
		var item: Dictionary=world.parts.back()
		item.transparent=true
		# Sort painted facade halves by their foundation rather than roof height.
		# Otherwise a tall illustration draws over people standing at its door.
		item.depth=((footprint[0]+footprint[2])*.5+footprint[3])*32.0+ground if side==0 else (footprint[2]+(footprint[1]+footprint[3])*.5)*32.0+ground
		# Projecting steps/planters are part of the painting's foreground footprint.
		# Do not erase them with the floor underneath the building.
		item.skip_terrain_clip=true
		item.foundation_height=ground
	world.blockers.append({"bounds":footprint,"id":id})
	var door_x: float=lerpf(footprint[0],footprint[2],.48)
	world.houses.append({"id":id,"bounds":footprint,"door":Vector2(door_x,footprint[3]+.9),"height":ground,"variant":variant,"paintedModel":model,"groundCorners":corners})
