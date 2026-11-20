extends SceneTree
## Etapa 1. Geometria independente, sem alterar mapas, sprites ou saves.
const OUT := "res://../art/professor-laboratorio-v2/"
const ROOM_WIDTH := 13.0
const ROOM_DEPTH := 7.6
const RECEPTION := Rect2(.95, 4.35, 2.25, 1.25)
const CART := Rect2(.42, 2.60, .94, .60)
const RESEARCH := Rect2(4.30, 4.35, 4.60, 1.30)
const STOOL := Rect2(6.95, 3.10, .45, .45)
const SHELF := Rect2(9.20, 6.85, 1.56, .68)
const STOCK := Rect2(10.95, 5.55, 2.05, 2.05)
const EQUIPMENT := Rect2(10.55, 1.10, 2.00, 1.35)
var stage: Node2D
var shapes: Array = []
var interior := false
# Ordem explícita dos conjuntos evita piso cobrindo móveis ou vidro cobrindo paredes.
var group_depth := 0.0
var origin := Vector2(250,500)
const INK := Color("454545")
const MID := Color("ababab")
const LIGHT := Color("dedede")
const DARK := Color("868686")

func _initialize() -> void:
	run.call_deferred()

func p(u: float, d: float, h: float=0) -> Vector2:
	return origin + Vector2((u+d)*32, (u-d)*16-h)

func face(points: Array, color: Color, outline: bool=true) -> void:
	var projected := PackedVector2Array()
	for point: Vector3 in points:
		projected.append(p(point.x,point.y,point.z))
	shapes.append({"points":projected,"color":color,"edge":outline,"depth":group_depth,"order":shapes.size()})

func box(u:float,d:float,w:float,b:float,z:float,h:float, color:Color=LIGHT) -> void:
	face([Vector3(u,d,z),Vector3(u+w,d,z),Vector3(u+w,d,z+h),Vector3(u,d,z+h)],color)
	face([Vector3(u+w,d,z),Vector3(u+w,d+b,z),Vector3(u+w,d+b,z+h),Vector3(u+w,d,z+h)],color.darkened(.18))
	face([Vector3(u,d,z+h),Vector3(u+w,d,z+h),Vector3(u+w,d+b,z+h),Vector3(u,d+b,z+h)],color.lightened(.12))

func segment(a:Vector3,b:Vector3,color:Color=INK,width:float=2) -> void:
	shapes.append({"line":PackedVector2Array([p(a.x,a.y,a.z),p(b.x,b.y,b.z)]),"color":color,"width":width,"depth":group_depth,"order":shapes.size()})

func roof(u:float,d:float,w:float,b:float,base:float,rise:float,cut:bool=false) -> void:
	var count := 24
	for i in count:
		var x0 := w*i/count
		var x1 := w*(i+1)/count
		var h0 := base+sin(PI*x0/w)*rise
		var h1 := base+sin(PI*x1/w)*rise
		var start := d+b-.7 if cut else d
		face([Vector3(u+x0,start,h0),Vector3(u+x1,start,h1),Vector3(u+x1,d+b,h1),Vector3(u+x0,d+b,h0)],Color(.72+.12*i/count,.72+.12*i/count,.72+.12*i/count),false)
		face([Vector3(u+x0,start,h0-8),Vector3(u+x1,start,h1-8),Vector3(u+x1,start,h1),Vector3(u+x0,start,h0)],DARK,false)
		segment(Vector3(u+x0,start,h0),Vector3(u+x1,start,h1))
		segment(Vector3(u+x0,start,h0-8),Vector3(u+x1,start,h1-8))
	if not cut:
		for side in [0.0,w]:
			segment(Vector3(u+side,d,base),Vector3(u+side,d+b,base))

