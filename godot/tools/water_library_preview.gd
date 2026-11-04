extends SceneTree
## Creates resources and a native 1280x720 gallery without campaign or saves.
const BASE := "res://assets/overworld/kits/aguas-v1/"
const PATCH = preload("res://scripts/overworld/water_patch.gd")
const FALL = preload("res://scripts/overworld/waterfall.gd")
const EFFECT = preload("res://scripts/overworld/water_effect.gd")
const PEERING = [14,1,2,5,6,9,10,13]
var stage: Node2D
var actors: Array[Node] = []
var output: String
var library: Dictionary

func _initialize() -> void:call_deferred("start")

func label(value: String,at: Vector2,size: int=20) -> void:
	var item := Label.new()
	item.position = at
	item.text = value
	item.add_theme_font_size_override("font_size",size)
	item.add_theme_color_override("font_color",Color("EAD6AA"))
	stage.add_child(item)

func page(title: String) -> void:
	actors.clear()
	if is_instance_valid(stage):
		root.remove_child(stage)
		stage.free()
	stage = Node2D.new()
	root.add_child(stage)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
	bg.color = Color("193B3D")
	stage.add_child(bg)
	label(title,Vector2(25,18),29)
	label("Biblioteca animada · 64×32 · margens fixas · sem alterar campanha",Vector2(25,62),18)

func make_sets() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE+"tilesets"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE+"materials"))
	for id: String in library.waters:
		var tiles := TileSet.new()
		tiles.tile_size = Vector2i(64,32)
		tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
		tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
		tiles.add_terrain_set()
		tiles.set_terrain_set_mode(0,TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
		tiles.add_terrain(0)
		tiles.set_terrain_name(0,0,library.waters[id].name)
		var atlas := TileSetAtlasSource.new()
		atlas.texture = load(BASE+library.waters[id].atlas)
		atlas.texture_region_size = Vector2i(64,32)
		tiles.add_source(atlas,0)
		for info: Dictionary in library.tiles:
			var cell := Vector2i(info.atlas[0],info.atlas[1])
			atlas.create_tile(cell)
			var data := atlas.get_tile_data(cell,0)
			data.terrain_set = 0
			data.terrain = 0
			for i in range(8):data.set_terrain_peering_bit(PEERING[i],0 if int(info.mask)&(1<<i) else -1)
		ResourceSaver.save(tiles,BASE+"tilesets/"+id+".tres")
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/overworld/water_surface.gdshader")
		mat.set_shader_parameter("surface_texture",load(BASE+library.waters[id].surface))
		mat.set_shader_parameter("shore_texture",load(BASE+"masks/shore-atlas.png"))
		mat.set_shader_parameter("flow_direction",Vector2(0,library.waters[id].flow[1]))
		ResourceSaver.save(mat,BASE+"materials/"+id+".tres")

func patch(id: String,kind: String,at: Vector2,zoom: float=1.0,size_value: Vector2i=Vector2i(8,8)) -> Node2D:
	var node := Node2D.new()
	node.set_script(PATCH)
	node.water_id = id
	node.layout = kind
	node.patch_size = size_value
	node.position = at
	node.scale = Vector2.ONE*zoom
	node.flow_direction = Vector2(0,0 if id.begins_with("lago") else (2 if id=="corredeira" else 1))
	stage.add_child(node)
	actors.append(node)
	return node

func floor_patch(at: Vector2,size_value: int,ground: String,zoom: float=1.0) -> void:
	var layer := TileMapLayer.new()
	layer.tile_set = load("res://assets/overworld/kits/terrenos-v1/tilesets/"+ground+".tres")
	layer.position = at
	layer.scale = Vector2.ONE*zoom
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.collision_enabled = false
	layer.navigation_enabled = false
	stage.add_child(layer)
	layer.position -= layer.map_to_local(Vector2i.ZERO)*zoom
	for y in range(size_value):
		for x in range(size_value):layer.set_cell(Vector2i(x,y),0,Vector2i((x+y)%8,6))

func falling(axis_value: String,levels: int,at: Vector2,zoom: float=1.0) -> void:
	# Receiving pool is rendered first; upper river ends exactly at the curtain lip.
	patch("lago-claro","lake",at+Vector2(0,levels*64)*zoom,zoom,Vector2i(7,7))
	var b := Vector2(0,112)
	var down := Vector2(0,levels*64)
	for sign_value in [-1,1]:
		var side := Polygon2D.new()
		var a := Vector2(sign_value*128,48)
		side.polygon = PackedVector2Array([a,b,b+down,a+down])
		side.uv = PackedVector2Array([Vector2(0,0),Vector2(256,0),Vector2(256,512),Vector2(0,512)])
		side.position = at
		side.scale = Vector2.ONE*zoom
		side.texture = load("res://assets/overworld/kits/terrenos-v1/superficies/pedra-arenito.png")
		side.color = Color(0.85,0.85,0.85) if sign_value==1 else Color.WHITE
		stage.add_child(side)
	floor_patch(at,4,"grama-campo",zoom)
	var upper := patch("rio-claro","rectangle",at+(Vector2(32,16) if axis_value=="v" else Vector2(-32,16))*zoom,zoom,Vector2i(2,4) if axis_value=="v" else Vector2i(4,2))
	if axis_value=="u":upper.water_material.set_shader_parameter("flow_direction",Vector2(1,0))
	var node := Node2D.new()
	node.set_script(FALL)
	node.axis = axis_value
	node.width_cells = 2
	node.drop_levels = levels
	node.curtain_id = "cortina-forte" if levels==2 else "cortina-suave"
	node.position = at+(Vector2(-96,64) if axis_value=="v" else Vector2(96,64))*zoom
	node.scale = Vector2.ONE*zoom
	stage.add_child(node)
	actors.append(node)

func capture(name_value: String,time_value: float=0.0) -> void:
	for actor in actors:actor.set_animation_time(time_value)
	for i in range(2):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_value+".png"))

