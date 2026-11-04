extends "res://tests/veredas_map_checks.gd"
## Reuse the actual ramp/bridge/exit traversal at sprint speed, including follower.
func run() -> void:
	preload("res://scripts/campaign/locomotion.gd").toggled=true
	await super.run()
