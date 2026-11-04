extends SceneTree
const Rules = preload("res://scripts/campaign/morro_rules.gd")
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr(message)
func _initialize() -> void:
	var cases: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/morro.json"))
	for entry in cases:
		var actual := Rules.settle(entry.progress, entry.id, entry.won, int(entry.roundsLost))
		check(JSON.parse_string(JSON.stringify(actual)) == entry.result, "Original rule mismatch: " + JSON.stringify(entry))
	var progress := Rules.defaults()
	check(Rules.unlocked(progress, "morro-1"), "First stage available")
	check(not Rules.unlocked(progress, "morro-2"), "Second stage gated")
	for id in Rules.IDS:
		check(Rules.unlocked(progress, id), "Previous victory opens next stage")
		progress = Rules.settle(progress, id, true).progress
	check(progress.items == [Rules.DROP], "Leader tail unique")
	check(Rules.stage("morro-3").foes.size() == 2, "Simultaneous opponents preserved")
	check(Rules.content().stories["morro-5"].won.size() == 1, "Demo ending preserved")
	print("Morro: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

