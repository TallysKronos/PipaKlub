extends SceneTree
func _initialize() -> void:
	var source := Image.load_from_file("res://../art/characters/bando-do-cerol/rato-idle-oito-direcoes-fonte.png")
	var cell := Vector2i(source.get_width()/4,source.get_height()/2)
	var sheet := Image.create_empty(512,96,false,Image.FORMAT_RGBA8)
	for i in 8:
		var frame := source.get_region(Rect2i(Vector2i(i%4,i/4)*cell,cell))
		frame = frame.get_region(frame.get_used_rect())
		frame.resize(roundi(frame.get_width()*86.0/frame.get_height()),86,Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(i*64+(64-frame.get_width())/2,8))
	quit(sheet.save_png("res://assets/overworld/kits/camara-do-elo-v1/rato-idle-eight.png"))
