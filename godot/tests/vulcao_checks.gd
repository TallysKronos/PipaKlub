extends SceneTree
## Vulcão de Kronasta · Caldeira (10/11/2026): mapa de lava registrado como região de
## exploração. Confere registro, tamanho, andares, lava não andável e alcance de tudo.
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Atlas = preload("res://scripts/campaign/kronasta_atlas.gd")
const State = preload("res://scripts/campaign/state.gd")

var failures := 0

func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL ", text)

func _initialize() -> void:
	var scene := "vulcao-a"
	check(CP.MAPS.has(scene), "cena registrada")
	check(CP.is_regional_preview(scene) and not CP.is_kronasta(scene), "região de exploração")
	var map := CP.data(scene)
	check(int(map.w) == 64 and int(map.h) == 56, "mapa grande 64×56")
	check(bool(map.forest.get("lava", false)), "bioma de lava")
	var top := 0
	var lava := 0
	for cell in map.cells:
		top = maxi(top, int(cell.level))
		if cell.material == "agua": lava += 1
	check(top >= 6, "sete andares (nível máximo %d)" % top)
	check(lava > 800, "lava cobre a base (%d células)" % lava)
	var model = CP.model_for(scene)
	var start := CP.spawn(scene)
	check(model.point_walkable(start), "chegada andável")
	# A lava não é chão: nenhuma célula de lava é andável.
	var walked_lava := 0
	for v in int(map.h):
		for u in int(map.w):
			if model.cell_at(Vector2i(u, v)).material == "agua" and model.point_walkable(Vector2(u + .5, v + .5)): walked_lava += 1
	check(walked_lava == 0, "lava não é andável (%d células)" % walked_lava)
	var items := 0
	for event in map.events:
		if event.type == "entrada": continue
		if event.type == "item": items += 1
		var at := Vector2(event.u + .5, event.v + .5)
		check(not model.path_to(start, at).is_empty(), "alcança " + str(event.name) + " em " + str(at))
	check(items >= 6, "achados para explorar (%d)" % items)
	# Quedas de lava: cada uma sai de células de lava na borda de um terraço e cai de verdade.
	var falls: Array = map.forest.get("lavaFalls", [])
	check(falls.size() >= 3, "quedas de lava (%d)" % falls.size())
	for fall in falls:
		for i in int(fall.width):
			var lip: Dictionary = model.cell_at(Vector2i(int(fall.u) + i, int(fall.v)))
			var below: Dictionary = model.cell_at(Vector2i(int(fall.u) + i, int(fall.v) + 1))
			check(lip.material == "agua" and int(lip.level) - int(below.get("level", 0)) == int(fall.drop), "queda em %d,%d cai %d níveis" % [int(fall.u) + i, int(fall.v), int(fall.drop)])
	var region: Dictionary = {}
	for entry in Atlas.REGIONS:
		if entry.id == "vulcao": region = entry
	check(region.get("scenes", []) == [scene] and region.get("preview", false), "atlas aponta para a caldeira")
	# Gravação real: o save aceita a cena e a posição.
	var session = load("res://scripts/campaign/session.gd").new()
	root.add_child(session)
	session._store = load("res://scripts/campaign/save_store.gd").new("user://vulcao-" + State.new_id())
	check(session.start("slot-1").status == "ok", "slot isolado")
	var player: Dictionary = session.snapshot().player
	player.partners = [{"id": "p", "modelId": "rabbito", "xp": 0, "craftBonus": 0}]
	player.equippedPartnerId = "p"
	player.journey = {"phase": "complete", "lesson": 5}
	check(session.checkpoint(CP.make(scene, start, CP.SPACE), player).status == "ok", "save aceita a cena")
	print("vulcao_checks: ", "OK" if failures == 0 else str(failures) + " falhas")
	quit(1 if failures else 0)