func glazing(u:float,d:float,w:float,z:float,h:float) -> void:
	face([Vector3(u,d,z),Vector3(u+w,d,z),Vector3(u+w,d,z+h),Vector3(u,d,z+h)],Color("737373"))
	for x in range(1,4):
		segment(Vector3(u+w*x/4,d,z),Vector3(u+w*x/4,d,z+h),LIGHT)
	segment(Vector3(u,d,z+h*.5),Vector3(u+w,d,z+h*.5),LIGHT)

func diamond(u:float,d:float,z:float,r:float) -> void:
	var points := [Vector3(u,d,z+r),Vector3(u+r/32,d,z),Vector3(u,d,z-r),Vector3(u-r/32,d,z)]
	face(points,Color("bcbcbc"))
	segment(points[0],points[2],INK,2)
	segment(points[1],points[3],INK,2)

func rail(u:float,d:float,U:float,D:float,z:float=24,h:float=36) -> void:
	var steps := maxi(1,ceili(Vector2(U-u,D-d).length()*2))
	for i in steps+1:
		var t := float(i)/steps
		segment(Vector3(lerpf(u,U,t),lerpf(d,D,t),z),Vector3(lerpf(u,U,t),lerpf(d,D,t),z+h),INK,2)
	segment(Vector3(u,d,z+h),Vector3(U,D,z+h),INK,3)

func cabinet(u:float,d:float,w:float,b:float,h:float) -> void:
	box(u,d,w,b,0,h)
	for j in 3:
		box(u+.12,d-.03,w-.24,.06,8+j*24,17,Color(.48+j*.1,.48+j*.1,.48+j*.1))

func bench(u:float,d:float,w:float,b:float,h:float=39) -> void:
	box(u+.1,d+.1,w-.2,b-.2,0,h-4,MID)
	box(u,d,w,b,h-4,4,LIGHT)

func screen(u:float,d:float,z:float,w:float=.8,h:float=25) -> void:
	box(u+.3,d+.1,.12,.12,z,7,DARK)
	box(u,d,w,.1,z+7,h,DARK)

func center_apparatus() -> void:
	footprint_bench(RESEARCH, 42)
	box(5.49, 4.83, 1.62, .62, 42, 7, DARK)
	var u := 6.30
	var d := 5.10
	diamond(u, d, 108, 43)
	# Os braços partem dos dois lados da base e terminam nos eixos laterais do losango.
	for side in [-1, 1]:
		var previous := Vector3(u + side * .52, d - .13, 49)
		for i in range(1, 17):
			var t := float(i) / 16.0
			var x: float = u + side * (.52 + .83 * sin(t * PI * .5))
			var at := Vector3(x, d - .13, 49 + 59 * t)
			segment(previous, at, DARK, 8)
			segment(previous + Vector3(0,0,1), at + Vector3(0,0,1), MID, 4)
			previous = at
		box(u + side * 1.35 - .09, d - .23, .18, .19, 104, 8, DARK)
	screen(7.70, 5.02, 42, .56, 22)
	screen(8.32, 5.02, 42, .52, 22)
	box(7.09, 3.24, .15, .15, 3, 18, DARK)
	box(STOOL.position.x, STOOL.position.y, STOOL.size.x, STOOL.size.y, 0, 3, DARK)
	box(STOOL.position.x, STOOL.position.y, STOOL.size.x, STOOL.size.y, 21, 6, MID)

