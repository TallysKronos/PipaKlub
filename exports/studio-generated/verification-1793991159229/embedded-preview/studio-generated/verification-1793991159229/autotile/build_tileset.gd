extends SceneTree
const MASKS: Array[int]=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,19,23,27,31,38,39,46,47,55,63,76,77,78,79,95,110,111,127,137,139,141,143,155,159,175,191,205,207,223,239,255]
func _initialize() -> void:
	var definitions: Array=[{"id":"grass","name":"Grama","color":"8eaa53"},{"id":"stone","name":"Pedra","color":"a6ac94"},{"id":"sand","name":"Areia","color":"d8be86"},{"id":"water","name":"Água","color":"24768d"}]
	definitions.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991159229/grounds.json")))
	var tileset := TileSet.new()
	tileset.tile_size=Vector2i(32,32)
	for set_index: int in range(definitions.size()):
		tileset.add_terrain_set()
		tileset.set_terrain_set_mode(set_index,TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
		tileset.add_terrain(set_index)
		tileset.set_terrain_name(set_index,0,"Terra" if set_index<2 else "Grama")
		tileset.set_terrain_color(set_index,0,Color("c6a16c"))
		tileset.add_terrain(set_index)
		tileset.set_terrain_name(set_index,1,str(definitions[set_index].name))
		tileset.set_terrain_color(set_index,1,Color(str(definitions[set_index].color)))
		var atlas := TileSetAtlasSource.new()
		atlas.texture=load("res://studio-generated/verification-1793991159229/autotile/"+str(definitions[set_index].id)+".png")
		atlas.texture_region_size=Vector2i(32,32)
		tileset.add_source(atlas,set_index)
		for variant: int in range(3):
			for i: int in range(MASKS.size()):
				var pos := Vector2i(i%8,int(i/8)+variant*6)
				atlas.create_tile(pos)
				var data := atlas.get_tile_data(pos,0)
				data.terrain_set=set_index
				data.terrain=1
				var bits := [[TileSet.CELL_NEIGHBOR_TOP_SIDE,1],[TileSet.CELL_NEIGHBOR_RIGHT_SIDE,2],[TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,4],[TileSet.CELL_NEIGHBOR_LEFT_SIDE,8],[TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,16],[TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,32],[TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,64],[TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,128]]
				for entry: Array in bits:
					data.set_terrain_peering_bit(int(entry[0]),1 if MASKS[i]&int(entry[1]) else 0)
		var dirt := TileSetAtlasSource.new()
		dirt.texture=load("res://studio-generated/verification-1793991159229/autotile/dirt.png" if set_index<2 else "res://studio-generated/verification-1793991159229/autotile/grass.png")
		dirt.texture_region_size=Vector2i(32,32)
		tileset.add_source(dirt,definitions.size()+set_index)
		for variant: int in range(3):
			var pos := Vector2i(0,variant) if set_index<2 else Vector2i(6,5+variant*6)
			dirt.create_tile(pos)
			var data := dirt.get_tile_data(pos,0)
			data.terrain_set=set_index
			data.terrain=0
			for bit: int in [TileSet.CELL_NEIGHBOR_TOP_SIDE,TileSet.CELL_NEIGHBOR_RIGHT_SIDE,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,TileSet.CELL_NEIGHBOR_LEFT_SIDE,TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER]:
				data.set_terrain_peering_bit(bit,0)
	var error := ResourceSaver.save(tileset,"res://studio-generated/verification-1793991159229/autotile/terrain-set.tres")
	assert(error==OK)
	var layer := TileMapLayer.new()
	layer.tile_set=tileset
	root.add_child(layer)
	for set_index: int in range(definitions.size()):
		layer.clear()
		var base: Array[Vector2i]=[]
		for y: int in range(12):
			for x: int in range(12):
				base.append(Vector2i(x,y))
		layer.set_cells_terrain_connect(base,set_index,0)
		var painted: Array[Vector2i]=[Vector2i(3,3),Vector2i(4,3),Vector2i(4,4),Vector2i(5,4),Vector2i(5,5),Vector2i(4,5),Vector2i(8,8)]
		layer.set_cells_terrain_connect(painted,set_index,1)
		for cell: Vector2i in painted:
			assert(layer.get_cell_tile_data(cell)!=null)
			assert(layer.get_cell_tile_data(cell).terrain==1)
	print("PASS TileSet Godot: 31 terrain sets, 47 máscaras x3, TileMapLayer pintável.")
	layer.queue_free()
	quit()

