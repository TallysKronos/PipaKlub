extends SceneTree
## Deterministic runtime-size normalization; source ImageGen PNG remains untouched.
func _initialize() -> void:
	var image: Image=load("res://assets/illustrated/tree-test/tree.png").get_image()
	var bounds:=image.get_used_rect()
	var factor:=216.0/bounds.size.x
	image.fix_alpha_edges()
	image.resize(roundi(image.get_width()*factor),roundi(image.get_height()*factor),Image.INTERPOLATE_LANCZOS)
	var result:=image.save_png("res://assets/illustrated/tree-test/tree-game.png")
	print("TREE_NORMALIZED ",image.get_size()," bounds=",image.get_used_rect())
	quit(result)
