extends SceneTree
func _initialize() -> void:
	var image := Image.load_from_file("res://../art/overworld/estadio/estadio-tiles-fonte.png")
	var folder := "res://assets/overworld/kits/estadio-v1/"
	DirAccess.make_dir_recursive_absolute(folder)
	var names := ["praca","arena","pista","parede","escada","arquibancada","arquibancada-ponta","grade","portal","placar","jardineira","bandeira"]
	for i in names.size():
		var x := i % 4
		var y := floori(i / 4.0)
		var start := Vector2i(x * image.get_width() / 4, y * image.get_height() / 3)
		var end := Vector2i((x+1) * image.get_width() / 4, (y+1) * image.get_height() / 3)
		var tile := image.get_region(Rect2i(start,end-start))
		var used := tile.get_used_rect()
		tile.get_region(used).save_png(folder+names[i]+".png")
	quit()