func facade() -> void:
	interior=false
	origin=Vector2(230,520)
	group_depth=-10000
	box(0,0,13.5,9,-8,8,MID)
	group_depth=-9000
	box(.35,2.8,8.15,5.8,0,24,Color("cccccc"))
	group_depth=-3000
	box(.55,3.0,4.8,5.3,24,108)
	group_depth=-2000
	box(7.2,4.25,5.75,4.15,24,120)
	group_depth=-3000
	glazing(.95,2.99,3.95,62,51)
	group_depth=-2000
	glazing(8.15,4.24,3.6,65,55)
	group_depth=-3000
	roof(.35,2.8,5.2,5.7,139,31)
	group_depth=-2000
	roof(7.0,4.1,6.2,4.5,151,38)
	group_depth=-2500
	box(5.15,3.8,2.4,3.1,24,200)
	glazing(5.3,3.79,2.1,135,82)
	diamond(6.35,3.77,172,15)
	group_depth=-1000
	# Portal escavado: duas ombreiras e travessa; vão de vidro ao fundo.
	box(4.95,3.0,.28,1.15,24,113,DARK)
	box(7.42,3.0,.28,1.15,24,113,DARK)
	box(4.95,3.0,2.75,1.15,129,8,DARK)
	glazing(5.28,3.78,2.0,24,92)
	box(7.71,4.21,.55,.1,24,120,DARK)
	for i in 3:
		box(5.25,1.2+i*.55,2.65,.55,0,(i+1)*8)
	rail(5.1,1.2,5.1,2.9,8,35)
	rail(8.05,1.2,8.05,2.9,8,35)
	# Rampa contínua paralela à escada, na face de chegada.
	face([Vector3(3.9,1.05,0),Vector3(4.8,1.05,0),Vector3(4.8,3.0,24),Vector3(3.9,3.0,24)],MID)
	segment(Vector3(3.85,1.05,35),Vector3(3.85,3,59),INK,3)
	for i in 4:
		var d:=1.05+i*.65
		segment(Vector3(3.85,d,24*(d-1.05)/1.95),Vector3(3.85,d,35+24*(d-1.05)/1.95))
	group_depth=200
	box(8.8,1.05,4.4,3.05,0,12,LIGHT)
	rail(8.8,1.05,13.2,1.05,12,39)
	rail(13.2,1.05,13.2,4.1,12,39)
	rail(8.8,1.05,8.8,3.0,12,39)
	# Cabine hexagonal em elevação, com ombros de vidro inclinados como no recorte.
	var profile:Array=[Vector2(10.65,12),Vector2(12.85,12),Vector2(12.85,56),Vector2(12.45,84),Vector2(11.05,84),Vector2(10.65,56)]
	var front:Array=[]
	for q:Vector2 in profile: front.append(Vector3(q.x,2.0,q.y))
	face(front,Color(.58,.58,.58,.20))
	for i in profile.size():
		var a:Vector2=profile[i]
		var b:Vector2=profile[(i+1)%profile.size()]
		if i>0:
			face([Vector3(a.x,2.0,a.y),Vector3(b.x,2.0,b.y),Vector3(b.x,3.55,b.y),Vector3(a.x,3.55,a.y)],Color(.58,.58,.58,.15))
		segment(Vector3(a.x,2.0,a.y),Vector3(a.x,3.55,a.y),INK,2)
		segment(Vector3(a.x,3.55,a.y),Vector3(b.x,3.55,b.y),INK,2)
	bench(11.15,2.7,1.0,.6,39)
	screen(11.35,2.7,39,.5,18)
	bench(9.25,1.75,1.0,.6,35)
	box(9.35,1.9,.65,.4,35,12,DARK)
	box(12.6,1.35,.25,.25,12,15,DARK)
	group_depth=-1900
	# Equipamentos de cobertura, arco e anemômetro.
	segment(Vector3(8.7,6.3,184),Vector3(8.7,6.3,237),INK,4)
	var previous:=Vector3(8.7,6.3,237)
	for i in 24:
		var angle:=PI*float(i+1)/24
		var at:=Vector3(8.7+cos(angle)*1.25,6.3,209+sin(angle)*28)
		if i>0: segment(previous,at,DARK,7)
		previous=at
	segment(Vector3(7.5,6.3,209),Vector3(9.95,6.3,209),INK,3)
	segment(Vector3(11.1,6.6,179),Vector3(11.1,6.6,244),INK,3)
	segment(Vector3(10.55,6.6,231),Vector3(11.65,6.6,231),INK,3)
	for u in [10.55,11.65]:
		box(u,6.5,.2,.2,228,6,DARK)
	group_depth=400
	# Massas de canteiros e copas, sem detalhamento vegetal.
	for rect in [Rect2(.15,1.25,2.7,1.3),Rect2(9.3,.25,3.7,.65),Rect2(.1,7.5,.55,1.1)]:
		box(rect.position.x,rect.position.y,rect.size.x,rect.size.y,0,13,DARK)
		box(rect.position.x+.08,rect.position.y+.08,rect.size.x-.16,rect.size.y-.16,13,12,MID)
	group_depth=-8500
	for tree in [Vector2(.5,7.8),Vector2(12.7,7.9)]:
		box(tree.x,tree.y,.18,.18,0,84,DARK)
		box(tree.x-.5,tree.y-.5,1.3,1.3,73,64,MID)
	group_depth=500
	for u in [2.9,8.45]:
		box(u,.35,.14,.14,0,24,DARK)

func inside() -> void:
	interior = true
	origin = Vector2(142, 382)
	# I1: a bancada e o losango são a referência da planta.
	group_depth = 200
	center_apparatus()

	group_depth = -10000
	box(0, 0, ROOM_WIDTH, ROOM_DEPTH, -8, 8, MID)
	for u in range(1, 13):
		segment(Vector3(u, 0, .1), Vector3(u, ROOM_DEPTH, .1), Color("969696"), 1)
	for d in range(1, 8):
		segment(Vector3(0, d, .1), Vector3(ROOM_WIDTH, d, .1), Color("969696"), 1)

	group_depth = -9000
	face([Vector3(0, 0, 0), Vector3(0, ROOM_DEPTH, 0), Vector3(0, ROOM_DEPTH, 135), Vector3(0, 0, 135)], LIGHT)
	face([Vector3(0, ROOM_DEPTH, 0), Vector3(ROOM_WIDTH, ROOM_DEPTH, 0), Vector3(ROOM_WIDTH, ROOM_DEPTH, 135), Vector3(0, ROOM_DEPTH, 135)], LIGHT)
	face([Vector3(.01, 2.7, 35), Vector3(.01, 7.2, 35), Vector3(.01, 7.2, 115), Vector3(.01, 2.7, 115)], DARK)
	for d in [2.7, 4.2, 5.7, 7.2]:
		segment(Vector3(.02, d, 35), Vector3(.02, d, 115), LIGHT, 2)
	segment(Vector3(.02, 2.7, 76), Vector3(.02, 7.2, 76), LIGHT, 2)

	# I2/I10: torre envidraçada no eixo do aparelho e abóbadas cortadas.
	face([Vector3(4.55, ROOM_DEPTH, 0), Vector3(8.10, ROOM_DEPTH, 0), Vector3(8.10, ROOM_DEPTH, 200), Vector3(4.55, ROOM_DEPTH, 200)], MID)
	glazing(4.75, 7.59, 3.15, 110, 82)
	roof(0, 0, 4.75, ROOM_DEPTH, 137, 28, true)
	roof(7.9, 0, 5.1, ROOM_DEPTH, 145, 32, true)
	box(0, 0, 5.05, .13, 0, 13, DARK)
	box(7.55, 0, 5.45, .13, 0, 13, DARK)
	box(12.87, 0, .13, 5.6, 0, 13, DARK)

	# I3/I4: recepção, carrinho, planta, quadro e estante à esquerda.
	group_depth = -500
	cabinet(.95, 6.85, 1.55, .65, 99)
	diamond(3.25, 7.59, 84, 17)
	box(.40, 6.05, .46, .46, 0, 22, MID)
	box(.28, 5.93, .70, .70, 22, 28, DARK)
	group_depth = 0
	footprint_bench(RECEPTION, 42)
	screen(1.75, 5.32, 42, .65, 20)
	box(2.56, 5.09, .28, .24, 42, 10, DARK)
	footprint_bench(CART, 20)
	box(.50, 2.67, .72, .47, 20, 14, DARK)
	box(.50, 2.67, .72, .47, 0, 13, DARK)
	for u in [.48, 1.18]:
		box(u, 2.66, .12, .12, -1, 5, DARK)

	# I6/I7: estante e estoque público com vão de porta desimpedido.
	group_depth = -450
	box(STOCK.position.x, STOCK.position.y, STOCK.size.x, STOCK.size.y, 0, .2, Color("a6a6a6"))
	draw_stock_shelf()
	for i in 3:
		box(12.02, 6.8, .70, .56, i * 20, 18, Color(.48 + .11*i, .48 + .11*i, .48 + .11*i))
	box(12.87, 5.55, .13, 2.05, 0, 28, LIGHT)
	box(12.87, 7.30, .13, .30, 28, 84, LIGHT)
	box(10.95, 5.55, .22, .18, 0, 108, MID)
	box(12.72, 5.55, .28, .18, 0, 108, MID)
	box(11.17, 5.55, 1.55, .18, 92, 16, MID)
	# Folha de vidro recolhida à direita, dentro do estoque.
	face([Vector3(12.62, 5.77, 0), Vector3(12.62, 6.62, 0), Vector3(12.62, 6.62, 92), Vector3(12.62, 5.77, 92)], Color(.45,.45,.45,.38))

	# I8: abrir a maleta na bancada e apoiar o sensor separado, ligado por cabo.
	group_depth = 480
	footprint_bench(EQUIPMENT, 40)
	box(10.78, 1.42, .90, .55, 40, 8, DARK)
	box(10.78, 1.93, .90, .09, 48, 27, DARK)
	face([Vector3(10.88, 1.92, 53), Vector3(11.58, 1.92, 53), Vector3(11.58, 1.92, 69), Vector3(10.88, 1.92, 69)], MID)
	box(12.03, 1.70, .20, .21, 40, 13, DARK)
	diamond(12.12, 1.70, 59, 10)
	segment(Vector3(11.65, 1.55, 42), Vector3(11.80, 1.33, 42))
	segment(Vector3(11.80, 1.33, 42), Vector3(12.11, 1.72, 42))

	# I9: vidro e capacho centralizados no mesmo eixo da torre.
	group_depth = 600
	box(5.05, 0, .16, .22, 0, 94, DARK)
	box(7.39, 0, .16, .22, 0, 94, DARK)
	face([Vector3(5.21, 0, 0), Vector3(7.39, 0, 0), Vector3(7.39, 0, 92), Vector3(5.21, 0, 92)], Color(.44,.44,.44,.22))
	for u in [5.95, 6.30, 6.65]:
		segment(Vector3(u, 0, 0), Vector3(u, 0, 92), MID, 2)
	box(5.37, -.62, 1.86, .49, 0, 1, DARK)

