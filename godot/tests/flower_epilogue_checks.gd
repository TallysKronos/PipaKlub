extends SceneTree
## F29 (MAPA-DE-REFINAMENTOS): the flower of the optional Fantasma quest opens Tyler's
## epilogue in the laboratory. With the flower: the talk can wait, then the flower is
## given once, with a reaction. Without it: no impossible request, campaign unchanged.
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
const Arcs = preload("res://scripts/campaign/tyler_arcs.gd")
const Story = preload("res://scripts/campaign/kronasta_story.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func _initialize() -> void:
	run.call_deferred()

func dialogs(view: Node) -> Array:
	return view.get_children().filter(func(c): return c.get("ok_button_text") != null and c.has_signal("confirmed") and not c.is_queued_for_deletion() and c.visible)

func quest(player: Dictionary) -> Dictionary:
	for entry in Story.optional_quests(player):
		if entry.title == "A Flor de Cerejeira": return entry
	return {}

func open(view: Node, flower: bool) -> void:
	view.session._store = preload("res://scripts/campaign/save_store.gd").new("user://flower-epilogue-" + State.new_id())
	view.session.start("slot-1")
	var built: Dictionary = QA.build("final")
	built.player.flags.demoEndingSeen=true
	if not flower: built.player.inventory.erase(Arcs.Flower)
	view.session.checkpoint({"kind":"world","scene":"professor-home","position":[912,480]}, built.player)

func run() -> void:
	root.size=Vector2i(1280,720)
	# Logic: when the epilogue opens and what the diary says.
	var early: Dictionary = QA.build("rato").player
	check(int(early.inventory.get(Arcs.Flower, 0)) == 1, "QA jump after the Fantasma carries the flower")
	check(not Arcs.finale_ready(early) and quest(early).text.contains("final de Kronasta abrir"), "before the final opens the diary says when")
	var ready: Dictionary = QA.build("final").player
	check(Arcs.finale_ready(ready) and quest(ready).text.contains("laboratório"), "final open: the diary points to the laboratory")
	var without: Dictionary = QA.build("final").player
	without.inventory.erase(Arcs.Flower)
	without.flags.erase("pipeiroFantasmaResolvido")
	check(not Arcs.finale_ready(without) and quest(without).is_empty(), "without the quest: no flower step")
	check(Story.current_beat(without).get("id", "") == Story.current_beat(ready).get("id", ""), "main campaign is the same without the flower")

	var view := FrontEnd.new()
	root.add_child(view)
	view.preferences.reduced_motion = not "--motion" in OS.get_cmdline_user_args()
	await process_frame
	# Without the flower, the study falls back to its normal use.
	open(view, false)
	check(not view._tyler_study(), "no epilogue request without the flower")
	# Interrupted: the flower stays and the talk is still there.
	open(view, true)
	check(view._tyler_study(), "epilogue offered with the flower")
	var talk: Array = dialogs(view)
	check(talk.size() == 1 and talk[0].dialog_text.contains("DNA é do Assis") and talk[0].dialog_text.contains("Você já sabe"), "talk separates what Kael knew from Tyler's dilemma")
	check(talk[0].dialog_text.contains("fios") and talk[0].dialog_text.contains("Câmara"), "Kael answers with Tyler's own choices")
	talk[0]._finish(false)
	await process_frame
	check(int(view.session.snapshot().player.inventory.get(Arcs.Flower, 0)) == 1 and Arcs.finale_ready(view.session.snapshot().player), "leaving it for later keeps the flower")
	# Delivered once, with a reaction.
	check(view._tyler_study(), "epilogue offered again")
	dialogs(view)[0]._finish(true)
	var started:=Time.get_ticks_msec()
	while dialogs(view).filter(func(d):return d.dialog_text.contains("Caiu junto")).is_empty() and Time.get_ticks_msec()-started<12000:
		await process_frame
	var player: Dictionary = view.session.snapshot().player
	check(player.flags.get("tylerFlowerGiven", false) and not player.inventory.has(Arcs.Flower), "flower given and consumed")
	var reaction: Array = dialogs(view).filter(func(d): return d.dialog_text.contains("Caiu junto"))
	check(reaction.size()==1, "spoken reaction follows the visible delivery")
	var scene=view.room.get_node_or_null("TylerEpilogue")
	check(scene!=null and is_instance_valid(scene.flower),"flower exists in the scene")
	check(scene.flower.position.distance_to(view.room.project(scene.point)+Vector2(0,-42))<1,"flower reaches Tyler")
	check(Arcs.presentation_pending(player),"presentation can resume after delivery")
	view.session.close_session()
	check(view.session.resume_slot("slot-1").status=="ok","reload after flower is consumed")
	view._show_saved()
	started=Time.get_ticks_msec()
	while dialogs(view).filter(func(d):return d.dialog_text.contains("Caiu junto")).is_empty() and Time.get_ticks_msec()-started<12000:
		await process_frame
	reaction=dialogs(view).filter(func(d):return d.dialog_text.contains("Caiu junto"))
	check(reaction.size()==1,"pending presentation resumes automatically")
	check(not view.session.snapshot().player.inventory.has(Arcs.Flower),"resume does not recreate the flower")
	if reaction.is_empty():quit(1);return
	scene=view.room.get_node_or_null("TylerEpilogue")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var folder:=ProjectSettings.globalize_path("res://../tmp/flower-review")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder.path_join("entrega.png"))
	if not reaction.is_empty():reaction[0]._finish(true)
	started=Time.get_ticks_msec()
	while Arcs.presentation_pending(view.session.snapshot().player) and Time.get_ticks_msec()-started<18000:
		await process_frame
	for frame in 12:await process_frame
	player=view.session.snapshot().player
	check(player.flags.get("tylerFlowerSceneSeen",false),"exit completes the presentation")
	check(not view.flow_busy,"exploration restored after the scene")
	check(view.session.snapshot().checkpoint.scene in ["professor-home","quintal"],"scene returns to a valid location")
	check(quest(player).done, "diary records the epilogue")
	check(not view._tyler_study() and Arcs.finish_finale(view.session).status == "wrong_step", "single delivery")
	check(view.session.resume_slot("slot-1").status == "ok" and view.session.snapshot().player.flags.get("tylerFlowerGiven", false), "epilogue survives reloading")
	view.queue_free()
	await process_frame
	await process_frame
	print("FLOWER EPILOGUE: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
