extends "res://tools/laboratorio_v2_revisao.gd"
## Remontagem via Sprite2D/AtlasTexture e prancha de recortes.

func run() -> void:
	var title := "LABORATÓRIO V2"
	var args := OS.get_cmdline_user_args()
	if "--loja-interior" in args:
		OUT = "res://../art/overworld/estilo/loja-piloto-v2/interior/"
		title = "LINHA & PAPEL"
	elif "--interior" in args:
		OUT = "res://../art/professor-laboratorio-v2/interior/"
	var kit := OUT + "kit/"
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor=1
	canvas=Node2D.new()
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(kit+"manifesto.json"))
	var atlas_image:=img(kit+"atlas.png")
	var atlas_texture:=ImageTexture.create_from_image(atlas_image)
	var source:=img(OUT+"quadro-chave.png")
	# O quadro pode conservar RGB sob alfa zero. Compare somente a arte visível.
	var source_pixels := source.get_data()
	for i in range(0, source_pixels.size(), 4):
		if source_pixels[i + 3] == 0:
			source_pixels[i] = 0
			source_pixels[i + 1] = 0
			source_pixels[i + 2] = 0
	var source_size := source.get_size()
	var reconstructed := Image.create(source_size.x, source_size.y, false, Image.FORMAT_RGBA8)
	var nodes:=Node2D.new()
	var render_at := Vector2i(source_size.x + 70, 90)
	nodes.position = Vector2(render_at)
	canvas.add_child(nodes)
	for part in data.parts:
		var r:Array=part.atlas_rect
		var rect:=Rect2i(r[0],r[1],r[2],r[3])
		var atlas_part:=atlas_image.get_region(rect)
		var png:=img(kit+part.file)
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
	if not check(source_pixels==reconstructed.get_data(),"Atlas/pivôs não reproduzem o quadro-chave"):return
	content = board(source_size.x * 2 + 90, source_size.y + 150)
	var reference_at := Vector2i(20, 90)
	var full_rect := Rect2i(Vector2i.ZERO, source_size)
	content.blend_rect(source, full_rect, reference_at)
	labels = [
		[Vector2(20, 45), "QUADRO-CHAVE APROVADO / 1×", 22],
		[Vector2(render_at.x, 45), "%s PEÇAS + ATLAS + PIVÔS / 1×" % data.parts.size(), 22],
		[Vector2(20, source_size.y + 128), "Remontagem no Godot. Encaixe, oclusão e colisões na cena pertencem à integração.", 19],
	]
	await capture("kit/remontagem-godot.png")
	var rendered := img(kit + "remontagem-godot.png")
	var renders_match := rendered.get_region(Rect2i(reference_at, source_size)).get_data() == rendered.get_region(Rect2i(render_at, source_size)).get_data()
	if not check(renders_match, "Sprite2D renderizado difere da referência na captura"):return
	nodes.hide()
	content=board(1600,1800)
	labels=[[Vector2(20,40),title+" / KIT DE MONTAGEM FIXA / RECORTES VISÍVEIS",24]]
	var cursor:=Vector2i(20,90)
	var row_height:=0
	for part in data.parts:
		var png:=img(kit+part.file)
		var slot_width:=maxi(220,png.get_width()+24)
		if cursor.x+slot_width>1580:
			cursor=Vector2i(20,cursor.y+row_height+58)
			row_height=0
		if not check(cursor.y+png.get_height()<1760,"Prancha excedida"):return
		content.blend_rect(png,Rect2i(Vector2i.ZERO,png.get_size()),cursor)
		labels.append([Vector2(cursor.x,cursor.y-12),part.id,17])
		cursor.x+=slot_width
		row_height=maxi(row_height,png.get_height())
	content = content.get_region(Rect2i(0, 0, content.get_width(), cursor.y + row_height + 30))
	await capture("kit/prancha-pecas.png")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(kit+"verificacao.json"))
	proof.atlas_matches_individual_pngs=true
	proof.atlas_and_pivots_reconstruct_exactly=true
	proof.transparent_padding_verified=true
	proof.godot_sprite_nodes=nodes.get_child_count()
	proof.godot_render_matches_reference=renders_match
	if FileAccess.file_exists(kit+"remontagem-aseprite.png"):
		var aseprite_output:=img(kit+"remontagem-aseprite.png")
		proof.aseprite_layers_reconstruct_exactly=source_pixels==aseprite_output.get_data()
		if not check(proof.aseprite_layers_reconstruct_exactly,"Camadas Aseprite não reproduzem a fonte"):return
	var f:=FileAccess.open(kit+"verificacao.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(proof,"\t"))
	print(JSON.stringify(proof))
	quit()

func check(condition:bool,message:String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition
