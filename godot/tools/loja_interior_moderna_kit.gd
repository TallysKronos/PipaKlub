extends "res://tools/laboratorio_v2_kit.gd"
## Recortes da pintura moderna aprovada, com apoio visual e referência da planta.
const ROOM_ORIGIN := Vector2(500,245)

func _initialize() -> void:
	base="res://../art/overworld/estilo/loja-piloto-v2/interior/modernizacao/"
	dest=base+"kit/"
	canvas_size=Vector2i(1120,820)
	atlas_size=Vector2i(2048,2048)
	build.call_deferred()

func canvas_anchor(anchor: Array, height: float) -> Vector2i:
	return Vector2i((ROOM_ORIGIN+Vector2((anchor[0]-anchor[1])*32,(anchor[0]+anchor[1])*16-height)).round())

func cut(id: String, label: String, mask: Array, footprint: Array, support: Vector2, height: float=0) -> void:
	var floor := support+Vector2(0,height)-ROOM_ORIGIN
	var u := floor.x/64.0+floor.y/32.0
	var v := floor.y/32.0-floor.x/64.0
	part(id,label,mask,footprint,[snappedf(u,.001),snappedf(v,.001)],height)

func definitions() -> void:
	cut("piso","Piso e base em corte",[],[0,0,18,14],Vector2(500,245))
	cut("parede-esquerda","Painéis creme e faixa teal",[],[0,0,0,14],Vector2(275,357))
	cut("parede-fundo","Parede teal e painéis creme",[],[0,0,18,0],Vector2(788,389))
	cut("janela-esquerda","Janela voltada à rua esquerda",[[328,187],[476,114],[476,230],[328,287]],[],Vector2(403,250),45)
	cut("janela-direita","Janela voltada à rua direita",[[813,261],[1004,355],[1006,465],[813,373]],[],Vector2(907,417),45)
	cut("quadro-pipa-a","Pipa amarela emoldurada",[[536,107],[586,131],[586,200],[536,177]],[],Vector2(561,175),80)
	cut("quadro-pipa-b","Pipa vermelha emoldurada",[[615,148],[668,173],[668,241],[615,215]],[],Vector2(641,213),80)
	cut("quadro-pipa-c","Pipa verde emoldurada",[[700,190],[752,215],[753,281],[700,255]],[],Vector2(725,255),80)
	cut("prateleira-a","Estante metálica de linhas e materiais",[[459,190],[488,171],[710,268],[711,360],[696,376],[684,377],[682,374],[469,288],[460,288]], [.5,.3,6.5,1.2],Vector2(587,332))
	cut("prateleira-b","Estante metálica junto à janela",[[777,349],[806,332],[1027,434],[1029,530],[1013,549],[1003,548],[1001,544],[786,450],[777,448]], [11.5,.3,17.5,1.2],Vector2(903,498))
	cut("expositor-pipas","Expositor em metal e vidro",[[154,290],[273,230],[288,237],[301,240],[307,247],[306,419],[299,432],[294,435],[289,433],[183,441],[158,427],[153,420]], [.3,7,1.3,10],Vector2(219,426))
	cut("gondola","Ilha de materiais com portas inferiores",[[325,376],[374,350],[500,410],[503,468],[486,484],[479,489],[435,501],[329,445],[324,439]], [3.5,6.5,6.5,8],Vector2(416,478))
	cut("balcao","Caixa com vitrine de cartas",[[503,342],[548,318],[752,412],[753,472],[739,482],[733,486],[728,485],[715,493],[507,402]], [5,2.5,11,4],Vector2(622,455))
	cut("terminal","Terminal digital inclinado",[[691,396],[704,371],[710,370],[735,381],[737,387],[727,405],[731,409],[719,417],[704,413],[703,409],[691,403]], [],Vector2(714,412),60)
	cut("mesa-fundo","Mesa do fundo com pés e banco posterior",[[551,529],[570,517],[571,493],[629,463],[786,533],[790,531],[799,536],[800,555],[794,560],[793,578],[786,584],[779,581],[775,607],[765,612],[754,605],[695,626],[681,631],[664,624],[660,611],[569,569],[568,574],[558,578],[551,571]], [11,6,15,8],Vector2(696,569))
	cut("banco-fundo","Banco do fundo e apoios",[[556,528],[568,520],[695,575],[698,583],[695,599],[688,604],[683,624],[671,626],[664,621],[663,607],[569,566],[569,570],[560,573],[553,568]], [11,7.4,15,8],Vector2(626,593))
	cut("mesa-frente","Mesa da frente com pés e banco posterior",[[381,598],[401,587],[402,562],[462,532],[618,601],[628,598],[635,605],[635,624],[627,631],[625,650],[617,656],[608,652],[607,678],[595,684],[584,678],[523,697],[510,705],[493,698],[490,683],[397,640],[396,646],[386,650],[380,642]], [11,10.5,15,12.5],Vector2(525,638))
	cut("banco-frente","Banco da frente e apoios",[[387,600],[398,589],[527,644],[530,653],[527,672],[518,676],[516,693],[503,699],[493,694],[493,680],[399,639],[397,643],[387,646],[381,639]], [11,11.9,15,12.5],Vector2(454,665))
	cut("capacho","Capacho digital da entrada",[[190,579],[212,566],[283,601],[266,613],[260,628],[248,629],[191,597]], [7,13.7,9,14],Vector2(234,608))
	cut("porta-vidro","Porta de vidro e montantes",[[183,469],[196,460],[211,464],[213,469],[213,477],[284,512],[288,510],[301,515],[305,522],[303,625],[290,631],[279,625],[276,613],[202,579],[187,575],[184,569]], [7,13.7,9,14],Vector2(244,600))

func base_part(pixel: Vector2) -> int:
	if pixel.x<ROOM_ORIGIN.x:
		return 1 if pixel.y<ROOM_ORIGIN.y+(ROOM_ORIGIN.x-pixel.x)*.5 else 0
	return 2 if pixel.y<ROOM_ORIGIN.y+(pixel.x-ROOM_ORIGIN.x)*.5 else 0

func layout_metadata() -> Dictionary:
	return {
		"grid":{"tile_px":[64,32],"room_cells":[18,14],"reference_canvas_origin_px":[500,245]},
		"entrance_cells":[8,14],
		"limitations":[
			"Recortes das superfícies visíveis. Reposicionar móveis requer completar superfícies ocultas.",
			"Pegadas em [u inicial,v inicial,u final,v final] vêm da planta aprovada. Apoios visuais foram estimados na pintura.",
			"As duas mesas e seus bancos têm camadas próprias. Faces ocultas entre eles precisarão de pintura para ordenar personagens intercalados.",
			"Calibrar escala, porta, circulação, colisões e oclusão na integração da cena kite-shop.",
		],
	}

func verification_stage() -> String:
	return "3 · kit moderno da Linha & Papel"
