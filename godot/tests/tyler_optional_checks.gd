extends SceneTree
## F01 (MAPA-DE-REFINAMENTOS): the Pipeiro Fantasma is optional. After Leo Antena the
## main objective goes to the laboratory with the quest done, ignored or left for later;
## only finishing the quest gives the flower, once.
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const Story = preload("res://scripts/campaign/kronasta_story.gd")
const Arcs = preload("res://scripts/campaign/tyler_arcs.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func fresh_session() -> Node:
	var session := Session.new()
	session._store = Store.new("user://tyler-optional-" + State.new_id())
	root.add_child(session)
	session.start("slot-1")
	# The "centro" QA jump: Leo Antena still ahead; then win him without the Fantasma.
	QA.install(session, "centro")
	var player: Dictionary = session.snapshot().player
	var entry: Dictionary = Rules.entry(player, "centro")
	entry.completed = true; entry.rewardClaimed = true; entry.champion = "player"
	Rules.store(player, "centro", entry)
	player.flags.pipaTvPedido = true
	session.checkpoint({"kind":"world","scene":"professor-home","position":[1056,1232]}, player)
	return session

func win_lab(session: Node) -> bool:
	if Arcs.begin_lab(session).status != "ok": return false
	var saved: Dictionary = session.snapshot()
	saved.player.encounter.state.outcome = "won"
	session.checkpoint(saved.checkpoint, saved.player)
	return Arcs.settle_lab(session).status == "ok"

func ghost(session: Node) -> Dictionary:
	var player: Dictionary = session.snapshot().player
	session.checkpoint(load("res://scripts/campaign/park_checkpoint.gd").make("kronasta-centro-c", Vector2(24.5, 20.5), "parque-overworld-v1"), player)
	return Arcs.finish_ghost(session)

func flowers(session: Node) -> int:
	return int(session.snapshot().player.inventory.get(Arcs.Flower, 0))

func _initialize() -> void:
	# Ignored: the main objective goes straight to the laboratory.
	var ignored := fresh_session()
	var p: Dictionary = ignored.snapshot().player
	check(Story.current_beat(p).id == "homunculo", "after Leo Antena the main step is the laboratory")
	check(not Story.objective(p).contains("Fantasma"), "main objective does not ask for the Fantasma")
	var side: Array = Story.optional_quests(p).filter(func(q): return q.title == "O Pipeiro Fantasma")
	check(side.size() == 1 and not side[0].done, "Fantasma listed as an open side quest")
	check(win_lab(ignored), "laboratory reachable without the Fantasma")
	p = ignored.snapshot().player
	check(p.flags.get("tylerCreatedKnown", false) and not p.flags.get("pipeiroFantasmaResolvido", false), "laboratory does not complete the Fantasma")
	check(flowers(ignored) == 0, "no flower without the quest")
	check(Story.current_beat(p).id == "barreira", "campaign continues to the night of the cerol")
	# Left for later: still available after the laboratory, gives the flower once.
	check(ghost(ignored).status == "ok" and flowers(ignored) == 1, "Fantasma after the laboratory gives the flower")
	check(ghost(ignored).status == "wrong_step" and flowers(ignored) == 1, "no second flower")
	check(Story.optional_quests(ignored.snapshot().player).any(func(q): return q.title == "A Flor de Cerejeira" and not q.done), "flower kept as a later side step")
	# Done first: the laboratory still opens and the flower stays single.
	var first := fresh_session()
	check(ghost(first).status == "ok" and flowers(first) == 1, "Fantasma before the laboratory")
	first.checkpoint({"kind":"world","scene":"professor-home","position":[1056,1232]}, first.snapshot().player)
	check(win_lab(first) and flowers(first) == 1, "laboratory after the Fantasma keeps one flower")
	print("TYLER OPTIONAL: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
