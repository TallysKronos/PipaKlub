extends SceneTree
## Base para pintura no Aseprite. Executar antes da pintura; nunca sobrescreve o quadro.
const DIR := "res://../art/professor-laboratorio-v2/interior/"
const SOURCE := "fontes/geracao-03-maleta.png"
const PALETTE := "../fachada/paleta-fachada.hex"
const SIZE := Vector2i(720, 512)
const WIDTH := 660

func _initialize() -> void:
	var art := Image.load_from_file(ProjectSettings.globalize_path(DIR + SOURCE))
	if art == null:
		quit(1)
		return
	art.convert(Image.FORMAT_RGBA8)
	var bounds := Rect2i()
	for y in art.get_height():
		for x in art.get_width():
			if art.get_pixel(x, y).a >= .90:
				var pixel := Rect2i(x, y, 1, 1)
				bounds = bounds.merge(pixel) if bounds.has_area() else pixel
	var factor := float(WIDTH) / bounds.size.x
	var height := roundi(bounds.size.y * factor * .956)
	var palette: Array[Color] = []
	for hex in FileAccess.get_file_as_string(DIR + PALETTE).strip_edges().split("\n"):
		palette.append(Color(hex.strip_edges()))
	var result := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	var origin := (SIZE - Vector2i(WIDTH, height)) / 2
	var cache := {}
	for y in height:
		for x in WIDTH:
			var sx := bounds.position.x + floori((x + .5) / factor)
			var sy := bounds.position.y + floori((y + .5) / (factor * .956))
			var color := art.get_pixel(sx, sy)
			if color.a < .90:
				continue
			var key := color.to_rgba32()
			if not cache.has(key):
				cache[key] = closest(color, palette)
			result.set_pixelv(origin + Vector2i(x, y), cache[key])
	var points := result.get_used_rect()
	for y in range(points.position.y, points.end.y):
		for x in range(points.position.x, points.end.x):
			var spot := Vector2i(x, y)
			if result.get_pixelv(spot).a == 0:
				continue
			var neighbors := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			if not neighbors.any(func(offset): return result.get_pixelv(spot + offset).a > 0):
				result.set_pixelv(spot, Color.TRANSPARENT)
	var status := result.save_png(ProjectSettings.globalize_path(DIR + "fontes/base-nativa-para-aseprite.png"))
	print("Base nativa ", result.get_used_rect(), ", exportação ", status)
	quit(status)

func closest(color: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var distance := INF
	for candidate in palette:
		var delta := Vector3(color.r - candidate.r, color.g - candidate.g, color.b - candidate.b)
		var score := delta.length_squared()
		if score < distance:
			distance = score
			best = candidate
	return best