func save_scenes() -> void:
	var path := "res://scenes/overworld/water/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	for id: String in library.waters:
		var node := Node2D.new()
		node.name = id
		node.set_script(PATCH)
		node.water_id = id
		node.layout = "lake" if id.begins_with("lago") or id=="agua-pantano" else "river"
		node.flow_direction = Vector2(0,library.waters[id].flow[1])
		var packed := PackedScene.new()
		packed.pack(node)
		ResourceSaver.save(packed,path+id+".tscn")
		node.free()
	for axis_value in ["u","v"]:
		for levels in [1,2]:
			var node := Node2D.new()
			node.name = "cachoeira-"+axis_value+"-"+str(levels)
			node.set_script(FALL)
			node.axis = axis_value
			node.drop_levels = levels
			node.curtain_id = "cortina-forte" if levels==2 else "cortina-suave"
			var packed := PackedScene.new()
			packed.pack(node)
			ResourceSaver.save(packed,path+"cachoeira-"+axis_value+"-"+str(levels)+".tscn")
			node.free()
	for kind in ["bend","branch"]:
		var node := Node2D.new()
		node.name = "rio-"+kind
		node.set_script(PATCH)
		node.water_id = "rio-claro"
		node.layout = kind
		var packed := PackedScene.new()
		packed.pack(node)
		ResourceSaver.save(packed,path+"rio-"+kind+".tscn")
		node.free()
	for id: String in library.effects:
		var node := Sprite2D.new()
		node.name = id
		node.set_script(EFFECT)
		node.effect_id = id
		var packed := PackedScene.new()
		packed.pack(node)
		ResourceSaver.save(packed,path+id+".tscn")
		node.free()

