extends SceneTree
const Rules = preload("res://scripts/campaign/district_rules.gd")
const State = preload("res://scripts/campaign/state.gd")
const Service = preload("res://scripts/campaign/district_campaign.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL "+label)
func _initialize() -> void:
	var district := Rules.definition("industrial")
	check(not district.playable, "story remains unavailable until maps and warehouse exist")
	check(district.prerequisiteFlag == "pipaDragaoDesatadaVencida", "warehouse result gates champion")
	check(district.stages.map(func(s):return s.npcId) == ["vasken","rivka","odrik","teyra","bruno-solda"], "approved cast order")
	check(district.stages.map(func(s):return s.part) == ["A","A","B","B","C"], "neighborhood structure")
	check(district.stages.map(func(s):return int(s.level)) == [21,22,22,23,24], "level curve inside bible range")
	for stage: Dictionary in district.stages:
		check(FileAccess.file_exists(stage.storySpritePath), "sprite exists "+stage.id)
		check(stage.authored and not Service.stage(stage.id).is_empty(), "authored preview duel "+stage.id)
		for field: String in ["before","won","lost"]:
			check(stage[field].size() == 1 and stage[field][0] is Array and stage[field][0].size() == 2 and stage[field][0][0] == stage.name and str(stage[field][0][1]).length()>20, "dialogue pair "+stage.id+" "+field)
	var player: Dictionary = State.fresh("slot-1").player
	check(not Rules.unlocked(player,"industrial"), "no entry before Cais victory")
	var prior := Rules.fresh("cais")
	prior.completed=true; prior.rewardClaimed=true; prior.champion="player"
	Rules.store(player,"cais",prior)
	check(Rules.unlocked(player,"industrial"), "Cais history qualifies next district")
	check(Rules.prepare(player,"industrial","industrial-2").status=="wrong_step", "cannot skip first opponent")
	for i in 4:
		var id := "industrial-"+str(i+1)
		var planned := Rules.prepare(player,"industrial",id)
		check(planned.status=="ok", "plan "+id)
		var lost := Rules.settle(player,planned.context,"lost")
		check(lost.status=="ok" and not lost.firstClear and Rules.entry(lost.player,"industrial").qualification==Rules.entry(player,"industrial").qualification, "loss does not qualify "+id)
		var fled := Rules.settle(player,planned.context,"fled")
		check(fled.status=="ok" and not fled.firstClear and Rules.entry(fled.player,"industrial").qualification==Rules.entry(player,"industrial").qualification, "flee does not qualify "+id)
		var result := Rules.settle(player,planned.context,"won")
		check(result.status=="ok" and result.firstClear, "win qualifies "+id)
		player=result.player
		check(Rules.settle(player,planned.context,"won").status!="ok", "stale result cannot repeat "+id)
	check(Rules.status(player,"industrial")=="prerequisite", "four victories still wait for warehouse")
	check(Rules.prepare(player,"industrial","industrial-5").status=="wrong_step", "Bruno cannot bypass warehouse")
	player.flags.pipaDragaoDesatadaVencida=true
	var final := Rules.prepare(player,"industrial","industrial-5")
	check(final.status=="ok", "warehouse result permits champion")
	var won := Rules.settle(player,final.context,"won")
	player=won.player
	check(won.firstDistrict and Rules.completed(player,"industrial"), "first championship victory")
	var stored: Dictionary=JSON.parse_string(JSON.stringify(player))
	check(Rules.valid(stored.championship) and Rules.status(stored,"industrial")=="won", "title survives JSON serialization")
	var challenge := Rules.offer(stored,"industrial","vasken","test-defense","kronasta-industrial-a")
	check(challenge.status=="ok", "approved opponent can challenge champion")
	player=challenge.player
	var defense := Rules.prepare(player,"industrial","industrial-5","test-defense")
	check(defense.status=="ok", "defense prepared")
	var defeat := Rules.settle(player,defense.context,"lost")
	player=defeat.player
	check(Rules.entry(player,"industrial").champion=="vasken" and Rules.entry(player,"industrial").qualification.is_empty(), "lost title goes to challenger and resets qualification")
	check(Rules.completed(player,"industrial") and Rules.status(player,"industrial")=="requalifying", "history retained and four opponents required again")
	print("VILA OPERARIA DEFINITION: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
