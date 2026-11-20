extends SceneTree
const Terrain=preload("res://terrain.gd")
func _initialize() -> void:
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	var p := Vector2(float(a.player.x),float(a.player.y))
	var stopped := Terrain.move(a,p,Vector2(0,-350))
	if Terrain.Autotile.water_at(a,stopped) or stopped.y<200:
		print("FAIL: margem não bloqueou Kael")
		quit(1)
		return
	var first := Terrain.Autotile.ripple_points(a,0)
	var second := Terrain.Autotile.ripple_points(a,1)
	if first==second or first.size()<100:
		print("FAIL: fases da água")
		quit(1)
		return
	for point: Vector2 in first:
		if not Terrain.Autotile.water_at(a,point):
			quit(1)
			return
	print("PASS Godot: água bloqueia entrada; ondulações animadas permanecem no lago.")
	quit()
