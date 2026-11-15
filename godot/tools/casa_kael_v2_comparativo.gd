extends "res://tools/laboratorio_v2_revisao.gd"
func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	canvas=Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(draw)
	OUT="res://../art/casa-kael-v2/fachada/integracao/"
	content=board(2400,830)
	var concept:=img(OUT+"../../concept/prancha.png").get_region(Rect2i(0,60,795,730))
	concept.resize(660,606,Image.INTERPOLATE_LANCZOS)
	content.blit_rect(concept,Rect2i(0,0,660,606),Vector2i(20,90))
	var key:=img(OUT+"../portao-geometria-v3/blockout-2x.png")
	key.resize(654,367,Image.INTERPOLATE_NEAREST)
	content.blit_rect(key,Rect2i(0,0,654,367),Vector2i(700,180))
	var game:=img(OUT+"06-retorno.png")
	game.resize(1000,562,Image.INTERPOLATE_LANCZOS)
	content.blit_rect(game,Rect2i(0,0,1000,562),Vector2i(1380,110))
	labels=[[Vector2(20,40),"CONCEPT",26],[Vector2(700,40),"VOLUMES APROVADOS",26],[Vector2(1380,40),"INTEGRADO NA CAMPANHA",26],[Vector2(20,780),"Pilares com faces completas · piso no plano da calçada · acesso e retorno preservados",23]]
	await capture("comparativo.png")
	var detail:=img(OUT+"02-portao-fora.png").get_region(Rect2i(420,240,520,330))
	detail.resize(1040,660,Image.INTERPOLATE_NEAREST)
	detail.save_png(OUT+"portao-detalhe.png")
	quit()
