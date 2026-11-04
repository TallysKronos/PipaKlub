extends SceneTree
## Native cave art gallery. Isolated from campaign, accounts and saves.
const BASE := "res://assets/overworld/kits/cavernas-v3/"
const PEERING = [14,1,2,5,6,9,10,13]
const WATER = preload("res://scripts/overworld/cave_water.gd")
const FALL = preload("res://scripts/overworld/cave_waterfall.gd")
const BASIN = preload("res://scripts/overworld/cave_basin.gd")
const GROUND = preload("res://scripts/overworld/cave_ground.gd")
var library: Dictionary
var stage: Node2D
var output: String
var sets: Dictionary = {}
var animated: Array[Node] = []
var visual_parent: Node2D

func _initialize() -> void:call_deferred("start")

func label(value: String,at: Vector2,size_value: int=20) -> void:
 var item := Label.new()
 item.text = value
 item.position = at
 item.add_theme_font_size_override("font_size",size_value)
 item.add_theme_color_override("font_color",Color("E6D8B3"))
 stage.add_child(item)

func page(title: String) -> void:
 animated.clear()
 if is_instance_valid(stage):
  root.remove_child(stage)
  stage.free()
 stage = Node2D.new()
 stage.name = "CaveGallery"
 root.add_child(stage)
 var bg := Polygon2D.new()
 bg.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
 bg.color = Color("19262D")
 stage.add_child(bg)
 label(title,Vector2(24,16),29)
 label("Gruta dos Elos · revisão de leitura · isometria 64×32 · galeria visual sem campanha",Vector2(24,62),18)

