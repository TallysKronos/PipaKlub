extends SceneTree
const View = preload("res://scripts/overworld/view.gd")
var failures: Array[String] = []
var checks := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var view := View.new()
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
		if str(node.name).begins_with("AguaRebaixada") or node.z_index == -3:
			water_count += 1
			var water: Polygon2D = node.get_child(0)
			check(is_equal_approx(water.polygon[0].y,18),"Água voltou ao nível do chão")
			check(node.z_index < -1,"Água cobre ponte ou terreno")
		if str(node.name).begins_with("MargemDoLeito"): bank_count += 1
	check(deck_count==2,"Deveriam existir duas pontes inteiras, sem tabuleiros por célula")
	check(water_count>30,"Leito não cobre o riacho e a água sob as pontes")
	check(bank_count>0,"Margens sem faces de profundidade")
	for u in [27,32]:
		for v in range(23,36):
			check(view.model.walkable(Vector2i(u,v)),"Travessia da ponte bloqueada pela arte")
			if v<35: check(view.model.can_step(Vector2i(u,v),Vector2i(u,v+1)),"Arte alterou conexão da ponte")
	for u in range(25,39):
		for v in range(25,34):
			var cell: Dictionary = view.model.cell_at(Vector2i(u,v))
			check(cell.material in ["agua","ponte"],"Chão seco restante na vala")
			if cell.material=="agua": check(not view.model.walkable(Vector2i(u,v)),"Água caminhável")
	check(view.parque_surfaces.water_material.shader.resource_path=="res://shaders/overworld/water_surface.gdshader","Água animada existente não foi reutilizada")
	print("PARQUE SURFACES: ",checks," verificações; ",failures.size()," falhas")
	for failure in failures: printerr(failure)
	quit(0 if failures.is_empty() else 1)
