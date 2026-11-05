extends SceneTree
## F33: the opponent named in a district duel's dialogue is the one the battle shows.
## (Feira used Beira-Canal's names, Dona Zulmira fought as "Kleie".) Pair duels
## (Morro 3: Juninho e Lia) list each member.
const Rules = preload("res://scripts/campaign/district_rules.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func _initialize() -> void:
	var seen := {}
	for district: Dictionary in Rules.catalog():
		for stage: Dictionary in Rules.definition(district.id).stages:
			var foes: Array = stage.get("foes", [])
			if foes.is_empty(): continue
			var names: Array = foes.map(func(f): return str(f.get("name", "")))
			check(foes.size() > 1 and names.all(func(n): return stage.name.contains(n)) or names[0] == stage.name, "%s: battle shows %s, dialogue says %s" % [stage.id, str(names), stage.name])
			check(not seen.has(stage.name) or seen[stage.name] == district.id, "%s: the name %s belongs to %s" % [stage.id, stage.name, str(seen.get(stage.name, ""))])
			seen[stage.name] = district.id
	print("DISTRICT NAMES: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
