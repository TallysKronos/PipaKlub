extends RefCounted
static func text_scale_for(node:Node) -> float:
	var ancestor:=node.get_parent()
	while ancestor!=null:
		if ancestor.has_meta("hud_text_scale"):return float(ancestor.get_meta("hud_text_scale"))
		ancestor=ancestor.get_parent()
	return 1.0
## Opt-in PIP-130 foundation. Does not install globally or alter campaign flows.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const PATH := "res://assets/ui/mural-v1/theme/mural_theme.tres"
const ROOT := "res://assets/ui/mural-v1/"
static var _theme: Theme
static var _icons: Dictionary = {}

static func shared() -> Theme:
	if _theme == null: _theme = load(PATH)
	return _theme

static func install(surface: Control) -> void:
	surface.theme = shared()

static func icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var path := ROOT + "icons/" + id + ".png"
		if not ResourceLoader.exists(path): return null
		_icons[id] = load(path)
	return _icons[id]
