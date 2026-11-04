extends SceneTree
const Model=preload("res://scripts/campaign/morro_model.gd")
const Moves=preload("res://scripts/campaign/veskoro_moves.gd")
const State=preload("res://scripts/campaign/state.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func duel()->RefCounted:
	return Model.new({"id":"test","modelId":"rabbito","xp":Model.xp_for_level(27)},"palafitas-5")
func armed(cycle:int=1)->RefCounted:
	var m=duel();m.intro=0
	m.p.x=300;m.p.y=250;m.q.x=800;m.q.y=250
	m.veskoro.merge({"phase":"warn","elapsed":0.0,"cycle":cycle,"aimX":300.0,"aimY":250.0,"originX":800.0,"originY":250.0},true)
	return m
func _initialize()->void:
	var m=armed()
	check(m.enemy_model_id=="veskoro","Caio owns approved species")
	var hp:float=m.p.hp
	for i in 26:Moves.tick(m,m.veskoro,.05)
	check(m.p.hp==hp and m.veskoro.phase=="warn","warning never damages")
	var aim:float=m.veskoro.aimY
	m.p.y=400
	for i in 3:Moves.tick(m,m.veskoro,.05)
	check(m.p.hp==hp and m.veskoro.poisonTime==0 and m.veskoro.aimY==aim,"locked lane can be left")
	for mode:String in ["guard","evade","hit"]:
		m=armed();m.veskoro.elapsed=1.34
		m.p.guardTime=.3 if mode=="guard" else 0.0;m.p.evade=.3 if mode=="evade" else 0.0
		hp=m.p.hp;var hull:float=m.p.hull
		Moves.tick(m,m.veskoro,.05)
		check((m.p.hp==hp and m.veskoro.poisonTime==0) if mode!="hit" else (is_equal_approx(m.p.hp,hp-8) and m.veskoro.poisonTime==3),"impact "+mode)
		if mode=="hit":
			for i in 60:Moves.tick(m,m.veskoro,.05)
			check(is_equal_approx(m.p.hp,hp-14) and m.p.hull==hull,"one impact plus three bounded poison ticks; no hull damage")
			check(m.veskoro.poisonTime<.00001,"poison expires")
	m=armed(2)
	check(Moves.hits(m.veskoro,Vector2(300,250)) and not Moves.hits(m.veskoro,Vector2(300,330)),"cloud radius")
	m.veskoro.elapsed=1.34;m.p.x=450
	hp=m.p.hp;Moves.tick(m,m.veskoro,.05)
	check(m.p.hp==hp,"leave cloud safely")
	m=armed();m.veskoro.elapsed=.9
	var saved:Dictionary=JSON.parse_string(JSON.stringify(m.snapshot()))
	check(State.valid_morro_state(saved),"warning serializes and validates")
	var resumed:=Model.new();resumed.restore(saved)
	for i in 20:
		Moves.tick(m,m.veskoro,.05);Moves.tick(resumed,resumed.veskoro,.05)
	var same:bool=is_equal_approx(m.p.hp,resumed.p.hp)
	for key:String in m.veskoro:
		if m.veskoro[key] is float or m.veskoro[key] is int:same=same and is_equal_approx(float(m.veskoro[key]),float(resumed.veskoro[key]))
		else:same=same and m.veskoro[key]==resumed.veskoro[key]
	check(same,"suspension preserves impact timing without duplicate hit")
	var broken:Dictionary=saved.duplicate(true);broken.veskoro.elapsed=-1
	check(not State.valid_morro_state(broken),"negative timer rejected")
	broken=saved.duplicate(true);broken.veskoro.aimX=99999
	check(not State.valid_morro_state(broken),"out of field target rejected")
	broken=saved.duplicate(true);broken.veskoro.poisonTime=INF
	check(not State.valid_morro_state(broken),"nonfinite poison rejected")
	m._new_round()
	check(m.veskoro==Moves.fresh(),"new round clears poison and charge")
	m.set_enemy_model("mata")
	check(m.veskoro.is_empty(),"challenger cannot inherit Caio poison")
	check(not load("res://scripts/campaign/battle_ink.gd").facing_flip("veskoro",100,800) and load("res://scripts/campaign/battle_ink.gd").facing_flip("veskoro",800,100),"authored right facing tracks opponent")
	# Real combat loop: a level50 partner against level27, no terminal outcome injection.
	m=Model.new({"id":"trained","modelId":"rabbito","xp":Model.xp_for_level(50),"craftBonus":12},"palafitas-5")
	for i in 24000:
		if not m.outcome.is_empty():break
		var input:Dictionary=m._rival_input(m.p,1.0/60)
		if m.veskoro.phase=="warn":
			input.y=-1.0 if m.p.y>275 else 1.0
		input.signature=i%120==0
		m.tick(1.0/60,input)
	check(m.outcome=="won","scripted trained partner wins full three-round duel: "+m.outcome)
	print("VESKORO: %d checks; %d failures; full scripted combat win plus targeted mechanics fixtures"%[checks,failures])
	quit(0 if failures==0 else 1)
