extends SceneTree
func _initialize() -> void:
	for name in ["capanga-feminina","capanga-masculino"]:
		var source := Image.load_from_file("res://../art/characters/bando-do-cerol/"+name+"-idle-oito-direcoes-fonte.png")
		var cell := Vector2i(source.get_width()/4,source.get_height()/2)
		var sheet := Image.create_empty(512,96,false,Image.FORMAT_RGBA8)
		var height := 81 if name=="capanga-feminina" else 80
		for i in 8:
			var frame := source.get_region(Rect2i(Vector2i(i%4,i/4)*cell,cell))
			frame = frame.get_region(frame.get_used_rect())
			frame.resize(roundi(frame.get_width()*float(height)/frame.get_height()),height,Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(i*64+(64-frame.get_width())/2,94-height))
		if sheet.save_png("res://assets/overworld/kits/camara-do-elo-v1/"+name+"-idle-eight.png")!=OK:
			quit(1)
			return
	quit()
