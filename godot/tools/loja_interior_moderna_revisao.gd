extends "res://tools/loja_interior_revisao.gd"
## Evidências do quadro moderno antes do recorte de produção.
const MODERN := "res://../art/overworld/estilo/loja-piloto-v2/interior/modernizacao/"

func run() -> void:
	OUT=MODERN
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor=1
	canvas=Node2D.new()
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	var art:=img(OUT+"quadro-chave.png")
	var dimensions:=art.get_size()
	var frame:=Rect2i(Vector2i.ZERO,dimensions)
	var native:=Image.create_empty(dimensions.x,dimensions.y,false,Image.FORMAT_RGBA8)
	native.fill(NAVY)
	native.blend_rect(art,frame,Vector2i.ZERO)
	for feet in [Vector2i(390,520),Vector2i(441,511),Vector2i(841,580)]:
		native.fill_rect(Rect2i(feet-Vector2i(11,2),Vector2i(22,4)),Color("788497"))
	figure(native,"res://assets/campaign/overworld-animations-v1/rabbito/idle.png",Rect2i(0,0,112,112),Vector2i(390,520),true)
	figure(native,"res://assets/kael-video/iso-v2/idle.png",Rect2i(0,672,64,96),Vector2i(441,511))
	figure(native,"res://assets/npc-ds/lia.png",Rect2i(192,96,64,96),Vector2i(841,580))
	native.save_png(OUT+"convivencia-nativa.png")
	var mono:=gray(native)
	mono.save_png(OUT+"convivencia-cinza.png")
	for variant in [["cor",native],["cinza",mono]]:
		var large:Image=variant[1].duplicate()
		large.resize(dimensions.x*2,dimensions.y*2,Image.INTERPOLATE_NEAREST)
		large.save_png(OUT+"convivencia-"+variant[0]+"-2x.png")
	content=board(2300,960)
	content.blend_rect(img(OUT+"../remapeamento/blockout.png"),frame,Vector2i(20,60))
	content.blend_rect(native,frame,Vector2i(1160,60))
	labels=[[Vector2(20,36),"VOLUMES APROVADOS",24],[Vector2(1160,36),"QUADRO MODERNO / PERSONAGENS EM 1×",24],[Vector2(20,920),"Móveis modernos em metal, vidro e detalhes teal. Quadro-chave para aprovação.",20]]
	await capture("comparativo.png")
	content=board(1490,940)
	var crops := [
		["Prateleira modular de linhas",Rect2i(459,170,253,211),Vector2i(20,80)],
		["Expositor de pipas",Rect2i(154,229,155,215),Vector2i(570,80)],
		["Balcão, vitrine e terminal",Rect2i(503,319,250,176),Vector2i(930,80)],
		["Gôndola de materiais",Rect2i(325,351,180,149),Vector2i(20,580)],
		["Mesa digital e banco",Rect2i(553,463,246,164),Vector2i(480,580)],
		["Mesa da comunidade",Rect2i(384,533,247,164),Vector2i(990,580)],
	]
	labels=[]
	for entry in crops:
		var detail:=art.get_region(entry[1])
		detail.resize(detail.get_width()*2,detail.get_height()*2,Image.INTERPOLATE_NEAREST)
		content.blend_rect(detail,Rect2i(Vector2i.ZERO,detail.get_size()),entry[2])
		labels.append([Vector2(entry[2])+Vector2(0,-16),entry[0]+" / 2×",20])
	await capture("prancha-assets.png")
	inspect_art(art)
