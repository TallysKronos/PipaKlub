extends SceneTree
## Win rate of Kael's Rabbito against each district duel, played by tools/duel_bot.gd.
##   godot --headless --path godot -s tools/duel_balance.gd -- --stages=bambuzal-1,bambuzal-4 --level=14 --skills=3,5,7 --runs=20
const Model = preload("res://scripts/campaign/morro_model.gd")
const Levels = preload("res://scripts/campaign/partner_levels.gd")
const DuelBot = preload("res://tools/duel_bot.gd")

func arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="): return a.trim_prefix("--" + name + "=")
	return fallback

func _initialize() -> void:
	var level := int(arg("level", "14").trim_prefix("+"))
	var runs := int(arg("runs", "20"))
	var skills := Array(arg("skills", "3,5,7").split(",")).map(func(v): return int(v))
	var model_id := arg("model", "rabbito")
	print("| Duelo | Nv Kael | Nv rival | " + " | ".join(skills.map(func(k): return "bot %d" % k)) + " |")
	var wanted := arg("stages", "all")
	var stages := PackedStringArray()
	if wanted == "all":
		for d in preload("res://scripts/campaign/district_rules.gd").catalog():
			for st in d.stages:
				if st.get("authored", false) and not str(st.id).begins_with("morro-"): stages.append(st.id)
	else: stages = wanted.split(",")
	# --level=+N: Kael N levels above each rival (the walker sees Kael ~2-5 above).
	var relative := arg("level", "14").begins_with("+")
	for stage in stages:
		if relative: level = int(Model.stage_definition(stage).get("level", 1)) + int(arg("level", "+2").trim_prefix("+"))
		var row := PackedStringArray()
		var foe := 0
		for skill in skills:
			var wins := 0
			for run in runs:
				var partner := {"id": "p", "modelId": model_id, "xp": Levels.xp_for_level(level)}
				var m := Model.new(partner, stage)
				foe = int(m.q.get("level", 0))
				DuelBot.play(m, skill, run * 7919 + skill)
				if m.outcome == "won": wins += 1
			row.append("%d%%" % (wins * 100 / runs))
		print("| %s | %d | %d | %s |" % [stage, level, foe, " | ".join(row)])
	quit()
