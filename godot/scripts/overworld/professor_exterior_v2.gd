extends RefCounted
## Fachada aprovada, 1 texel = 1 px. Usa o mesmo depth atlas dos atores da Vila.
const BASE := "res://assets/campaign/professor-laboratorio-v2/fachada/"
const Pixelgen = preload("res://scripts/pixelgen_sprites.gd")
const ENTRANCE := Vector2(7.25,-1)
const THRESHOLD := Vector2(6.75,-4.55)
const LOT := [.5,-10.0,14.0,-1.0]

static func in_rect(p:Vector2,b:Array) -> bool:
	return p.x>=b[0] and p.x<=b[2] and p.y>=b[1] and p.y<=b[3]

static func added_height(p:Vector2,stepped:bool=false) -> float:
	# Eixos medidos no chão pintado; o corrimão fica acima e não é o apoio.
	if in_rect(p,[5.0,-4.85,8.3,-3.5]):return 24
	if in_rect(p,[8.3,-5.0,9.2,-4.3]):return lerpf(24,12,(p.x-8.3)/.9)
	if in_rect(p,[9.2,-5.15,13.7,-2.05]):return 12
	var stairs_a:=Vector2(6.75,-2.44)
	var stairs_b:=Vector2(7.03,-3.78)
	var axis:=stairs_b-stairs_a
	var t:float=(p-stairs_a).dot(axis)/axis.length_squared()
	if t>=0 and t<=1 and p.distance_to(stairs_a+axis*t)<1.0:
		return ceil(t*3)*8 if stepped else t*24
	var ramp_a:=Vector2(3.6,-2.6)
	var ramp_b:=Vector2(5.3,-3.65)
	axis=ramp_b-ramp_a
	t=(p-ramp_a).dot(axis)/axis.length_squared()
	if t>=0 and t<=1.08 and p.distance_to(ramp_a+axis*t)<.55:return clampf(t,0,1)*24
	return 0

static func place(world:Node2D) -> void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"manifesto.json"))
	var texture:Texture2D=Pixelgen.load_texture(BASE+"atlas.png")
	var ground:float=world.patch_height(world.find_surface("0:-1"),Vector2(.5,-1))
	var origin:Vector2=world.iso(Vector2(.5,-1),ground)-Vector2(24,316)
	for item:Dictionary in data.parts:
		var src:Array=item.source_rect
		var cuts:Array=[src[0],src[0]+src[2]]
		if item.id=="estrutura":
			cuts=[src[0],310,570,src[0]+src[2]]
		for i in cuts.size()-1:
			if cuts[i+1]>cuts[i]:piece(world,texture,item,origin,ground,cuts[i],cuts[i+1])
	# Corpos sólidos, deixando faixa frontal, escada, rampa e patamar livres.
	for b in [[1.05,-9.4,5.65,-4.05],[5.65,-9.0,8.05,-4.85],[8.05,-9.4,13.65,-5.15],[11.15,-4.55,13.35,-3.0],[9.75,-3.35,10.75,-2.75],[10.0,-4.0,11.2,-3.35],[.65,-3.55,3.35,-2.25],[12.8,-4.7,13.7,-2.6]]:
		world.blockers.append({"bounds":b,"id":"professor-v2"})
	# Cerca do pátio: três lados; acesso pelo lado de trás junto ao prédio.
	for b in [[9.2,-4.0,9.35,-2.05],[9.2,-2.15,13.7,-2.0],[13.6,-4.1,13.75,-2.05]]:
		world.blockers.append({"bounds":b,"id":"cerca-professor-v2"})
	world.houses.append({"id":"professor","bounds":LOT,"door":ENTRANCE,"door_threshold":THRESHOLD,"height":ground,"variant":"professor","paintedModel":"professor-v2","native_pixel_scale":1.0})

static func piece(world:Node2D,texture:Texture2D,item:Dictionary,origin:Vector2,ground:float,left:int,right:int) -> void:
	var r:Array=item.atlas_rect.duplicate()
	var src:Array=item.source_rect.duplicate()
	r[0]+=left-src[0]
	r[2]=right-left
	src[0]=left
	src[2]=right-left
	var top_left:=origin+Vector2(src[0],src[1])
	var size:=Vector2(src[2],src[3])
	var poly:=PackedVector2Array([top_left,top_left+Vector2(size.x,0),top_left+size,top_left+Vector2(0,size.y)])
	var uv:=PackedVector2Array([Vector2(r[0],r[1]),Vector2(r[0]+r[2],r[1]),Vector2(r[0]+r[2],r[1]+r[3]),Vector2(r[0],r[1]+r[3])])
	for i in uv.size():uv[i]/=texture.get_size()
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=poly
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node:=MeshInstance2D.new()
	node.name="LaboratorioV2_"+item.id+"_"+str(left)
	node.mesh=mesh
	node.texture=texture
	node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var a:Array=item.ground_anchor_cells
	var sum:float=a[0]+a[1]
	var plane:=Vector3(0,-1,sum*48)
	if item.id in ["piso","escada","rampa"]:plane=Vector3(0,2,ground*3+.4)
	elif item.id=="portico" or item.id=="torre":plane=Vector3(1.5,-1,-4.8*96)
	elif item.id=="painel" or item.id=="telhado-b":plane=Vector3(1.5,-1,-5.1*96)
	elif item.id=="telhado-a":plane=Vector3(1.5,-1,-4.0*96)
	elif item.id=="cabine":plane=Vector3(1.5,-1,-3.1*96)
	elif item.id=="estrutura":
		if left>=570:plane=Vector3(-1.5,-1,13.65*96)
		else:plane=Vector3(1.5,-1,(-5.1 if left>=310 else -4.0)*96)
	world.queue(node,sum*32+ground+float(item.draw_order)*.001,poly,plane)
	var queued:Dictionary=world.parts.back()
	queued.surface="professor-v2"
	queued.transparent=true
	queued.skip_terrain_clip=true
	queued.professor_piece=item.id
