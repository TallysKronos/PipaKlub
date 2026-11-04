extends SceneTree
## Authoring gallery and TileSet export. Never loads campaign or saves.
var library: Dictionary
var stage: Node2D
var output: String
var resource_root := "res://assets/overworld/kits/terrenos-v1/"
const PEERING = [14,1,2,5,6,9,10,13] # N NE E SE S SW W NW on DIAMOND_DOWN.

func _initialize() -> void:call_deferred("start")

func text_label(value: String,at: Vector2,size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("23394A"))
	stage.add_child(label)

func new_page(title: String) -> void:
	if is_instance_valid(stage):
		root.remove_child(stage)
		stage.free()
	stage = Node2D.new()
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(stage)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
	bg.color = Color("ECDFC1")
	stage.add_child(bg)
	text_label(title,Vector2(22,15),29)
	text_label("Galeria técnica · isometria 64×32 · sem campanha, colisão ou salvamento",Vector2(22,60),18)

func make_set(id: String,entry: Dictionary) -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(64,32)
	tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tiles.add_terrain_set()
	tiles.set_terrain_set_mode(0,TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	tiles.add_terrain(0)
	tiles.set_terrain_name(0,0,entry.name)
	tiles.set_terrain_color(0,0,Color("739653"))
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(resource_root+entry.atlas)
	atlas.texture_region_size = Vector2i(64,32)
	tiles.add_source(atlas,0)
	var entries: Array = entry.tiles.duplicate(true)
	for center: Dictionary in entry.centers:entries.append({"mask":255,"atlas":center.atlas})
	for item: Dictionary in entries:
		var cell := Vector2i(item.atlas[0],item.atlas[1])
		atlas.create_tile(cell)
		var data := atlas.get_tile_data(cell,0)
		data.terrain_set = 0
		data.terrain = 0
		for i in range(8):data.set_terrain_peering_bit(PEERING[i],0 if int(item.mask)&(1<<i) else -1)
		data.probability = .15 if int(item.mask)==255 and cell.y<6 else 1.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(resource_root+"tilesets"))
	ResourceSaver.save(tiles,resource_root+"tilesets/"+id+".tres")
	return tiles

func layer(tiles: TileSet,at: Vector2) -> TileMapLayer:
	var result := TileMapLayer.new()
	result.tile_set = tiles
	result.position = at
	result.collision_enabled = false
	result.navigation_enabled = false
	stage.add_child(result)
	return result

func sprite(file: String,at: Vector2,zoom: float=1.0) -> void:
	var image := Sprite2D.new()
	image.texture = load(resource_root+file)
	image.centered = false
	image.position = at
	image.scale = Vector2.ONE*zoom
	stage.add_child(image)

func capture(name_value: String) -> void:
	for frame in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_value+"-1280x720.png"))

func start() -> void:
	root.size = Vector2i(1280,720)
	library = JSON.parse_string(FileAccess.get_file_as_string(resource_root+"library.json"))
	output = ProjectSettings.globalize_path("res://../documentation/overworld/terrenos-v1/nativo")
	DirAccess.make_dir_recursive_absolute(output)
	var sets: Dictionary = {}
	for id: String in library.floors:sets[id] = make_set(id,library.floors[id])
	var page := 0
	var placed := 0
	for id: String in library.floors:
		var info: Dictionary = library.floors[id]
		new_page("PISOS MODULARES · "+str(info.name))
		var repeat := layer(sets[id],Vector2(300,185))
		var base_id := "terra-ocre" if id.begins_with("grama") else "grama-campo"
		var background := layer(sets[base_id],Vector2(930,185))
		var shaped := layer(sets[id],Vector2(930,185))
		var cells: Array[Vector2i] = []
		for y in range(8):
			for x in range(8):
				repeat.set_cell(Vector2i(x,y),0,Vector2i((x*3+y*5)%8,6))
				background.set_cell(Vector2i(x,y),0,Vector2i((x+y)%8,6))
				if not (x>=4 and y>=4) and not (x==2 and y==2):cells.append(Vector2i(x,y))
		shaped.set_cells_terrain_connect(cells,0,0,false)
		shaped.update_internals()
		placed += shaped.get_used_cells().size()
		text_label("8×8 centros alternativos · sem contorno de tile",Vector2(28,485),19)
		text_label("Autotile real · L + canto interno + vazado",Vector2(655,485),19)
		text_label("Atlas: 47 estados + 8 centros · terreno: lados e cantos",Vector2(28,535),20)
		text_label("Peças planas: a borda do material não cria elevação nem parede.",Vector2(28,575),18)
		text_label("Bases e materiais de cenário; aplicação nos mapas ainda pendente.",Vector2(28,622),17)
		await capture("piso-%02d-"%page+id)
		page += 1
	for id: String in library.walls:
		new_page("PAREDES MODULARES · "+str(library.walls[id].name))
		for i in range(4):
			sprite("paredes/"+id+"/u-"+str(i)+".png",Vector2(80+i*64,320-i*32),2.0)
			sprite("paredes/"+id+"/v-"+str(i)+".png",Vector2(410+i*64,224+i*32),2.0)
		sprite("paredes/"+id+"/canto-externo-0.png",Vector2(800,185),2.0)
		sprite("paredes/"+id+"/canto-interno-0.png",Vector2(1040,185),2.0)
		text_label("Face U · fases consecutivas",Vector2(55,485),18)
		text_label("Face V · fases consecutivas",Vector2(395,485),18)
		text_label("Canto externo",Vector2(795,410),19)
		text_label("Canto interno",Vector2(1035,410),19)
		var cap := 0
		for side in ["u","v"]:
			for end in ["inicio","fim"]:
				sprite("paredes/"+id+"/"+side+"-"+end+".png",Vector2(770+cap*110,490),1.4)
				cap += 1
		text_label("Altura nativa 64 px · faces sem tampas no meio · terminações separadas",Vector2(28,650),19)
		await capture("parede-"+id)
	print("Terrain library: 24 native autotile resources; 36 material pages; ",placed," terrain-connect cells. No campaign/test suite.")
	quit()
