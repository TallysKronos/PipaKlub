extends "res://tools/laboratorio_v2_kit.gd"
## Recortes visíveis no quadro-chave da sala pública. As pegadas vêm da planta ampliada.
const ROOM_ORIGIN := Vector2(32, 270)

func _initialize() -> void:
	base = "res://../art/professor-laboratorio-v2/interior/"
	dest = base + "kit/"
	canvas_size = Vector2i(720, 512)
	build.call_deferred()

func canvas_anchor(a:Array,z:float) -> Vector2i:
	return Vector2i((ROOM_ORIGIN + Vector2((a[0]+a[1])*32, (a[0]-a[1])*16-z)).round())

func layout_metadata() -> Dictionary:
	return {
		"grid": {
			"tile_px": [64,32],
			"room_cells": [13,7.6],
			"reference_canvas_origin_px": [ROOM_ORIGIN.x,ROOM_ORIGIN.y],
			"reference_room_cell": [0,0],
			"coordinate_system": "u para a direita e d para o fundo, na planta",
		},
		"entrance_cells": [6.30,0],
		"limitations": [
			"Recortes das superfícies visíveis. Mover um móvel expõe trechos de piso ainda sem pintura.",
			"Pegadas e apoios foram estimados pela planta revisada. Pivôs recompõem o PNG em 1×.",
			"Conferir o acesso, oclusão e colisões na etapa 4 com a cena professor-home.",
		],
	}

func verification_stage() -> String:
	return "3 · kit interno para montagem"

func definitions() -> void:
	# Máscaras em pixels do quadro aprovado, na ordem de prioridade de recorte.
	part("piso", "Piso e bordas do corte", [], [0,0,13,7.6], [0,0])
	part("parede-lateral", "Parede esquerda", [], [0,0,.15,7.6], [0,4.1])
	part("parede-fundo", "Parede de fundo", [], [0,7.45,13,7.6], [6.3,7.6])
	part("abobada-esquerda", "Abóbada esquerda em corte", [[241,36],[266,22],[302,18],[330,19],[357,26],[388,46],[411,73],[428,102],[406,123],[392,120],[374,100],[350,84],[322,68],[297,61],[258,53],[243,54]], [0,6.9,4.75,7.6], [2.5,7.25], 138)
	part("abobada-direita", "Abóbada direita em corte", [[493,151],[523,137],[547,132],[574,132],[606,137],[633,151],[660,173],[690,208],[692,219],[672,244],[661,245],[647,224],[624,203],[600,188],[574,174],[546,165],[515,162],[498,167]], [7.9,6.9,13,7.6], [10.45,7.25], 146)
	part("torre-vidro", "Janela alta da torre", [[421,31],[537,89],[539,135],[519,143],[503,152],[501,178],[421,134]], [4.55,7.45,8.10,7.6], [6.30,7.6], 110)
	part("janela-esquerda", "Janela da recepção", [[117,115],[264,54],[266,144],[118,209]], [0,2.7,.12,7.20], [0,4.7], 35)
	part("quadro-losango", "Quadro na parede esquerda", [[359,123],[379,109],[398,134],[379,147]], [3.1,7.54,3.5,7.6], [3.25,7.6], 84)
	part("painel-teal", "Painel atrás da pesquisa", [[452,150],[488,166],[490,211],[447,192],[447,158]], [7.85,7.52,8.2,7.6], [8.05,7.6], 84)
	part("estante-livros", "Estante e livros", [[280,92],[304,78],[354,102],[354,195],[326,216],[280,189]], [.95,6.85,2.50,7.50], [1.72,6.85])
	part("planta-recepcao", "Vaso e planta", [[235,150],[233,131],[252,127],[273,132],[279,151],[268,165],[268,182],[243,174],[241,157]], [.28,5.93,.98,6.63], [.63,5.93])
	part("recepcao", "Balcão com monitor", [[199,184],[239,164],[244,168],[272,179],[298,186],[317,201],[314,237],[276,256],[201,224]], [.95,4.35,3.20,5.60], [2.07,4.35])
	part("carrinho", "Carrinho com caixas", [[120,243],[124,219],[131,208],[151,199],[173,209],[174,219],[184,227],[179,256],[155,271],[121,257]], [.42,2.60,1.36,3.20], [.89,2.60])
	part("bancada-pesquisa", "Bancada de pesquisa", [[314,237],[365,212],[414,229],[502,286],[502,319],[463,342],[314,268]], [4.30,4.35,8.90,5.65], [6.60,4.35])
	part("aparelho-losango", "Aparelho com dois arcos", [[341,172],[347,164],[359,164],[394,143],[423,179],[443,200],[440,220],[424,247],[423,258],[410,269],[355,244],[362,232],[350,216]], [5.49,4.83,7.11,5.45], [6.30,5.10], 42)
	part("monitores", "Dois monitores de pesquisa", [[427,235],[434,224],[463,235],[469,245],[490,247],[493,280],[484,293],[449,284],[429,270]], [7.70,4.9,8.88,5.18], [8.3,5.02], 42)
	part("banqueta", "Banqueta", [[346,309],[364,300],[386,312],[384,326],[376,329],[383,342],[368,353],[348,342],[354,330],[348,325]], [6.95,3.10,7.40,3.55], [7.18,3.10])
	part("estante-caixas", "Estante de caixas coloridas", [[539,208],[562,198],[612,221],[611,306],[577,330],[538,307]], [9.20,6.85,10.76,7.53], [9.98,6.85])
	part("estoque-fundos", "Recinto, porta e maletas amarelas", [[555,249],[617,279],[670,249],[687,242],[690,346],[632,395],[612,393],[610,385],[551,356]], [10.95,5.55,13,7.60], [12.00,5.55])
	part("mesa-maleta", "Mesa de equipamento", [[391,389],[437,366],[508,395],[504,444],[459,460],[395,429]], [10.55,1.10,12.55,2.45], [11.55,1.10])
	part("maleta-sensor", "Maleta aberta e sensor com cabo", [[399,371],[406,345],[431,336],[459,331],[467,341],[469,362],[475,356],[492,358],[497,369],[492,386],[494,404],[472,414],[421,414],[401,401]], [10.78,1.42,12.22,1.94], [11.46,1.67], 40)
	part("entrada", "Porta de vidro e capacho", [[185,287],[201,277],[278,313],[280,325],[280,388],[270,397],[241,405],[183,379],[183,368],[188,357]], [5.05,-.62,7.55,.22], [6.30,0])

func base_part(pixel: Vector2) -> int:
	# Junções de piso e parede medidas no quadro. Mesa e props têm prioridade.
	var corner := Vector2(275, 147)
	if pixel.x < corner.x:
		return 1 if pixel.y < corner.y + (corner.x - pixel.x) * .50 else 0
	return 2 if pixel.y < corner.y + (pixel.x - corner.x) * .51 else 0