func footprint_bench(bounds: Rect2, height: float) -> void:
	bench(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y, height)

func draw_stock_shelf() -> void:
	box(SHELF.position.x, SHELF.position.y, SHELF.size.x, SHELF.size.y, 0, 98)
	for level in range(3):
		for slot in range(3):
			var tone := .43 + .09 * ((slot + level) % 3)
			box(9.32 + .49 * slot, 6.78, .40, .20, 27 + level * 22, 14, Color(tone, tone, tone))

func draw_plan(layer: Node2D) -> void:
	var floor_rect := Rect2(plan_point(Vector2(0, ROOM_DEPTH)), Vector2(ROOM_WIDTH, ROOM_DEPTH) * 53)
	layer.draw_rect(floor_rect, Color("e7e7e7"))
	for u in range(1, 13):
		layer.draw_line(plan_point(Vector2(u, 0)), plan_point(Vector2(u, ROOM_DEPTH)), Color("cccccc"))
	for d in range(1, 8):
		layer.draw_line(plan_point(Vector2(0, d)), plan_point(Vector2(ROOM_WIDTH, d)), Color("cccccc"))
	layer.draw_rect(floor_rect, INK, false, 2)
	plan_prop(layer, STOCK, "I7")
	plan_prop(layer, Rect2(.95, 6.85, 1.55, .65), "I4  Livros")
	plan_prop(layer, Rect2(.28, 5.93, .70, .70), "")
	plan_prop(layer, CART, "")
	plan_prop(layer, RECEPTION, "I3  Recepção")
	plan_prop(layer, RESEARCH, "I1/I5  Losango e pesquisa")
	plan_prop(layer, STOOL, "")
	plan_prop(layer, SHELF, "I6  Caixas")
	plan_prop(layer, Rect2(12.02, 6.8, .70, .56), "")
	label(layer, plan_point(Vector2(11.12,5.84)), "Estoque público", 12)
	plan_prop(layer, EQUIPMENT, "I8  Maleta")
	layer.draw_line(plan_point(Vector2(5.21, 0)), plan_point(Vector2(7.39, 0)), LIGHT, 5)
	var paths := [
		[Vector2(6.30,.1), Vector2(6.30,2.60), Vector2(6.30,4.05)],
		[Vector2(1.95,4.05), Vector2(1.95,2.60), Vector2(9.60,2.60), Vector2(9.60,3.55), Vector2(11.92,3.55), Vector2(11.92,6.45)],
		[Vector2(6.30,2.60), Vector2(9.60,2.60), Vector2(9.60,6.48)],
		[Vector2(9.60,2.60), Vector2(9.60,1.75), Vector2(10.20,1.75)],
	]
	for route in paths:
		for i in range(1, route.size()):
			layer.draw_dashed_line(plan_point(route[i-1]), plan_point(route[i]), Color("555555"), 2, 5)
		layer.draw_circle(plan_point(route.back()), 3, INK)
	label(layer, Vector2(72,66), "PLANTA POR ZONAS  /  INTERIOR", 26)
	label(layer, Vector2(72,98), "13 × 7,6 células   ·   +50% de área de piso   ·   mesma altura de Kael e dos equipamentos", 17)
	label(layer, plan_point(Vector2(5.30,-.42)), "I9  Entrada", 15)
	label(layer, Vector2(72,627), "Tracejado: percurso proposto. A bancada fica a 4,35 células da porta.", 17)
	label(layer, Vector2(72,654), "A faixa frontal tem 3,10 células de profundidade até a banqueta.", 17)

