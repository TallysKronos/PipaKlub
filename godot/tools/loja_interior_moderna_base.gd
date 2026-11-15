extends "res://tools/loja_interior_base.gd"
## Normaliza o estudo moderno à densidade e à paleta do bairro.
const MODERN := "res://../art/overworld/estilo/loja-piloto-v2/interior/modernizacao/"

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(MODERN+"fontes/estudo-imagegen.png"))
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var color := source.get_pixel(x,y)
			source.set_pixel(x,y,Color(color.r,color.g,color.b,1) if color.a>=ALPHA else Color.TRANSPARENT)
	remove_edge_specks(source)
	var bounds := source.get_used_rect()
	var crop := source.get_region(bounds)
	var height := roundi(bounds.size.y * 1024.0 / bounds.size.x)
	crop.resize(1024,height,Image.INTERPOLATE_NEAREST)
	var colors: Array[Color] = []
	for palette_path in ["res://../art/overworld/estilo/paleta-mestra.hex","res://../art/overworld/estilo/paleta-cenario.hex"]:
		for hex in FileAccess.get_file_as_string(palette_path).strip_edges().split("\n"):
			colors.append(Color(hex.strip_edges()))
	var result := Image.create_empty(1120,820,false,Image.FORMAT_RGBA8)
	var anchor := Vector2i(48,roundi((820-height)*.5))
	var cache := {}
	for y in crop.get_height():
		for x in crop.get_width():
			var color := crop.get_pixel(x,y)
			if color.a==0:
				continue
			var key := color.to_rgba32()
			if not cache.has(key):
				cache[key]=nearest_color(color,colors)
			result.set_pixelv(anchor+Vector2i(x,y),cache[key])
	remove_edge_specks(result)
	result.save_png(MODERN+"fontes/base-nativa.png")
	print("Loja moderna: ",result.get_used_rect(),"; base salva para acabamento no Aseprite.")
	quit()
