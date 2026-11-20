extends "res://tools/laboratorio_v2_kit.gd"
## Recorta as superfícies visíveis da Linha & Papel na resolução nativa.
const ROOM_ORIGIN := Vector2(443, 208)
const U_AXIS := Vector2(28.0, 13.6)
const V_AXIS := Vector2(-29.0, 13.1)

func _initialize() -> void:
	base = "res://../art/overworld/estilo/loja-piloto-v2/interior/"
	dest = base + "kit/"
	canvas_size = Vector2i(976, 680)
	build.call_deferred()

func canvas_anchor(anchor: Array, height: float) -> Vector2i:
	return Vector2i((ROOM_ORIGIN + U_AXIS * anchor[0] + V_AXIS * anchor[1] - Vector2(0, height)).round())

func visual_part(id: String, label: String, mask: Array, footprint: Array, support: Vector2, height: float = 0.0) -> void:
	var floor := support + Vector2(0, height) - ROOM_ORIGIN
	var determinant := U_AXIS.cross(V_AXIS)
	var u := floor.cross(V_AXIS) / determinant
	var v := U_AXIS.cross(floor) / determinant
	part(id, label, mask, footprint, [snappedf(u, 0.001), snappedf(v, 0.001)], height)

func definitions() -> void:
	visual_part("piso", "Ladrilhos e borda do corte", [], [0,0,18,14], Vector2(443,208))
	visual_part("parede-esquerda", "Parede creme e rodapé coral", [], [0,0,0,14], Vector2(246,292))
	visual_part("parede-fundo", "Parede petróleo e rodapé coral", [], [0,0,18,0], Vector2(710,334))
	visual_part("janela-esquerda", "Janela da rua esquerda", [[295,145],[425,82],[425,176],[295,238]], [], Vector2(364,198), 49)
	visual_part("janela-direita", "Janela da rua direita", [[724,211],[895,294],[895,379],[724,301]], [], Vector2(811,348), 43)
	visual_part("quadro-pipa-esquerda", "Pipa amarela emoldurada", [[472,88],[520,111],[521,168],[474,148]], [], Vector2(500,138), 96)
	visual_part("quadro-pipa-central", "Pipa vermelha emoldurada", [[538,107],[599,134],[599,198],[539,171]], [], Vector2(561,164), 101)
	visual_part("quadro-pipa-direita", "Pipa verde emoldurada", [[624,155],[671,177],[671,237],[624,216]], [], Vector2(645,207), 100)
	visual_part("estante-fundo", "Estante de carretéis do fundo", [[408,161],[423,147],[465,158],[469,157],[516,175],[552,184],[554,182],[587,194],[620,204],[622,283],[610,295],[601,291],[600,288],[559,280],[554,282],[548,277],[511,265],[506,267],[502,263],[460,252],[459,254],[454,250],[418,236],[411,238],[407,235]], [0,0,6,1], Vector2(516,267))
	visual_part("estante-lateral", "Estante de carretéis junto à janela", [[726,331],[746,316],[784,327],[791,329],[801,330],[835,344],[845,342],[886,357],[902,361],[938,370],[941,448],[929,460],[925,460],[920,456],[878,444],[874,448],[869,444],[827,432],[823,435],[818,431],[775,417],[770,419],[765,414],[736,403],[730,405],[725,402]], [12,0,18,1], Vector2(829,435))
	visual_part("expositor-pipas", "Expositor vertical de pipas", [[129,241],[242,196],[243,194],[270,204],[270,304],[272,309],[267,315],[260,314],[178,351],[177,358],[172,361],[165,360],[161,355],[138,346],[133,347],[129,341]], [0,7,1.5,10], Vector2(177,355))
	visual_part("gondola", "Gôndola baixa de materiais", [[295,319],[324,303],[455,352],[456,389],[428,408],[423,413],[415,411],[413,409],[360,389],[353,393],[347,387],[302,366],[299,367],[294,363]], [4,6,7,8], Vector2(384,395))
	visual_part("balcao-caixa", "Balcão com vitrine", [[465,294],[494,279],[613,320],[637,317],[687,332],[697,337],[697,381],[680,396],[675,400],[668,397],[612,379],[607,381],[600,376],[539,356],[535,359],[528,355],[472,339],[468,339],[463,335]], [5,2,11,3.5], Vector2(580,370))
	visual_part("terminal", "Terminal do caixa", [[640,322],[648,304],[677,312],[681,323],[679,330],[676,332],[676,336],[665,341],[655,338],[655,335],[642,330]], [], Vector2(663,336), 44)
	visual_part("tapete-comunidade", "Tapete da área de montagem", [[315,533],[591,383],[761,473],[480,615]], [10.5,4.5,15.5,13.5], Vector2(539,518))
	visual_part("mesa-a", "Mesa de montagem do fundo e banco", [[505,426],[525,415],[525,401],[572,375],[714,437],[715,470],[704,484],[662,502],[658,507],[651,507],[647,502],[636,504],[635,509],[626,514],[615,514],[614,504],[521,454],[519,459],[512,459],[505,453]], [11,5,15,8], Vector2(618,489))
	visual_part("mesa-b", "Mesa de montagem da frente e banco", [[354,496],[370,488],[370,467],[421,445],[475,470],[568,512],[569,538],[554,546],[554,553],[547,556],[541,553],[514,566],[512,575],[504,581],[494,578],[478,582],[471,588],[465,587],[460,583],[460,568],[369,522],[364,531],[357,529],[352,524]], [11,10,15,13], Vector2(463,560))
	visual_part("capacho", "Capacho listrado da entrada", [[167,495],[182,489],[226,507],[213,514],[198,523],[165,504]], [6.5,13,8.5,14], Vector2(194,508))
	visual_part("porta-vidro", "Porta de vidro e montantes", [[156,393],[168,388],[257,438],[259,517],[251,525],[156,480]], [6.5,13,8.5,14], Vector2(206,506))

func base_part(pixel: Vector2) -> int:
	if pixel.x < ROOM_ORIGIN.x:
		return 1 if pixel.y < 200.0 + (ROOM_ORIGIN.x - pixel.x) * 0.475 else 0
	return 2 if pixel.y < 200.0 + (pixel.x - ROOM_ORIGIN.x) * 0.495 else 0

func layout_metadata() -> Dictionary:
	return {
		"grid": {
			"game_tile_px": [64,32],
			"room_cells": [18,14],
			"reference_canvas_origin_px": [ROOM_ORIGIN.x, ROOM_ORIGIN.y],
			"reference_u_axis_px": [U_AXIS.x, U_AXIS.y],
			"reference_v_axis_px": [V_AXIS.x, V_AXIS.y],
			"coordinate_system": "u para a direita e v para a esquerda, ambos descendo na tela",
		},
		"entrance_cells": [7.5,13.5],
		"limitations": [
			"Recortes das superfícies visíveis. Mover móveis expõe áreas de piso e parede sem pintura.",
			"Pegadas de referência da planta de jogabilidade em [u inicial, v inicial, u final, v final]. Apoios estimados no quadro para remontagem sem deformar.",
			"Conferir a posição da porta, circulação, colisões e oclusão na cena kite-shop na integração.",
		],
	}

func verification_stage() -> String:
	return "3 · kit do interior da Linha & Papel"
