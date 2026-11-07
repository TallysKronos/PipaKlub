extends SceneTree
## F26 (MAPA-DE-REFINAMENTOS): the Mirante is the last district. The four challengers
## build the way up to Ícaro, Ícaro says why he accepts (distrust of the TV, what Kael
## did in the city) and his defeat points to the Estádio.
const Rules = preload("res://scripts/campaign/district_rules.gd")
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func said(lines: Array) -> String:
	return " ".join(lines.map(func(line): return line[1]))

func _initialize() -> void:
	var stages: Array = Rules.definition("mirante").stages
	var seen := {}
	for stage: Dictionary in stages:
		for key in ["before","won","lost"]:
			var text := said(stage[key])
			check(text != "Bom duelo. Pode seguir." and text != "Recupere a linha e tente de novo.", stage.id + " " + key + " has its own line")
			check(not seen.has(text), stage.id + " " + key + " is not repeated")
			seen[text] = true
	for index in 3:
		check(said(stages[index].won).contains(stages[index + 1].name), stages[index].id + " points to the next challenger")
	check(said(stages[3].before).contains("Ícaro") and said(stages[3].before).contains("título"), "Senael announces Ícaro's story")
	var icaro: Dictionary = stages[4]
	check(icaro.before.size() >= 3, "Ícaro presents himself over several lines")
	check(said(icaro.before).contains("TV"), "Ícaro distrusts the TV")
	check(said(icaro.before).contains("Ruínas") and said(icaro.before).contains("gerador"), "Ícaro recognizes what Kael did")
	check(said(icaro.before).contains("aceito"), "Ícaro says why he accepts")
	check(said(icaro.won).contains("Estádio") and said(icaro.won).contains("Jamile"), "defeat points to the Estádio and Jamile")
	# F25: arrival presents the course; after Ícaro the Mirante points to the Estádio.
	var Story = load("res://scripts/campaign/kronasta_story.gd")
	var QA = load("res://scripts/campaign/qa_jump.gd")
	var arrival: String = Story.region_objective(QA.build("mirante").player, "kronasta-mirante-a")
	check(arrival.contains("Ícaro") and arrival.contains("Vael"), "arrival presents the course and Ícaro")
	check(Story.region_objective(QA.build("final").player, "kronasta-mirante-c").contains("Estádio"), "after Ícaro the Mirante points to the Estádio")
	var view := FrontEnd.new()
	var joined: String = view._stage_lines(icaro.before, "Ícaro")
	check(joined.split("\n\n").size() == icaro.before.size() and not joined.begins_with("Ícaro:"), "all of Ícaro's lines shown without repeating the speaker")
	check(view._stage_lines([["Vael","a"],["Ilyra","b"]], "Vael") == "a\n\nIlyra: b", "another speaker keeps the name")
	view.free()
	print("MIRANTE STORY: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
