extends SceneTree
## Etapa 3: recortes sem reamostragem do quadro-chave aprovado.
var base := "res://../art/professor-laboratorio-v2/fachada/"
var dest := base + "kit/"
var canvas_size := Vector2i(768, 576)
var atlas_size := Vector2i(1024, 2048)
var parts:Array=[]

func _initialize() -> void:
	build.call_deferred()

func part(id:String,label:String,polygon:Array,cells:Array,anchor:Array,z:float=0) -> void:
	var poly:=PackedVector2Array()
	for xy in polygon:poly.append(Vector2(xy[0],xy[1]))
	parts.append({"id":id,"label":label,"mask":poly,"footprint_cells":cells,"ground_anchor_cells":anchor,"support_height_px":z,"image":Image.create(canvas_size.x,canvas_size.y,false,Image.FORMAT_RGBA8),"pixels":0})

func canvas_anchor(a:Array,z:float) -> Vector2i:
	var u:float=a[0]-.5
	var v:float=a[1]+1
	return Vector2i(roundi(24+(u-v)*32),roundi(316+(u+v)*16-z))

func definitions() -> void:
	part("piso","Piso e soleiras",[],[.5,-10,14,-1],[.5,-1])
	part("estrutura","Paredes e janelas",[[128,133],[265,53],[343,25],[412,54],[493,92],[606,184],[736,248],[736,389],[714,402],[573,449],[424,365],[392,347],[271,328],[135,271],[135,150]], [1.05,-9.4,13.45,-4],[7.25,-4],24)
	part("telhado-a","Abóbada esquerda",[[120,0],[410,0],[410,217],[310,224],[270,210],[250,190],[225,175],[200,161],[175,153],[150,152],[120,165]],[.85,-9.5,6.05,-3.8],[3.45,-3.8],24)
	part("telhado-b","Abóbada direita",[[375,80],[760,80],[760,260],[720,275],[572,329],[549,305],[517,279],[481,255],[444,238],[408,227],[375,230]],[7.5,-9.6,13.7,-5.1],[10.6,-5.1],24)
	part("torre","Torre envidraçada",[[310,109],[409,52],[490,92],[490,195],[399,243],[310,199]],[5.65,-7.9,8.05,-4.8],[6.85,-4.8],24)
	part("portico","Pórtico e portas",[[270,203],[386,244],[386,352],[270,323]],[5.45,-5.15,8.2,-4],[6.75,-4],24)
	part("painel","Painel verde-água",[[384,225],[427,238],[427,355],[385,337]],[8.2,-5.3,8.8,-5.2],[8.5,-5.2],24)
	part("escada","Escada e corrimãos",[[208,337],[268,306],[373,348],[374,368],[318,410],[207,367]],[5.75,-4,8.55,-2.2],[7.15,-2.2])
	part("rampa","Rampa e corrimão",[[155,319],[235,274],[272,292],[272,311],[215,350],[210,367],[157,343]],[4.35,-4,5.3,-2.05],[4.8,-2.05])
	part("cerca-fundo","Alambrado posterior",[[316,405],[423,348],[604,415],[604,439],[423,370],[317,431]],[9.3,-5.1,13.7,-2.05],[11.5,-4.9],12)
	part("cerca-frente","Alambrado frontal",[[315,409],[474,489],[606,418],[607,448],[474,522],[315,440]],[9.3,-4.1,13.7,-2.05],[11.5,-2.05],12)
	part("cabine","Cabine e computador",[[443,378],[494,351],[543,370],[559,400],[560,444],[507,473],[444,438]],[11.15,-4.55,13.35,-3],[12.25,-3],12)
	part("mesa-maleta","Mesa e maleta dourada",[[364,416],[391,405],[423,420],[423,451],[400,467],[364,446]],[9.75,-3.35,10.75,-2.75],[10.25,-2.75],12)
	part("caixa-patio","Caixa de equipamento",[[399,388],[428,374],[449,390],[450,417],[423,432],[399,418]],[10,-4,11.2,-3.35],[10.6,-3.35],12)
	part("cone","Cone",[[442,462],[451,454],[460,462],[465,486],[451,494],[439,484]],[13.05,-2.6,13.4,-2.3],[13.2,-2.3],12)
	part("arco","Arco e haste",[[467,112],[479,101],[495,96],[513,101],[533,115],[549,135],[561,159],[552,166],[525,148],[523,156],[548,158],[551,166],[523,169],[523,182],[530,189],[529,199],[506,204],[491,197],[492,189],[503,182],[503,169],[466,170],[464,161],[500,156],[500,126],[489,119],[477,127]],[8.7,-7.9,10.6,-6.9],[9.7,-7.25],190)
	part("anemometro","Anemômetro",[[572,132],[584,127],[585,122],[598,121],[603,132],[615,136],[630,145],[629,158],[614,163],[612,198],[620,206],[615,216],[599,219],[587,213],[588,203],[597,197],[596,161],[577,158],[567,149]],[10.9,-8.1,12.3,-7.1],[11.6,-7.6],180)
	part("arvores","Árvores da lateral",[[76,191],[83,153],[102,119],[114,97],[140,76],[164,69],[204,80],[207,95],[160,124],[137,142],[137,241],[123,254],[101,248],[103,222],[80,217]],[.6,-9.8,2.2,-6.5],[1.3,-6.5])
	part("canteiro-esquerdo","Canteiro florido esquerdo",[[62,277],[78,250],[110,240],[135,249],[158,258],[179,260],[199,271],[216,290],[216,312],[175,338],[63,301]],[.65,-3.55,3.35,-2.25],[2,-2.25])
	part("jardim-direito","Jardim lateral direito",[[601,411],[619,384],[645,366],[665,352],[684,352],[703,371],[716,381],[716,406],[607,449]],[12.8,-4.7,13.7,-2.6],[13.25,-2.6])
	part("planta-portico","Planta junto à entrada",[[382,353],[389,337],[400,322],[419,321],[434,339],[443,355],[433,367],[413,381],[383,370]],[8.8,-4,9.55,-3.1],[9.2,-3.1],12)
	part("canteiro-frente","Canteiro dianteiro do pátio",[[314,438],[331,436],[358,445],[389,463],[417,477],[421,492],[410,501],[314,453]],[9.8,-2.1,12.9,-1.45],[11.3,-1.45])
	part("balizador-a","Balizador esquerdo",[[110,316],[124,315],[127,351],[121,359],[110,354]],[3.35,-1.6,3.6,-1.3],[3.5,-1.3])
	part("balizador-b","Balizador central",[[289,413],[304,410],[307,443],[301,453],[289,449]],[8.35,-1.6,8.65,-1.3],[8.5,-1.3])

