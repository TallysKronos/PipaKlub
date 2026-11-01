extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const Training=preload("res://scripts/campaign/park_training.gd")
var front: Control
var output: String
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL ",label)
func shot(id: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))
func place(scene: String,point: Vector2,xp: int=0) -> void:
	var map=Checkpoint.model_for(scene)
	for event in map.data.events+Training.events(Checkpoint.MAPS[scene],map):
		if event.type!="npc" or point.distance_to(Vector2(event.u+.5,event.v+.5))>.1: continue
		for offset in [Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN,Vector2.UP]:
			var candidate: Vector2=point+offset
			if map.walkable(Vector2i(candidate.floor())) and absf(map.height_at(candidate)-map.height_at(point))<.25: point=candidate;break
		break
	var saved: Dictionary=front.session.snapshot()
	saved.player.partners=[{"id":"flow-review","modelId":"rabbito","personalName":"Rabbito","xp":xp,"craftBonus":0,"condition":{"line":100,"structure":100}}]
	saved.player.equippedPartnerId="flow-review"
	saved.player.journey={"lesson":5,"phase":"complete"}
	saved.player.flags={"ninaAccepted":true}
	check(front.session.checkpoint(Checkpoint.make(scene,point,Checkpoint.SPACE),saved.player).status=="ok","fixture stored through actual local session")
	front._show_saved()
	for i in 180:
		await process_frame
		if is_instance_valid(front.park) and not front.flow_busy: break
	check(is_instance_valid(front.park) and not front.flow_busy,"loading reveals playable area")
	front.park.set_physics_process(false)
func dialog() -> Control:
	var all:=get_nodes_in_group("manga_dialogue")
	return all.back() if not all.is_empty() else null
func close_dialog() -> void:
	if dialog()!=null: dialog().canceled.emit();dialog().queue_free()
	await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../documentation/campaign/park-flow-refinement")
	DirAccess.make_dir_recursive_absolute(output)
	front=load("res://scripts/campaign/front_end.gd").new()
	var temporary: String=ProjectSettings.globalize_path("res://../tmp/flow-review-"+State.new_id())
	front.session._store=load("res://scripts/campaign/save_store.gd").new(temporary)
	front.preferences.storage_path=temporary+"-settings.cfg"
	front.preferences.reduced_motion=true
	root.add_child(front)
	check(front.session.start("slot-1").status=="ok","isolated save starts")
	await place("park-trail",Training.point("assis",Checkpoint.model_for("park-trail")))
	await shot("01-professor-no-parque")
	front._park_training("assis")
	check(front.park.paused and dialog()!=null,"trainer conversation pauses world")
	await shot("02-primeiro-duelo")
	await close_dialog()
	check(not front.park.paused,"cancel returns to exploration")
	var point: Vector2=front.park.player
	check(front.encounters.start_training("assis",point).status=="ok","trainer service uses saved scene")
	var held: Dictionary=front.session.snapshot().player.encounter
	check(front.session._store.load_slot("slot-1").data.player.encounter.trainerId=="assis","trainer survives actual disk reload")
	front._show_saved()
	front.battle.set_process(false)
	await shot("03-duelo-identificado")
	var state: Dictionary=held.state
	state.outcome="fled"
	check(front.encounters.save_battle(state).status=="ok" and front.encounters.settle().status=="ok","leaving training settles without XP")
	await place("park-clearing",Vector2(29.5,39.5),450)
	var saved: Dictionary=front.session.snapshot()
	saved.player.partners[0].condition={"line":0,"structure":15}
	check(front.session.checkpoint(saved.checkpoint,saved.player).status=="ok","injured state persists")
	front.park.refresh(front.session.snapshot().player)
	await shot("04-descanso-orientado")
	front._park_event("37")
	check(dialog()!=null and front.park.paused,"bench opens recovery choice")
	await shot("05-banco-recupera")
	if dialog()!=null: dialog().confirmed.emit()
	for i in 3: await process_frame
	check(front.session.snapshot().player.partners[0].condition.line==100 and front.session.snapshot().player.partners[0].condition.structure==100,"bench heals through actual session")
	await shot("06-equipe-recuperada")
	await place("park-veredas",Checkpoint.target("park-veredas","boss"),650)
	front._park_action("boss")
	check(dialog()!=null and dialog().dialog_text.contains("Nv. 6") and dialog().dialog_text.contains("Nv. 8"),"boss warning shows actual and recommended levels")
	await shot("07-preparacao-boss")
	await close_dialog()
	await place("park-veredas",Training.point("tiao",Checkpoint.model_for("park-veredas")),1100)
	await shot("08-ultimo-treino")
	var report:={"checks":checks,"failures":failures,"isolatedSave":true,"nativeResolution":[1280,720]}
	var file:=FileAccess.open(output.path_join("ui-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("PARK FLOW UI: ",JSON.stringify(report))
	quit(1 if failures else 0)
