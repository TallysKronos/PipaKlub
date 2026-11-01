extends SceneTree
var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); printerr("FAIL ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view: Node2D = load("res://scripts/overworld/view.gd").new()
	view.area_id = "kronasta-bosque-b"
	view.art_preview = false
	root.add_child(view)
	await process_frame
	view.set_physics_process(false)
	check(view.player == Vector2(24.5,41.5), "B defaults to its south entrance")
	var back: Dictionary = {}
	for event in view.model.data.events:
		if event.type == "saida" and event.props.destino == "kronasta-bosque-a": back = event
	check(not back.is_empty(), "B declares return to A")
	view.nearby = back
	view.interact()
	check(view.area_id == "kronasta-bosque-a", "return loads A")
	check(view.player == Vector2(24.5,2.5), "return arrives beside A north exit")
	check(view.follower == view.player, "follower arrives on the same surface")
	for invalid in [{"chegada_u":-1,"chegada_v":-1},{"chegada_u":0,"chegada_v":0},{"chegada_u":"bad","chegada_v":2},{"chegada_u":24.5,"chegada_v":2},{"chegada_u":24}]:
		view.load_area("kronasta-bosque-a",invalid)
		check(view.player == Vector2(27.5,41.5), "invalid arrival falls back to A entrance")
	view.load_area("kronasta-bosque-c",{"chegada_u":24,"chegada_v":41})
	check(view.player == Vector2(24.5,41.5), "C arrival preserves matching south approach")
	view.queue_free()
	await process_frame
	print("BOSQUE ARRIVALS ",checks," checks; ",failures.size()," failures; no saves changed")
	quit(0 if failures.is_empty() else 1)
