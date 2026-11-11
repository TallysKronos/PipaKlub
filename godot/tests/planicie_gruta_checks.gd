extends SceneTree
## Planícies de Kronasta (A–C) e Gruta do Moinho (A–C), 11/11/2026: saídas em lados
## diferentes, a gruta ligando as Colinas do Moinho ao vale escondido do Vale das Pedras,
## tudo alcançável e baús que abrem.
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const SCENES := ["planicie-a", "planicie-b", "planicie-c", "caverna-a", "caverna-b", "caverna-c"]

var failures := 0

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)

func side(map: Dictionary, event: Dictionary) -> String:
	if int(event.u) == 0: return "oeste"
	if int(event.u) == int(map.w) - 1: return "leste"
	if int(event.v) == 0: return "norte"
	if int(event.v) == int(map.h) - 1: return "sul"
	return "interior"

func _initialize() -> void:
	var links := {}
	for scene in SCENES:
		check(CP.MAPS.has(scene) and CP.is_regional_preview(scene), scene + " registrada")
		var map := CP.data(scene)
		var model = CP.model_for(scene)
		var start := CP.spawn(scene)
		var sides := {}
		for event in map.events:
			if event.type == "entrada": continue
			var at := Vector2(event.u + .5, event.v + .5)
			check(not model.path_to(start, at).is_empty(), scene + ": alcança " + str(event.name))
			if event.type != "saida": continue
			sides[side(map, event)] = true
			var destination: String = event.props.get("destino", "")
			if destination == "kronasta": continue
			links[scene + ">" + destination] = true
			var target := CP.exit_target({"kind": "world", "scene": scene, "position": [at.x, at.y], "space": CP.SPACE}, str(int(event.id)), {"flags": {}})
			check(target.get("status", "") == "ok" and target.scene == destination, scene + ": " + str(event.name) + " leva a " + destination)
			if target.get("status", "") == "ok":
				check(CP.model_for(destination).point_walkable(target.point), scene + " → " + destination + ": chega andando em " + str(target.point))
		check(sides.size() >= 2, scene + ": saídas em lados diferentes " + str(sides.keys()))
		for piece in map.pieces:
			if piece.asset != "bau": continue
			var ok := false
			for d in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
				var near: Vector2 = Vector2(piece.u + .5, piece.v + .5) + d
				if model.point_walkable(near) and not model.path_to(start, near).is_empty(): ok = true
			check(ok, scene + ": baú alcançável em %d,%d" % [int(piece.u), int(piece.v)])
	# Toda ligação tem volta, e a gruta fecha o circuito Colinas → gruta → vale escondido.
	for key in links:
		var pair: PackedStringArray = str(key).split(">")
		check(links.has(pair[1] + ">" + pair[0]), "volta de " + pair[1] + " para " + pair[0])
	for key in ["planicie-b>caverna-a", "caverna-a>caverna-b", "caverna-b>caverna-c", "caverna-c>planicie-c", "planicie-a>planicie-c", "planicie-b>planicie-c"]:
		check(links.has(key), "ligação " + key)
	print("planicie_gruta_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)
