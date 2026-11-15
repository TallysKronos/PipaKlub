extends "res://tools/laboratorio_v2_revisao.gd"
## Estudo geométrico isolado. Não altera assets nem a cena jogável.
const DIR := "res://../art/casa-kael-v2/fachada/portao-geometria-v3/"
const GROUND := 8.0
const LEFT := 3.55
const RIGHT := 5.25
const INK := Color("48535e")
var semantic := true
var show_geometry := true
var show_marks := true
var at := Vector2(660,-30)

func p(u:float,v:float,z:float=GROUND) -> Vector2:
	return at+Vector2((u-v)*32,(u+v)*16-z)

func poly(points:PackedVector2Array,color:Color,outline:bool=true) -> void:
	canvas.draw_colored_polygon(points,color)
	if outline:
		var edge:=points.duplicate()
		edge.append(edge[0])
		canvas.draw_polyline(edge,INK,1,false)

func plane(b:Array,z:float,color:Color,outline:bool=true) -> void:
	poly(PackedVector2Array([p(b[0],b[1],z),p(b[2],b[1],z),p(b[2],b[3],z),p(b[0],b[3],z)]),color,outline)

func box(b:Array,low:float,high:float,top:Color=Color("eef0f2"),front:Color=Color("b4bdc5"),side:Color=Color("788792")) -> void:
	poly(PackedVector2Array([p(b[2],b[1],high),p(b[2],b[3],high),p(b[2],b[3],low),p(b[2],b[1],low)]),side)
	poly(PackedVector2Array([p(b[0],b[3],high),p(b[2],b[3],high),p(b[2],b[3],low),p(b[0],b[3],low)]),front)
	plane(b,high,top)

func pillar(b:Array) -> void:
	box(b,GROUND,50)
	box([b[0]-.035,b[1]-.035,b[2]+.035,b[3]+.035],50,53)

func draw() -> void:
	super.draw()
	if not show_geometry:return
	# Chão inteiro na mesma cota. Nenhuma face vertical atravessa o vão.
	plane([.5,16.3,8.5,20.2],GROUND,Color("aab79b") if semantic else Color("c2c5be"))
	plane([.5,18.46,8.5,20.2],GROUND,Color("d5dadd"))
	plane([LEFT,16.3,RIGHT,20.2],GROUND,Color("91abb9") if semantic else Color("a0adb7"))
	for v in [17.1,18.2,19.15]:
		canvas.draw_line(p(LEFT,v),p(RIGHT,v),Color("718894"),1,false)
	# A faixa de pedras termina reta nos limites do vão, sem ressalto.
	for span in [[.5,LEFT],[RIGHT,8.5]]:
		plane([span[0],18.46,span[1],18.73],GROUND,Color("b1bbc3"))
		for u in range(ceili(span[0]*2),floori(span[1]*2)+1):
			canvas.draw_line(p(float(u)*.5,18.46),p(float(u)*.5,18.73),Color("85929d"),1,false)
	# Sombras de contato pertencem ao chão, não ao plano do muro.
	for b in [[3.1,17.94,LEFT,18.46],[RIGHT,17.94,5.7,18.46]]:
		plane([b[0],b[3],b[2],b[3]+.12],GROUND,Color("87929c"),false)
	# Folha aberta para dentro, com um plano visível e dobradiças na ombreira.
	box([3.48,17.08,3.56,18.08],12,43,Color("8094a5"),Color("526c82"),Color("3d5369"))
	for z in [17,35]:box([3.48,18.02,3.61,18.1],z,z+3,Color("b8c2c9"),Color("8594a0"),Color("586a79"))
	box([1.2,18.08,3.1,18.32],GROUND,48)
	pillar([3.1,17.94,LEFT,18.46])
	pillar([RIGHT,17.94,5.7,18.46])
	box([5.7,18.08,8.0,18.32],GROUND,48)
	# Caixa de correio no plano vertical do pilar direito.
	box([5.32,18.46,5.63,18.6],20,38,Color("8094a5"),Color("526c82"),Color("3d5369"))
	if not show_marks:return
	canvas.draw_string(ThemeDB.fallback_font,Vector2(465,195),"1  Tampa do muro",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	canvas.draw_string(ThemeDB.fallback_font,Vector2(465,226),"2  Face frontal",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	canvas.draw_string(ThemeDB.fallback_font,Vector2(465,257),"3  Face terminal",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	canvas.draw_string(ThemeDB.fallback_font,Vector2(465,307),"Piso na cota 8",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	canvas.draw_string(ThemeDB.fallback_font,Vector2(465,338),"Calçada na cota 8",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	canvas.draw_string(ThemeDB.fallback_font,Vector2(465,369),"Vão livre 1,7 cél.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	for pair in [[p(3.32,18.2,53),"1"],[p(3.32,18.47,28),"2"],[p(LEFT+.015,18.18,31),"3"]]:
		canvas.draw_circle(pair[0],7,Color("eef2f4"))
		canvas.draw_string(ThemeDB.fallback_font,pair[0]+Vector2(-3,4),pair[1],HORIZONTAL_ALIGNMENT_LEFT,-1,11,INK)

func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	canvas=Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(draw)
	OUT=DIR
	for color in [true,false]:
		semantic=color
		content=board(720,490)
		labels=[[Vector2(22,30),"PORTÃO / ESTUDO DE PLANOS / 1×",22],[Vector2(22,62),"Sem personagens e vegetação · projeção 64 × 32",17],[Vector2(22,466),"Pilares completos · sem viga no vão · piso contínuo com a calçada",18]]
		await capture("planos.png" if color else "volumes.png")
	semantic=true
	show_marks=false
	content=board(720,490)
	labels=[]
	await capture("sem-marcacoes.png")
	var clean:=img(DIR+"sem-marcacoes.png").get_region(Rect2i(20,210,410,230))
	clean.save_png(DIR+"blockout.png")
	clean.resize(820,460,Image.INTERPOLATE_NEAREST)
	clean.save_png(DIR+"blockout-2x.png")
	show_geometry=false
	var detail:=img(DIR+"planos.png")
	detail.resize(1440,980,Image.INTERPOLATE_NEAREST)
	detail.save_png(DIR+"planos-2x.png")
	var report:={"projection":[64,32],"ground_height":GROUND,"sidewalk_height":GROUND,"opening_cells":RIGHT-LEFT,"left_jamb":[3.1,17.94,LEFT,18.46],"right_jamb":[RIGHT,17.94,5.7,18.46],"wall_top":48,"pillar_cap_top":53,"runtime_changed":false}
	assert(is_equal_approx(RIGHT-LEFT,1.7))
	FileAccess.open(DIR+"medidas.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit()
