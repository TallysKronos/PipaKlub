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
		if part.id in ["fechamento-frontal","soleira-portao"]:continue
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
	build_gate(world)
	var bicycle:Node2D=preload("res://scenes/overworld/props/bicycle.tscn").instantiate()
	bicycle.install(world)
	world.blockers.append({"bounds":BODY,"id":"casa-kael"})
	world.houses.append({"id":"casa-kael","bounds":BODY,"door":DOOR,"height":8,"variant":"kael","paintedModel":"kael-v2","gate":GATE})

static func solid(world:Node2D,b:Array,low:float,high:float,front:Color,side:Color,top:Color) -> void:
	var first:int=world.parts.size()
	var uv:=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN])
	world.face([Vector3(b[2],b[1],high),Vector3(b[2],b[3],high),Vector3(b[2],b[3],low),Vector3(b[2],b[1],low)],uv,"ink",side)
	world.face([Vector3(b[0],b[3],high),Vector3(b[2],b[3],high),Vector3(b[2],b[3],low),Vector3(b[0],b[3],low)],uv,"ink",front)
	world.face([Vector3(b[0],b[1],high),Vector3(b[2],b[1],high),Vector3(b[2],b[3],high),Vector3(b[0],b[3],high)],uv,"ink",top)
	for i in range(first,world.parts.size()):world.parts[i].kael_gate_volume=true

static func edge(world:Node2D,a:Vector3,b:Vector3,color:Color) -> void:
	world.line3([a,b],color,1,.25)
	world.parts.back().node.antialiased=false

static func build_gate(world:Node2D) -> void:
	# Approved blockout dimensions. Materials never change the support geometry.
	var cream:=Color("f0dcc0")
	var shade:=Color("b59f8e")
	var cap:=Color("f7f3ee")
	var trim:=Color("84727c")
	world.paint([1.2,16,9.8,18.46],Color("789661"),.03)
	world.paint([3.55,16.3,5.25,20.2],Color("c8cdd1"),.15)
	for v in [17.1,18.2,19.15]:edge(world,Vector3(3.55,v,8.2),Vector3(5.25,v,8.2),Color("9da9b5"))
	for span in [[1.2,3.55],[5.25,9.8]]:
		world.paint([span[0],18.46,span[1],18.73],Color("b8c4d0"),.10)
		for u in range(ceili(span[0]*2),floori(span[1]*2)+1):edge(world,Vector3(float(u)*.5,18.46,8.2),Vector3(float(u)*.5,18.73,8.2),Color("8a99b0"))
	# Contact shadows lie on the floor, immediately outside the pillar bases.
	for b in [[3.1,17.94,3.55,18.46],[5.25,17.94,5.7,18.46]]:
		world.paint([b[0],b[3],b[2],b[3]+.10],Color("9da9b5"),.16)
		world.blockers.append({"bounds":b,"id":"kael-gate-pillar"})
		solid(world,b,8,50,cream,shade,cap)
		solid(world,[b[0]-.035,b[1]-.035,b[2]+.035,b[3]+.035],50,53,Color("d6b79f"),shade,cap)
		edge(world,Vector3(b[2],b[3],8),Vector3(b[2],b[3],50),trim)
	for b in [[1.2,18.08,3.1,18.32],[5.7,18.08,9.8,18.32],[9.68,11,9.8,18.32]]:
		solid(world,b,8,48,cream,shade,cap)
		edge(world,Vector3(b[0],b[3],48),Vector3(b[2],b[3],48),Color("d6b79f"))
	# Installed after static visibility reconstruction: the leaf is a moving component.
	var gate:Node2D=preload("res://scenes/overworld/props/kael_gate.tscn").instantiate()
	world.call_deferred("add_child",gate)
	var mail:=[5.32,18.46,5.63,18.60]
	solid(world,mail,20,38,Color("2b5ba5"),Color("303b58"),Color("55709b"))
	world.wall_patch(mail,false,.12,.88,34,35,Color("18394e"),.012)
	world.face([Vector3(5.475,18.62,31),Vector3(5.55,18.62,27),Vector3(5.475,18.62,23),Vector3(5.40,18.62,27)],PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),"ink",Color("c8cdd1"))
