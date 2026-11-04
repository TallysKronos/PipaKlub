extends SceneTree
## F02 (MAPA-DE-REFINAMENTOS): Retalho's personal arc never holds the main objective.
## Refusing, leaving it for later or waiting for a bench slot keep the campaign on
## its next step (Mormaço), while the diary lists the arc as a side activity.
const State = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/campaign/kronasta_story.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

## Acts 1-3 done up to Remar, Retalho met in the Bosque, nothing else of the arc.
func base() -> Dictionary:
	var player: Dictionary = QA.build("serra").player
	for flag in ["retalhoAcolhido","assisReconheceuNoRetalho","mormacoVentosPararam","mormacoLiberto"]: player.flags.erase(flag)
	var rules = preload("res://scripts/campaign/district_rules.gd")
	var palafitas: Dictionary = rules.entry(player, "palafitas")
	palafitas.completed = false; palafitas.champion = "caio-garca"; palafitas.qualification = []
	rules.store(player, "palafitas", palafitas)
	return player

func arc(player: Dictionary) -> Dictionary:
	for quest in Story.optional_quests(player):
		if quest.title == "Retalho": return quest
	return {}

func _initialize() -> void:
	var cases := {
		"postponed": func(p): p.flags.assisReconheceuNoRetalho = true,
		"refused": func(p): p.flags.assisReconheceuNoRetalho = true; p.flags.retalhoRecusadoKael = true,
		"waiting for a bench slot": func(p): p.flags.assisReconheceuNoRetalho = true; p.flags.retalhoAceitoKael = true,
		"not yet at the workshop": func(p): pass,
	}
	for name in cases:
		var player := base()
		cases[name].call(player)
		check(Story.current_beat(player).get("id", "") == "mormaco-sinais", name + ": main step stays on the campaign (got " + str(Story.current_beat(player).get("id", "")) + ")")
		check(not Story.objective(player).begins_with("Arco pessoal") and Story.objective(player) != "Volte para casa.", name + ": HUD objective is the campaign")
		check(not arc(player).is_empty(), name + ": arc listed as a side activity")
	var refused := base(); refused.flags.assisReconheceuNoRetalho = true; refused.flags.retalhoRecusadoKael = true
	check(Story.optional_quests(refused).any(func(q): return q.title == "Heleana e Retalho" and q.text == "Volte para casa."), "refusal keeps the reunion at home as a side step")
	var welcomed := base(); welcomed.flags.assisReconheceuNoRetalho = true; welcomed.flags.retalhoAcolhido = true
	check(arc(welcomed).done, "welcomed arc shows as done")
	print("RETALHO OPTIONAL: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
