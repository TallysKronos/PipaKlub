extends SceneTree
## Prepara a fonte ImageGen para retoque na grade nativa do Aseprite.
const DIR := "res://../art/overworld/estilo/loja-piloto-v2/interior/"
const NATIVE_WIDTH := 924
const CANVAS := Vector2i(976, 680)
const ALPHA := .94
const MOVES := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(DIR + "fontes/estudo-imagegen.png"))
	if source == null:
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var bounds := Rect2i()
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x, y).a < ALPHA:
				continue
			var pixel := Rect2i(x, y, 1, 1)
			bounds = bounds.merge(pixel) if bounds.has_area() else pixel
	if not bounds.has_area():
		quit(1)
		return
	var crop := source.get_region(bounds)
	var height := roundi(bounds.size.y * float(NATIVE_WIDTH) / bounds.size.x)
	crop.resize(NATIVE_WIDTH, height, Image.INTERPOLATE_NEAREST)
	var palette: Array[Color] = []
	for list_path in ["../../paleta-cenario.hex", "../../paleta-mestra.hex"]:
		for hex in FileAccess.get_file_as_string(DIR + list_path).strip_edges().split("\n"):
			palette.append(Color(hex.strip_edges()))
	var output := Image.create_empty(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var anchor := (CANVAS - Vector2i(NATIVE_WIDTH, height)) / 2
	var cache := {}
	for y in crop.get_height():
		for x in crop.get_width():
			var color := crop.get_pixel(x, y)
			if color.a < ALPHA:
				continue
			var key := color.to_rgba32()
			if not cache.has(key):
				cache[key] = nearest_color(color, palette)
			output.set_pixelv(anchor + Vector2i(x, y), cache[key])
	remove_edge_specks(output)
	var error := output.save_png(DIR + "fontes/base-nativa.png")
	print("Loja interior · quadro ", CANVAS, " · tinta ", output.get_used_rect())
	quit(error)

func nearest_color(color: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var score := INF
	for candidate in palette:
		var delta := Vector3(color.r-candidate.r, color.g-candidate.g, color.b-candidate.b)
		var distance := delta.length_squared()
		if distance < score:
			score = distance
			best = candidate
	return best

func remove_edge_specks(art: Image) -> void:
	var bounds := art.get_used_rect()
	var visited := PackedByteArray()
	visited.resize(art.get_width() * art.get_height())
	var main: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var start := Vector2i(x, y)
			var id := y * art.get_width() + x
			if visited[id] or art.get_pixelv(start).a == 0:
				continue
			visited[id] = 1
			var group: Array[Vector2i] = [start]
			var head := 0
			while head < group.size():
				var at := group[head]
				head += 1
				for offset in MOVES:
					var next: Vector2i = at + offset
					if not bounds.has_point(next):
						continue
					var index := next.y * art.get_width() + next.x
					if visited[index] or art.get_pixelv(next).a == 0:
						continue
					visited[index] = 1
					group.append(next)
			if group.size() > main.size():
				main = group
	# Todo o interior, incluindo o capacho, faz parte da mesma silhueta.
	for point in main:
		visited[point.y * art.get_width() + point.x] = 2
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			if visited[y * art.get_width() + x] == 1:
				art.set_pixel(x, y, Color.TRANSPARENT)