func start() -> void:
	root.size = Vector2i(1280,720)
	output = ProjectSettings.globalize_path("res://../documentation/overworld/aguas-v1/nativo")
	DirAccess.make_dir_recursive_absolute(output+"/frames")
	library = JSON.parse_string(FileAccess.get_file_as_string(BASE+"library.json"))
	make_sets()
	save_scenes()
	page("ÁGUAS VIVAS · seis materiais contínuos")
	var index := 0
	for id: String in library.waters:
		var at := Vector2(220+(index%3)*420,135+(index/3)*265)
		floor_patch(at,8,"grama-campo",0.72)
		patch(id,"lake",at,0.72)
		label(library.waters[id].name,at+Vector2(-180,190),20)
		index += 1
	await capture("01-seis-aguas-1280x720")
	page("RIOS · curva, bifurcação e correnteza")
	var kinds := ["bend","branch","river"]
	for i in range(3):
		var at := Vector2(215+i*420,165)
		floor_patch(at,8,"grama-campo",0.75)
		patch("corredeira" if i==2 else "rio-claro",kinds[i],at,0.75)
		label(["Curva","Bifurcação","Corredeira"][i],at+Vector2(-100,240),22)
	label("47 encaixes por material · a espuma acompanha a margem, nunca a aresta de cada tile",Vector2(25,570),20)
	await capture("02-rios-1280x720")
	page("CACHOEIRAS · lábio, queda e impacto")
	falling("v",1,Vector2(250,160),1.2)
	falling("u",2,Vector2(900,125),1.2)
	label("Face V · queda de 64 px",Vector2(65,560),22)
	label("Face U · queda de 128 px",Vector2(740,560),22)
	label("Água do topo termina no lábio; espuma e poço recebem a queda no nível inferior.",Vector2(25,650),20)
	await capture("03-cachoeiras-1280x720")
	for i in range(48):await capture("frames/cachoeiras-%02d"%i,float(i)/12.0)
	await capture("cachoeiras-loop-final",4.0)
	if "--live-falls" in OS.get_cmdline_user_args():
		for actor in actors:actor.set_animation_time(-1.0)
		return
	page("ANIMAÇÃO · lago, rio e redemoinho")
	floor_patch(Vector2(340,150),8,"grama-campo",1.0)
	patch("lago-claro","lake",Vector2(340,150))
	floor_patch(Vector2(990,150),8,"grama-campo",1.0)
	patch("corredeira","bend",Vector2(990,150))
	var effect := Sprite2D.new()
	effect.texture = load(BASE+"effects/redemoinho.png")
	effect.position = Vector2(340,260)
	effect.scale = Vector2.ONE*.36
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/overworld/water_foam.gdshader")
	effect.material = mat
	stage.add_child(effect)
	label("Lago claro + efeito separado",Vector2(80,470),23)
	label("Corredeira em curva",Vector2(790,470),23)
	for i in range(48):
		mat.set_shader_parameter("preview_time",float(i)/12.0)
		await capture("frames/agua-%02d"%i,float(i)/12.0)
	mat.set_shader_parameter("preview_time",4.0)
	await capture("agua-loop-final",4.0)
	if "--live" in OS.get_cmdline_user_args():
		for actor in actors:actor.set_animation_time(-1.0)
		mat.set_shader_parameter("preview_time",-1.0)
		return
	page("ESPUMA · efeitos independentes com transparência")
	var effect_index := 0
	for id: String in library.effects:
		var node := Sprite2D.new()
		node.set_script(EFFECT)
		node.effect_id = id
		node.position = Vector2(325+(effect_index%2)*630,220+(effect_index/2)*230)
		node.scale = Vector2.ONE*0.9
		stage.add_child(node)
		actors.append(node)
		label(library.effects[id].name,node.position+Vector2(-200,75),23)
		effect_index += 1
	await capture("04-efeitos-1280x720")
	print("Water library: 6 TileSets, 6 ShaderMaterials, 16 reusable scenes, 4 native pages, 96 animation frames.")
	quit()
