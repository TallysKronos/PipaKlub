extends SceneTree
## Calibra a leitura (ai_level) de cada duelo de bairro contra uma curva-alvo de vitória
## com o Kael 1 nível acima do rival, e imprime JSON {stage: ai} para gravar em
## districts.json ("ai"). A taxa é a média do bot 4 (jogador casual) e do bot 6 (atento):
## só com o bot 6 a curva subia o Bambuzal da leitura 2 para a 5, porque entre a 5 e a 6
## o bot 6 cai de 100% para perto de zero.
##   godot --headless --path godot -s tools/district_calibration.gd -- --runs=16 --stages=all
## Alvo: tenentes 90% (Nv.9) → 65% (Nv.43); campeões 80% (Nv.12) → 50% (Nv.44).
const Model = preload("res://scripts/campaign/morro_model.gd")
const Levels = preload("res://scripts/campaign/partner_levels.gd")
const DuelBot = preload("res://tools/duel_bot.gd")

func arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="): return a.trim_prefix("--" + name + "=")
	return fallback

static func target(entry: Dictionary) -> float:
	var level := int(entry.level)
	if str(entry.get("role", "")) == "champion": return lerpf(.8, .5, clampf((level - 12) / 32.0, 0, 1))
	return lerpf(.9, .65, clampf((level - 9) / 34.0, 0, 1))

func rate(stage: String, ai: int, runs: int, skill: int) -> float:
	var entry := Model.stage_definition(stage)
	var wins := 0
	for run in runs:
		var m := Model.new({"id": "p", "modelId": "rabbito", "xp": Levels.xp_for_level(int(entry.level) + 1)}, stage)
		m.ai_level = ai
		DuelBot.play(m, skill, run * 7919 + skill)
		if m.outcome == "won": wins += 1
	return float(wins) / runs

func _initialize() -> void:
	var runs := int(arg("runs", "16"))
	var wanted := arg("stages", "all")
	var stages := PackedStringArray()
	for d in preload("res://scripts/campaign/district_rules.gd").catalog():
		for st in d.stages:
			if st.get("authored", false) and not str(st.id).begins_with("morro-") and (wanted == "all" or st.id in wanted.split(",")): stages.append(st.id)
	var result := {}
	for stage in stages:
		var entry := Model.stage_definition(stage)
		var goal := target(entry)
		var ai := Model.district_ai_formula(entry)
		var seen := {}
		while not seen.has(ai):
			seen[ai] = (rate(stage, ai, runs, 4) + rate(stage, ai, runs, 6)) / 2
			if seen[ai] > goal and ai < 10: ai += 1
			elif seen[ai] < goal and ai > 1: ai -= 1
			else: break
		var best := ai
		for k in seen:
			if absf(seen[k] - goal) < absf(seen[best] - goal) or (absf(seen[k] - goal) == absf(seen[best] - goal) and k > best): best = k
		result[stage] = best
		printerr("%s alvo %d%% → ai %d (%d%%) testados %s" % [stage, roundi(goal * 100), best, roundi(seen[best] * 100), str(seen)])
	print("CALIBRACAO " + JSON.stringify(result))
	quit()
