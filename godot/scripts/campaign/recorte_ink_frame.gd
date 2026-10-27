extends Control
## Decorative NinePatchRect only. The owner supplies its geometric fill and text.
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
@export var asset_id := "frame-panel"
@export var high_density := false
var patch: NinePatchRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch = NinePatchRect.new()
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	patch.draw_center = false
	patch.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	patch.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	add_child(patch)
	resized.connect(refresh)
	refresh()

func refresh() -> void:
	if patch == null: return
	var asset := Ink.definition(asset_id)
	if asset.is_empty(): return
	var density := 2 if high_density else 1
	custom_minimum_size = Vector2(asset.slice.minimum[0], asset.slice.minimum[1])
	patch.texture = Ink.texture(asset_id, high_density)
	patch.modulate = Tokens.PAPEL if asset.slice.mode == "three_slice" else Tokens.UNTINTED
	patch.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH if asset.slice.mode == "three_slice" else NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	patch.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH if asset.slice.mode == "three_slice" else NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	patch.scale = Vector2.ONE / density
	patch.size = size * density
	var margins: Array = asset.slice.margins
	patch.patch_margin_left = int(margins[0]) * density
	patch.patch_margin_top = int(margins[1]) * density
	patch.patch_margin_right = int(margins[2]) * density
	patch.patch_margin_bottom = int(margins[3]) * density
	patch.draw_center = asset.slice.mode == "three_slice"
	# NinePatchRect clips neither content nor hit targets: this layer is artwork only.
