extends SceneTree
## Cartela importável com o mesmo índice dos arquivos HEX e GPL.
const DIR := "res://../art/overworld/estilo/"

func _initialize() -> void:
	var colors := FileAccess.get_file_as_string(DIR + "paleta-cenario.hex").strip_edges().split("\n")
	if colors.size() != 40:
		push_error("A extensão deve ter oito rampas de cinco tons.")
		quit(1)
		return
	# Leitura em ordem de índice, da esquerda para a direita e de cima para baixo.
	var swatches := Image.create_empty(5 * 32, 8 * 32, false, Image.FORMAT_RGB8)
	for i in range(colors.size()):
		var pos := Vector2i(i % 5, i / 5) * 32
		swatches.fill_rect(Rect2i(pos, Vector2i(32, 32)), Color(colors[i].strip_edges()))
	var error := swatches.save_png(DIR + "paleta-cenario.png")
	quit(error)
