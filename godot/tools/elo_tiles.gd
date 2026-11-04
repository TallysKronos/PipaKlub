extends SceneTree
func _initialize() -> void:
	for asset in ["pilar","carretel","fragmentos"]:
		var source := Image.load_from_file("res://../art/overworld/camara-do-elo/"+asset+"-fonte.png")
		var cutout := source.get_region(source.get_used_rect())
		cutout.resize(256,roundi(256.0*cutout.get_height()/cutout.get_width()),Image.INTERPOLATE_LANCZOS)
		if cutout.save_png("res://assets/overworld/kits/camara-do-elo-v1/"+asset+".png")!=OK:
			quit(1)
			return
	quit()
