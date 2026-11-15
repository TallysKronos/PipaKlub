extends "res://tools/laboratorio_v2_revisao.gd"
## Etapa 1: volumes medidos em células e alturas de sprite, sem pintura final.
const ROOT_DIR := "res://../art/casa-kael-v2/"
const LOT := Rect2(1.2,11,8.6,7.2)
const BODY := [2.0,11.5,8.0,16.0]
const STOREY := 136.0
const STAIR := Rect2(.88,5.9/11.0,.09,1.0-5.9/11.0)
const INK := Color("414b55")
var origin := Vector2.ZERO
var mode := ""
var person: Texture2D
var home: Array = [
	["Estante",[.3,6.2,1.5,7.9],90],
	["Sofá",[.8,1.4,2.3,5.3],42],
	["Mesa de centro",[3.2,2.2,4.8,4.7],28],
	["Cozinha",[7.4,.3,13.5,1.6],66],
	["Geladeira",[13.7,.3,14.8,1.8],116],
	["Mesa de jantar",[8.4,3.3,11.1,5.1],43],
	["Cadeira 1",[8.3,2.3,9.2,3.0],32],
	["Cadeira 2",[10.2,2.3,11.1,3.0],32],
	["Cadeira 3",[8.3,5.5,9.2,6.2],32],
	["Cadeira 4",[10.2,5.5,11.1,6.2],32],
]
var bedroom: Array = [
	["Mesa e gaveteiro",[.3,.8,1.8,5.7],44],
	["Estante",[.3,6.1,1.3,7.7],82],
	["Cama",[1.8,5.8,5.1,7.7],29],
	["Cadeira",[2.3,2.9,3.3,3.9],35],
	["Guarda-roupa",[5.6,.3,7.5,1.6],112],
	["Móvel da TV",[8.0,.3,9.7,1.5],32],
]
func point(u: float,v: float,z: float=0) -> Vector2:
	return origin+Vector2((u-v)*32,(u+v)*16-z)
func polygon(points: PackedVector2Array,color: Color) -> void:
	canvas.draw_colored_polygon(points,color)
	var closed:=points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed,INK,1,false)
func flat(b: Array,z: float,color: Color=Color("d4d8dc")) -> void:
	polygon(PackedVector2Array([point(b[0],b[1],z),point(b[2],b[1],z),point(b[2],b[3],z),point(b[0],b[3],z)]),color)
func box(b: Array,low: float,high: float) -> void:
	polygon(PackedVector2Array([point(b[2],b[1],high),point(b[2],b[3],high),point(b[2],b[3],low),point(b[2],b[1],low)]),Color("9ca6ae"))
	polygon(PackedVector2Array([point(b[0],b[3],high),point(b[2],b[3],high),point(b[2],b[3],low),point(b[0],b[3],low)]),Color("b9c1c7"))
	flat(b,high,Color("e0e3e6"))
func line(a:Vector3,b:Vector3,width:float=2) -> void:
	canvas.draw_line(point(a.x,a.y,a.z),point(b.x,b.y,b.z),INK,width,false)
func front_panel(u0:float,u1:float,v:float,bottom:float,top:float) -> void:
	polygon(PackedVector2Array([point(u0,v,bottom),point(u1,v,bottom),point(u1,v,top),point(u0,v,top)]),Color("83919b"))
func person_at(u:float,v:float,z:float=0) -> void:
	var size:=person.get_size()
	canvas.draw_texture(person,point(u,v,z)-Vector2(size.x*.5,size.y))
func railing(u0:float,u1:float,v:float,z:float) -> void:
	line(Vector3(u0,v,z+44),Vector3(u1,v,z+44))
	for i in 7:
		var u:=lerpf(u0,u1,float(i)/6)
		line(Vector3(u,v,z),Vector3(u,v,z+44),1)
func draw() -> void:
	super.draw()
	if mode=="facade":
		draw_facade()
	elif mode=="home" or mode=="bedroom":
		draw_room(mode=="home")
	elif mode=="plan-home" or mode=="plan-bedroom":
		draw_plan(mode=="plan-home")
