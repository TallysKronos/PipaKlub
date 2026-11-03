extends SceneTree
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const Map = preload("res://scripts/campaign/park_checkpoint.gd")
const Finals = preload("res://scripts/campaign/ruinas_elo.gd")
const Scene := "kronasta-estadio-a"
const Point := Vector2(24.5,8.1)

func _initialize() -> void:
	var session := Session.new()
	var store := Store.new("user://stadium-check-"+State.new_id())
	session._store = store
	var player: Dictionary = State.fresh("slot-1").player
	player.partners = [{"id":"test","modelId":"basica","xp":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId = "test"
	var model = Map.model_for(Scene)
	if not verify(not model.point_walkable(Vector2(23.5,7.5)),"counter blocks walking"):return
	if not verify(not model.point_walkable(Vector2(18.5,13.5)),"bench blocks walking"):return
	if not verify(not model.path_to(Map.spawn(Scene),Point).is_empty(),"spawn to bracket"):return
	if not verify(not model.path_to(Point,Vector2(24.5,21.5)).is_empty(),"bracket to exit"):return
	var cp := Map.make(Scene,Point,Map.SPACE)
	if not verify(session.start("slot-1").status=="ok" and session.checkpoint(cp,player).status=="ok","open stadium fixture"):return
	if not verify(Finals.begin(session,Point).status=="wrong_step","require Mirante"):return
	player = session.snapshot().player
	Rules.award_emblem(player,"mirante")
	var entry: Dictionary = Rules.entry(player,"mirante")
	entry.completed = true
	entry.rewardClaimed = true
	entry.champion = "player"
	Rules.store(player,"mirante",entry)
	if not verify(session.checkpoint(cp,player).status=="ok","persist Mirante"):return
	for round in [0,1,1,2,3]:
		if not verify(Finals.begin(session,Point).status=="ok","start round "+str(round)):return
		session.close_session()
		if not verify(session.resume_slot("slot-1").status=="ok","resume encounter"):return
		var saved: Dictionary = session.snapshot()
		if not verify(saved.player.encounter.stadiumRound==round and saved.player.encounter.state.q.name==Finals.BRACKET[round][0],"correct opponent"):return
		var won: bool = round!=1 or saved.player.flags.get("testLostOnce",false)
		saved.player.flags.testLostOnce = round==1 or saved.player.flags.get("testLostOnce",false)
		saved.player.encounter.state.outcome = "won" if won else "lost"
		if not verify(session.checkpoint(saved.checkpoint,saved.player).status=="ok","persist outcome"):return
		if not verify(Finals.settle(session).status=="ok","settle"):return
		var flags: Dictionary = session.snapshot().player.flags
		if not verify(Finals.round_index(flags)==round+int(won),"advance only on victory"):return
		if not verify(flags.get("campeaoKronasta",false)==(round==3),"title only after Jamile"):return
	session.free()
	print("STADIUM: passed")
	quit()

func verify(ok: bool, label: String) -> bool:
	if not ok:
		printerr("FAIL: "+label)
		quit(1)
	return ok








