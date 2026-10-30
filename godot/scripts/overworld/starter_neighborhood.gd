extends "res://scripts/overworld/pier_precision.gd"
## Three inhabited streets, with geometry and foot support from the same cells.
const KIT := "res://assets/overworld/kits/bairro-inicial-v2/"
const INK := Color("293D43")
var lookup: Dictionary = {}
var blockers: Array[Dictionary] = []
var people: Array[Dictionary] = []
var houses: Array[Dictionary] = []
var prop_cache: Dictionary = {}
# Shared art-scale reference: an overworld person occupies 51 source pixels.
# Vehicle image height includes the projected ground footprint as well as body.
const PERSON_HEIGHT := 51.0
const VEHICLE_HEIGHTS := {"fusca-azul":100.0,"kombi-oficina":128.0,"jipe-pesquisa":118.0}
const BUS_STOP_HEIGHT := 130.0
const FOUNDATION_BOTTOM := -40.0
var road_names := ["Rua do Primeiro Vento","Ladeira das Rabiolas","Rua dos Inventos"]

static func cell_id(u: int,v: int) -> String:return "%d:%d" % [u,v]

func kind_at(p: Vector2) -> String:
	# Lower stair landing turns into the existing pedestrian sidewalk at u=11.
	if p.x>=8 and p.x<11 and p.y>=11 and p.y<13:return "paving"
	if (p.y>=1 and p.y<5) or (p.y>=21 and p.y<25) or (p.x>=13 and p.x<17 and p.y>=5 and p.y<21):return "asphalt"
	if (p.y>=-1 and p.y<7) or (p.y>=19 and p.y<27) or (p.x>=11 and p.x<19 and p.y>=7 and p.y<19):return "paving"
	if p.x>=20 and p.x<24 and p.y>=16 and p.y<19:return "paving"
	if p.x>=4 and p.x<6 and p.y>=16 and p.y<19:return "paving"
	return "grass"

func patch_height(s: Dictionary,p: Vector2) -> float:
	var center := Vector2(s.bounds[0]+.5,s.bounds[1]+.5)
	var h := 48.0 if center.y<7 else 0.0
	if center.x>=8 and center.x<19 and center.y>=7 and center.y<11:h = clampf((11.0-p.y)/4.0,0,1)*48.0
	if s.get("shortcut",false):return 8.0+clampf((11.0-p.y)/4.0,0,1)*48.0
	var offset := 0.0 if s.kind=="asphalt" else 8.0
	# Curb cuts meet the road exactly; no wall is drawn across the mouth.
	if (center.x>=9 and center.x<11) or (center.x>=20 and center.x<22):
		if center.y>=0 and center.y<1:offset = 8.0*(1.0-p.y)
		if center.y>=5 and center.y<6:offset = 8.0*(p.y-5.0)
		if center.y>=20 and center.y<21:offset = 8.0*(21.0-p.y)
		if center.y>=25 and center.y<26:offset = 8.0*(p.y-25.0)
	if center.y>=16 and center.y<18:
		if center.x>=12 and center.x<13:offset = 8.0*(13.0-p.x)
		if center.x>=17 and center.x<18:offset = 8.0*(p.x-17.0)
	return h+clampf(offset,0,8)

func surface_height(s: Dictionary,p: Vector2,stepped: bool=false) -> float:
	if stepped and s.get("shortcut",false):return 8.0+ceil(clampf((11.0-p.y)/4.0,0,1)*8.0)*6.0
	return patch_height(s,p)

func find_surface(id: String) -> Dictionary:return lookup.get(id,{})

func support(p: Vector2) -> float:
	var s: Dictionary = lookup.get(cell_id(floori(p.x),floori(p.y)),{})
	return patch_height(s,p) if not s.is_empty() else 0.0

func plan() -> void:
	surfaces.clear();lookup.clear()
	for u in range(0,32):
		for v in range(-7,28):
			var point := Vector2(u+.5,v+.5)
			var s := {"id":cell_id(u,v),"bounds":[u,v,u+1,v+1],"kind":kind_at(point),"height":0.0,"neighbors":[]}
			if u>=8 and u<10 and v>=7 and v<11:s.kind="paving";s.shortcut=true
			s.height = patch_height(s,point)
			for d in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN]:
				if u+d.x>=0 and u+d.x<32 and v+d.y>=-7 and v+d.y<28:s.neighbors.append(cell_id(u+d.x,v+d.y))
			lookup[s.id]=s;surfaces.append(s)

func terrain_cell(s: Dictionary) -> void:
	if s.get("shortcut",false):
		shortcut_steps(s)
		return
	var cells := rect(s.bounds)
	var points: Array = []
	var uv := PackedVector2Array()
	for p in cells:
		points.append(Vector3(p.x,p.y,patch_height(s,p)))
		uv.append(p/(16.0 if s.kind=="paving" else 20.0 if s.kind=="grass" else 16.0))
	var tint := Color.WHITE
	if geometry_only:tint = Color("C7BD8D") if s.kind=="paving" else Color("526D74") if s.kind=="asphalt" else Color("7E9B67")
	face(points,uv,s.kind if not geometry_only else "ink",tint)
	for i in range(4):
		var a := cells[i]
		var b := cells[(i+1)%4]
		var outward := Vector2(b.y-a.y,a.x-b.x).normalized()
		var neighbor: Dictionary = lookup.get(cell_id(floori(((a+b)*.5+outward*.03).x),floori(((a+b)*.5+outward*.03).y)),{})
		if neighbor.is_empty():
			foundation_edge(s,a,b,outward)
			continue
		var ha := patch_height(s,a)
		var hb := patch_height(s,b)
		var la := patch_height(neighbor,a)
		var lb := patch_height(neighbor,b)
		if maxf(ha-la,hb-lb)<.01:continue
		var vertices: Array = []
		for p in [Vector3(a.x,a.y,ha),Vector3(b.x,b.y,hb),Vector3(b.x,b.y,lb),Vector3(a.x,a.y,la)]:
			if vertices.is_empty() or vertices.back().distance_to(p)>.001:vertices.append(p)
		if vertices.size()>2 and vertices[0].distance_to(vertices.back())<.001:vertices.pop_back()
		if vertices.size()<3:continue
		var wall_uv := PackedVector2Array()
		for p in vertices:wall_uv.append(Vector2((p.x+p.y)/16,p.z/128))
		var cliff := maxf(ha-la,hb-lb)>16
		face(vertices,wall_uv,"stone" if cliff else "ink",Color("FFFFFF") if cliff else Color("B9B7A7"))
		line3([Vector3(a.x,a.y,ha),Vector3(b.x,b.y,hb)],Color("E2D5AB"),.9)

func foundation_edge(s: Dictionary,a: Vector2,b: Vector2,outward: Vector2) -> void:
	# Only perimeter edges: internal neighbors never acquire a foundation wall.
	# All four sides share one bottom elevation, including the raised district.
	var ha := patch_height(s,a)
	var hb := patch_height(s,b)
	var shade := Color.WHITE if outward.y>0 else Color("CFBDB0") if outward.x>0 else Color("B9A18F")
	var points := [Vector3(a.x,a.y,ha),Vector3(b.x,b.y,hb),Vector3(b.x,b.y,FOUNDATION_BOTTOM),Vector3(a.x,a.y,FOUNDATION_BOTTOM)]
	var uv:=PackedVector2Array()
	for p: Vector3 in points:
		uv.append(Vector2((p.x+p.y)/24.0,-p.z/160.0))
	face(points,uv,"foundation",shade)
	# Thin compact soil lip under the paving/grass; no decorative top overhang.
	quad(a,b,b,a,ha,hb,hb-5.0,ha-5.0,"ink",Color("685140")*shade)
	line3([Vector3(a.x,a.y,FOUNDATION_BOTTOM),Vector3(b.x,b.y,FOUNDATION_BOTTOM)],Color("382F2B"),1.0)

