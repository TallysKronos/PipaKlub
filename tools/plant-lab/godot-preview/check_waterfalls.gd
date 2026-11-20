extends SceneTree
const Falls=preload("res://waterfalls.gd")
const Terrain=preload("res://autotile.gd")
func _initialize() -> void:
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	var r := Terrain.plan(a)
	var atlas: Image=(load("res://assets/waterfall-atlas.png") as Texture2D).get_image()
	for phase: int in range(4):
		var image := Image.create(r.width,r.height,false,Image.FORMAT_RGBA8)
		for o: Dictionary in a.objects:
			if not Falls.WIDTHS.has(o.asset):
				continue
			var frame := Falls.render(a,Vector2(o.x,o.y),o.asset,atlas,phase)
			assert(not frame.is_empty())
			for y: int in range(frame.height):
				for x: int in range(frame.width):
					var c: Color=frame.image.get_pixel(x,y)
					if c.a>0:
						image.set_pixel(frame.x+x,frame.y+y+Terrain.PAD,c)
		var expected: Image=Image.load_from_file("res://autotile/waterfall-phase-%s.png" % phase)
		if image.get_data()!=expected.get_data():
			var count := 0
			for y: int in range(image.get_height()):
				for x: int in range(image.get_width()):
					if image.get_pixel(x,y)!=expected.get_pixel(x,y):
						if count<8:
							print(Vector2i(x,y)," native=",image.get_pixel(x,y)," expected=",expected.get_pixel(x,y))
						count+=1
			print("Different pixels: ",count," formats: ",image.get_format(),"/",expected.get_format())
			push_error("Waterfall phase differs: %s" % phase)
			quit(1)
			return
	print("PASS: four waterfall phases match Studio pixels exactly.")
	quit()
