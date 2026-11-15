extends "res://tools/laboratorio_v2_revisao.gd"
## Pranchas de aprovação para o interior da Linha & Papel.
const STYLE := "res://../art/overworld/estilo/"
const STORE := "loja-piloto-v2/interior/"
const OLD := "res://assets/campaign/loja-tcg-v1/preview.png"
const NAVY := Color("172536")

func run() -> void:
	OUT = STYLE + STORE
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	canvas = Node2D.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(canvas)
	canvas.draw.connect(draw)
	var art := img(OUT + "quadro-chave.png")
	var dimensions := art.get_size()
	var frame := Rect2i(Vector2i.ZERO, dimensions)
	var native := Image.create_empty(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	native.fill(NAVY)
	native.blend_rect(art, frame, Vector2i.ZERO)
	var partner_at := Vector2i(304, 433)
	var kael_at := Vector2i(367, 430)
	var npc_at := Vector2i(712, 421)
	for feet: Vector2i in [partner_at, kael_at, npc_at]:
		native.fill_rect(Rect2i(feet - Vector2i(12, 3), Vector2i(24, 5)), Color("ab918b"))
	figure(native, "res://assets/campaign/overworld-animations-v1/rabbito/idle.png", Rect2i(0,0,112,112), partner_at, true)
	figure(native, "res://assets/kael-video/iso-v2/idle.png", Rect2i(0,672,64,96), kael_at)
	figure(native, "res://assets/npc-ds/lia.png", Rect2i(192,96,64,96), npc_at)
	native.save_png(OUT + "convivencia-nativa.png")
	var mono := gray(native)
	mono.save_png(OUT + "convivencia-cinza.png")
	for variant in [["cor", native], ["cinza", mono]]:
		var large: Image = variant[1].duplicate()
		large.resize(dimensions.x * 2, dimensions.y * 2, Image.INTERPOLATE_NEAREST)
		large.save_png(OUT + "convivencia-" + variant[0] + "-2x.png")
	content = board(dimensions.x * 2 + 60, dimensions.y + 128)
	var original := img(OLD).get_region(Rect2i(107, 20, dimensions.x, dimensions.y))
	content.blit_rect(original, frame, Vector2i(20, 74))
	content.blit_rect(native, frame, Vector2i(dimensions.x + 40, 74))
	labels = [
		[Vector2(20, 48), "LINHA & PAPEL / INTERIOR ATUAL", 24],
		[Vector2(dimensions.x + 40, 48), "QUADRO-CHAVE / KAEL, RABBITO E LIA EM 1×", 24],
		[Vector2(20, dimensions.y + 107), "A entrada, o caixa e as duas mesas dão referência ao percurso. Prancha de aprovação de arte.", 18],
	]
	await capture("comparativo.png")
	inspect_art(art)

func inspect_art(art: Image) -> void:
	var allowed: Dictionary = {}
	for file in ["paleta-cenario.hex", "paleta-mestra.hex"]:
		for hex in FileAccess.get_file_as_string(STYLE + file).strip_edges().split("\n"):
			allowed[hex.strip_edges().to_lower()] = true
	var used: Dictionary = {}
	var off_palette: Dictionary = {}
	var partial := 0
	var visible := 0
	var data := art.get_data()
	var isolated := 0
	var width := art.get_width()
	var height := art.get_height()
	for y in height:
		for x in width:
			var pixel := (y * width + x) * 4
			var alpha := data[pixel + 3]
			if alpha == 0:
				continue
			visible += 1
			if alpha < 255:
				partial += 1
			var code := "%02x%02x%02x" % [data[pixel], data[pixel + 1], data[pixel + 2]]
			used[code] = true
			if not allowed.has(code):
				off_palette[code] = true
			var at := Vector2i(x, y)
			var has_neighbor := false
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = at + step
				if next.x >= 0 and next.y >= 0 and next.x < width and next.y < height and data[(next.y * width + next.x) * 4 + 3] > 0:
					has_neighbor = true
					break
			if not has_neighbor:
				isolated += 1
	var report := {
		"canvas": [width, height],
		"bounds": str(art.get_used_rect()),
		"colors_used": used.size(),
		"opaque_pixels": visible,
		"semi_transparent_pixels": partial,
		"isolated_opaque_pixels": isolated,
		"off_palette": off_palette.keys(),
		"scope": "quadro-chave; prova visual 1×/2×",
	}
	var file := FileAccess.open(OUT + "verificacao.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if off_palette.is_empty() and partial == 0 and isolated == 0 else 1)