func shortcut_steps(s: Dictionary) -> void:
	var u0: float=s.bounds[0]
	var u1: float=s.bounds[2]
	for i in range(8):
		var v0 := maxf(float(s.bounds[1]),7.0+float(i)*.5)
		var v1 := minf(float(s.bounds[3]),7.0+float(i+1)*.5)
		if v1<=v0+.001:continue
		var h := 56.0-float(i)*6.0
		var p := rect([u0,v0,u1,v1])
		# The same world UV scale/phase as both landings, not quad()'s /4.
		var tread_uv:=PackedVector2Array()
		var tread_points: Array=[]
		for corner: Vector2 in p:
			tread_points.append(Vector3(corner.x,corner.y,h))
			tread_uv.append(corner/16.0)
		face(tread_points,tread_uv,"paving")
		if absf(v1-(7.0+float(i+1)*.5))<.001:
			quad(Vector2(u0,v1),Vector2(u1,v1),Vector2(u1,v1),Vector2(u0,v1),h,h,h-6,h-6,"ink",Color("B4AD96"))
			line3([Vector3(u0,v1,h),Vector3(u1,v1,h)],Color("E1D5B0"),1)
		for u in [u0,u1]:
			if absf(u-8.0)>.001 and absf(u-10.0)>.001:continue
			var bottom0 := 8.0 if u==8.0 else 8.0+clampf((11.0-v0)/4.0,0,1)*48.0
			var bottom1 := 8.0 if u==8.0 else 8.0+clampf((11.0-v1)/4.0,0,1)*48.0
			var cheek: Array=[Vector3(u,v0,h),Vector3(u,v1,h),Vector3(u,v1,bottom1)]
			if absf(h-bottom0)>.001:cheek.append(Vector3(u,v0,bottom0))
			face(cheek,PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]).slice(0,cheek.size()),"ink",Color("A6A48C"))
	# Build each continuous handrail once, anchored to treads and both landings.
	if int(u0)==8 and int(s.bounds[1])==7:
		for u in [8.08,9.92]:
			blockers.append({"bounds":[u-.035,6.85,u+.035,11.35],"id":"corrimao-escada"})
			for v in [6.85,7.8,8.8,9.8,11.2]:
				var surface: Dictionary=find_surface(cell_id(floori(u),floori(v)))
				var foot: float=surface_height(surface,Vector2(u,v),true)
				var rail: float=8.0+clampf((11.0-v)/4.0,0,1)*48.0+32.0
				line3([Vector3(u,v,foot),Vector3(u,v,rail)],Color("586C66"),1.8)
			line3([Vector3(u,6.85,88),Vector3(u,7,88),Vector3(u,11,40),Vector3(u,11.35,40)],Color("687B70"),2.2)

func paint(b: Array,color: Color,bias: float=.15) -> void:
	var cells := rect(b)
	var points: Array = []
	for p in cells:points.append(Vector3(p.x,p.y,support(p)+bias))
	face(points,PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),"ink",color)

func volume(b: Array,bottom: float,top: float,color: Color) -> void:
	var p := rect(b)
	for i in [1,2]:
		var j: int = (i+1)%4
		face([Vector3(p[i].x,p[i].y,top),Vector3(p[j].x,p[j].y,top),Vector3(p[j].x,p[j].y,bottom),Vector3(p[i].x,p[i].y,bottom)],PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),"ink",color.darkened(.16) if i==1 else color)
	quad(p[0],p[1],p[2],p[3],top,top,top,top,"ink",color.lightened(.10))

func wall_patch(b: Array,side: bool,t0: float,t1: float,z0: float,z1: float,color: Color,out: float=.025) -> void:
	var a := Vector2(b[2]+out,lerpf(b[3],b[1],t0)) if side else Vector2(lerpf(b[0],b[2],t0),b[3]+out)
	var c := Vector2(b[2]+out,lerpf(b[3],b[1],t1)) if side else Vector2(lerpf(b[0],b[2],t1),b[3]+out)
	quad(a,c,c,a,z1,z1,z0,z0,"ink",color)

func window(b: Array,side: bool,t0: float,t1: float,h: float,tall: float) -> void:
	wall_patch(b,side,t0-.018,t1+.018,h-2,h+tall+2,Color("D8B681"))
	wall_patch(b,side,t0,t1,h,h+tall,Color("264F61"),.045)
	wall_patch(b,side,t0+.02,(t0+t1)*.5-.012,h+2,h+tall-2,Color("4597A1"),.05)
	wall_patch(b,side,(t0+t1)*.5+.012,t1-.02,h+2,h+tall-2,Color("317481"),.05)
	wall_patch(b,side,t0-.03,t1+.03,h-4,h-1,Color("B78A57"),.10)

