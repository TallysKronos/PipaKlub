extends "res://tools/park_flow_refinement_review.gd"
func run() -> void:
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../documentation/overworld/veredas-refinement-v1")
	DirAccess.make_dir_recursive_absolute(output)
	front=load("res://scripts/campaign/front_end.gd").new()
	var temporary=ProjectSettings.globalize_path("res://../tmp/veredas-art-"+State.new_id())
	front.session._store=load("res://scripts/campaign/save_store.gd").new(temporary)
	front.preferences.storage_path=temporary+"-settings.cfg"
	front.preferences.reduced_motion=true
	root.add_child(front)
	check(front.session.start("slot-1").status=="ok","isolated save")
	await place("park-veredas",Checkpoint.target("park-veredas","boss")+Vector2(0,5),1260)
	if dialog()!=null: await close_dialog()
	for i in 3: await process_frame
	front.park.set_physics_process(false)
	check(front.park.clareira_terrain!=null,"continuous Veredas material loaded")
	await shot("01-patio")
	front.park.hide_characters()
	await shot("02-patio-geometria")
	for entry in [["03-trilha",Vector2(33.5,35.5)],["04-ponte",Vector2(30.5,27.5)],["05-rampa",Vector2(42.5,24.5)]]:
		front.park.camera.position=front.park.model.project(entry[1])
		await shot(entry[0])
	for entry in [["06-rampa-norte",Vector2(26.5,15.5)],["07-rampa-oeste",Vector2(17.5,26.5)],["08-rampa-patio",Vector2(48.5,29.5)],["09-rampa-sul",Vector2(23.5,38.5)]]:
		front.park.camera.position=front.park.model.project(entry[1])
		front.park.camera.zoom=Vector2(1.6,1.6)
		await shot(entry[0])
	print("VEREDAS ART: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
