extends SceneTree
## Release build (QA off): every campaign place is reachable from the city map at the
## story point that opens it. Debug builds turn QA on, which hid places that were
## missing from the atlas (Centro, Condomínio, Porto Novo, Ruínas, Mirante, Estádio)
## and kept the Vila Operária as a preview (found by tools/campaign_walker.gd).
const Story = preload("res://scripts/campaign/kronasta_story.gd")
const Atlas = preload("res://scripts/campaign/kronasta_atlas.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func _initialize() -> void:
	Story.qa_override = 0
	# Every story region has a marker on the city map, entered by part A.
	for id in CP.REGIONS:
		var marker := Atlas.REGIONS.filter(func(r): return r.id == id)
		check(marker.size() == 1, "city map has a marker for " + id)
	# Story point → place that must open there (and the place the step happens in).
	var cases := {
		"aracati": "kronasta-aracati-a", "trovareta": "kronasta-bosque-a", "reuniao": "kronasta-centro-a",
		"noite": "kronasta-centro-a", "taina": "kronasta-lajes-a", "galpao": "kronasta-industrial-a",
		"porto": "kronasta-porto-a", "ruinas": "kronasta-coracao-a", "mirante": "kronasta-mirante-a", "final": "kronasta-estadio-a",
	}
	for jump in cases:
		var player: Dictionary = QA.build(jump).player
		check(Atlas.can_travel(cases[jump], player), "%s: city map reaches %s" % [jump, cases[jump]])
	# Vila Operária by day, after the Cais (act 3).
	var act3: Dictionary = QA.build("serra").player
	check(Atlas.can_travel("kronasta-industrial-a", act3), "Vila Operária open by day after the Cais")
	# Places stay closed before their step.
	var early: Dictionary = QA.build("serra").player
	for scene in ["kronasta-centro-a", "kronasta-lajes-a", "kronasta-porto-a", "kronasta-coracao-a", "kronasta-mirante-a", "kronasta-estadio-a"]:
		check(not Atlas.can_travel(scene, early), "closed at the start of act 4: " + scene)
	# Parts B/C are reached by walking, never by the map.
	check(not Atlas.can_travel("kronasta-centro-b", QA.build("reuniao").player), "map enters the Centro by part A only")
	# Non-story previews stay off in a release build.
	check(not Atlas.can_travel("gelo-a", act3), "Geleira stays a preview")
	# The pause map works indoors: travel from the workshop (found by the walker).
	var session = load("res://scripts/campaign/session.gd").new()
	session._store = load("res://scripts/campaign/save_store.gd").new("user://release-travel-" + load("res://scripts/campaign/state.gd").new_id())
	root.add_child(session)
	session.start("slot-1")
	var night: Dictionary = QA.build("noite").player
	check(session.checkpoint({"kind":"world","scene":"professor-home","position":[1056,1232]}, night).status == "ok", "in the workshop at night")
	check(load("res://scripts/campaign/bosque_campaign.gd").new(session).travel("kronasta-centro-a").status == "ok", "travel from the workshop to the Centro")
	check(session.snapshot().checkpoint.scene == "kronasta-centro-a", "arrives at the Centro")
	print("RELEASE TRAVEL: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
