extends SceneTree
## Edge masks: 1=-X, 2=+X, 4=-Y, 8=+Y. Original illustrations only.
func _init() -> void:
	var source: Image=load("res://assets/terrain.png").get_image()
	if "--paint" not in OS.get_cmdline_user_args():
		var image:=Image.create(2048,256,false,Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for variant in range(4):
			for mask in range(16):
				for y in range(64):
					for x in range(128):
						var u:=((x+.5-64)/64.0+(y+.5)/32.0)/2.0
						var v:=((y+.5)/32.0-(x+.5-64)/64.0)/2.0
						if u<0 or u>=1 or v<0 or v>=1:
							continue
						var distance:=1.0
						if mask&1: distance=minf(distance,u)
						if mask&2: distance=minf(distance,1-u)
						if mask&4: distance=minf(distance,v)
						if mask&8: distance=minf(distance,1-v)
						var su: float=1.0-u if variant%2 else u
						var sv: float=1.0-v if variant>=2 else v
						var px:=mini(int(su*627),626)
						var py:=mini(int(sv*627),626)
						var grass:=source.get_pixel(px,627+py)
						var dirt:=source.get_pixel(627+px,627+py)
						var irregular:=sin(u*31+v*17)*.015+sin(u*53-v*29)*.01
						var weight:=smoothstep(.025,.18,distance+irregular)
						image.set_pixel(mask*128+x,variant*64+y,grass.lerp(dirt,weight))
		image.save_png("res://tiles/path-transitions-v1.png")
		quit()
		return
	var tileset:=TileSet.new()
	tileset.tile_shape=TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout=TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tileset.tile_size=Vector2i(128,64)
	var atlas:=TileSetAtlasSource.new()
	atlas.texture=load("res://tiles/path-transitions-v1.png")
	atlas.texture_region_size=Vector2i(128,64)
	for variant in range(4):
		for mask in range(16):
			atlas.create_tile(Vector2i(mask,variant))
	tileset.add_source(atlas,0)
	ResourceSaver.save(tileset,"res://tiles/path-transitions.tres")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/scale-yard.json"))
	var root:=Node2D.new()
	root.name="PathTransitions"
	for height in [0,80]:
		var layer:=TileMapLayer.new()
		layer.name="PathsLow" if height==0 else "PathsHigh"
		layer.tile_set=tileset
		layer.scale=Vector2(.41,.41)
		layer.position=Vector2(0,13.12-height)-Vector2(layer.map_to_local(Vector2i.ZERO))*.41
		root.add_child(layer)
		layer.owner=root
		var filled: Dictionary={}
		var paint: Dictionary={}
		for y in range(0,24):
			for x in range(0,28):
				var cell:=Vector2i(x,y)
				var point:=Vector2(x*32+16,y*32+16)
				for r in data.terrain.paths:
					if r.elevation==height and Rect2(r.x,r.y,r.w,r.h).has_point(point):
						filled[cell]=true
						paint[cell]=true
				for r in data.terrain.bridges+data.terrain.ramps:
					if Rect2(r.x,r.y-32,r.w,r.h+64).has_point(point):
						filled[cell]=true
		for cell: Vector2i in paint:
			var mask:=0
			for side in [[Vector2i.LEFT,1],[Vector2i.RIGHT,2],[Vector2i.UP,4],[Vector2i.DOWN,8]]:
				if not filled.has(cell+side[0]): mask|=side[1]
			layer.set_cell(cell,0,Vector2i(mask,posmod(cell.x,2)+2*posmod(cell.y,2)))
	var packed:=PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed,"res://tiles/reference-paths.tscn")
	root.free()
	quit()
