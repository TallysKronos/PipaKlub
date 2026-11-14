extends "res://tools/laboratorio_v2_revisao.gd"
## Pranchas da loja-piloto a partir dos PNGs originais. A fachada de produção é somente lida.
const STYLE := "res://../art/overworld/estilo/"
const OLD := "res://assets/overworld/kits/bairro-inicial-v2/buildings/shop.png"
const PANEL := Vector2i(430, 366)

func run() -> void:
	OUT = STYLE
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	canvas = Node2D.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	var art := img(OUT + "loja-piloto-v2/loja.png")
	var native := storefront(art, Vector2i(37, 0))
	native.save_png(OUT + "loja-piloto-v2/convivencia-nativa.png")
	var mono := gray(native)
	mono.save_png(OUT + "loja-piloto-v2/convivencia-cinza.png")
	var large := resize2(native)
	var mono2 := gray(large)
	var size := Rect2i(Vector2i.ZERO, PANEL)
	var large_size := Rect2i(Vector2i.ZERO, PANEL * 2)
	content = board(1370, 1620)
	content.blit_rect(native, size, Vector2i(20, 76))
	content.blit_rect(large, large_size, Vector2i(480, 76))
	content.blit_rect(mono, size, Vector2i(20, 870))
	content.blit_rect(mono2, large_size, Vector2i(480, 870))
	labels = [
		[Vector2(20, 49), "LINHA & PAPEL / COR / 1×", 21],
		[Vector2(480, 49), "COR / 2× NEAREST", 21],
		[Vector2(20, 850), "CINZA / 1×", 21],
		[Vector2(480, 850), "CINZA / 2× NEAREST", 21],
		[Vector2(20, 495), "Kael, Rabbito e Lia em escala nativa.", 16],
		[Vector2(20, 520), "A loja tem 340 × 328 px no PNG.", 16],
	]
	await capture("teste-convivencia-loja-v2.png")
	var old := img(OLD)
	# A fachada anterior recebe a mesma largura entre os apoios da revisão.
	var scale_factor := 298.0 / (750.314381 - 40.749164)
	old.resize(roundi(old.get_width() * scale_factor), roundi(old.get_height() * scale_factor), Image.INTERPOLATE_LANCZOS)
	var old_panel := storefront(old, Vector2i(40, 9))
	content = board(PANEL.x * 4 + 60, PANEL.y * 2 + 125)
	content.blit_rect(resize2(old_panel), large_size, Vector2i(20, 70))
	content.blit_rect(large, large_size, Vector2i(PANEL.x * 2 + 40, 70))
	labels = [
		[Vector2(20, 44), "REFERÊNCIA ATUAL / PINTURA REDUZIDA", 24],
		[Vector2(PANEL.x * 2 + 40, 44), "PILOTO / PIXEL ART E PALETA DE CENÁRIO", 24],
		[Vector2(20, PANEL.y * 2 + 102), "Ambas as vistas usam os mesmos pontos de apoio e a mesma régua de personagens / Ampliação 2×", 18],
	]
	await capture("loja-piloto-v2/comparativo.png")
	inspect_palette(art)

func resize2(source: Image) -> Image:
	var large := source.duplicate()
	large.resize(source.get_width() * 2, source.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return large

func storefront(art: Image, at: Vector2i) -> Image:
	var page := board(PANEL.x, PANEL.y)
	page.fill(Color("bdc9be"))
	page.fill_rect(Rect2i(0, 235, PANEL.x, PANEL.y - 235), Color("c8cdd1"))
	page.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), at)
	for point: Vector2i in [Vector2i(88,305), Vector2i(133,326), Vector2i(300,292)]:
		page.fill_rect(Rect2i(point - Vector2i(11,2), Vector2i(22,3)), Color("9da9b5"))
	figure(page, "res://assets/campaign/overworld-animations-v1/rabbito/idle.png", Rect2i(0,0,112,112), Vector2i(88,305), true)
	figure(page, "res://assets/kael-video/iso-v2/idle.png", Rect2i(0,672,64,96), Vector2i(133,326))
	figure(page, "res://assets/npc-ds/lia.png", Rect2i(192,96,64,96), Vector2i(300,292))
	return page

func inspect_palette(art: Image) -> void:
	var allowed := {}
	for filename in ["paleta-cenario.hex", "paleta-mestra.hex"]:
		for line_value in FileAccess.get_file_as_string(OUT + filename).strip_edges().split("\n"):
			allowed[line_value.strip_edges().to_lower()] = true
	var used := {}
	var off_palette := {}
	var partial := 0
	var isolated := 0
	for y in art.get_height():
		for x in art.get_width():
			var color := art.get_pixel(x, y)
			if color.a <= 0:
				continue
			if color.a < 1.0:
				partial += 1
			var hex := color.to_html(false)
			used[hex] = true
			if not allowed.has(hex):
				off_palette[hex] = true
			var at := Vector2i(x, y)
			var connected := false
			for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]:
				var sample: Vector2i = at + offset
				if Rect2i(Vector2i.ZERO,art.get_size()).has_point(sample) and art.get_pixelv(sample).a > 0:
					connected = true
			if not connected:
				isolated += 1
	var report := {
		"canvas":[art.get_width(),art.get_height()],
		"bounds":str(art.get_used_rect()),
		"used_colors":used.size(),
		"out_of_palette":off_palette.keys(),
		"semitransparent_pixels":partial,
		"isolated_opaque_pixels":isolated,
		"foundation_px":[[20,237],[170,312],[318,238]],
		"tile_px":[64,32],
		"scope":"prancha visual de aprovação",
	}
	var file := FileAccess.open(OUT + "loja-piloto-v2/verificacao.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if off_palette.is_empty() and partial == 0 and isolated == 0 else 1)
