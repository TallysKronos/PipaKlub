extends SceneTree
## Story duels (1 contra 1, encounter_model) played by tools/duel_bot.gd: win rate,
## average seconds and Kael's line left when he wins. Counterpart of duel_balance.gd.
##   godot --headless --path godot -s tools/story_balance.gd -- --level=+1 --skills=4,6,8 --runs=12
##   --only=Jamile,Faye   restricts by name; --assist=N simulates N losses in a row
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Levels = preload("res://scripts/campaign/partner_levels.gd")
const DuelBot = preload("res://tools/duel_bot.gd")
const Endgame = preload("res://scripts/campaign/endgame_story.gd")
const Ruinas = preload("res://scripts/campaign/ruinas_elo.gd")

func arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="): return a.trim_prefix("--" + name + "=")
	return fallback

## [name, modelId, level, extra] in campaign order (acts 4–6).
static func duels() -> Array:
	var out: Array = [["Mormaço", "mormaco-possuido", 27, ""], ["Tufanocorte", "tufanocorte", 29, "tufano"]]
	for id in ["trovareta", "reuniao", "barreira", "desalmado-centro", "desalmado-lajes", "galpao", "gollia-bando", "copa"]:
		if not Endgame.STEPS.has(id): continue
		for d in Endgame.STEPS[id].get("duels", []): out.append([d[0], d[1], d[2], ""])
	for scene in ["kronasta-aracati-c", "kronasta-coracao-a", "kronasta-coracao-b", "kronasta-coracao-c"]:
		var s: Array = Ruinas.STAGES[scene]
		out.append([s[0], s[1], s[2], "platyx" if scene == "kronasta-coracao-c" else ""])
	out.append([Ruinas.CHIEF[0], Ruinas.CHIEF[1], Ruinas.CHIEF[2], ""])
	var eremor: Array = Ruinas.STAGES["kronasta-coracao-d"]
	out.append([eremor[0], eremor[1], eremor[2], ""])
	for b in Ruinas.BRACKET: out.append([b[0], b[1], b[2], ""])
	return out

func _initialize() -> void:
	var offset := int(arg("level", "+1").trim_prefix("+"))
	var runs := int(arg("runs", "12"))
	var skills := Array(arg("skills", "4,6,8").split(",")).map(func(v): return int(v))
	var only := arg("only", "")
	print("| Duelo | Nv rival | Nv Kael | " + " | ".join(skills.map(func(k): return "bot %d (vitória · s · linha)" % k)) + " |")
	for d in duels():
		if not only.is_empty() and not d[0] in only.split(","): continue
		var level: int = int(d[2]) + offset
		var row := PackedStringArray()
		for skill in skills:
			var wins := 0
			var seconds := 0.0
			var left := 0.0
			for run in runs:
				var m := Model.new({"id": "p", "modelId": "rabbito", "xp": Levels.xp_for_level(level)}, {"modelId": d[1], "level": d[2]})
				m.q.boss = true
				if d[3] == "platyx": m.q.platyxRefusal = "pending"
				if d[3] == "tufano": m.duration = 150
				m.assist = int(arg("assist", "0"))
				seconds += DuelBot.play(m, skill, run * 7919 + skill)
				if m.outcome == "won":
					wins += 1
					left += m.p.hp / m.p.stats.line
			row.append("%d%% · %ds · %d%%" % [wins * 100 / runs, roundi(seconds / runs), roundi(left * 100 / maxi(wins, 1))])
		print("| %s | %d | %d | %s |" % [d[0], d[2], level, " | ".join(row)])
	quit()
