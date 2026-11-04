extends SceneTree
func _initialize() -> void:
	var source := Image.load_from_file("res://../art/overworld/camara-do-elo/enamor-despertar-fonte.png")
	var size := Vector2i(443,443)
	var atlas := Image.create_empty(1772,886,false,Image.FORMAT_RGBA8)
	source.convert(Image.FORMAT_RGBA8)
	for i in 8:
		var origin := Vector2i(i%4,floori(i/4.0))*size
		var frame := source.get_region(Rect2i(origin,size))
		if frame.get_pixel(0,0).a>.05 or frame.get_used_rect().size.x<300:
			printerr("Invalid Enamor frame ",i)
			quit(1)
			return
		atlas.blit_rect(frame,Rect2i(Vector2i.ZERO,size),origin)
	quit(atlas.save_png("res://assets/overworld/kits/camara-do-elo-v1/enamor-despertar.png"))
