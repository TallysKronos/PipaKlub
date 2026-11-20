extends RefCounted
## Fixed probes only; no arbitrary resource paths or player-profile access.
static var claimed := false

static func try_run(host: Control) -> bool:
	if claimed or OS.get_environment("SOULMONSTERS_PACKAGE_PROBE") != "1": return false
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or args[0] != "--package-probe": return false
	claimed = true
	var tree := host.get_tree()
	var mode: String = args[1] if args.size() == 2 else "invalid"
	# The host has not attached these freshly allocated services yet.
	host.sound.free()
	host.session.free()
	host.queue_free()
	execute.call_deferred(tree, mode)
	return true

static func execute(tree: SceneTree, mode: String) -> void:
	if mode not in ["resources", "create", "resume"]:
		printerr("Unknown package probe")
		tree.quit(1)
		return
	var path := "res://scripts/diagnostics/export_resources_probe.gd" if mode == "resources" else "res://scripts/diagnostics/package_journey.gd"
	var probe: RefCounted = load(path).new()
	var result: int = await probe.run(tree)
	tree.quit(result)
