extends SceneTree
func _initialize() -> void:
	_export("res://../art/overworld/camara-do-elo/elenco-fonte.png",["rato","capanga","mikka","jamile"])
	_export("res://../art/characters/bando-do-cerol/overworld-fonte.png",["rato","capanga-feminina","capanga-masculino"])
	quit()

func _export(source: String, names: Array) -> void:
	var sheet := Image.load_from_file(source)

	var kit := "res://assets/overworld/kits/camara-do-elo-v1/"
	for column in names.size():
		for row in 3:
			var cell := Vector2i(sheet.get_width()/names.size(),sheet.get_height()/3)
			var frame := sheet.get_region(Rect2i(Vector2i(column,row)*cell,cell))
			frame = frame.get_region(frame.get_used_rect())
			var height: int = {"rato":86,"capanga-feminina":81,"capanga-masculino":80,"mikka":80,"jamile":84}.get(names[column],82)
			var factor := float(height)/frame.get_height()
			frame.resize(roundi(frame.get_width()*factor),height,Image.INTERPOLATE_LANCZOS)
			var result := Image.create_empty(64,96,false,Image.FORMAT_RGBA8)
			result.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i((64-frame.get_width())/2,94-height))
			if result.save_png(kit+names[column]+"-"+str(row)+".png")!=OK:
				quit(1)
				return
