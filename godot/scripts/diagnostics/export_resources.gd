extends SceneTree
## Editor-side wrapper; release uses the explicitly gated in-app dispatcher.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	quit(preload("res://scripts/diagnostics/export_resources_probe.gd").new().run(self))