func plan_point(point: Vector2) -> Vector2:
	return Vector2(72 + point.x * 53, 566 - point.y * 53)

func plan_prop(layer: Node2D, bounds: Rect2, title: String) -> void:
	var rect := Rect2(plan_point(Vector2(bounds.position.x, bounds.end.y)), bounds.size * 53)
	layer.draw_rect(rect, Color("b6b6b6"))
	layer.draw_rect(rect, INK, false, 1)
	if not title.is_empty():
		label(layer, rect.position + Vector2(4, 17), title, 12)

func label(layer: Node2D, pos: Vector2, title: String, size: int) -> void:
	layer.draw_string(ThemeDB.fallback_font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)

func draw_scene() -> void:
	shapes.sort_custom(func(a,b):return a.order<b.order if a.depth==b.depth else a.depth<b.depth)
	for shape in shapes:
		if shape.has("line"):
			stage.draw_polyline(shape.line,shape.color,shape.width,true)
		else:
			stage.draw_colored_polygon(shape.points,shape.color)
			if shape.edge:
				var points:PackedVector2Array=shape.points.duplicate()
				points.append(points[0])
				stage.draw_polyline(points,INK,1,true)

	stage.draw_string(ThemeDB.fallback_font,Vector2(45,55),"LABORATÓRIO V2 / ETAPA 1 / "+("INTERIOR" if interior else "FACHADA"),HORIZONTAL_ALIGNMENT_LEFT,-1,23,INK)
	stage.draw_string(ThemeDB.fallback_font,Vector2(45,88),"Câmera 2:1 · célula 64 × 32 px · Kael nativo · maquete de volumes",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)
	if interior:
		label(stage, Vector2(45,650), "13 × 7,6 células  ·  pé-direito central de 200 px", 18)
		label(stage, Vector2(45,676), "Passagem de 3,10 células até a banqueta. Luz, cores e materiais na etapa 2.", 17)
	else:
		label(stage, Vector2(45,894), "Lote: u 0,5 → 14 · v −10 → −1 · entrada (7,25; −1) · terreno +48 px", 18)
		label(stage, Vector2(45,923), "Faixa frontal livre: 1 célula. Materiais, cores e acabamento: etapa 2.", 17)
	var ruler := p(3.70, 2.15) if interior else p(6.75,.5)
	stage.draw_line(ruler+Vector2(30,0),ruler+Vector2(30,-70),INK,1)
	stage.draw_string(ThemeDB.fallback_font,ruler+Vector2(39,-32),"70 px",HORIZONTAL_ALIGNMENT_LEFT,-1,14,INK)

