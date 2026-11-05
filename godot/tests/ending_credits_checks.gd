extends SceneTree
## F28 (MAPA-DE-REFINAMENTOS): after the credits, a failed save keeps the title and
## leaves the "Voltar à cidade" button usable; the retry goes home with the title kept.
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
const Finals = preload("res://scripts/campaign/ruinas_elo.gd")
var checks := 0
var failures := 0
class FailingStore extends "res://scripts/campaign/save_store.gd":
	func save_slot(_snapshot: Dictionary) -> Dictionary: return {"status":"io_error"}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func _initialize() -> void:
	run.call_deferred()

func credits(view: Node) -> Node:
	for child in view.get_children():
		if child.get("ok_button_text") == "Voltar à cidade" and not child.is_queued_for_deletion(): return child
	return null

func run() -> void:
	var view := FrontEnd.new()
	root.add_child(view)
	view.preferences.reduced_motion = true
	await process_frame
	var disk = preload("res://scripts/campaign/save_store.gd").new("user://ending-credits-" + State.new_id())
	view.session._store = disk
	view.session.start("slot-1")
	var built: Dictionary = QA.build("final")
	for stage in Finals.BRACKET: built.player.flags[stage[3]] = true
	built.checkpoint = CP.make("kronasta-estadio-a", Vector2(24.5, 9.5), CP.SPACE)
	check(view.session.checkpoint(built.checkpoint, built.player).status == "ok", "champion fixture saved")
	view._show_kronasta_credits()
	await process_frame
	var panel: Node = credits(view)
	check(panel != null, "credits shown")
	view.session._store = FailingStore.new()
	panel._finish(true)
	await process_frame
	await process_frame
	check(is_instance_valid(panel) and credits(view) == panel and not panel._closed, "failed save keeps the credits usable")
	var kept: Dictionary = view.session.snapshot()
	check(kept.player.flags.get("campeaoKronasta", false) and not kept.player.flags.get("kronastaEndingSeen", false), "title kept, ending not marked seen")
	check(kept.checkpoint.scene == "kronasta-estadio-a", "still in the stadium after the failure")
	view.session._store = disk
	panel._finish(true)
	for frame in 5: await process_frame
	var home: Dictionary = view.session.snapshot()
	check(home.player.flags.get("kronastaEndingSeen", false) and home.player.flags.get("campeaoKronasta", false), "retry records the ending with the title")
	check(home.checkpoint.scene == "quintal", "retry returns to the city")
	check(credits(view) == null, "credits closed after the retry")
	# BIBLIA §13: the epilogue closes the arcs once, then the post-credits hook.
	var seen := PackedStringArray()
	var started := Time.get_ticks_msec()
	while not view.session.snapshot().player.flags.get("kronastaEpilogueSeen", false) and Time.get_ticks_msec() - started < 20000:
		await process_frame
		for child in view.get_children():
			if child.get("dialog_text") != null and child.has_method("_finish") and child.visible and not child.get("_closed") and not child.is_queued_for_deletion():
				seen.append(str(child.title) + "|" + str(child.dialog_text))
				child._finish(true)
	var told := "\n".join(seen)
	check(view.session.snapshot().player.flags.get("kronastaEpilogueSeen", false), "epilogue recorded after the credits")
	check(told.contains("câmara do ovo") and told.contains("Você é o Tyler") and told.contains("voltar a pesquisar") and told.contains("remendo"), "Elo stays, Assis accepts Tyler, Heleana researches, post-credits hook")
	check(seen.size() == 4, "four epilogue pages, shown once (got %d)" % seen.size())
	check(view.session.snapshot().checkpoint.scene == "quintal", "epilogue keeps the player in the city")
	var branch: Dictionary = QA.build("final").player
	branch.flags.retalhoParceiraHeleana = true
	check(str(FrontEnd.epilogue_pages(branch)[2][1]).contains("A Retalho e eu"), "Heleana researches with Retalho when she took her back")
	branch.flags.erase("retalhoParceiraHeleana")
	branch.flags.heleanaLacoKael = true
	check(str(FrontEnd.epilogue_pages(branch)[2][1]).contains("Você e a Retalho"), "Retalho comes with Kael when she chose him")
	check(view.session.resume_slot("slot-1").status == "ok" and view.session.snapshot().player.flags.get("campeaoKronasta", false), "title survives reloading")
	print("ENDING CREDITS: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