func make_sets() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE+"tilesets"))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE+"materials"))
 for id: String in library.floors:
  var ts := TileSet.new()
  ts.tile_size = Vector2i(64,32)
  ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
  ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
  ts.add_terrain_set()
  ts.set_terrain_set_mode(0,TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
  ts.add_terrain(0)
  ts.set_terrain_name(0,0,library.floors[id].name)
  var source := TileSetAtlasSource.new()
  source.texture = load(BASE+library.floors[id].atlas)
  source.texture_region_size = Vector2i(64,32)
  ts.add_source(source,0)
  var entries: Array = library.floors[id].tiles.duplicate(true)
  for center: Dictionary in library.floors[id].centers:entries.append({"mask":255,"atlas":center.atlas})
  for entry: Dictionary in entries:
   var coord := Vector2i(entry.atlas[0],entry.atlas[1])
   source.create_tile(coord)
   var data := source.get_tile_data(coord,0)
   data.terrain_set = 0
   data.terrain = 0
   data.probability = 0.1 if int(entry.mask)==255 and coord.y<6 else 1.0
   for i in range(8):data.set_terrain_peering_bit(PEERING[i],0 if int(entry.mask)&(1<<i) else -1)
  ResourceSaver.save(ts,BASE+"tilesets/"+id+".tres")
  sets[id] = ts
  var mat := ShaderMaterial.new()
  mat.shader = load("res://shaders/overworld/cave_floor.gdshader")
  mat.set_shader_parameter("surface_texture",load(BASE+library.floors[id].surface))
  mat.set_shader_parameter("cells_per_repeat",8.0)
  mat.set_shader_parameter("surface_contrast",0.72)
  var tones := {"rocha-cinza":Color("344453"),"terra-gruta":Color("7C624C"),"rocha-umida":Color("293E49"),"cascalho-gruta":Color("69635A")}
  mat.set_shader_parameter("base_tone",tones[id])
  ResourceSaver.save(mat,BASE+"materials/"+id+".tres")

func layer(id: String,at: Vector2) -> TileMapLayer:
 var result := TileMapLayer.new()
 result.tile_set = sets[id]
 result.material = load(BASE+"materials/"+id+".tres")
 result.position = at
 result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 result.collision_enabled = false
 result.navigation_enabled = false
 if is_instance_valid(visual_parent):visual_parent.add_child(result)
 else:stage.add_child(result)
 result.position -= result.map_to_local(Vector2i.ZERO)
 return result

func floor_grid(id: String,at: Vector2,size_value: int) -> TileMapLayer:
 var result := layer(id,at)
 for y in range(size_value):
  for x in range(size_value):result.set_cell(Vector2i(x,y),0,Vector2i((x*3+y*5)%8,6))
 return result

func sprite(file: String,at: Vector2,zoom: float=1.0) -> void:
 var node := Sprite2D.new()
 node.texture = load(BASE+file)
 node.centered = false
 node.position = at
 node.scale = Vector2.ONE*zoom
 stage.add_child(node)

func prop(id: String,at: Vector2,parent: Node2D=null) -> void:
 if parent==null:parent = stage
 var node: Node2D = load("res://scenes/overworld/caves-v3/props/"+id+".tscn").instantiate()
 node.position = at
 parent.add_child(node,true)

func iso(x: float,y: float) -> Vector2:return Vector2((x-y)*32,(x+y)*16)

func quad(parent: Node2D,points: PackedVector2Array,id: String,tint: float=1.0,uv_width: float=640.0) -> void:
 var face := Polygon2D.new()
 face.polygon = points
 face.uv = PackedVector2Array([Vector2.ZERO,Vector2(uv_width,0),Vector2(uv_width,512),Vector2(0,512)])
 face.texture = load(BASE+"surfaces/"+id+".png")
 face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
 face.color = Color(tint,tint,tint)
 parent.add_child(face)

func room(wet: bool) -> void:
 var at := Vector2(640,245)
 visual_parent = Node2D.new()
 visual_parent.name = "GrutaInundada" if wet else "GrutaSeca"
 stage.add_child(visual_parent)
 var walls := Node2D.new()
 walls.position = at
 visual_parent.add_child(walls)
 var corner_value := iso(-.5,-.5)
 for sign_value in [-1,1]:
  var a := corner_value
  var b := Vector2(sign_value*320,144)
  var up := Vector2(0,-128)
  var back := Vector2(sign_value*12,-6)
  quad(walls,PackedVector2Array([a+up,b+up,b,a]),"parede-umida" if wet else "parede-basalto",.86 if sign_value==1 else 1.0)
  quad(walls,PackedVector2Array([a+up+back,b+up+back,b+up,a+up]),"parede-basalto",1.0)
  quad(walls,PackedVector2Array([b+up,b+up+back,b+back,b]),"parede-basalto",.7,48)
 if wet:
  var basin := Node2D.new()
  basin.set_script(BASIN)
  basin.name = "RecessedBasin"
  basin.position = at
  visual_parent.add_child(basin)
  animated.append(basin)
 else:
  var ground := Polygon2D.new()
  ground.name = "BlendedCaveGround"
  ground.position = at
  ground.polygon = PackedVector2Array([iso(-.5,-.5),iso(9.5,-.5),iso(9.5,9.5),iso(-.5,9.5)])
  ground.material = GROUND.material(false)
  visual_parent.add_child(ground)
  var wall_contact := Line2D.new()
  wall_contact.points = PackedVector2Array([at+Vector2(-320,144),at+Vector2(0,-16),at+Vector2(320,144)])
  wall_contact.width = 4.0
  wall_contact.default_color = Color("171A29")
  visual_parent.add_child(wall_contact)
 var objects := Node2D.new()
 objects.name = "DepthSortedProps"
 objects.position = at
 objects.y_sort_enabled = true
 visual_parent.add_child(objects)
 for placement in [["estalagmite-alta",1,1],["estalagmite-baixa",2,3],["coluna-calcario",1,5],["rocha-solta",7,8],["estalagmite-baixa",8,6],["cristal-ambar",2,7],["cristal-azul",8,5],["cogumelos-gruta",6,6],["cogumelos-gruta",2,9]]:
  prop(placement[0],iso(placement[1],placement[2]),objects)
 for child in visual_parent.get_children():child.position -= at
 own_visuals(visual_parent,visual_parent)
 var packed := PackedScene.new()
 packed.pack(visual_parent)
 ResourceSaver.save(packed,"res://scenes/overworld/caves-v3/"+("gruta-inundada" if wet else "gruta-seca")+".tscn")
 visual_parent.position = at
 visual_parent = null
 label("Caminho central livre · rocha sustenta as paredes · objetos separados por profundidade",Vector2(24,640),19)

func own_visuals(node: Node,scene_root: Node) -> void:
 for child in node.get_children():
  child.owner = scene_root
  # Procedural visual children are rebuilt by their own scripts on instantiation.
  if child.get_script()!=WATER and child.get_script()!=FALL and child.get_script()!=BASIN and child.scene_file_path.is_empty():own_visuals(child,scene_root)

func capture(name_value: String,time_value: float=0.0) -> void:
 for node in animated:node.set_animation_time(time_value)
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name_value+".png"))

