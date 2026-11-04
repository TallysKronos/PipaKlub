extends SceneTree
## QA jumps (qa_jump.gd): every story point builds a save the game accepts, opens
## at the intended place with the story pointing there, and never touches real slots.
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
const Story = preload("res://scripts/campaign/kronasta_story.gd")
const Endgame = preload("res://scripts/campaign/endgame_story.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)
func _initialize() -> void:
	var expected := {"serra":"tufanocorte","dona-neve":"dona-neve","aracati":"rabiolava","trovareta":"trovareta","reuniao":"reuniao","centro":"pipa-tv","noite":"barreira","taina":"taina","galpao":"galpao","gerador":"gerador","porto":"jurandir","ruinas":"ruinas-aliados","rato":"gollia-arrependimento","mirante":"icaro","final":"final"}
	for entry: Dictionary in QA.JUMPS:
		var built: Dictionary = QA.build(entry.id)
		check(not built.is_empty(), entry.id + " builds")
		var session := Session.new()
		session._store = Store.new("user://qa-jump-check-" + State.new_id())
		root.add_child(session)
		check(session.start("slot-1").status == "ok" and QA.install(session, entry.id).status == "ok", entry.id + " save accepted")
		var player: Dictionary = session.snapshot().player
		check(Story.current_beat(player).get("id", "") == expected[entry.id], entry.id + " story points to " + expected[entry.id] + " (got " + str(Story.current_beat(player).get("id", "")) + ")")
		var place: String = Story.place_for_scene(built.checkpoint.scene).get("id", "")
		check(Story.state(player, place) in ["aberto", "vencido"], entry.id + " opens in a reachable place: " + place)
		if Endgame.STEPS.has(entry.at): check(Endgame.ready(player, entry.at), entry.id + " step " + entry.at + " is available")
		session.queue_free()
	print("QA JUMP: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
