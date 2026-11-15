extends "res://tools/laboratorio_v2_revisao.gd"
## Conferência do recorte, sem substituir o cenário ou abrir saves.
const DIR := "res://../art/casa-kael-v2/fachada/"

func run() -> void:
	var kit:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"kit/kit.json"))
	var target:=img(DIR+"kit-remontado.png")
	var assembled:=Image.create_empty(654,601,false,Image.FORMAT_RGBA8)
	var occupancy:=PackedByteArray()
	occupancy.resize(654*601)
	var overlap:=0
	for part in kit.parts:
		var piece:=img(DIR+"kit/"+str(part.file))
		assert(piece.get_size()==Vector2i(654,601))
		for y in 601:
			for x in 654:
				if piece.get_pixel(x,y).a<.5:continue
				var i:=y*654+x
				if occupancy[i]>0:overlap+=1
				occupancy[i]=1
		assembled.blend_rect(piece,Rect2i(0,0,654,601),Vector2i.ZERO)
	var mismatch:=0
	var partial_alpha:=0
	var colors:Dictionary={}
	for y in 601:
		for x in 654:
			var a:=assembled.get_pixel(x,y)
			if a!=target.get_pixel(x,y):mismatch+=1
			if a.a>0 and a.a<1:partial_alpha+=1
			if a.a>0:colors[a.to_html(false)]=true
	var report:={"canvas":[654,601],"parts":kit.parts.size(),"overlapping_pixels":overlap,"reassembly_mismatches":mismatch,"partial_alpha_pixels":partial_alpha,"opaque_colors":colors.size(),"native_scale":1,"runtime_integrated":false,"note":"verificação de recorte; calibração dos acessos e colisões ainda pendente"}
	FileAccess.open(DIR+"kit/qa.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	assert(overlap==0 and mismatch==0 and partial_alpha==0)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	canvas=Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(draw)
	OUT=DIR
	content=board(1370,740)
	content.fill_rect(Rect2i(700,0,670,740),Color("142030"))
	content.fill_rect(Rect2i(700,0,670,50),Color("e8edf0"))
	content.fill_rect(Rect2i(0,680,1370,60),Color("e8edf0"))
	content.blend_rect(assembled,Rect2i(0,0,654,601),Vector2i(10,60))
	content.blend_rect(assembled,Rect2i(0,0,654,601),Vector2i(710,60))
	for offset in [Vector2i(0,0),Vector2i(700,0)]:
		figure(content,"res://assets/kael-video/iso-v2/idle.png",Rect2i(0,672,64,96),Vector2i(231,546)+offset)
	labels=[[Vector2(20,30),"KIT EM 1× / KAEL 70 PX / FUNDO CLARO",21],[Vector2(720,30),"MESMOS PIXELS / FUNDO ESCURO",21],[Vector2(20,710),"7 recortes · 45 cores · alpha binário · calibração dos acessos ainda pendente",22]]
	await capture("kit-convivencia.png")
	content=board(1600,900)
	for index in kit.parts.size():
		var part:Dictionary=kit.parts[index]
		var piece:=img(DIR+"kit/"+str(part.file))
		var crop:=piece.get_region(piece.get_used_rect())
		var factor:=minf(1.0,minf(360.0/crop.get_width(),330.0/crop.get_height()))
		crop.resize(maxi(1,int(crop.get_width()*factor)),maxi(1,int(crop.get_height()*factor)),Image.INTERPOLATE_NEAREST)
		var at:=Vector2i(20+(index%4)*395,70+(index/4)*420)
		content.blend_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),at)
		labels.append([Vector2(at.x,at.y+350),part.id,20])
	labels=labels.slice(3)
	await capture("kit-contato.png")
	print(JSON.stringify(report))
	quit()
