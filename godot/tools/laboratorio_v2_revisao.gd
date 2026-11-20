extends SceneTree
## Pranchas de aprovação; nenhuma alteração do mapa ou dos sprites de produção.
var OUT := "res://../art/professor-laboratorio-v2/fachada/"
var content:Image
var labels:Array=[]
var canvas:Node2D
var render_texture:ImageTexture

func _initialize() -> void:
	run.call_deferred()

func img(path:String) -> Image:
	var value:=Image.load_from_file(ProjectSettings.globalize_path(path))
	value.convert(Image.FORMAT_RGBA8)
	return value

func gray(source:Image) -> Image:
	var out:Image=source.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			var c:=out.get_pixel(x,y)
			var v:=.2126*c.r+.7152*c.g+.0722*c.b
			out.set_pixel(x,y,Color(v,v,v,c.a))
	return out

func board(w:int,h:int) -> Image:
	var result:=Image.create(w,h,false,Image.FORMAT_RGBA8)
	result.fill(Color("e8edf0"))
	return result

func figure(target:Image,path:String,region:Rect2i,feet:Vector2i,outline:bool=false) -> void:
	var frame:=img(path).get_region(region)
	var bound:=frame.get_used_rect()
	frame=frame.get_region(bound)
	var at := feet - Vector2i(frame.get_width()/2, frame.get_height())
	if outline:
		var padded := Image.create_empty(frame.get_width() + 2, frame.get_height() + 2, false, Image.FORMAT_RGBA8)
		for y in frame.get_height():
			for x in frame.get_width():
				if frame.get_pixel(x, y).a <= .5:
					continue
				for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					padded.set_pixelv(Vector2i(x + 1, y + 1) + step, Color(.10, .07, .09, .92))
		padded.blit_rect_mask(frame, frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i.ONE)
		target.blend_rect(padded, Rect2i(Vector2i.ZERO, padded.get_size()), at - Vector2i.ONE)
	else:
		target.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), at)

func draw() -> void:
	canvas.draw_texture(render_texture,Vector2.ZERO)
	for label in labels:
		canvas.draw_string(ThemeDB.fallback_font,label[0],label[1],HORIZONTAL_ALIGNMENT_LEFT,-1,label[2],Color("23364b"))

func capture(path:String) -> void:
	render_texture=ImageTexture.create_from_image(content)
	root.size=content.get_size()
	DisplayServer.window_set_size(root.size)
	canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+path)

func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor=1.0
	canvas=Node2D.new()
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	if "--interior" in OS.get_cmdline_user_args():
		OUT = "res://../art/professor-laboratorio-v2/interior/"
		await render_interior()
		return
	var art:=img(OUT+"quadro-chave.png")
	var native:=board(768,576)
	native.blend_rect(art,Rect2i(Vector2i.ZERO,art.get_size()),Vector2i.ZERO)
	figure(native,"res://assets/kael-video/iso-v2/idle.png",Rect2i(0,672,64,96),Vector2i(212,400))
	figure(native,"res://assets/campaign/overworld-companions/rabbito.png",Rect2i(0,0,80,80),Vector2i(167,378))
	figure(native,"res://assets/npc-ds/professor.png",Rect2i(0,0,64,96),Vector2i(265,426))
	native.save_png(OUT+"convivencia-nativa.png")
	var mono:=gray(native)
	mono.save_png(OUT+"convivencia-cinza.png")
	content=board(2400,2480)
	var native2:Image=native.duplicate()
	native2.resize(1536,1152,Image.INTERPOLATE_NEAREST)
	var mono2:=gray(native2)
	content.blit_rect(native,Rect2i(0,0,768,576),Vector2i(20,90))
	content.blit_rect(native2,Rect2i(0,0,1536,1152),Vector2i(820,90))
	content.blit_rect(mono,Rect2i(0,0,768,576),Vector2i(20,1310))
	content.blit_rect(mono2,Rect2i(0,0,1536,1152),Vector2i(820,1310))
	labels=[[Vector2(20,45),"CONVIVÊNCIA / COR / 1× NATIVO",24],[Vector2(820,45),"2× NEAREST / KAEL, RABBITO E SR. ASSIS ORIGINAIS",24],[Vector2(20,1260),"ESCALA DE CINZA / 1×",24],[Vector2(820,1260),"ESCALA DE CINZA / 2×",24]]
	await capture("teste-convivencia.png")
	content=board(2176,800)
	var concept:=img(OUT+"../referencias/concept-fachada.png")
	concept.resize(640,314,Image.INTERPOLATE_LANCZOS)
	var integrated:=FileAccess.file_exists(OUT+"integracao/depois.png")
	var current:=img(OUT+("integracao/depois.png" if integrated else "../referencias/jogo-atual-fachada.png"))
	current.resize(640,360,Image.INTERPOLATE_LANCZOS)
	content.blend_rect(concept,Rect2i(Vector2i.ZERO,concept.get_size()),Vector2i(20,180))
	content.blend_rect(art,Rect2i(0,0,768,576),Vector2i(680,110))
	content.blend_rect(current,Rect2i(Vector2i.ZERO,current.get_size()),Vector2i(1480,165))
	labels=[[Vector2(20,60),"CONCEPT DO DESIGNER",24],[Vector2(680,60),"QUADRO-CHAVE / 768 × 576 NATIVOS",24],[Vector2(1480,60),"INTEGRADO NA VILA" if integrated else "JOGO ATUAL / REFERÊNCIA LEGADA",24],[Vector2(20,742),"Fachada integrada em escala nativa. Interior: ampliação e nova aprovação pendentes." if integrated else "Fachada: etapa 2 para aprovação. Interior: espaço a rever. Kit e montagem no mapa após os portões.",22]]
	await capture("comparativo.png")
	audit_art(art)

