extends "res://tools/laboratorio_v2_revisao.gd"
## Revisão visual isolada. Não altera mapa, colisões ou saves.
const DIR := "res://../art/casa-kael-v2/fachada/"
var painting:Texture2D
var show_painting:=false
var kael:Texture2D

func draw() -> void:
	super.draw()
	if show_painting:
		canvas.draw_texture_rect(painting,Rect2(0,35,760,698),false)
		canvas.draw_texture(kael,Vector2(300-kael.get_width()/2,580-kael.get_height()))

func run() -> void:
	root.size=Vector2i(1280,720)
	var play:Node2D=load("res://scenes/overworld/neighborhood/bairro-jogavel.tscn").instantiate()
	root.add_child(play)
	play.set_physics_process(false)
	play._refresh_visuals()
	play._update_hint()
	play.camera.position=play.player_root.position-Vector2(0,95)
	play.camera.reset_smoothing()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+"jogo-atual.png")
	play.free()
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	canvas=Node2D.new()
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	OUT=DIR
	var source:=img(DIR+"quadro-chave.png")
	painting=ImageTexture.create_from_image(source)
	var frame:=img("res://assets/kael-video/iso-v2/idle.png").get_region(Rect2i(0,672,64,96))
	kael=ImageTexture.create_from_image(frame.get_region(frame.get_used_rect()))
	show_painting=true
	content=board(760,790)
	labels=[[Vector2(20,25),"PRÉVIA DE CONVIVÊNCIA / KAEL 70 PX NATIVOS",20],[Vector2(20,765),"Pintura ajustada para visualização · densidade final ainda em revisão",17]]
	await capture("previa-com-kael.png")
	show_painting=false
	content=board(2300,900)
	var concept:=img(DIR+"../concept/prancha.png").get_region(Rect2i(0,60,795,730))
	concept.resize(720,661,Image.INTERPOLATE_LANCZOS)
	content.blit_rect(concept,Rect2i(0,0,720,661),Vector2i(20,90))
	var candidate:=source.duplicate()
	candidate.resize(760,698,Image.INTERPOLATE_NEAREST)
	content.blit_rect(candidate,Rect2i(0,0,760,698),Vector2i(770,90))
	var current:=img(DIR+"jogo-atual.png")
	current.resize(730,411,Image.INTERPOLATE_LANCZOS)
	content.blit_rect(current,Rect2i(0,0,730,411),Vector2i(1550,210))
	labels=[[Vector2(20,45),"CONCEPT APROVADO",25],[Vector2(770,45),"PINTURA PARA APROVAÇÃO",25],[Vector2(1550,45),"CAPTURA DO MAPA ATUAL",25],[Vector2(20,850),"Etapa 2 · prévia de direção visual · sem substituir os assets do jogo",23]]
	await capture("comparativo.png")
	print("Casa Kael: fonte ",source.get_size(),". Kael ",kael.get_height()," px. Captura isolada, sem saves.")
	quit()
