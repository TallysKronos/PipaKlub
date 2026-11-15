extends "res://tools/laboratorio_v2_revisao.gd"
## Planta e volumes de revisão. Toda aresta horizontal deriva da projeção 64×32.
const ORIGIN := Vector2(480, 220)
const INK := Color("43505b")
const PAPER := Color("e8edf0")
var mode := ""
var kael_texture: ImageTexture
var furniture: Array[Dictionary] = [
	{"id":"A","name":"Prateleira do fundo","rect":[0.5,0.3,6.5,1.2],"height":110},
	{"id":"B","name":"Prateleira direita","rect":[11.5,0.3,17.5,1.2],"height":110},
	{"id":"C","name":"Expositor de pipas","rect":[0.3,7.0,1.3,10.0],"height":110},
	{"id":"D","name":"Gôndola de materiais","rect":[3.5,6.5,6.5,8.0],"height":65},
	{"id":"E","name":"Balcão e caixa","rect":[5.0,2.5,11.0,4.0],"height":66},
	{"id":"F","name":"Mesa e bancos do fundo","rect":[11.0,6.0,15.0,8.0],"height":52},
	{"id":"G","name":"Mesa e bancos da frente","rect":[11.0,10.5,15.0,12.5],"height":52},
]
func project(u: float, v: float, height: float = 0) -> Vector2:
	return ORIGIN + Vector2((u-v)*32, (u+v)*16-height)

func outline(points: PackedVector2Array, color: Color, width: float = 1) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, color, width, false)

func face(points: PackedVector2Array, color: Color) -> void:
	canvas.draw_colored_polygon(points, color)
	outline(points, INK)

func footprint(rect: Array, height: float = 0) -> PackedVector2Array:
	return PackedVector2Array([project(rect[0],rect[1],height),project(rect[2],rect[1],height),project(rect[2],rect[3],height),project(rect[0],rect[3],height)])

func volume(rect: Array, height: float) -> void:
	var base := footprint(rect)
	var top := footprint(rect,height)
	face(PackedVector2Array([top[1],top[2],base[2],base[1]]),Color("9aa3aa"))
	face(PackedVector2Array([top[2],top[3],base[3],base[2]]),Color("b4bbc0"))
	face(top,Color("d9dde0"))

func caption(at: Vector2, value: String, size: int = 18, color: Color = INK) -> void:
	canvas.draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func draw() -> void:
	super.draw()
	if mode == "isometric":
		draw_isometric()
	elif mode == "plan":
		draw_plan()
	elif mode == "diagnosis":
		draw_diagnosis()

func draw_isometric() -> void:
	face(footprint([0,0,18,14]),Color("d5d9dc"))
	for u in range(19):
		canvas.draw_line(project(u,0),project(u,14),Color("b1b9c0"),1,false)
	for v in range(15):
		canvas.draw_line(project(0,v),project(18,v),Color("b1b9c0"),1,false)
	face(PackedVector2Array([project(0,14),project(0,0),project(0,0,150),project(0,14,150)]),Color("c6ccd1"))
	face(PackedVector2Array([project(0,0),project(18,0),project(18,0,150),project(0,0,150)]),Color("aeb7bf"))
	for item in furniture:
		volume(item.rect,item.height)
		var r: Array = item.rect
		var center := project((r[0]+r[2])*.5,(r[1]+r[3])*.5,item.height+8)
		caption(center,item.id,22)
		if item.id in ["A","B"]:
			for level in [25,53,81]:
				canvas.draw_line(project(r[0],r[3],level),project(r[2],r[3],level),INK,2,false)
		if item.id == "C":
			for level in [25,53,81]:
				canvas.draw_line(project(r[2],r[1],level),project(r[2],r[3],level),INK,2,false)
	# Soleira na mesma grade e recorte frontal aberto.
	canvas.draw_line(project(7,14),project(9,14),INK,5,false)
	caption(project(6,14)+Vector2(-60,28),"ENTRADA",17)
	canvas.draw_line(project(7.5,13),project(7.5,5),Color("6e7b85"),2,false)
	caption(Vector2(22,780),"A–B prateleiras   C pipas   D materiais   E caixa   F–G mesas",18)
	var feet := project(8.5,11)
	var size := kael_texture.get_size()
	canvas.draw_texture(kael_texture,feet-Vector2(size.x*.5,size.y))

func plan_point(u: float, v: float) -> Vector2:
	return Vector2(80+u*38,105+v*38)

