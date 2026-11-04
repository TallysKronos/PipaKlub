extends RefCounted
## Public Theme entry; semantic variations replace per-view color/style overrides.
const PATH := "res://assets/ui/recorte-v1/theme/recorte_theme.tres"
static var _theme: Theme

static func shared() -> Theme:
	if _theme == null: _theme = load(PATH)
	return _theme

static func install(surface: Control, reduced_motion: bool = false) -> void:
	surface.theme = shared()
	var controller := surface.get_node_or_null("RecorteUX")
	if controller == null:
		controller = load("res://scripts/campaign/recorte_ux.gd").new()
		controller.name = "RecorteUX"
		controller.reduced_motion = reduced_motion
		surface.add_child(controller)
	else: controller.set_reduced_motion(reduced_motion)
