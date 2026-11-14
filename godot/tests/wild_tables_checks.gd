extends SceneTree
## Wild encounter tables (assets/campaign/encounters.json): weights, species with battle art,
## the approved plan per region, and saves of wild duels in every Kronasta region (Cais and
## later regions failed validation and never started before 08/11).
const Tables = preload("res://scripts/campaign/wild_tables.gd")
const State = preload("res://scripts/campaign/state.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Pacing = preload("res://scripts/campaign/park_pacing.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func _initialize() -> void:
	var data := Tables.data()
	var never: Array = data.nuncaSelvagem
	# Battle art: the original species (LEGACY) or a content.json "combat" entry (Planícies, 11/11).
	var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json")).combat
	for id: String in data.regioes:
		var region: Dictionary = data.regioes[id]
		var total := 0
		for row in region.encontros:
			total += int(row.peso)
			check(row.modelo in Tables.LEGACY or combat.has(str(row.modelo)), id + " uses a species with battle art: " + str(row.modelo))
		check(total == 100, id + " weights add up to 100")
		var plan: Dictionary = region.planejado
		var keys: Array = []
		for role in plan: keys.append_array(plan[role] if plan[role] is Array else [plan[role]])
		for k in keys: check(str(k).split(":")[0] not in never, id + " plans no story-only creature: " + str(k))
		if id not in ["kronasta-caverna", "caverna-mural"]: check(plan.get("comuns", []).size() == 3, id + " plans three common families")
	# Same draws as before the tables.
	check(Tables.choose("kronasta-bambuzal-a", 0, false) == "rascunho-bicho-pau" and Tables.choose("kronasta-bambuzal-a", .5, false) == "mata" and Tables.choose("kronasta-bambuzal-a", .9, false) == "rascunho-joaninha", "Bambuzal keeps its pool")
	check(Tables.choose("kronasta-beira-canal-b", .7, true) == "lacertubo", "Beira-Canal keeps the young Lacertubo, first encounter included")
	check(Tables.choose("kronasta-cais-a", .7, true) == "mata" and Tables.choose("kronasta-cais-a", .9, false) == "raio", "generic table and the tutorial first encounter")
	# Every Kronasta scene with grass accepts its own wild duel.
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/index.json"))
	for scene: String in index.scenes:
		if not scene.begins_with("kronasta-"): continue
		for roll in 3:
			var species := Tables.choose(scene, roll / 3.0 + .1, false)
			var level := Pacing.wild_level(scene, roll)
			var m := Model.new({"id": "p", "modelId": "rabbito", "xp": 9000}, {"modelId": species, "level": level})
			var e := {"id": "x", "kind": "wild", "scene": scene, "space": "parque-overworld-v1", "dropRoll": .5, "returnPoint": [1, 1], "state": m.snapshot(), "rewardXp": 10}
			check(State.valid_encounter(e), scene + " accepts its wild duel (" + species + " Nv." + str(level) + ")")
	var bad := Model.new({"id": "p", "modelId": "rabbito", "xp": 9000}, {"modelId": "eremor", "level": 30})
	check(not State.valid_encounter({"id": "x", "kind": "wild", "scene": "kronasta-cais-a", "space": "parque-overworld-v1", "dropRoll": .5, "returnPoint": [1, 1], "state": bad.snapshot(), "rewardXp": 10}), "a story creature is never a valid wild duel")
	var high := Model.new({"id": "p", "modelId": "rabbito", "xp": 9000}, {"modelId": "mata", "level": 40})
	check(not State.valid_encounter({"id": "x", "kind": "wild", "scene": "kronasta-cais-a", "space": "parque-overworld-v1", "dropRoll": .5, "returnPoint": [1, 1], "state": high.snapshot(), "rewardXp": 10}), "a level above the region's band is refused")
	print("WILD TABLES: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
