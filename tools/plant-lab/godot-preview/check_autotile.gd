extends SceneTree
const Terrain=preload("res://terrain.gd")
func _initialize() -> void:
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	var initial := Terrain.Autotile.plan(a)
	var baked_top: Image=initial.top.get_image()
	var baked_faces: Image=initial.faces.get_image()
	var baked_shadow: Image=initial.shadow.get_image()
	Terrain.Autotile.source["autotiling"]=false
	Terrain.Autotile.cached={}
	var live := Terrain.Autotile.plan(a)
	var live_top: Image=live.top.get_image()
	var live_faces: Image=live.faces.get_image()
	var live_shadow: Image=live.shadow.get_image()
	var errors := 0
	var counts := [0,0,0]
	for y: int in range(baked_top.get_height()):
		for x: int in range(baked_top.get_width()):
			if not same(baked_top.get_pixel(x,y),live_top.get_pixel(x,y)) or not same(baked_faces.get_pixel(x,y),live_faces.get_pixel(x,y)) or not same(baked_shadow.get_pixel(x,y),live_shadow.get_pixel(x,y)):
				errors+=1
				if not same(baked_top.get_pixel(x,y),live_top.get_pixel(x,y)):
					counts[0]+=1
				if not same(baked_faces.get_pixel(x,y),live_faces.get_pixel(x,y)):
					counts[1]+=1
				if not same(baked_shadow.get_pixel(x,y),live_shadow.get_pixel(x,y)):
					counts[2]+=1
				if errors<6:
					print(Vector2i(x,y)," T:",baked_top.get_pixel(x,y),"/",live_top.get_pixel(x,y)," F:",baked_faces.get_pixel(x,y),"/",live_faces.get_pixel(x,y)," S:",baked_shadow.get_pixel(x,y),"/",live_shadow.get_pixel(x,y))
	if errors:
		for point: Vector2i in [Vector2i(10,210),Vector2i(100,300),Vector2i(350,500)]:
			print(point, " baked=",baked_top.get_pixelv(point)," live=",live_top.get_pixelv(point))
		print("Diferenças: ",errors," por camada ",counts)
		quit(1)
		return
	assert(Terrain.height_at(a,Vector2(64,96))==0)
	print("PASS: raster Godot dinâmico idêntico às camadas geradas no Studio.")
	quit()


func same(a: Color,b: Color) -> bool:
	return a.a==b.a and (a.a==0 or a==b)