func start() -> void:
 root.size = Vector2i(1280,720)
 output = ProjectSettings.globalize_path("res://../documentation/overworld/cavernas-v3/nativo")
 DirAccess.make_dir_recursive_absolute(output+"/frames")
 library = JSON.parse_string(FileAccess.get_file_as_string(BASE+"library.json"))
 make_sets()
 var basin_piece := Node2D.new()
 basin_piece.name = "PocoRebaixado"
 basin_piece.set_script(BASIN)
 var basin_scene := PackedScene.new()
 basin_scene.pack(basin_piece)
 ResourceSaver.save(basin_scene,"res://scenes/overworld/caves-v3/poco-rebaixado.tscn")
 basin_piece.free()
 var index := 0
 for id: String in library.floors:
  page("PISO · "+str(library.floors[id].name))
  floor_grid(id,Vector2(300,170),8)
  var back := "terra-gruta" if id!="terra-gruta" else "rocha-cinza"
  floor_grid(back,Vector2(940,170),8)
  var shaped := layer(id,Vector2(940,170))
  var cells: Array[Vector2i] = []
  for y in range(8):
   for x in range(8):
    if not(x>=4 and y>=4) and not(x==2 and y==2):cells.append(Vector2i(x,y))
  shaped.set_cells_terrain_connect(cells,0,0,false)
  label("8×8 células · pintura contínua",Vector2(70,480),23)
  label("L + canto interno + vazado",Vector2(730,480),23)
  label("47 encaixes e 8 centros · materiais planos, sem altura pintada",Vector2(24,590),21)
  await capture("piso-"+str(index)+"-"+id+"-1280x720")
  index += 1
 for id: String in library.walls:
  page("PAREDE · "+str(library.walls[id].name))
  for i in range(4):
   sprite("walls/"+id+"/u-"+str(i)+".png",Vector2(75+i*64,320-i*32),2.0)
   sprite("walls/"+id+"/v-"+str(i)+".png",Vector2(410+i*64,224+i*32),2.0)
  sprite("walls/"+id+"/canto-externo-0.png",Vector2(805,185),2.0)
  sprite("walls/"+id+"/canto-interno-0.png",Vector2(1040,185),2.0)
  label("Face U · fases",Vector2(65,495),20)
  label("Face V · fases",Vector2(400,495),20)
  label("Canto externo",Vector2(800,410),19)
  label("Canto interno",Vector2(1035,410),19)
  var cap := 0
  for side in ["u","v"]:
   for end in ["inicio","fim"]:
    sprite("walls/"+id+"/"+side+"-"+end+".png",Vector2(760+cap*110,490),1.4)
    cap += 1
  await capture(id+"-1280x720")
 page("OBJETOS · silhueta, escala e pivô de apoio")
 index = 0
 for id: String in library.props:
  var at := Vector2(165+(index%4)*315,325+(index/4)*270)
  prop(id,at)
  label(library.props[id].name,at+Vector2(-130,25),21)
  index += 1
 await capture("objetos-1280x720")
 page("GRUTA DOS ELOS · montagem com o kit")
 room(false)
 await capture("gruta-seca-1280x720")
 page("GRUTA DOS ELOS · ÁGUA · água e cachoeira subterrânea")
 room(true)
 await capture("gruta-inundada-1280x720")
 for i in range(48):await capture("frames/gruta-%02d"%i,float(i)/12.0)
 await capture("gruta-loop-final",4.0)
 if "--live" in OS.get_cmdline_user_args():
  for node in animated:node.set_animation_time(-1.0)
  return
 for variant in ["gruta-seca","gruta-inundada"]:
  page("GRUTA DOS ELOS · instância da cena salva")
  var saved: Node2D = load("res://scenes/overworld/caves-v3/"+variant+".tscn").instantiate()
  saved.position = Vector2(640,245)
  stage.add_child(saved)
  var basin: Node = saved.get_node_or_null("RecessedBasin")
  if basin:animated.append(basin)
  await capture(variant+"-instancia-1280x720")
 page("POÇO · geometria de margem e cota inferior")
 var geometry := Node2D.new()
 geometry.set_script(BASIN)
 geometry.name = "BasinGeometryReview"
 geometry.position = Vector2(640,245)
 geometry.show_geometry = true
 stage.add_child(geometry)
 animated.append(geometry)
 await capture("poco-geometria-1280x720")
 var record := {"topHeightPx":0,"waterHeightPx":-geometry.depth_px,"fallDropPx":128+geometry.depth_px,"sharedContourVertices":geometry.top_contour().size(),"floorPolygonPieces":geometry.floor_piece_count,"pathPolygonPieces":geometry.path_piece_count,"waterSurfaceIsRecessed":true,"campaignIntegrated":false}
 var report := FileAccess.open(output.path_join("../revisao-poco/geometria.json"),FileAccess.WRITE)
 if report:report.store_string(JSON.stringify(record,"  "))
 print("Cave library: recessed pool, 11 reusable scenes, 14 native pages, 48 animation frames. No campaign loaded.")
 quit()
