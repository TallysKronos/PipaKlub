extends RefCounted
## Bioma "floresta" de Kronasta: prova das regras contra o mapa chapado
## (art/overworld/REGIOES-E-PARTES.md, seção 6, e as referências de Digimon World DS).
## Cada célula de chão é um nó ordenado por profundidade com o paredão da borda da frente,
## então um platô na frente cobre o que está atrás dele. O chão usa máscaras de trilha, mata,
## manchas e mato (bordas orgânicas, fora da grade). A moldura continua além do mapa com mata.
const KITS := "res://assets/overworld/kits/"
const Structures=preload("res://scripts/overworld/forest_structures.gd")
const RING := 9
const TREES := {"a":"comum/pecas/arvore-a.png","b":"comum/pecas/arvore-b.png","florida":"comum/pecas/arvore-florida.png","grande":"comum/pecas/arvore-tronco-largo.png"}

static func _hash(u:int,v:int,salt:int=0) -> float:
	var h:int=(u*374761393+v*668265263+salt*982451653)&0x7fffffff
	h=((h^(h>>13))*1274126177)&0x7fffffff
	return float(h%10000)/10000.0

static func build(view) -> void:
	var model = view.model
	var w:int=int(model.data.w)
	var h:int=int(model.data.h)
	var material:=ShaderMaterial.new()
	material.shader=load("res://shaders/kronasta_ground.gdshader")
	material.set_shader_parameter("masks",_masks(model))
	material.set_shader_parameter("grass_a",load(KITS+"terrenos-v1/superficies/grama-campo.png"))
	material.set_shader_parameter("grass_b",load(KITS+"terrenos-v1/superficies/grama-musgo.png"))
	material.set_shader_parameter("dirt",load(KITS+"terrenos-v1/superficies/terra-ocre.png"))
	material.set_shader_parameter("map_size",Vector2(w,h))
	var blank:=Image.create(1,1,false,Image.FORMAT_RGBA8)
	blank.fill(Color.WHITE)
	var white:=ImageTexture.create_from_image(blank)
	var wall_texture:Texture2D=load(KITS+"terrenos-v1/superficies/terra-barranco.png")
	var exits:=_exit_columns(model)
	for v in range(-RING,h+RING):
		for u in range(-RING,w+RING):
			var inside:=u>=0 and v>=0 and u<w and v<h
			var node:=Node2D.new()
			node.position=Vector2((u-v)*32,(u+v)*16+2)
			view.actors.add_child(node)
			var poly:=Polygon2D.new()
			var corners:=[Vector2(u,v),Vector2(u+1,v),Vector2(u+1,v+1),Vector2(u,v+1)]
			var points:=PackedVector2Array()
			var uvs:=PackedVector2Array()
			var colors:=PackedColorArray()
			var level:=int(model.cell_at(Vector2i(u,v)).get("level",0)) if inside else 0
			# Platô um pouco mais claro que o chão de baixo; rampa sombreada pelo lado em que sobe
			# (subindo para +u/+v ela vira de costas para a câmera e escurece).
			var tone:=.88+.18*level
			if inside and model.cell_at(Vector2i(u,v)).get("ramp")!=null:
				tone*=.80 if str(model.cell_at(Vector2i(u,v)).ramp) in ["u+","v+"] else 1.12
			for corner in corners:
				var height:=_corner_height(model,u,v,corner) if inside else 0.0
				points.append(_screen(corner,height)-node.position)
				uvs.append(corner)
				colors.append(Color(tone,tone,tone))
			poly.polygon=points
			poly.uv=uvs
			poly.vertex_colors=colors
			poly.texture=white
			poly.material=material
			if OS.get_environment("KRONASTA_GEOMETRIA")=="1":
				# Conferência geométrica: cores chapadas por nível, rampa em vermelho.
				poly.material=null
				var c:Dictionary=model.cell_at(Vector2i(u,v)) if inside else {}
				var flat:=Color("6a8f4e") if c.is_empty() or int(c.level)==0 else Color("b9d77a") if int(c.level)==1 else Color("d9e9a8")
				if not c.is_empty() and c.material=="bosque":flat=flat.darkened(.28)
				if not c.is_empty() and c.material=="terra":flat=Color("cbac72")
				if not c.is_empty() and c.get("ramp")!=null:flat=Color("d0473b") if str(c.ramp) in ["u+","v+"] else Color("e0a03a")
				poly.vertex_colors=PackedColorArray([flat,flat,flat,flat])
			Structures.floor_cut(model,node,poly,corners,u,v)
			if inside:
				_walls(view,model,node,u,v,wall_texture)
				if bool(model.data.get("forest",{}).get("nativeProps",false)) and model.cell_at(Vector2i(u,v)).material=="mato" and OS.get_environment("KRONASTA_GEOMETRIA")!="1":
					view._encounter_tufts(Vector2i(u,v),model.cell_at(Vector2i(u,v)))
			elif OS.get_environment("KRONASTA_GEOMETRIA")!="1" and _hash(u,v,7)<.82 and not Structures.is_water(model,Vector2(u+.5,v+.5)) and not _near_exit(u,v,w,h,exits) and _hidden_behind(model,u,v)>4:
				_tree(view,model,Vector2(u+.5+(_hash(u,v,3)-.5)*.5,v+.5+(_hash(u,v,4)-.5)*.5),0,"a" if _hash(u,v,5)<.5 else "b",_hash(u,v,6),true)
	Structures.build(view)
	if bool(model.data.get("forest",{}).get("nativeProps",false)):
		var native_pieces: Array = []
		for piece in model.data.pieces:
			if piece.asset in ["arvore","arbusto","flores","pedra"]:_piece(view,model,piece)
			else:native_pieces.append(piece)
		if not native_pieces.is_empty():
			var preview: bool = view.art_preview
			if OS.get_environment("KRONASTA_GEOMETRIA")=="1":view.art_preview=false
			view._build_pieces(native_pieces)
			view.art_preview=preview
	else:
		for piece in model.data.pieces:_piece(view,model,piece)
	_tufts(view,model)
	for event in model.data.events:
		if OS.get_environment("KRONASTA_GEOMETRIA")!="1" and event.type=="item" and str(event.props.get("visibilidade","")) in ["visivel","brilho"]:_glint(view,model,event)

