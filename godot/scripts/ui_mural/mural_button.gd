extends Button
## Native Button owns hitbox/input/disabled/pressed; art and focus never animate text.
const Mural = preload("res://scripts/ui_mural/mural_theme.gd")
const T = preload("res://scripts/campaign/ui_tokens.gd")
var icon_id := ""
var variant := "MuralButton"
var illustration: TextureRect
const ICON_SIZE := Vector2(96,96)
const ICON_POSITION := Vector2(-16,-12)

func _ready() -> void:
	custom_minimum_size = Vector2(264, 82)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	# The native Button icon shrinks into the text's content height. A separate
	# illustration keeps its optical size and can break the paper silhouette.
	if not icon_id.is_empty():
		icon = null
		illustration=TextureRect.new()
		illustration.name="IllustratedIcon"
		illustration.texture=Mural.icon(icon_id)
		illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		illustration.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
		illustration.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		illustration.position=ICON_POSITION
		illustration.size=ICON_SIZE
		illustration.z_index=1
		add_child(illustration)
	focus_entered.connect(_sync)
	focus_exited.connect(_sync)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	set_available(not disabled)

func set_available(available:bool) -> void:
	disabled=not available
	focus_mode=Control.FOCUS_ALL if available else Control.FOCUS_NONE
	if is_instance_valid(illustration):illustration.modulate=T.alpha(T.UNTINTED,1.0 if available else .45)
	_sync()

func icon_visual_bounds() -> Rect2:
	# Optical 224/256 content, plus its 2px paper keyline / 3px cast shadow.
	return Rect2(-12,-8,90,92) if is_instance_valid(illustration) else Rect2()

func _has_point(point:Vector2) -> bool:
	# The protruding part remains clickable, without expanding into the next card.
	return Rect2(Vector2.ZERO,size).has_point(point) or (is_instance_valid(illustration) and Rect2(-10,-6,84,84).has_point(point))

func _sync() -> void:
	theme_type_variation = "MuralFocusButton" if has_focus() else variant
	queue_redraw()

func _draw() -> void:
	if is_instance_valid(illustration) and illustration.texture != null:
		var r:=Rect2(ICON_POSITION,ICON_SIZE)
		var opacity:=.45 if disabled else 1.0
		draw_texture_rect(illustration.texture,Rect2(r.position+Vector2(2,3),r.size),false,T.alpha(T.MURAL_INK,.28*opacity))
		for offset in [Vector2(-2,0),Vector2(2,0),Vector2(0,-2),Vector2(0,2)]:
			draw_texture_rect(illustration.texture,Rect2(r.position+offset,r.size),false,T.alpha(T.MURAL_PAPER,opacity))
	if disabled or not has_focus(): return
	# A static paper-kite corner distinguishes focus without relying on color.
	var p := Vector2(size.x-18, 15)
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-7),p+Vector2(7,0),p+Vector2(0,9),p+Vector2(-7,0)]),T.MURAL_INK)
	draw_polyline(PackedVector2Array([p+Vector2(0,9),p+Vector2(5,13),p+Vector2(1,17)]),T.MURAL_INK,2,true)
