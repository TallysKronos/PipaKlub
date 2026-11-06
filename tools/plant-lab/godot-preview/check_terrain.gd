extends SceneTree
const Terrain = preload("res://terrain.gd")
func _initialize() -> void:
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	assert(Terrain.face(a,4*24+5).size==Vector2.ZERO)
	var p:=Terrain.move(a,Vector2(176,280),Vector2(0,-170))
	assert(p.y==110 and Terrain.height_at(a,p)==2)
	p=Terrain.move(a,p,Vector2(0,170))
	assert(p.y==280)
	assert(Terrain.move(a,Vector2(144,280),Vector2(0,-100)).y>=220)
	for y: float in [224.01,239.0,255.99]:
		var root:=Vector2(176,y)
		assert(Terrain.surface(a,Terrain.project(a,root)).distance_to(root)<0.02)
	print("PASS Godot: rampas, bloqueio de barrancos e picking.")
	quit()