func draw_facade() -> void:
	origin=Vector2(674,185)
	box([LOT.position.x,LOT.position.y,LOT.end.x,LOT.end.y],0,8)
	for tree in [Vector2(1.6,12.5),Vector2(1.6,14.3)]:
		box([tree.x-.07,tree.y-.07,tree.x+.07,tree.y+.07],8,68)
		var crown:=point(tree.x,tree.y,82)
		canvas.draw_circle(crown,25,Color("a6afb6"))
		canvas.draw_arc(crown,25,0,TAU,32,INK,1,false)
	box(BODY,8,144)
	# Janela térrea e porta de entrada no plano da fachada.
	front_panel(6.2,7.5,16.01,42,112)
	front_panel(3.9,4.9,16.01,8,100)
	box([2.1,11.6,7.5,15.8],144,280)
	front_panel(2.7,5.8,15.81,188,248)
	front_panel(6.3,7.2,15.81,144,236)
	box([2,11.5,7.65,15.95],280,292)
	box([5.6,15.8,8,16.9],136,144)
	railing(5.6,8,16.9,144)
	line(Vector3(8,15.8,188),Vector3(8,16.9,188))
	for v in [15.8,16.35,16.9]:
		line(Vector3(8,v,144),Vector3(8,v,188),1)
	box([5.6,13.7,8.1,16.1],265,275)
	box([3.2,16,5.3,17],107,115)
	for u in [3.2,5.2]:
		box([u,16.83,u+.10,16.95],8,107)
	box([2.8,12.1,6.0,13.7],292,320)
	# Equipamento solar junto ao núcleo da cobertura.
	box([3.3,12.2,4.9,13.3],320,324)
	for u in [3.7,4.1,4.5]:
		line(Vector3(u,12.2,325),Vector3(u,13.3,325),1)
	box([5.1,12.4,5.8,13.0],320,333)
	# Piso de acesso conserva o portão em u=4,4.
	flat([3.7,16.0,5.1,18.2],9,Color("c2c9cf"))
	for b in [[1.2,11,1.32,18.2],[9.68,11,9.8,18.2],[1.2,18.08,3.65,18.2],[5.15,18.08,9.8,18.2]]:
		box(b,8,48)
	for b in [[1.5,12,1.9,16.2],[7.9,17.2,9.3,17.8]]:
		box(b,8,24)
	box([5.2,18.0,5.65,18.2],8,57)
	front_panel(3.65,5.15,18.21,8,43)
	var wheel_a:=point(1.6,16.4,18)
	var wheel_b:=point(1.6,17.5,18)
	for wheel in [wheel_a,wheel_b]:
		canvas.draw_circle(wheel,12,Color("a6afb6"))
		canvas.draw_arc(wheel,12,0,TAU,24,INK,1,false)
	var saddle:=point(1.6,16.95,43)
	canvas.draw_line(wheel_a,saddle,INK,2)
	canvas.draw_line(saddle,wheel_b,INK,2)
	canvas.draw_line(wheel_a,wheel_b,INK,2)
	person_at(4.4,19.0,8)
func stair_rect(dimensions:Vector2) -> Array:
	return [STAIR.position.x*dimensions.x,STAIR.position.y*dimensions.y,STAIR.end.x*dimensions.x,STAIR.end.y*dimensions.y]
