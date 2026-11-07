extends SceneTree
const Trees=preload("res://trees.gd")
func _initialize() -> void:
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	var expected: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tree-regions.json"))
	for entry: Dictionary in expected:
		var p := Vector2(float(entry.x),float(entry.y))
		var r := Trees.region(a,p)
		if Trees.mask(a,p)!=int(entry.mask) or r.position!=Vector2(float(entry.region.x),float(entry.region.y)):
			print("FAIL: encaixe Godot diferente do Studio em ",p)
			quit(1)
			return
	print("PASS árvores Godot: máscaras e recortes iguais ao Studio.")
	quit()