func shot(path:String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+path)

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(1280,960)
	DisplayServer.window_set_size(root.size)
	RenderingServer.set_default_clear_color(Color("f3f3f3"))
	stage=Node2D.new()
	root.add_child(stage)
	stage.draw.connect(draw_scene)
	var kael:=Sprite2D.new()
	kael.texture=ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://assets/kael-video/iso-v2/idle.png")))
	kael.region_enabled=true
	kael.region_rect=Rect2(0,7*96,64,96)
	kael.offset=Vector2(0,-46)
	kael.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(kael)
	# A imagem original de Kael serve de régua; toda a maquete usa cinza.
	var interior_only := "--interior" in OS.get_cmdline_user_args()
	if not interior_only:
		facade()
		kael.position = p(6.75,.5,0)
		stage.queue_redraw()
		await shot("fachada/blockout.png")
	shapes.clear()
	root.size = Vector2i(960,720)
	DisplayServer.window_set_size(root.size)
	inside()
	kael.position = p(3.70, 2.15)
	stage.queue_redraw()
	await shot("interior/blockout.png")
	stage.hide()

	var plan := Node2D.new()
	root.add_child(plan)
	plan.draw.connect(draw_plan.bind(plan))
	await shot("interior/planta.png")
	plan.hide()

	root.size = Vector2i(1280,960)
	DisplayServer.window_set_size(root.size)
	var overlay:=Node2D.new()
	root.add_child(overlay)
	overlay.draw.connect(draw_overlay.bind(overlay))
	for side in (["interior"] if interior_only else ["fachada","interior"]):
		var texture:Texture2D=ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(OUT+"referencias/concept-"+side+".png")))
		overlay.set_meta("texture",texture)
		overlay.set_meta("side",side)

		overlay.queue_redraw()
		await shot(side+"/blockout-sobre-concept.png")
	print("Blockouts fachada/interior 2:1, célula 64x32, Kael nativo 70px.")
	quit()


