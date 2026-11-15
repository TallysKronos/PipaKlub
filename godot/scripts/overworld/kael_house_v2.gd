extends RefCounted
## Native pixel cutouts. Their geometry is never stretched to fit the old house.
const BASE := "res://assets/campaign/kael-house-v2/"
const GATE := Vector2(4.4,18.2)
const GATE_PIXEL := Vector2(177,447)
const DOOR := Vector2(5.8,16.2)
const BODY := [2.0,11.5,8.0,15.55]

static func origin(world:Node2D) -> Vector2:
	return (world.iso(GATE,8)-GATE_PIXEL).round()

static func place(world:Node2D) -> void:
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"kit.json"))
	var at:=origin(world)
	for part in manifest.parts:
		var texture:Texture2D=load(BASE+str(part.file))
		var bounds:Rect2i=texture.get_image().get_used_rect()
		var spans:Array=[Rect2(bounds)]
		if part.id=="fechamento-frontal":
			spans=[Rect2(bounds.position,Vector2(326-bounds.position.x,bounds.size.y)),Rect2(Vector2(326,bounds.position.y),Vector2(bounds.end.x-326,bounds.size.y))]
		for i in spans.size():
			var rect:Rect2=spans[i]
			if not rect.has_area():continue
			var vertices:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
			var uv:=PackedVector2Array()
			for j in vertices.size():
				uv.append(vertices[j]/texture.get_size())
				vertices[j]+=at
			var arrays:=[]
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX]=vertices
			arrays[Mesh.ARRAY_TEX_UV]=uv
			arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
			var mesh:=ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var node:=MeshInstance2D.new()
			node.name="KaelV2_"+str(part.id)+str(i)
			node.mesh=mesh
			node.texture=texture
			node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
			var plane:=Vector3(0,-1,(DOOR.x+15.1)*48)
			if part.id=="base-jardim":plane=Vector3(0,2,24.2)
			elif part.id=="soleira-portao":plane=Vector3(0,2,24.7)
			elif part.id=="fechamento-frontal":plane=Vector3(1.5,-1,96*18.2) if i==0 else Vector3(-1.5,-1,96*9.8)
			var center:=at+rect.get_center()
			world.queue(node,plane.x*center.x+plane.y*center.y+plane.z,vertices,plane)
			world.parts.back().transparent=true
			world.parts.back().skip_terrain_clip=true
	world.blockers.append({"bounds":BODY,"id":"casa-kael"})
	world.houses.append({"id":"casa-kael","bounds":BODY,"door":DOOR,"height":8,"variant":"kael","paintedModel":"kael-v2","gate":GATE})