func draw_plan() -> void:
	canvas.draw_rect(Rect2(plan_point(0,0),Vector2(18,14)*38),Color("d5d9dc"))
	for u in range(19):
		canvas.draw_line(plan_point(u,0),plan_point(u,14),Color("b1b9c0"),1,false)
	for v in range(15):
		canvas.draw_line(plan_point(0,v),plan_point(18,v),Color("b1b9c0"),1,false)
	canvas.draw_rect(Rect2(plan_point(0,0),Vector2(18,14)*38),INK,false,2)
	canvas.draw_rect(Rect2(plan_point(7,4),Vector2(3,10)*38),Color("c3cbd0"))
	for item in furniture:
		var r: Array = item.rect
		var area := Rect2(plan_point(r[0],r[1]),Vector2(r[2]-r[0],r[3]-r[1])*38)
		canvas.draw_rect(area,Color("9faab2"))
		canvas.draw_rect(area,INK,false,2)
		caption(area.get_center()+Vector2(-7,6),item.id,22)
	canvas.draw_line(plan_point(7,14),plan_point(9,14),Color("e8edf0"),7,false)
	caption(plan_point(7,14)+Vector2(0,28),"ENTRADA",18)
	for index in furniture.size():
		var item: Dictionary = furniture[index]
		caption(Vector2(820,155+index*48),item.id+"  "+item.name,18)
	caption(Vector2(820,560),"Corredor central de 3 células",18)
	caption(Vector2(820,590),"Acesso traseiro ao caixa de 1,3 célula",18)
	caption(Vector2(80,740),"18 × 14 células • pegadas retangulares • apoios no mesmo plano",20)

func guide(a: Vector2, b: Vector2, color: Color, label: String, label_at: Vector2) -> void:
	canvas.draw_line(a,b,color,2,false)
	canvas.draw_circle(a,3,color)
	canvas.draw_circle(b,3,color)
	caption(label_at,label,17,color)

func draw_diagnosis() -> void:
	var shift := Vector2(0,70)
	guide(Vector2(444,47)+shift,Vector2(945,290)+shift,Color("08718a"),"parede ≈ 0,49 px/px",Vector2(644,91)+shift)
	guide(Vector2(425,150)+shift,Vector2(619,206)+shift,Color("a53d39"),"prateleira ≈ 0,29 px/px",Vector2(480,123)+shift)
	guide(Vector2(747,318)+shift,Vector2(938,373)+shift,Color("a53d39"),"≈ 0,29",Vector2(831,330)+shift)
	guide(Vector2(494,280)+shift,Vector2(613,320)+shift,Color("a53d39"),"caixa ≈ 0,34",Vector2(470,274)+shift)

func run() -> void:
	OUT = "res://../art/overworld/estilo/loja-piloto-v2/interior/remapeamento/"
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor=1
	canvas=Node2D.new()
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	var kael := img("res://assets/kael-video/iso-v2/idle.png").get_region(Rect2i(0,672,64,96))
	kael = kael.get_region(kael.get_used_rect())
	kael_texture = ImageTexture.create_from_image(kael)
	mode = "isometric"
	content = board(1120,820)
	labels=[[Vector2(22,36),"LINHA & PAPEL / NOVO MAPEAMENTO / GRADE 64 × 32",24]]
	await capture("blockout.png")
	mode = "plan"
	content = board(1280,820)
	labels=[[Vector2(80,48),"PLANTA PROPOSTA / PRATELEIRAS PARALELAS ÀS PAREDES",24]]
	await capture("planta.png")
	mode = "diagnosis"
	content = board(976,820)
	var old := img(OUT+"../quadro-chave.png")
	content.blend_rect(old,Rect2i(Vector2i.ZERO,old.get_size()),Vector2i(0,70))
	labels=[[Vector2(22,36),"PERSPECTIVA ATUAL / ARESTAS MEDIDAS VISUALMENTE",23],[Vector2(22,790),"Azul = parede • vermelho = prateleiras e caixa com menor inclinação",18]]
	await capture("diagnostico.png")
	mode = ""
	content = board(2096,820)
	content.blend_rect(img(OUT+"diagnostico.png"),Rect2i(0,0,976,820),Vector2i.ZERO)
	content.blend_rect(img(OUT+"blockout.png"),Rect2i(0,0,1120,820),Vector2i(976,0))
	labels=[]
	await capture("comparativo.png")
	for item in furniture:
		var r: Array = item.rect
		assert(r[0]>=0 and r[1]>=0 and r[2]<=18 and r[3]<=14, "Móvel fora da sala")
		var edge := project(r[2],r[1])-project(r[0],r[1])
		assert(is_equal_approx(edge.y/edge.x,0.5), "Aresta fora da projeção 2:1")
	var report := {"stage":"revisão de planta e perspectiva","projection_px":[64,32],"room_cells":[18,14],"origin_px":[480,220],"furniture":furniture,"kael_visible_height_px":kael.get_height(),"all_u_edges_slope":0.5,"all_footprints_inside_room":true,"scope":"blockout para aprovação, circulação estimada em planta"}
	var file := FileAccess.open(OUT+"planta.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("Mapeamento da loja salvo em "+OUT)
	quit()
