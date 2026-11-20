extends SceneTree
## BIBLIA §8: Kael's level follows the rivals' curve. Found with real duels
## (tools/campaign_walker.gd --fight, tools/duel_balance.gd): story duels paid no XP
## while the result card promised some, and the authored district XP left Kael near
## Lv.23 at the Mirante, whose champion is Lv.44.
const Levels = preload("res://scripts/campaign/partner_levels.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const District = preload("res://scripts/campaign/district_campaign.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const Rewards = preload("res://scripts/campaign/hud_rewards.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func player_at(level: int) -> Dictionary:
	return {"equippedPartnerId": "p", "partners": [{"id": "p", "modelId": "rabbito", "xp": Levels.xp_for_level(level)}], "tamerXp": 0, "flags": {}}

func _initialize() -> void:
	# The rule: more when behind, less when ahead, never zero.
	check(Levels.win_xp(30, 27, "story") > Levels.win_xp(30, 30, "story"), "behind earns more")
	check(Levels.win_xp(30, 33, "story") < Levels.win_xp(30, 30, "story") and Levels.win_xp(30, 45, "story") > 0, "ahead earns less, never zero")
	check(Levels.win_xp(18, 18, "champion") > Levels.win_xp(18, 18, "lieutenant"), "champions pay more than lieutenants")
	# Story duels pay, and the result card shows what is credited.
	var player := player_at(40)
	var model := Model.new(player.partners[0], {"modelId": "lacertubo", "level": 45})
	model.outcome = "won"
	var state: Dictionary = model.snapshot()
	var shown: int = Rewards.preview(player, {"kind": "ruinas-elo"}, model).xp
	var before := int(player.partners[0].xp)
	var credited := Progression.story_win(player, state)
	check(credited > 0 and int(player.partners[0].xp) == before + credited, "a won story duel credits XP")
	check(shown == credited, "result card shows the credited XP (%d vs %d)" % [shown, credited])
	# Walk every championship duel in order, Kael starting Lv.14 after the Morro: the
	# championship alone keeps him close to each champion (story duels add on top).
	var me := player_at(14)
	var worst := 99
	var best := -99
	for d in Rules.catalog():
		if d.id == "morro": continue
		for st in d.stages:
			if not st.get("authored", false): continue
			var ctx := {"district": d.id, "duel": st.id, "mode": "normal"}
			var xp: int = District.reward(me, ctx, "won").xp
			Progression.award(me, me.partners[0], xp)
			if str(st.get("role", "")) == "champion":
				var gap := Levels.level_for_xp(int(me.partners[0].xp)) - int(st.level)
				worst = mini(worst, gap); best = maxi(best, gap)
	check(worst >= -6, "never far behind a champion (worst %+d)" % worst)
	check(best <= 4, "never far ahead of a champion (best %+d)" % best)
	# A lost championship duel still moves Kael forward (30% of the win).
	var ctx_champion := {"district": "lajes", "duel": "lajes-5", "mode": "normal"}
	var at36 := player_at(36)
	var lost_xp: int = District.reward(at36, ctx_champion, "lost").xp
	check(lost_xp > 20 and lost_xp == roundi(District.reward(at36, ctx_champion, "won").xp * .3), "a loss pays 30%% of the win (%d)" % lost_xp)
	# Rival skill climbs across the acts instead of peaking at Lv.14.
	var Trail = preload("res://scripts/campaign/morro_model.gd")
	check(Trail.district_ai({"level": 12, "role": "lieutenant"}) < Trail.district_ai({"level": 33, "role": "lieutenant"}), "rivals read better later in the campaign")
	check(Trail.district_ai({"level": 15, "role": "lieutenant"}) <= 4, "act 2 rivals are not the perfect reader")
	check(Trail.district_ai({"level": 44, "role": "champion"}) > Trail.district_ai({"level": 44, "role": "lieutenant"}), "champions read better than lieutenants")
	check(Trail.district_ai({"level": 50, "role": "champion"}) <= 10, "skill capped")
	print("XP CURVE: %d checks; %d failures (gaps %+d..%+d)" % [checks, failures, worst, best])
	quit(1 if failures else 0)
