extends SceneTree
func _initialize() -> void:
	var image := Image.load_from_file("res://../art/overworld/estadio/lobby-moveis-fonte.png")
	var folder := "res://assets/overworld/kits/estadio-lobby-v2/"
	DirAccess.make_dir_recursive_absolute(folder)
	var names := ["bancos","poltrona","mesa","balcao","expositor","bebedouro","jardineira","painel"]
	for i in names.size():
		var size := image.get_size()
		var x := i % 4
		var y := floori(i / 4.0)
		var start := Vector2i(x * size.x / 4, y * size.y / 2)
		var end := Vector2i((x+1) * size.x / 4, (y+1) * size.y / 2)
		var tile := image.get_region(Rect2i(start+Vector2i(7,7),end-start-Vector2i(14,14)))
		_clear_background(tile)
		tile.get_region(tile.get_used_rect()).save_png(folder+names[i]+".png")
	quit()

func _clear_background(tile: Image) -> void:
	tile.convert(Image.FORMAT_RGBA8)
	var size := tile.get_size()
	var pending: Array[Vector2i] = [Vector2i.ZERO]
	var seen := {}
	while not pending.is_empty():
		var p: Vector2i = pending.pop_back()
		if not Rect2i(Vector2i.ZERO,size).has_point(p) or seen.has(p):
			continue
		seen[p] = true
		var c := tile.get_pixelv(p)
		if c.a > .01 and (minf(c.r,minf(c.g,c.b)) < .84 or maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b)) > .10):
			continue
		tile.set_pixelv(p,Color.TRANSPARENT)
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			pending.append(p+direction)

