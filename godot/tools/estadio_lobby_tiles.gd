extends SceneTree
func _initialize() -> void:
	var image := Image.load_from_file("res://../art/overworld/estadio/lobby-tiles-fonte.png")
	var folder := "res://assets/overworld/kits/estadio-lobby-v1/"
	DirAccess.make_dir_recursive_absolute(folder)
	var names := ["terrazzo","passadeira","balcao","tunel","bancos","painel","jardineira","parede"]
	for i in names.size():
		var size := image.get_size()
		var x := i % 4
		var y := floori(i / 4.0)
		var start := Vector2i(x * size.x / 4, y * size.y / 2)
		var end := Vector2i((x+1) * size.x / 4, (y+1) * size.y / 2)
		var tile := image.get_region(Rect2i(start,end-start))
		tile.get_region(tile.get_used_rect()).save_png(folder+names[i]+".png")
	quit()