func build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dest+"pecas"))
	var source:=Image.load_from_file(ProjectSettings.globalize_path(base+"quadro-chave.png"))
	source.convert(Image.FORMAT_RGBA8)
	if not check(source.get_size()==canvas_size,"Quadro-chave mudou de tamanho"):return
	definitions()
	for y in source.get_height():
		for x in source.get_width():
			var color:=source.get_pixel(x,y)
			if color.a==0:
				# RGB de pixels invisíveis não faz parte de nenhum recorte.
				source.set_pixel(x,y,Color(0,0,0,0))
				continue
			var owner := base_part(Vector2(x + .5, y + .5))
			for i in range(1,parts.size()):
				if parts[i].mask.size() >= 3 and Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),parts[i].mask):owner=i
			parts[owner].image.set_pixel(x,y,color)
			parts[owner].pixels+=1
	var atlas:=Image.create(atlas_size.x,atlas_size.y,false,Image.FORMAT_RGBA8)
	var assembled:=Image.create(canvas_size.x,canvas_size.y,false,Image.FORMAT_RGBA8)
	var debug:=Image.create(canvas_size.x,canvas_size.y,false,Image.FORMAT_RGBA8)
	var records:Array=[]
	var shelf:=Vector2i(2,2)
	var row_h:=0
	var sum_pixels:=0
	for i in parts.size():
		var item:Dictionary=parts[i]
		var full:Image=item.image
		var bounds:Rect2i=full.get_used_rect()
		if not check(bounds.has_area(),"Peça vazia: "+item.id):return
		var cut:=full.get_region(bounds)
		cut.save_png(dest+"pecas/"+item.id+".png")
		if not check(cut.get_width()+4<=atlas_size.x,"Peça excede a largura do atlas: "+item.id):return
		if shelf.x+cut.get_width()+2>atlas_size.x:
			shelf=Vector2i(2,shelf.y+row_h+4)
			row_h=0
		if not check(shelf.y+cut.get_height()+2<=atlas_size.y,"Atlas excedido"):return
		atlas.blit_rect(cut,Rect2i(Vector2i.ZERO,cut.get_size()),shelf)
		var pivot:=canvas_anchor(item.ground_anchor_cells,item.support_height_px)
		records.append({"id":item.id,"label":item.label,"file":"pecas/"+item.id+".png","atlas_rect":[shelf.x,shelf.y,bounds.size.x,bounds.size.y],"source_rect":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"pivot_px":[pivot.x-bounds.position.x,pivot.y-bounds.position.y],"position_px":[pivot.x,pivot.y],"draw_order":i,"footprint_cells":item.footprint_cells,"ground_anchor_cells":item.ground_anchor_cells,"support_height_px":item.support_height_px,"opaque_pixels":item.pixels})
		assembled.blend_rect(cut,Rect2i(Vector2i.ZERO,cut.get_size()),bounds.position)
		var tint:=Color.from_hsv(float(i)/parts.size(),.65,.9)
		for y in bounds.size.y:
			for x in bounds.size.x:
				if cut.get_pixel(x,y).a>0:debug.set_pixelv(bounds.position+Vector2i(x,y),tint)
		shelf.x+=cut.get_width()+4
		row_h=maxi(row_h,cut.get_height())
		sum_pixels+=item.pixels
	atlas.save_png(dest+"atlas.png")
	assembled.save_png(dest+"remontagem.png")
	debug.save_png(dest+"mapa-de-recortes.png")
	var mismatch:=0
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y)!=assembled.get_pixel(x,y):mismatch+=1
	if not check(mismatch==0,"Remontagem difere do quadro-chave"):return
	var manifest:={"version":1,"type":"kit de montagem fixa por recortes visíveis","source":"../quadro-chave.png","source_sha256":FileAccess.get_sha256(base+"quadro-chave.png"),"canvas":[canvas_size.x,canvas_size.y],"atlas":{"file":"atlas.png","size":[atlas_size.x,atlas_size.y],"padding_px":2,"filter":"nearest","mipmaps":false},"parts":records}
	manifest.merge(layout_metadata())
	var f:=FileAccess.open(dest+"manifesto.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest,"\t"))
	var proof:={"piece_count":parts.size(),"opaque_pixels_partitioned":sum_pixels,"reconstruction_mismatched_pixels":mismatch,"source_sha256":manifest.source_sha256,"atlas_size":[atlas_size.x,atlas_size.y],"padding_px":2,"stage":verification_stage()}
	f=FileAccess.open(dest+"verificacao.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(proof,"\t"))
	print(JSON.stringify(proof))
	quit()

func check(condition:bool,message:String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func layout_metadata() -> Dictionary:
	return {
		"grid": {"tile_px":[64,32], "lot_cells":[.5,-10,14,-1], "terrain_height_px":48, "reference_canvas_origin_px":[24,316], "reference_world_cell":[.5,-1]},
		"entrance_cells": [7.25,-1],
		"limitations": [
			"Recortes de superfícies visíveis, sem faces ocultas reconstruídas.",
			"Footprints são indicação de apoio da planta aprovada, não colisões prontas.",
			"Conferir encaixe do piso pintado, acesso e profundidade no mapa na etapa 4; não aplicar deformação afim ao PNG.",
		],
	}

func verification_stage() -> String:
	return "3 · kit, sem integração na Vila"

func base_part(pixel: Vector2) -> int:
	return 1 if pixel.y < 300 else 0