func gable_roof(b: Array,h: float,color: Color) -> void:
	var center := (float(b[1])+float(b[3]))*.5
	var ridge := h+31.0
	var u0: float = b[0]-.25
	var u1: float = b[2]+.25
	var front: float = b[3]+.30
	var back: float = b[1]-.30
	face([Vector3(b[2],b[1],h),Vector3(b[2],center,ridge),Vector3(b[2],b[3],h)],PackedVector2Array([Vector2.ZERO,Vector2(.5,1),Vector2.RIGHT]),"ink",Color("D9D2AC"))
	for edge in [back,front]:
		var p := [Vector3(u0,edge,h+2),Vector3(u1,edge,h+2),Vector3(u1,center,ridge),Vector3(u0,center,ridge)]
		face(p,PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2.ZERO]),"roof",Color.WHITE)
		var roof_material := ShaderMaterial.new()
		roof_material.shader = load("res://shaders/overworld/neighborhood_roof.gdshader")
		roof_material.set_shader_parameter("roof_color",color if edge==front else color.darkened(.14))
		parts.back().node.material = roof_material
		line3([p[0],p[1]],INK,1.5)
	line3([Vector3(u0,center,ridge),Vector3(u1,center,ridge)],INK,2)

func building(b: Array,id: String,variant: String) -> void:
	preload("res://scripts/overworld/neighborhood_architecture.gd").place(self,b,id,variant)

func street_sign(p: Vector2,h: float,text: String,scale_value: float=1.0,standing: bool=false) -> void:
	if text.is_empty():return
	if standing:
		line3([Vector3(p.x,p.y,support(p)),Vector3(p.x,p.y,h+7)],INK,2.0)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font",load("res://assets/campaign/ui-modern/fonts/BarlowCondensed-Bold.ttf"))
	label.add_theme_font_size_override("font_size",15)
	label.add_theme_color_override("font_color",Color("FFF0C9"))
	label.add_theme_color_override("font_outline_color",INK)
	label.add_theme_constant_override("outline_size",5)
	label.position = iso(p,h)-Vector2(text.length()*3.8,8)*scale_value
	label.scale = Vector2.ONE*scale_value
	label.z_index = 4
	add_child(label)

func billboard(path: String,p: Vector2,h: float,height_pixels: float,flip: bool=false,crop: Rect2=Rect2()) -> void:
	var key := path+str(crop)
	if not prop_cache.has(key):
		var texture: Texture2D = load(path)
		if crop.has_area():
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas=texture;atlas_texture.region=crop
			texture=ImageTexture.create_from_image(atlas_texture.get_image())
		prop_cache[key] = {"texture":texture,"bounds":texture.get_image().get_used_rect()}
	var info: Dictionary = prop_cache[key]
	var image_bounds: Rect2i = info.bounds
	var scale_value := height_pixels/float(image_bounds.size.y)
	var size: Vector2 = info.texture.get_size()*scale_value
	var pivot := Vector2(float(image_bounds.position.x+image_bounds.end.x)*.5,float(image_bounds.end.y))*scale_value
	var position_value := iso(p,h)-pivot
	var poly := PackedVector2Array([position_value,position_value+Vector2(size.x,0),position_value+size,position_value+Vector2(0,size.y)])
	var uv := PackedVector2Array([Vector2.RIGHT,Vector2.ZERO,Vector2.DOWN,Vector2.ONE]) if flip else PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=poly;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
	var mesh := ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := MeshInstance2D.new();node.mesh=mesh;node.texture=info.texture
	queue(node,(p.x+p.y)*32+h,poly,Vector3(0,-1,(p.x+p.y)*48))
	parts.back()["transparent"]=true

func garden(b: Array,gate: float) -> void:
	var h := support(Vector2(b[0]+.5,b[3]-.5))
	# Short side fences leave the center gate and all sidewalks open.
	for span in [[b[0],gate-.85],[gate+.85,b[2]]]:
		for x in range(ceili(span[0]*2),floori(span[1]*2)+1):
			var u := float(x)*.5
			volume([u-.035,b[3]-.035,u+.035,b[3]+.035],h,h+12,Color("B6AA85"))
		line3([Vector3(span[0],b[3],h+9),Vector3(span[1],b[3],h+9)],Color("E3D3A8"),2)
		blockers.append({"bounds":[span[0],b[3]-.08,span[1],b[3]+.08],"id":"fence"})