func render_interior() -> void:
	var art := img(OUT + "quadro-chave.png")
	var size := art.get_size()
	var rect := Rect2i(Vector2i.ZERO, size)
	var native := board(size.x, size.y)
	native.blend_rect(art, rect, Vector2i.ZERO)
	figure(native, "res://assets/campaign/overworld-animations-v1/rabbito/idle.png", Rect2i(0, 0, 112, 112), Vector2i(259, 301), true)
	figure(native, "res://assets/npc-ds/professor.png", Rect2i(0, 0, 64, 96), Vector2i(514, 381))
	figure(native, "res://assets/kael-video/iso-v2/idle.png", Rect2i(0, 672, 64, 96), Vector2i(299, 327))
	native.save_png(OUT + "convivencia-nativa.png")
	var mono := gray(native)
	mono.save_png(OUT + "convivencia-cinza.png")
	var native2 := native.duplicate()
	native2.resize(size.x * 2, size.y * 2, Image.INTERPOLATE_NEAREST)
	var mono2 := gray(native2)
	var large_rect := Rect2i(Vector2i.ZERO, size * 2)
	content = board(size.x * 3 + 80, size.y * 4 + 160)
	var right := size.x + 50
	var lower := size.y * 2 + 130
	content.blit_rect(native, rect, Vector2i(20, 70))
	content.blit_rect(native2, large_rect, Vector2i(right, 70))
	content.blit_rect(mono, rect, Vector2i(20, lower))
	content.blit_rect(mono2, large_rect, Vector2i(right, lower))
	labels = [
		[Vector2(20, 48), "CONVIVÊNCIA / COR / 1× NATIVO", 22],
		[Vector2(right, 48), "KAEL, RABBITO E SR. ASSIS / 2× NEAREST", 22],
		[Vector2(20, lower - 22), "ESCALA DE CINZA / 1×", 22],
		[Vector2(right, lower - 22), "ESCALA DE CINZA / 2×", 22],
	]
	await capture("teste-convivencia.png")

	var concept := img(OUT + "../referencias/concept-interior.png")
	var integrated := FileAccess.file_exists(OUT + "integracao/depois.png")
	var current := img(OUT + ("integracao/depois.png" if integrated else "../referencias/jogo-atual-interior.png"))
	concept.resize(630, roundi(concept.get_height() * 630.0 / concept.get_width()), Image.INTERPOLATE_LANCZOS)
	current.resize(610, roundi(current.get_height() * 610.0 / current.get_width()), Image.INTERPOLATE_LANCZOS)
	content = board(2040, 660)
	content.blend_rect(concept, Rect2i(Vector2i.ZERO, concept.get_size()), Vector2i(20, 205))
	content.blend_rect(art, rect, Vector2i(651, 82))
	content.blit_rect(current, Rect2i(Vector2i.ZERO, current.get_size()), Vector2i(1402, 154))
	labels = [
		[Vector2(20, 57), "CONCEPT DO DESIGNER", 24],
		[Vector2(681, 57), "QUADRO-CHAVE  /  720 × 512 NATIVOS", 24],
		[Vector2(1402, 57), "INTERIOR INTEGRADO NO JOGO" if integrated else "INTERIOR ATUAL NO JOGO", 24],
		[Vector2(20, 622), "Interior público do Sr. Assis · Planta ampliada · Captura in-game" if integrated else "Interior público do Sr. Assis · Planta ampliada · Revisão de arte antes do kit", 20],
	]
	await capture("comparativo.png")
	audit_art(art)

func audit_art(art:Image) -> void:
	var colors:={}
	var semi:=0
	var opaque:=0
	var stray:Array=[]
	for y in art.get_height():
		for x in art.get_width():
			var c:=art.get_pixel(x,y)
			if c.a==0:continue
			if c.a<1:semi+=1
			opaque+=1
			colors[c.to_html(false)]=true
			var connected:=false
			for v in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
				var p:Vector2i=Vector2i(x,y)+v
				if Rect2i(Vector2i.ZERO,art.get_size()).has_point(p) and art.get_pixelv(p).a>0:connected=true
			if not connected:stray.append([x,y])
	var metrics:={"canvas":[art.get_width(),art.get_height()],"colors_opaque":colors.size(),"semi_transparent_pixels":semi,"opaque_pixels":opaque,"isolated_opaque_pixels":stray,"character_scale":"1:1 original PNG frames","test":"render de aprovação, não integração de gameplay"}
	var f:=FileAccess.open(OUT+"verificacao.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(metrics,"\t"))
	print(JSON.stringify(metrics))
	quit()