func draw_overlay(layer:Node2D) -> void:
	var texture:Texture2D=layer.get_meta("texture")
	var side:String=layer.get_meta("side")
	var at:=Vector2(45,220)
	layer.draw_texture(texture,at)
	var groups:Array
	if side=="fachada":
		groups=[
			["F1",[[90,265],[170,212],[300,167],[423,174],[423,234],[300,203],[171,236],[90,277]],Vector2(244,192)],
			["F1",[[584,235],[688,172],[802,143],[913,160],[1015,205],[1095,263],[1064,276],[983,220],[885,187],[780,171],[685,196],[584,253]],Vector2(853,163)],
			["F2",[[425,237],[425,85],[623,61],[671,78],[671,210],[624,235]],Vector2(541,109)],
			["F3",[[341,240],[584,235],[584,268],[367,272],[367,402],[341,406]],Vector2(407,259)],
			["F4",[[145,501],[383,510],[559,426],[553,394],[337,403],[226,452]],Vector2(309,466)],
			["F4",[[136,458],[338,385],[339,410],[139,493]],Vector2(206,428)],
			["F5",[[176,287],[339,286],[340,359],[176,364]],Vector2(240,322)],
			["F5",[[725,282],[932,282],[931,357],[725,363]],Vector2(814,315)],
			["F6",[[609,254],[681,219],[681,391],[609,409]],Vector2(644,321)],
			["F7",[[560,440],[693,384],[1109,415],[1127,536],[970,571],[559,535]],Vector2(817,515)],
			["F7",[[853,470],[852,385],[891,330],[971,330],[1018,374],[1018,470]],Vector2(937,399)],
			["F8",[[717,150],[718,105],[758,55],[792,41],[842,46],[855,60],[810,52],[769,71],[738,111],[738,151]],Vector2(778,99)],
			["F8",[[924,167],[926,48],[971,43],[980,64],[964,80],[976,102],[967,173]],Vector2(952,107)],
			["F9",[[20,355],[51,304],[90,320],[127,363],[193,370],[270,360],[335,382],[336,410],[89,461],[20,438]],Vector2(100,391)],
		]
	else:
		groups=[
			["I1",[[470,263],[460,194],[500,138],[519,138],[566,190],[577,233],[559,272]],Vector2(517,190)],
			["I2",[[388,140],[390,29],[599,9],[600,137]],Vector2(484,72)],
			["I3",[[91,363],[95,298],[125,293],[128,266],[218,271],[250,285],[379,284],[389,347],[337,351],[217,326],[216,350]],Vector2(286,311)],
			["I4",[[232,260],[233,168],[285,168],[286,260],[295,260],[295,156],[370,157],[373,267]],Vector2(331,190)],
			["I5",[[419,265],[447,249],[684,257],[709,273],[708,326],[421,310]],Vector2(602,290)],
			["I6",[[649,156],[770,156],[772,265],[649,264]],Vector2(707,200)],
			["I7",[[798,165],[958,167],[959,294],[797,291]],Vector2(877,228)],
			["I8",[[708,343],[749,321],[890,330],[891,351],[860,361],[861,412],[710,400]],Vector2(797,354)],
			["I9",[[374,343],[542,350],[540,418],[376,411]],Vector2(453,385)],
			["I10",[[23,171],[89,123],[203,84],[388,61],[389,86],[206,107],[98,143],[24,183]],Vector2(182,105)],
			["I10",[[558,86],[684,59],[804,56],[921,77],[1036,116],[1038,134],[920,98],[805,76],[686,79],[558,105]],Vector2(815,77)]
		]
	for group in groups:
		var points:=PackedVector2Array()
		for xy in group[1]: points.append(at+Vector2(xy[0],xy[1]))
		layer.draw_colored_polygon(points,Color(0.22,0.22,0.22,.22))
		points.append(points[0])
		layer.draw_polyline(points,Color("333333"),2.2,true)
		var label_at:Vector2=at+group[2]
		layer.draw_rect(Rect2(label_at-Vector2(7,18),Vector2(36,23)),Color("eeeeee"))
		layer.draw_string(ThemeDB.fallback_font,label_at,group[0],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.BLACK)
	layer.draw_string(ThemeDB.fallback_font,Vector2(45,85),"ETAPA 1  /  "+side.to_upper()+"  /  volumes identificados sobre o concept",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("333333"))
	layer.draw_string(ThemeDB.fallback_font,Vector2(45,127),"Referência em sua câmera original. O blockout.png ao lado usa a câmera 2:1 do jogo.",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("555555"))

	if side == "interior":
		label(layer, Vector2(45,731), "Na maquete revisada, I1 e I2 continuam no eixo da entrada I9.", 19)
		label(layer, Vector2(45,765), "A profundidade passa de 5,3 para 7,6 células e abre a circulação diante de I5.", 19)
		label(layer, Vector2(45,799), "I8 continua no primeiro plano à direita, com passagem até I7 e I6 pelo mesmo lado.", 19)