func dress() -> void:
	building([2,12,7,16],"casa-kael","kael")
	building([2,-5,8,-1.7],"professor","professor")
	building([23,-5,29,-1.7],"loja","shop")
	building([13,-6,18,-2.7],"vizinha-norte","neighbor")
	building([24,12,29,16],"vizinha-sul","neighbor")
	for row in [[1.2,11,9.8,18.2,4.4],[1.2,-6,9.8,-.15,4.9],[22.2,-6,30.8,-.15,25.9],[23,11,30.5,18.2,26.4]]:garden(row.slice(0,4),row[4])
	for u in [9.0,20.0]:
		for v in [1.2,21.2]:
			for i in range(6):paint([u,v+float(i)*.57,u+1.8,v+.26+float(i)*.57],Color("E9DFC0"))
	for i in range(7):paint([13.1+float(i)*.55,16.1,13.35+float(i)*.55,17.9],Color("E9DFC0"))
	# Sparse center road markings, absent at crossing mouths.
	for u in [2.0,6.0,15.0,24.0,29.0]:
		for v in [3.0,23.0]:paint([u,v-.035,u+1.2,v+.035],Color("CEB980"))
	for v in [6.2,12.2,19.0]:paint([14.97,v,15.03,v+.8],Color("CEB980"))
	for p in [Vector2(7,22.5),Vector2(27.6,23.0),Vector2(27,3.7)]:
		var id := "fusca-azul" if p.x<10 else "kombi-oficina" if p.y>10 else "jipe-pesquisa"
		billboard("res://assets/overworld/kits/mobilidade/pecas/"+id+"-default.png",p,support(p),VEHICLE_HEIGHTS[id],true)
		var length_cells := 4.6 if id=="kombi-oficina" else 4.0 if id=="jipe-pesquisa" else 3.6
		blockers.append({"bounds":[p.x-length_cells,p.y-1.15,p.x+.8,p.y+.65],"id":"carro"})
	for p in [Vector2(1.3,10.5),Vector2(9.0,16.5),Vector2(22.5,12),Vector2(30.4,15),Vector2(1.0,-4),Vector2(10,-4.5),Vector2(21,-4),Vector2(30.5,-4.5),Vector2(28,18.5)]:
		billboard("res://assets/overworld/kits/planicie-v1/props/arvore.png",p,support(p),90)
		blockers.append({"bounds":[p.x-.23,p.y-.23,p.x+.23,p.y+.23],"id":"arvore"})
	for p in [Vector2(11.5,1),Vector2(18.5,5.7),Vector2(11.5,19.5),Vector2(18.5,20),Vector2(22,25.8)]:
		billboard("res://assets/overworld/kits/comum/pecas/poste-ferro.png",p,support(p),86)
		blockers.append({"bounds":[p.x-.12,p.y-.12,p.x+.12,p.y+.12],"id":"poste"})
	for p in [Vector2(21,17.7),Vector2(23,17.7),Vector2(9.0,26.6)]:
		billboard("res://assets/overworld/kits/comum/pecas/banco-madeira.png",p,support(p),38)
		blockers.append({"bounds":[p.x-.95,p.y-.3,p.x+.95,p.y+.3],"id":"banco"})
	var bus := Vector2(5.6,26.6)
	billboard("res://assets/overworld/kits/mobilidade/pecas/ponto-onibus-default.png",bus,support(bus),BUS_STOP_HEIGHT)
	blockers.append({"bounds":[3.2,25.55,6.65,26.75],"id":"ponto-onibus"})
	# Mailbox fixed to a post beside Kael's open gate.
	volume([5.4,18.1,5.5,18.2],8,29,Color("8E7956"))
	volume([5.23,18.0,5.65,18.3],27,39,Color("438998"))
	wall_patch([5.23,18.0,5.65,18.3],false,.15,.85,31,33,INK,.02)
	blockers.append({"bounds":[5.23,18.0,5.65,18.3],"id":"correio"})
	for p in [Vector2(3,16.8),Vector2(6.7,16.8),Vector2(2.3,-.9),Vector2(7.2,-.9),Vector2(23.3,-.8),Vector2(28.5,-.8),Vector2(24.5,16.9)]:
		billboard("res://assets/overworld/kits/comum/pecas/vaso-ceramica.png",p,support(p),24)
	for p in [Vector2(8.7,17),Vector2(1,13),Vector2(29.7,17),Vector2(21.3,16.4)]:
		billboard("res://assets/overworld/kits/comum/pecas/flores-coral.png",p,support(p),13)
	people = [
		{"id":"assis","name":"Prof. Assis","p":Vector2(6.8,-.65),"image":"res://assets/campaign/assis-overworld.png","line":"Bom dia, Kael! O vento ganha vida nas mãos de quem cuida dele. Conheça a lojinha da Lia, aqui na rua alta."},
		{"id":"nina","name":"Nina","p":Vector2(7.2,19.7),"image":"res://assets/nina.png","line":"Aqui embaixo é a Rua do Primeiro Vento. A ladeira leva ao professor. Pela faixa, você cruza sem esbarrar nos carros!"},
		{"id":"lia","name":"Lia · Linha & Papel","p":Vector2(25.8,-.6),"image":"res://assets/campaign/morro/bia.png","line":"Pode chegar! Linha, papel e um bom conselho nunca faltam. Escolha um papel que goste de dançar com o vento, não só um que brilhe na vitrine."},
		{"id":"zeca","name":"Zeca","p":Vector2(22.8,18.5),"image":"res://assets/campaign/morro/zeca.png","line":"Um banco na sombra e espaço pra empinar pipa… essa pracinha é nosso ponto de encontro."}]
	for person in people:
		var id: String="professor" if person.id=="assis" else person.id
		person.image="res://assets/npc-ds/"+id+".png"
		var pixels=preload("res://scripts/npc_pixel_sprite.gd")
		var kael=preload("res://scripts/kael_video_avatar.gd")
		billboard(person.image,person.p,support(person.p),pixels.height_for(id,.58*kael.BODY_SCALE),false,Rect2(192,96,64,96))
		parts.back().node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	street_sign(Vector2(9.4,20),support(Vector2(9.4,20))+30,"RUA DO PRIMEIRO VENTO",.8,true)
	street_sign(Vector2(18.8,13.5),support(Vector2(18.8,13.5))+30,"LADEIRA DAS RABIOLAS",.8,true)
	street_sign(Vector2(19.8,.2),support(Vector2(19.8,.2))+30,"RUA DOS INVENTOS",.8,true)
	street_sign(Vector2(30.5,.2),support(Vector2(30.5,.2))+28,"MORRO DO SOL →",.8,true)
	street_sign(Vector2(30.5,20),support(Vector2(30.5,20))+28,"PARQUE →",.8,true)
	for p in [Vector2(18.7,23.4),Vector2(8,3.8)]:
		var verts: Array=[]
		var uv:=PackedVector2Array()
		for i in range(12):
			var c: Vector2=p+Vector2(cos(i*TAU/12),sin(i*TAU/12))*.32
			verts.append(Vector3(c.x,c.y,support(p)+.2));uv.append(Vector2.ZERO)
		face(verts,uv,"ink",Color("343E42"))
		for off in [-.12,.0,.12]:line3([Vector3(p.x-.17,p.y+off,support(p)+.25),Vector3(p.x+.17,p.y+off,support(p)+.25)],Color("87928D"),.7)

func _ready() -> void:
	textures["foundation"] = load(KIT+"surfaces/terra-fundacao.png")
	for id in ["asfalto","passeio","grama","pedra","telhado"]:
		var names := {"asfalto":"asphalt","passeio":"paving","grama":"grass","pedra":"stone","telhado":"roof"}
		var file: String = id+"-manga-v4" if id!="telhado" else id
		textures[names[id]] = load(KIT+"surfaces/"+file+".png")
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2(-6000,-6000),Vector2(6000,-6000),Vector2(6000,6000),Vector2(-6000,6000)])
	backdrop.color = Color("0B1525")
	add_child(backdrop)
	plan()
	# Close the monolithic slab underneath. It does not add walkable surfaces.
	var base := rect([0,-7,32,28])
	quad(base[0],base[1],base[2],base[3],FOUNDATION_BOTTOM,FOUNDATION_BOTTOM,FOUNDATION_BOTTOM,FOUNDATION_BOTTOM,"ink",Color("55402F"))
	for s in surfaces:terrain_cell(s)
	if not geometry_only and decorate:dress()
	order_faces()
	for item in parts:add_child(item.node)
	probe = Node2D.new();probe.visible=false;add_child(probe)
	set_process(false)
	set_process_unhandled_key_input(false)