func draw_plan(ground:bool) -> void:
	var dimensions:=Vector2(15,11) if ground else Vector2(10,8)
	var at:=Vector2(55,100)
	var scale:=34.0
	var area:=Rect2(at,dimensions*scale)
	canvas.draw_rect(area,Color("d4d8dc"))
	canvas.draw_rect(area,INK,false,2)
	for u in range(int(dimensions.x)+1):
		canvas.draw_line(at+Vector2(u*scale,0),at+Vector2(u*scale,dimensions.y*scale),Color("bac3ca"),1)
	for v in range(int(dimensions.y)+1):
		canvas.draw_line(at+Vector2(0,v*scale),at+Vector2(dimensions.x*scale,v*scale),Color("bac3ca"),1)
	var furniture:Array=home if ground else bedroom
	for i in furniture.size():
		var b:Array=furniture[i][1]
		var rect:=Rect2(at+Vector2(b[0],b[1])*scale,Vector2(b[2]-b[0],b[3]-b[1])*scale)
		canvas.draw_rect(rect,Color("a6b0b8"))
		canvas.draw_rect(rect,INK,false,1)
		canvas.draw_string(ThemeDB.fallback_font,rect.get_center()+Vector2(-5,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,INK)
		canvas.draw_string(ThemeDB.fallback_font,Vector2(620,115+i*31),str(i+1)+" · "+furniture[i][0],HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	var hole:=stair_rect(dimensions)
	var stair_area:=Rect2(at+Vector2(hole[0],hole[1])*scale,Vector2(hole[2]-hole[0],hole[3]-hole[1])*scale)
	canvas.draw_rect(stair_area,Color("8998a3"))
	canvas.draw_rect(stair_area,INK,false,2)
	for i in 17:
		var y:=stair_area.position.y+stair_area.size.y*float(i)/17
		canvas.draw_line(Vector2(stair_area.position.x,y),Vector2(stair_area.end.x,y),INK,1)
	canvas.draw_string(ThemeDB.fallback_font,Vector2(620,470),"Escada · 17 × 8 px",HORIZONTAL_ALIGNMENT_LEFT,-1,19,INK)
	if ground:
		canvas.draw_line(at+Vector2(4.9,11)*scale,at+Vector2(7.1,11)*scale,Color("f8fafb"),5)
		canvas.draw_string(ThemeDB.fallback_font,at+Vector2(4.9,11)*scale+Vector2(0,25),"ENTRADA",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	else:
		canvas.draw_string(ThemeDB.fallback_font,Vector2(55,430),"Varanda ao longo da frente · acesso ao lado da escada",HORIZONTAL_ALIGNMENT_LEFT,-1,17,INK)
func stair_geometry(hole:Array,ground:bool) -> void:
	var base:float=0.0 if ground else -STOREY
	var side:=PackedVector2Array([point(hole[2],hole[3],base)])
	for i in 17:
		var v0:float=lerpf(hole[3],hole[1],float(i+1)/17)
		var v1:float=lerpf(hole[3],hole[1],float(i)/17)
		var z:float=base+float(i+1)*8
		side.append(point(hole[2],v1,z))
		side.append(point(hole[2],v0,z))
	side.append(point(hole[2],hole[1],base))
	polygon(side,Color("a2acb4"))
	for i in 17:
		var v0:float=lerpf(hole[3],hole[1],float(i+1)/17)
		var v1:float=lerpf(hole[3],hole[1],float(i)/17)
		var z:float=base+float(i+1)*8
		flat([hole[0],v0,hole[2],v1],z,Color("d9dee2"))
		front_panel(hole[0],hole[2],v1,z-8,z)
func draw_room(ground:bool) -> void:
	origin=Vector2(410,211) if ground else Vector2(400,225)
	var dimensions:=Vector2(15,11) if ground else Vector2(10,8)
	var hole:=stair_rect(dimensions)
	if ground:
		flat([0,0,dimensions.x,dimensions.y],0)
	else:
		# Corte verdadeiro do piso, com a mesma abertura normalizada da escada.
		flat([0,0,hole[0],dimensions.y],0)
		flat([hole[0],0,dimensions.x,hole[1]],0)
		flat([hole[2],hole[1],dimensions.x,dimensions.y],0)
	stair_geometry(hole,ground)
	# Paredes recuadas. Frente aberta para leitura dos móveis.
	polygon(PackedVector2Array([point(0,0),point(0,dimensions.y),point(0,dimensions.y,150),point(0,0,150)]),Color("c1c8ce"))
	polygon(PackedVector2Array([point(0,0),point(dimensions.x,0),point(dimensions.x,0,150),point(0,0,150)]),Color("aeb8c1"))
	polygon(PackedVector2Array([point(0,1.5,55),point(0,5.8,55),point(0,5.8,130),point(0,1.5,130)]),Color("8796a2"))
	var furniture:Array=home if ground else bedroom
	var sorted:=furniture.duplicate(true)
	sorted.sort_custom(func(a:Array,b:Array)->bool:return a[1][2]+a[1][3]<b[1][2]+b[1][3])
	for entry in sorted:
		box(entry[1],0,entry[2])
	if ground:
		box([.8,1.4,1.1,5.3],42,62)
		# Pia e fogão são volumes baixos sobre a bancada.
		for u in [9.1,11.6]:
			box([u,.5,u+1.1,1.35],66,69)
		front_panel(4.9,7.1,11,0,92)
		person_at(6.7,8.0)
	else:
		box([1.8,5.8,2.02,7.7],29,48)
		box([2.1,6.0,2.8,7.5],29,36)
		box([.65,2.3,1.2,3.3],44,60)
		front_panel(8.1,9.6,.75,32,82)
		flat([6.8,8,10,9.2],0,Color("c3cbd1"))
		railing(6.8,10,9.2,0)
		front_panel(7.3,8.5,8,0,92)
		person_at(5.9,4.4)
	line(Vector3(hole[0],hole[1],44+(STOREY if ground else 0.0)),Vector3(hole[0],hole[3],44))
	for t in [0.0,.25,.5,.75,1.0]:
		var v:=lerpf(hole[1],hole[3],t)
		var z:float=0.0 if not ground else (1.0-t)*STOREY
		line(Vector3(hole[2],v,z),Vector3(hole[2],v,z+44))
	line(Vector3(hole[2],hole[1],44+(STOREY if ground else 0.0)),Vector3(hole[2],hole[3],44))
func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	canvas=Node2D.new()
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	var frame:=img("res://assets/kael-video/iso-v2/idle.png").get_region(Rect2i(0,672,64,96))
	person=ImageTexture.create_from_image(frame.get_region(frame.get_used_rect()))
	OUT=ROOT_DIR+"fachada/"
	mode="facade"
	content=board(760,700)
	labels=[[Vector2(22,30),"CASA DO KAEL / FACHADA / BLOCOS EM 1×",22],[Vector2(22,670),"Lote existente 8,6 × 7,2 células · Kael em escala nativa · solar na cobertura",17]]
	await capture("blockout.png")
	OUT=ROOT_DIR+"interior/"
	for ground in [true,false]:
		mode="home" if ground else "bedroom"
		content=board(1040,790)
		labels=[[Vector2(22,30),"CASA DO KAEL / "+("TÉRREO" if ground else "QUARTO")+" / BLOCOS EM 1×",23],[Vector2(22,750),"Grade 64 × 32 · sem pintura final · 17 degraus de 8 px entre pavimentos",19]]
		await capture("blockout-"+("terreo" if ground else "quarto")+".png")
		mode="plan-home" if ground else "plan-bedroom"
		content=board(1040,620)
		labels=[[Vector2(22,35),"PLANTA / "+("TÉRREO · 15 × 11" if ground else "QUARTO · 10 × 8")+" CÉLULAS",24]]
		await capture("planta-"+("terreo" if ground else "quarto")+".png")
	mode=""
	OUT=ROOT_DIR
	content=board(1840,1080)
	var concept:=img(ROOT_DIR+"concept/prancha.png")
	concept.resize(1536,1024,Image.INTERPOLATE_LANCZOS)
	content.blit_rect(concept,Rect2i(0,64,790,720),Vector2i(20,85))
	var block:=img(ROOT_DIR+"fachada/blockout.png")
	content.blit_rect(block,Rect2i(0,0,760,700),Vector2i(1050,90))
	labels=[[Vector2(20,40),"CONCEPT APROVADO",26],[Vector2(1050,40),"TRADUÇÃO PARA A CÂMERA 2:1",26],[Vector2(30,950),"Comparação de conteúdo e volumes. A projeção do concept é traduzida para a grade do jogo.",20]]
	await capture("comparativo-blockout.png")
	# Sobreposição uniforme para comparar as massas entre duas projeções.
	var source_concept:=img(ROOT_DIR+"concept/prancha.png")
	content=board(1536,1120)
	content.blit_rect(source_concept,Rect2i(0,0,1536,1024),Vector2i.ZERO)
	var crop:=block.get_region(Rect2i(120,90,530,550))
	var silhouette:=Image.create_empty(crop.get_width(),crop.get_height(),false,Image.FORMAT_RGBA8)
	for y in range(1,crop.get_height()-1):
		for x in range(1,crop.get_width()-1):
			var color:=crop.get_pixel(x,y)
			if color.r>.88:
				continue
			for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if crop.get_pixelv(Vector2i(x,y)+step).r>.89:
					silhouette.set_pixel(x,y,Color(.15,.19,.23,.8))
					break
	silhouette.resize(689,715,Image.INTERPOLATE_NEAREST)
	content.blend_rect(silhouette,Rect2i(0,0,689,715),Vector2i(35,65))
	labels=[[Vector2(22,1070),"Contorno do blockout sobre a fachada, em escala uniforme. Conferência de massas entre projeções.",20]]
	await capture("fachada/blockout-sobre-concept.png")
	var lot_bounds:=Rect2(Vector2(BODY[0],BODY[1]),Vector2(BODY[2]-BODY[0],BODY[3]-BODY[1]))
	assert(LOT.encloses(lot_bounds))
	assert(is_equal_approx(17*8.0,STOREY))
	var report:={"lot":[1.2,11,9.8,18.2],"building":BODY,"lot_contains_building":true,"tile_px":[64,32],"kael_visible_height_px":person.get_height(),"storey_px":STOREY,"stair_risers":17,"riser_px":8,"stair_normalized_rect":[STAIR.position.x,STAIR.position.y,STAIR.end.x,STAIR.end.y],"home_cells":[15,11],"bedroom_cells":[10,8],"scope":"blockout de aprovação; circulação proposta em planta"}
	var file:=FileAccess.open(ROOT_DIR+"verificacao-blockout.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("Blockouts da casa salvos. Kael: ",person.get_height()," px. Lote: ",LOT)
	quit()
