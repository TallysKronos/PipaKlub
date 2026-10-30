extends "res://tools/park_flow_refinement_review.gd"
func run() -> void:
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../documentation/campaign/lacertubo-flow")
	DirAccess.make_dir_recursive_absolute(output)
	front=load("res://scripts/campaign/front_end.gd").new()
	var temporary=ProjectSettings.globalize_path("res://../tmp/lacertubo-review-"+State.new_id())
	front.session._store=load("res://scripts/campaign/save_store.gd").new(temporary)
	front.preferences.storage_path=temporary+"-settings.cfg"
	front.preferences.reduced_motion=false
	root.add_child(front)
	check(front.session.start("slot-1").status=="ok","isolated session")
	var boss:=Checkpoint.target("park-veredas","boss")
	var model=Checkpoint.model_for("park-veredas")
	for event in model.data.events+Training.events("veredas-do-encanamento",model):
		if event.type=="npc" and event.props.get("acao","")!="parkBoss":
			check(Vector2(event.u+.5,event.v+.5).distance_to(boss)>=16,"human NPC outside boss staging")
	check(not model.data.events.any(func(e):return e.name=="Nina"),"Nina stays in Jardim")
	await place("park-veredas",boss+Vector2(0,5),1260)
	front.park._physics_process(.016)
	for i in 90: await process_frame
	check(dialog()!=null and front.park.guardian_focus,"approach opens presentation and focuses guardian")
	check(front.session.snapshot().player.flags.get("lacertuboIntroduced",false),"presentation persists")
	await shot("01-apresentacao")
	await close_dialog()
	for i in 60: await process_frame
	check(not front.park.paused and not front.park.guardian_focus,"dismiss restores player control")
	check(front.park.camera.position.distance_to(model.project(front.park.player))<1,"camera returns to Kael")
	front.park._physics_process(.016)
	check(dialog()==null,"presentation does not repeat")
	await shot("02-aproximacao-sem-npcs")
	# Move within actual interaction radius, preserving the introduced flag.
	var saved=front.session.snapshot()
	front.session.checkpoint(Checkpoint.make("park-veredas",boss,Checkpoint.SPACE),saved.player)
	front._show_saved()
	for i in 180:
		await process_frame
		if is_instance_valid(front.park) and not front.flow_busy: break
	front.park.set_physics_process(false)
	front._park_action("boss")
	check(dialog()!=null and dialog().dialog_text.contains("Nv. 8"),"explicit boss choice keeps level warning")
	await shot("03-escolha-confronto")
	await close_dialog()
	check(front.encounters.start_boss(front.park.player).status=="ok","boss can start at its position")
	var held=front.session.snapshot().player.encounter
	var state=held.state
	state.outcome="won"
	check(front.encounters.save_battle(state).status=="ok" and front.encounters.settle().status=="ok","post-battle fixture settles via services")
	front._show_saved()
	for i in 180:
		await process_frame
		if is_instance_valid(front.park) and not front.flow_busy: break
	front.park.set_physics_process(false)
	var shortcut={}
	for event in model.data.events:
		if int(event.id)==1100: shortcut=event
	check(not Checkpoint.allowed(shortcut,front.session.snapshot().player),"shortcut waits for quest item")
	check(not front.park.npc_nodes.any(func(a):return a.root.visible and a.point.distance_to(boss)<8),"boss arena empty after victory")
	await shot("04-rabiola-apos-vitoria")
	var tail:=Checkpoint.target("park-veredas","tail")
	var current=front.session.snapshot()
	front.session.checkpoint(Checkpoint.make("park-veredas",tail,Checkpoint.SPACE),current.player)
	check(front.exploration.collect_tail(tail).status=="ok","tail collected separately")
	check(Checkpoint.allowed(shortcut,front.session.snapshot().player),"shortcut now available")
	check(Training.objective(front.session.snapshot().player,"park-veredas").contains("atalho"),"return objective names shortcut")
	var report={"checks":checks,"failures":failures,"isolatedSave":true,"combatOutcome":"synthetic here; real combat covered by journey/integration suite"}
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("LACERTUBO FLOW: ",JSON.stringify(report))
	quit(1 if failures else 0)
