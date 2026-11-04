extends SceneTree
const Front = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Morro = preload("res://scripts/campaign/morro.gd")
const View = preload("res://scripts/campaign/morro_view.gd")
var checks := 0
var failures := 0
func check(value: bool, text: String) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", text)
	return value
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/morro-maps.json"))
	for fixture in fixtures:
		var view := View.new()
		view.data = Morro.maps()[fixture.id]
		view.foot_radius = 12
		for probe in fixture.probes: check(view.safe(Vector2(probe.point[0], probe.point[1])) == probe.safe, fixture.id + " source collision parity")
		for edge in view.data.edges:
			var a: Array = view.data.nodes[edge[0]]
			var b: Array = view.data.nodes[edge[1]]
			check(view.segment(Vector2(a[0], a[1]), Vector2(b[0], b[1])), fixture.id + " exported edge preserves terrain transitions")
		view.free()
	var front := Front.new()
	front.session._store = Store.new("user://morro-checks-" + State.new_id())
	root.add_child(front)
	await process_frame
	check(front.session.start("slot-1").status == "ok", "isolated slot")
	var saved: Dictionary = front.session.snapshot()
	saved.player.partners = [{"id": "partner", "modelId": "basica", "craftBonus": 12, "xp": 0, "condition": {"line": 100, "structure": 100}}]
	saved.player.equippedPartnerId = "partner"
	saved.player.journey = {"phase": "complete", "lesson": 5}
	check(front.session.checkpoint({"kind": "world", "scene": "morro", "position": [528, 752]}, saved.player).status == "ok", "enter Morro checkpoint")
	front._show_saved()
	await process_frame
	check(front.park != null, "Morro view created")
	check(front.park.gate_closed, "gate initially closed")
	var data: Dictionary = front.park.data
	var npc: Dictionary = data.places.filter(func(p): return p.has("stage"))[0]
	check(front.park.walk_to(Vector2(npc.point[0], npc.point[1])), "NPC reachable before victory")
	var exit: Dictionary = data.places.filter(func(p): return p.get("action", "") == "road_next")[0]
	check(not front.park.walk_to(Vector2(exit.point[0], exit.point[1])), "gate blocks click path")
	for viewport_size in [Vector2i(1280, 720), Vector2i(1024, 768)]:
		root.size = viewport_size
		for frame in 2:await process_frame
		var story: Dictionary = Morro.Rules.content().stories["morro-3"]
		var text: String = "\n\n".join(story.before.map(func(line): return "%s: %s" % [line[0], line[1]])) + "\n\n" + story.tactic
		front._confirm_park("Juninho e Lia", text, "Vamos voar!", func(): pass)
		for index in 4: await process_frame
		for child in front.get_children():
			if not child.is_in_group("manga_dialogue"): continue
			# The new dialogue is a Control in stretched UI units, rather than a Window in pixels.
			check(Rect2(Vector2.ZERO,front.size).encloses(child.get_rect()), "long dialogue stays inside UI viewport " + str(viewport_size))
			var button_rect: Rect2 = child.get_ok_button().get_global_rect()
			check(button_rect.end.y <= child.size.y and button_rect.position.y >= 0, "dialogue action remains visible " + str(viewport_size))
			child.canceled.emit()
		await process_frame
	front.free()
	await process_frame
	print("Morro maps/views: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