static func _screen(point:Vector2,height:float) -> Vector2:
	return Vector2((point.x-point.y)*32.0,(point.x+point.y)*16.0-height*64.0)

static func _corner_height(model,u:int,v:int,corner:Vector2) -> float:
	var cell:Dictionary=model.cell_at(Vector2i(u,v))
	return model.surface_height(cell,corner-Vector2(u,v))

# Paredão de terra nas bordas da frente (+u e +v) onde o vizinho é mais baixo: textura com
# estratos, face sudeste média e sudoeste escura, sombra na base, borda de grama dobrando.
static func _walls(view,model,node:Node2D,u:int,v:int,texture:Texture2D) -> void:
	for side in ["u","v"]:
		var n:=Vector2i(u+1,v) if side=="u" else Vector2i(u,v+1)
		var neighbour:Dictionary=model.cell_at(n)
		if neighbour.is_empty():continue
		var a:=Vector2(u+1,v) if side=="u" else Vector2(u,v+1)
		var b:=Vector2(u+1,v+1)
		var top_a:=_corner_height(model,u,v,a)
		var top_b:=_corner_height(model,u,v,b)
		var low_a:=_corner_height(model,n.x,n.y,a)
		var low_b:=_corner_height(model,n.x,n.y,b)
		if top_a<=low_a+.001 and top_b<=low_b+.001:continue
		low_a=minf(low_a,top_a);low_b=minf(low_b,top_b)
		var wall:=Polygon2D.new()
		var pts:=[_screen(a,top_a),_screen(b,top_b),_screen(b,low_b),_screen(a,low_a)]
		wall.polygon=PackedVector2Array(pts.map(func(p):return p-node.position))
		wall.texture=texture if OS.get_environment("KRONASTA_GEOMETRIA")!="1" else null
		wall.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
		var s0:=float(u+v)*44.0
		wall.uv=PackedVector2Array([Vector2(s0,-top_a*112),Vector2(s0+44,-top_b*112),Vector2(s0+44,-low_b*112),Vector2(s0,-low_a*112)])
		var lit:=Color(1.0,.97,.92) if side=="u" else Color(.70,.66,.64)
		if OS.get_environment("KRONASTA_GEOMETRIA")=="1":lit=Color("9a7652") if side=="u" else Color("775b46")
		wall.vertex_colors=PackedColorArray([lit,lit,lit*Color(.62,.60,.62),lit*Color(.62,.60,.62)])
		node.add_child(wall)
		# Borda de grama que dobra por cima do paredão, com recorte irregular.
		var lip:=Polygon2D.new()
		var lip_pts:=PackedVector2Array([pts[0]-node.position,pts[1]-node.position])
		for k in range(6,-1,-1):
			var t:=float(k)/6.0
			var drop:=4.0+_hash(u*7+k,v*3,11 if side=="u" else 13)*7.0
			lip_pts.append(pts[0].lerp(pts[1],t)-node.position+Vector2(0,drop))
		lip.polygon=lip_pts
		lip.color=Color("4a7a2a") if side=="u" else Color("3d6824")
		node.add_child(lip)
		var rim:=Line2D.new()
		rim.points=PackedVector2Array([pts[0]-node.position+Vector2(0,1),pts[1]-node.position+Vector2(0,1)])
		rim.width=2.0
		rim.default_color=Color("a7d65e")
		node.add_child(rim)
		# Sombra de contato no chão de baixo, desenhada logo depois desse chão.
		var shade:=Node2D.new()
		shade.position=Vector2((n.x-n.y)*32,(n.x+n.y)*16+3)
		view.actors.add_child(shade)
		var inner_a:=a+(Vector2(.5,0) if side=="u" else Vector2(0,.5))
		var inner_b:=b+(Vector2(.5,0) if side=="u" else Vector2(0,.5))
		var shadow:=Polygon2D.new()
		shadow.polygon=PackedVector2Array([_screen(a,low_a)-shade.position,_screen(b,low_b)-shade.position,_screen(inner_b,low_b)-shade.position,_screen(inner_a,low_a)-shade.position])
		var dark:=Color(.04,.07,.02,.42)
		shadow.vertex_colors=PackedColorArray([dark,dark,Color(dark,0),Color(dark,0)])
		shade.add_child(shadow)

