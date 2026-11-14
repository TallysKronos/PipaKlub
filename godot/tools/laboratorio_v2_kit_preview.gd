extends "res://tools/laboratorio_v2_revisao.gd"
## Remontagem via 24 Sprite2D/AtlasTexture e contatos do kit, sem mapa de produção.
const KIT:=OUT+"kit/"

func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor=1
	canvas=Node2D.new()
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(KIT+"manifesto.json"))
	var atlas_image:=img(KIT+"atlas.png")
	var atlas_texture:=ImageTexture.create_from_image(atlas_image)
	var source:=img(OUT+"quadro-chave.png")
	var reconstructed:=Image.create(768,576,false,Image.FORMAT_RGBA8)
	var nodes:=Node2D.new()
	nodes.position=Vector2(860,110)
	canvas.add_child(nodes)
	for part in data.parts:
		var r:Array=part.atlas_rect
		var rect:=Rect2i(r[0],r[1],r[2],r[3])
		var atlas_part:=atlas_image.get_region(rect)
		var png:=img(KIT+part.file)
		if not check(atlas_part.get_data()==png.get_data(),"Atlas não coincide com PNG: "+part.id):return
		var pos:=Vector2i(part.position_px[0],part.position_px[1])
		var pivot:=Vector2i(part.pivot_px[0],part.pivot_px[1])
		reconstructed.blend_rect(atlas_part,Rect2i(Vector2i.ZERO,atlas_part.get_size()),pos-pivot)
		# Borda de 2px totalmente vazia em torno de cada região.
		for y in range(rect.position.y-2,rect.end.y+2):
			for x in range(rect.position.x-2,rect.end.x+2):
				if not rect.has_point(Vector2i(x,y)) and not check(atlas_image.get_pixel(x,y).a==0,"Sangramento no atlas" ):return
		var region:=AtlasTexture.new()
		region.atlas=atlas_texture
		region.region=rect
		region.filter_clip=true
		var sprite:=Sprite2D.new()
		sprite.name=part.id
		sprite.texture=region
		sprite.centered=false
		sprite.offset=-Vector2(pivot)
		sprite.position=Vector2(pos)
		sprite.z_index=part.draw_order
		nodes.add_child(sprite)
	if not check(source.get_data()==reconstructed.get_data(),"Atlas/pivôs não reproduzem o quadro-chave"):return
	content=board(1680,760)
	content.blend_rect(source,Rect2i(0,0,768,576),Vector2i(20,110))
	labels=[[Vector2(20,45),"QUADRO-CHAVE APROVADO / 1×",22],[Vector2(860,45),"24 PEÇAS + ATLAS + PIVÔS / 1×",22],[Vector2(20,735),"Remontagem sem diferença de pixels. Encaixe no bairro e colisões: etapa 4.",20]]
	await capture("kit/remontagem-godot.png")
	nodes.hide()
	content=board(1600,1800)
	labels=[[Vector2(20,40),"LABORATÓRIO V2 / KIT DE MONTAGEM FIXA / RECORTES VISÍVEIS",24]]
	var cursor:=Vector2i(20,90)
	var row_height:=0
	for part in data.parts:
		var png:=img(KIT+part.file)
		var slot_width:=maxi(220,png.get_width()+24)
		if cursor.x+slot_width>1580:
			cursor=Vector2i(20,cursor.y+row_height+58)
			row_height=0
		if not check(cursor.y+png.get_height()<1760,"Prancha excedida"):return
		content.blend_rect(png,Rect2i(Vector2i.ZERO,png.get_size()),cursor)
		labels.append([Vector2(cursor.x,cursor.y-12),part.id,17])
		cursor.x+=slot_width
		row_height=maxi(row_height,png.get_height())
	await capture("kit/prancha-pecas.png")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(KIT+"verificacao.json"))
	proof.atlas_matches_individual_pngs=true
	proof.atlas_and_pivots_reconstruct_exactly=true
	proof.transparent_padding_verified=true
	proof.godot_sprite_nodes=nodes.get_child_count()
	if FileAccess.file_exists(KIT+"remontagem-aseprite.png"):
		var aseprite_output:=img(KIT+"remontagem-aseprite.png")
		proof.aseprite_layers_reconstruct_exactly=source.get_data()==aseprite_output.get_data()
		if not check(proof.aseprite_layers_reconstruct_exactly,"Camadas Aseprite não reproduzem a fonte"):return
	var f:=FileAccess.open(KIT+"verificacao.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(proof,"\t"))
	print(JSON.stringify(proof))
	quit()

func check(condition:bool,message:String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition
