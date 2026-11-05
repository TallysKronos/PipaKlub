extends SceneTree
## F05: a story notice opened while a map is loading (after a duel) is shown once the
## load ends, instead of being erased when the load clears the screen.
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL ", message)

func _initialize() -> void:
	run.call_deferred()

func notices(view: Node) -> Array:
	return view.get_children().filter(func(c): return c.get("dialog_text") == "Os fios cederam." and not c.is_queued_for_deletion())

func run() -> void:
	var view := FrontEnd.new()
	root.add_child(view)
	view.preferences.reduced_motion = true
	for i in 5: await process_frame
	var loading := CanvasLayer.new()
	view.add_child(loading)
	view.scene_loading = loading
	view._notice("Os fios cederam.")
	for i in 3: await process_frame
	check(notices(view).is_empty(), "notice waits while the map loads")
	# The load clears the screen, then ends.
	view._clear()
	loading.queue_free()
	view.scene_loading = null
	for i in 3: await process_frame
	check(notices(view).size() == 1, "notice shown once the load ends")
	print("NOTICE AFTER LOAD: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