static func _tree(view,model,point:Vector2,level:int,variant:String,r:float,occluder:bool,shrink:float=1.0) -> void:
	var root:=Node2D.new()
	root.set_meta("scenery",true)
	root.position=model.project(point,false)
	var contact:=Sprite2D.new()
	contact.texture=load(KITS+"comum/sombras/contato.png")
	contact.scale=Vector2(1.9,1.0)
	contact.modulate=Color(1,1,1,.7)
	contact.position=Vector2(0,-level*64-2)
	root.add_child(contact)
	var art:=Sprite2D.new()
	art.name="Art"
	art.texture=load(KITS+TREES.get(variant,TREES.a))
	art.centered=false
	var size:=(.86+r*.30)*shrink
	art.scale=Vector2(size*(-1.0 if r>.5 else 1.0),size)
	art.position=Vector2(96*size*(1.0 if r>.5 else -1.0),-272*size-level*64)
	root.add_child(art)
	view.actors.add_child(root)
	if occluder:view.occluders.append(root)

# A copa sobe ~4 fileiras de tela acima do tronco e cobre o que fica atrás (u-k, v-k).
# Devolve a distância até o primeiro chão caminhável coberto; 99 quando só cobre mata.
static func _hidden_behind(model,u:int,v:int) -> int:
	for k in range(1,6):
		for d in [Vector2i(k,k),Vector2i(k,k-1),Vector2i(k-1,k)]:
			if model.walkable(Vector2i(u,v)-d):return k
	return 99

