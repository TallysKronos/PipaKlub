extends SceneTree
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
	var deck_count := 0
	var water_count := 0
	var bank_count := 0
	for node in view.actors.get_children():
		if str(node.name).begins_with("PonteInteira3x5") or node is Sprite2D and node.z_index == -1:
			deck_count += 1
			check(node.scale==Vector2.ONE,"Tabuleiro esticado")
			check(node.texture.get_size()==Vector2(480,276),"Tamanho nativo da ponte incorreto")
		if str(node.name).begins_with("AguaRebaixada"):
			water_count += 1
			var water: Polygon2D = node if node is Polygon2D else node.get_child(0)
			if water.has_meta("shore_top"):
				var top: PackedVector2Array = water.get_meta("shore_top")
				var bed: PackedVector2Array = water.get_meta("full_bed")
				var aperture: PackedVector2Array = water.get_meta("aperture")
				check(top.size()==bed.size(),"Margem e leito com contornos diferentes")
				check(not Geometry2D.triangulate_polygon(water.polygon).is_empty(),"Contorno da água cruza a si mesmo")
				for i in top.size():
					var expected: Vector2 = view.model.project(top[i],false)+Vector2(0,float(view.kits[1].mangaWater.depthPx))
					check(bed[i].is_equal_approx(expected),"Leito não corresponde à margem medida")
				for p in water.polygon:
					var inside := Geometry2D.is_point_in_polygon(p,aperture)
					for i in aperture.size():
						if p.distance_to(Geometry2D.get_closest_point_to_segment(p,aperture[i],aperture[(i+1)%aperture.size()]))<.01: inside = true
					check(inside,"Água projetada vaza pela margem próxima")
			else:
				check(is_equal_approx(water.polygon[0].y,float(view.kits[1].mangaWater.depthPx)),"Água não segue a profundidade do kit")
			check(node.z_index < -1,"Água cobre ponte ou terreno")
		if str(node.name).begins_with("MargemDoLeito") or str(node.name).begins_with("MargemContinua"): bank_count += 1
	check(deck_count==2,"Deveriam existir duas pontes inteiras, sem tabuleiros por célula")
	check(water_count==1,"Leito deveria ser uma superfície contínua")
	check(view.parque_surfaces.natural_channel,"Margem contínua não foi construída")
	check(not view.parque_surfaces.shoreline.wet.has(Vector2i(27,24)),"Água invade apoio seco da ponte")
	check(not view.parque_surfaces.shoreline.wet.has(Vector2i(32,34)),"Água invade desembarque da ponte")
	check(bank_count>0,"Margens sem faces de profundidade")
	check(float(view.kits[1].mangaWater.depthPx)>=32,"Recuo do leito pouco legível")
	for surface in ["grama","terra","piso"]:
		var paint: Texture2D = view._paint_material(surface).get_shader_parameter("painting")
		check(paint.resource_path.ends_with(".png"),"Pintura aprovada substituída por marcas SVG: "+surface)
	check(view.parque_surfaces.water_material.get_shader_parameter("screen_space_surface"),"Água ilustrada deformada pela projeção do atlas")
	for u in [27,32]:
		for v in range(23,36):
			check(view.model.walkable(Vector2i(u,v)),"Travessia da ponte bloqueada pela arte")
			if v<35: check(view.model.can_step(Vector2i(u,v),Vector2i(u,v+1)),"Arte alterou conexão da ponte")
	for u in range(25,39):
		for v in range(25,34):
			var cell: Dictionary = view.model.cell_at(Vector2i(u,v))
			if cell.material=="agua":
				check(not view.model.walkable(Vector2i(u,v)),"Água caminhável")
				check(view.parque_surfaces.shoreline.wet.has(Vector2i(u,v)),"Buraco no leito da água")
	check(view.model.cell_at(Vector2i(38,29)).material=="grama","Reentrância da margem não está no mapa lógico")
	check(view.parque_surfaces.water_material.shader.resource_path=="res://shaders/overworld/water_surface.gdshader","Água animada existente não foi reutilizada")
	print("PARQUE SURFACES: ",checks," verificações; ",failures.size()," falhas")
	for failure in failures: printerr(failure)
	quit(0 if failures.is_empty() else 1)
