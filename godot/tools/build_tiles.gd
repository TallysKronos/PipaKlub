extends SceneTree
## Deterministic import: sample existing materials into transparent isometric tiles.
func _init() -> void:
	var source: Image=load("res://assets/terrain.png").get_image()
	var atlas:=Image.create(2048,64,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var quadrants: Array[Vector2i]=[Vector2i(0,1),Vector2i(1,1),Vector2i(0,0),Vector2i(1,0)]
	for tile in range(16):
		for y in range(64):
			for x in range(128):
				var u:=((x+.5-64)/64.0+(y+.5)/32.0)/2.0
				var v:=((y+.5)/32.0-(x+.5-64)/64.0)/2.0
				if u>=0 and u<1 and v>=0 and v<1:
					var variant: int=tile%4
					var su: float=1.0-u if variant%2 else u
					var sv: float=1.0-v if variant>=2 else v
					atlas.set_pixel(tile*128+x,y,source.get_pixel(quadrants[tile/4].x*627+mini(int(su*627),626),quadrants[tile/4].y*627+mini(int(sv*627),626)))
	atlas.save_png("res://tiles/materials-iso-v1.png")
	var tiles:=TileMapLayer.new()
	tiles.name="ReferenceGround"
	tiles.tile_set=load("res://tiles/veredas-materials.tres")
	tiles.scale=Vector2(.82,.82)
	tiles.position=Vector2(0,26.24)-Vector2(tiles.map_to_local(Vector2i.ZERO))*.82
	tiles.z_index=-1
	for y in range(-20,32):
		for x in range(-20,32):
			tiles.set_cell(Vector2i(x,y),0,Vector2i(posmod(x,2)+2*posmod(y,2),0))
	var scene:=PackedScene.new()
	scene.pack(tiles)
	ResourceSaver.save(scene,"res://tiles/reference-ground.tscn")
	tiles.free()
	quit()