static func _sprite(view,model,point:Vector2,level:int,file:String,anchor:Vector2,scale:float=1.0,shadow:float=0.0) -> Node2D:
	var root:=Node2D.new()
	root.set_meta("scenery",true)
	root.position=model.project(point,false)
	if shadow>0:
		var contact:=Sprite2D.new()
		contact.texture=load(KITS+"comum/sombras/contato.png")
		contact.scale=Vector2(shadow,shadow*.55)
		contact.modulate=Color(1,1,1,.6)
		contact.position=Vector2(0,-level*64-1)
		root.add_child(contact)
	var art:=Sprite2D.new()
	art.name="Art"
	art.texture=load(KITS+file)
	art.centered=false
	art.scale=Vector2.ONE*scale
	art.position=-anchor*scale-Vector2(0,level*64)
	root.add_child(art)
	view.actors.add_child(root)
	return root

static func _piece(view,model,piece:Dictionary) -> void:
	if OS.get_environment("KRONASTA_GEOMETRIA")=="1":return
	if piece.interact!=null:view.interaction_events.append({"id":"piece-"+str(piece.id),"type":"piece","name":piece.name,"asset":piece.asset,"piece_id":piece.id,"u":piece.u,"v":piece.v,"props":piece.props})
	var cell:Dictionary=model.cell_at(Vector2i(piece.u,piece.v))
	var level:=int(cell.get("level",0))
	var r:=_hash(int(piece.u),int(piece.v),21)
	var variant:=str(piece.props.get("variante",""))
	var at:=Vector2(piece.u+.5,piece.v+.5)
	match str(piece.asset):
		"arvore":
			# Copa alta na frente de chão caminhável vira arbusto ou árvore baixa: a mata
			# emoldura a trilha pelos lados e por trás, sem tampar o caminho.
			var cover:=_hidden_behind(model,int(piece.u),int(piece.v))
			if model.data.get("forest",{}).get("water")!=null and at.x>30 and at.x<47 and at.y>8 and at.y<25:return
			if cover<=2:
				return
			else:
				_tree(view,model,at+Vector2(r-.5,_hash(int(piece.u),int(piece.v),22)-.5)*.36,level,variant,r,true,.62 if cover<=3 else .8 if cover<=4 else 1.0)
		"arbusto":
			if _hidden_behind(model,int(piece.u),int(piece.v))<=2:return
			var bush:=_sprite(view,model,at,level,"parque/decalques/arbusto-baixo-"+("a" if variant=="a" else "b")+".png",Vector2(48,45),1.15+r*.3,1.5)
			view.occluders.append(bush)
		"banco":_sprite(view,model,at,level,"comum/pecas/banco-madeira.png",Vector2(48,120),1.4,1.4)
		"pedra":_sprite(view,model,at,level,"comum/pecas/pedra-"+variant+".png",Vector2(32,80),1.0,.9)
		"flores":_sprite(view,model,at,level,"comum/pecas/flores-"+variant+".png",Vector2(32,80),1.0,0.0)
		"placa-mapa":_sprite(view,model,at,level,"comum/pecas/placa-mapa-parque.png",Vector2(64,160),.9,1.2)

# Tufos de capim concentrados nas bordas (mata e trilha), raros no meio da grama.
static func _tufts(view,model) -> void:
	if OS.get_environment("KRONASTA_GEOMETRIA")=="1":return
	for v in int(model.data.h):
		for u in int(model.data.w):
			var cell:Dictionary=model.cell_at(Vector2i(u,v))
			if cell.material!="grama" or cell.get("ramp")!=null:continue
			var edge:=false
			for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
				var n:Dictionary=model.cell_at(Vector2i(u,v)+d)
				if not n.is_empty() and n.material in ["bosque","terra","mato"]:edge=true
			if _hash(u,v,31)>(.55 if edge else .07):continue
			var at:=Vector2(u+.2+_hash(u,v,32)*.6,v+.2+_hash(u,v,33)*.6)
			_sprite(view,model,at,int(cell.level),"parque/decalques/capim-"+("a" if _hash(u,v,34)<.5 else "b")+".png",Vector2(26,44),.75+_hash(u,v,35)*.35)

