extends SceneTree
## Playtest coherence: Nina is not in the Jardim while she is held in the Ruínas, and the
## idle talk of Nina and Tyler follows the story and alternates between visits.
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func _initialize() -> void:
	var nina := {"id": 8243, "type": "npc", "name": "Nina", "u": 10, "v": 32, "props": {"fala": "nina-jardim-proposta", "missao": "nina"}}
	var before: Dictionary = QA.build("serra").player
	var held: Dictionary = QA.build("ruinas").player
	var freed: Dictionary = QA.build("rato").player
	check(CP.allowed(nina, before, "park-trail"), "Nina in the Jardim before the kidnapping")
	check(not CP.allowed(nina, held, "park-trail"), "Nina absent from the Jardim while held in the Ruínas")
	check(CP.allowed(nina, freed, "park-trail"), "Nina back in the Jardim once freed")
	var view := FrontEnd.new()
	var a: String = view._idle_line("nina", view._nina_lines(before))
	var b: String = view._idle_line("nina", view._nina_lines(before))
	check(a != b, "Nina alternates her idle line")
	check(view._idle_line("nina", view._nina_lines(before)) == a, "and cycles back")
	check(view._nina_lines(freed)[0].contains("Ruínas") or view._nina_lines(freed)[0].contains("descido"), "after the rescue Nina remembers it")
	var champion: Dictionary = QA.build("final").player
	champion.flags.campeaoKronasta = true
	check(view._nina_lines(champion)[0].contains("Campeão") and view._tyler_lines(champion)[0].contains("Campeão"), "the title changes the talk")
	check(view._tyler_lines(freed)[0].contains("laboratório"), "Tyler remembers the laboratory after the record")
	for lines in [view._nina_lines(before), view._nina_lines(held), view._nina_lines(freed), view._tyler_lines(before), view._tyler_lines(freed), view._tyler_lines(champion)]:
		check(not "\n".join(lines).contains("pipa que eu estava construindo"), "no promise that never pays off")
	view.free()
	print("IDLE LINES: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
