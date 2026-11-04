extends SceneTree
## Parque B (Clareira do Papel) surfaces.
## The rebuilt Clareira has no water by brief (art/overworld/briefs/clareira-do-papel.md:
## "Sem água: ... reservando os canais às Veredas"). The river contract below still runs
## in full if water returns to this map; it no longer pins the old map's coordinates.
var failures: Array[String] = []
var checks := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var View = load("res://scripts/overworld/view.gd")
	var view = View.new()
	view.art_preview = true
	root.add_child(view)
	view.load_area("clareira-do-papel")
	await process_frame
	var water_cells: Array[Vector2i] = []
	for v in int(view.model.data.h):
		for u in int(view.model.data.w):
			if view.model.cell_at(Vector2i(u,v)).get("material","")=="agua": water_cells.append(Vector2i(u,v))
	var water_nodes: Array[Node] = []
	var bank_count := 0
	for node in view.actors.get_children():
		if str(node.name).begins_with("AguaRebaixada"): water_nodes.append(node)
		if str(node.name).begins_with("MargemDoLeito") or str(node.name).begins_with("MargemContinua"): bank_count += 1
	for surface in ["grama","terra","piso"]:
		var paint: Texture2D = view._paint_material(surface).get_shader_parameter("painting")
		check(paint.resource_path.ends_with(".png"),"Pintura aprovada substituída por marcas SVG: "+surface)
	if water_cells.is_empty():
		check(water_nodes.is_empty(),"Água desenhada sem células de água no mapa lógico")
		check(view.parque_surfaces == null or not view.parque_surfaces.natural_channel,"Margem construída sem água")
	else:
		# Water came back: the full recessed-bank contract applies (AGENTS.md, margens e poços).
		check(view.parque_surfaces != null and view.parque_surfaces.natural_channel,"Margem contínua não foi construída")
		check(water_nodes.size()==1,"Leito deveria ser uma superfície contínua")
		check(bank_count>0,"Margens sem faces de profundidade")
		check(float(view.kits[1].mangaWater.depthPx)>=32,"Recuo do leito pouco legível")
		for cell in water_cells:
			check(not view.model.walkable(cell),"Água caminhável")
			if view.parque_surfaces != null and view.parque_surfaces.shoreline != null:
				check(view.parque_surfaces.shoreline.wet.has(cell),"Buraco no leito da água")
		for node in water_nodes:
			var water: Polygon2D = node if node is Polygon2D else node.get_child(0)
			check(node.z_index < -1,"Água cobre ponte ou terreno")
			check(not Geometry2D.triangulate_polygon(water.polygon).is_empty(),"Contorno da água cruza a si mesmo")
		if view.parque_surfaces != null:
			check(view.parque_surfaces.water_material.shader.resource_path=="res://shaders/overworld/water_surface.gdshader","Água animada existente não foi reutilizada")
			check(view.parque_surfaces.water_material.get_shader_parameter("screen_space_surface"),"Água ilustrada deformada pela projeção do atlas")
	print("PARQUE SURFACES: ",checks," verificações; ",failures.size()," falhas; água=",water_cells.size()," células")
	for failure in failures: printerr(failure)
	quit(0 if failures.is_empty() else 1)