static func _glint(view,model,event:Dictionary) -> void:
	var cell:Dictionary=model.cell_at(Vector2i(event.u,event.v))
	var root:=Node2D.new()
	root.position=model.project(Vector2(event.u+.5,event.v+.5),false)
	var star:=Polygon2D.new()
	var pts:=PackedVector2Array()
	for k in 8:
		var radius:=9.0 if k%2==0 else 3.0
		pts.append(Vector2.from_angle(TAU*k/8.0-PI/2)*radius+Vector2(0,-14-int(cell.get("level",0))*64))
	star.polygon=pts
	star.color=Color("ffe07a")
	root.add_child(star)
	view.actors.add_child(root)

static func _exit_columns(model) -> Array:
	var out:=[]
	for e in model.data.events:
		if e.type in ["saida","entrada"]:out.append(Vector2i(e.u,e.v))
	return out

static func _near_exit(u:int,v:int,w:int,h:int,exits:Array) -> bool:
	for e in exits:
		var inline:bool=(v<0 or v>=h) and absi(u-e.x)<=3 and ((v<0 and e.y<4) or (v>=h and e.y>h-5))
		var inrow:bool=(u<0 or u>=w) and absi(v-e.y)<=3 and ((u<0 and e.x<4) or (u>=w and e.x>w-5))
		if inline or inrow:return true
	return false

# Máscaras em baixa resolução, suavizadas: R terra (e rampas), G mata, B manchas, A mato.
static func _masks(model) -> ImageTexture:
	var w:int=int(model.data.w)
	var h:int=int(model.data.h)
	var grids:=[PackedFloat32Array(),PackedFloat32Array(),PackedFloat32Array()]
	for g in grids:g.resize(w*h)
	for i in w*h:
		var c:Dictionary=model.data.cells[i]
		grids[0][i]=1.0 if c.material=="terra" or c.get("ramp")!=null else 0.0
		grids[1][i]=1.0 if c.material=="bosque" else 0.0
		grids[2][i]=1.0 if c.material=="mato" else 0.0
	for g in grids:
		var copy:PackedFloat32Array=g.duplicate()
		for v in h:
			for u in w:
				var total:=0.0
				var weight:=0.0
				for dv in [-1,0,1]:
					for du in [-1,0,1]:
						var x:int=clampi(u+du,0,w-1)
						var y:int=clampi(v+dv,0,h-1)
						var k:=2.0 if du==0 and dv==0 else 1.0
						total+=copy[y*w+x]*k;weight+=k
				g[v*w+u]=total/weight
	# Rampa é terra inteira, sem o desfoque da borda: a subida precisa ler como caminho.
	for i in w*h:
		if model.data.cells[i].get("ramp")!=null:grids[0][i]=1.0
	var scale:=4
	var image:=Image.create(w*scale,h*scale,false,Image.FORMAT_RGBA8)
	var noise:=FastNoiseLite.new()
	noise.seed=int(model.data.w)*7+int(model.data.h)
	noise.frequency=.045
	noise.fractal_octaves=3
	for y in h*scale:
		for x in w*scale:
			var fu:=float(x)/scale-.5+.125
			var fv:=float(y)/scale-.5+.125
			var sample:=func(g:PackedFloat32Array) -> float:
				var u0:int=clampi(floori(fu),0,w-1);var v0:int=clampi(floori(fv),0,h-1)
				var u1:int=clampi(u0+1,0,w-1);var v1:int=clampi(v0+1,0,h-1)
				var tx:=clampf(fu-floorf(fu),0,1);var ty:=clampf(fv-floorf(fv),0,1)
				return lerpf(lerpf(g[v0*w+u0],g[v0*w+u1],tx),lerpf(g[v1*w+u0],g[v1*w+u1],tx),ty)
			image.set_pixel(x,y,Color(sample.call(grids[0]),sample.call(grids[1]),noise.get_noise_2d(x*.25,y*.25)*.5+.5,sample.call(grids[2])))
	return ImageTexture.create_from_image(image)
